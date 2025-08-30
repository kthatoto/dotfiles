-- lua/plugins/lsp.lua
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    ----------------------------------------------------------------
    -- Mason
    ----------------------------------------------------------------
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = {
        "vue_ls", "vtsls",
        "lua_ls", "ruby_lsp", "rubocop", "tailwindcss", "yamlls", "zk", "sorbet",
      },
    })

    local lspconfig    = require("lspconfig")
    local configs      = require("lspconfig.configs")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    local util         = lspconfig.util

    ----------------------------------------------------------------
    -- 保険：.vue の filetype を保証
    ----------------------------------------------------------------
    vim.filetype.add({ extension = { vue = "vue" } })

    ----------------------------------------------------------------
    -- ルート検出（最寄り → Git → ファイルディレクトリ）
    ----------------------------------------------------------------
    local function root(fname)
      return util.root_pattern(
        "pnpm-workspace.yaml","yarn.lock","package-lock.json",
        "package.json","tsconfig.json",".git"
      )(fname) or util.find_git_ancestor(fname) or util.path.dirname(fname)
    end

    ----------------------------------------------------------------
    -- Mason パス（bin 直指定 & Vue プラグイン location 解決）
    ----------------------------------------------------------------
    local mason_root = vim.fn.stdpath("data") .. "/mason"
    local function mason_bin(exe) return mason_root .. "/bin/" .. exe end
    local function vue_language_server_dir()
      local p = mason_root .. "/packages/vue-language-server/node_modules/@vue/language-server"
      local uv = vim.uv or vim.loop
      return ((uv.fs_stat and uv.fs_stat(p)) or vim.fn.isdirectory(p) == 1) and p or nil
    end
    local vue_ls_dir = vue_language_server_dir()

    ----------------------------------------------------------------
    -- 表示ノイズを減らす（基本は signs/underline、float はカーソル下だけ）
    ----------------------------------------------------------------
    vim.diagnostic.config({
      virtual_text = false,          -- グローバルでは消す
      signs = true,
      underline = true,
      severity_sort = true,
      update_in_insert = false,
    })
    -- .vue でホバー無しでもカーソル下だけ自動で表示
    vim.o.updatetime = 300
    vim.api.nvim_create_autocmd({ "FileType" }, {
      pattern = "vue",
      callback = function(args)
        vim.diagnostic.config({ virtual_text = false }, args.buf)  -- 念のためバッファローカルでも無効
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
          buffer = args.buf,
          callback = function()
            vim.diagnostic.open_float(nil, {
              focus = false,
              scope = "cursor",
              border = "rounded",
              source = "if_many",
            })
          end,
        })
      end,
    })

    ----------------------------------------------------------------
    -- 競合しやすい ts_ls は停止（vtsls を使う）
    ----------------------------------------------------------------
    if lspconfig.ts_ls then lspconfig.ts_ls.setup({ autostart = false }) end

    ----------------------------------------------------------------
    -- 共通 on_attach：.vue では vtsls の“診断だけ”を無効化（template誤判定の荒れを防止）
    ----------------------------------------------------------------
    local function on_attach(client, bufnr)
      if client.name == "vtsls" and vim.bo[bufnr].filetype == "vue" then
        client.handlers["textDocument/publishDiagnostics"] = function() end
      end
      vim.keymap.set("n", "<space>h", vim.lsp.buf.hover, { buffer = bufnr, desc = "LSP Hover" })
    end

    ----------------------------------------------------------------
    -- vtsls：TS/JS + .vue にも attach（←重要）
    --    - @vue/typescript-plugin の location は「@vue/language-server」を指す
    --    - autoUseWorkspaceTsdk でプロジェクトの TS を優先
    --    - tsserver メモリ増量（必要に応じて調整）
    ----------------------------------------------------------------
    local vtsls_settings = {
      vtsls = {
        autoUseWorkspaceTsdk = true,
        tsserver = {
          globalPlugins = {},
        },
      },
      typescript = { tsserver = { maxTsServerMemory = 6144 } },
      javascript = { tsserver = { maxTsServerMemory = 6144 } },
    }
    if vue_ls_dir then
      table.insert(vtsls_settings.vtsls.tsserver.globalPlugins, {
        name = "@vue/typescript-plugin",
        location = vue_ls_dir,          -- ★ plugin 本体でなく “親”（@vue/language-server）
        languages = { "vue" },
        configNamespace = "typescript",
      })
    end

    lspconfig.vtsls.setup({
      cmd          = { mason_bin("vtsls"), "--stdio" },
      filetypes    = { "vue","typescript","javascript","javascriptreact","typescriptreact" },
      root_dir     = root,
      settings     = vtsls_settings,
      on_attach    = on_attach,
      capabilities = capabilities,
    })

    ----------------------------------------------------------------
    -- Vue LSP：新名が無ければ 'volar' に自動フォールバック
    --    - hybridMode=true で vtsls と協調（template 側の診断は vue_ls が担当）
    --    - 古い lspconfig 向けに on_init で tsserver/request を vtsls/ts_ls に橋渡し
    --    - cmd は Mason bin を直指定
    ----------------------------------------------------------------
    local VUE_SERVER = (configs.vue_ls ~= nil) and "vue_ls" or "volar"
    if VUE_SERVER == "vue_ls" and lspconfig.volar then
      lspconfig.volar.setup({ autostart = false }) -- 新名がある環境では旧名をブロック
    end

    lspconfig[VUE_SERVER].setup({
      cmd          = { mason_bin("vue-language-server"), "--stdio" },
      filetypes    = { "vue" },
      root_dir     = root,
      init_options = { vue = { hybridMode = true } },
      on_init      = function(client)
        -- 古い lspconfig のためのブリッジ：.vue → vtsls/ts_ls へ TS リクエスト中継
        client.handlers["tsserver/request"] = function(_, result, context)
          local function pick_ts_like()
            return
              (vim.lsp.get_clients({ bufnr = context.bufnr, name = "vtsls" })[1]) or
              (vim.lsp.get_clients({ name = "vtsls" })[1]) or
              (vim.lsp.get_clients({ bufnr = context.bufnr, name = "ts_ls" })[1]) or
              (vim.lsp.get_clients({ name = "ts_ls" })[1])
          end
          local ts = pick_ts_like()
          if not ts then
            local tries = 0
            local function retry()
              tries = tries + 1
              local c = pick_ts_like()
              if c then ts = c elseif tries < 10 then return vim.defer_fn(retry, 120) end
            end
            retry()
            if not ts then
              vim.notify("Could not find `ts_ls` or `vtsls` (required by vue_ls).", vim.log.levels.WARN)
              return
            end
          end
          local param = unpack(result)
          local id, command, payload = unpack(param)
          ts:exec_cmd({
            title = "vue_request_forward",
            command = "typescript.tsserverRequest",
            arguments = { command, payload },
          }, { bufnr = context.bufnr }, function(_, r)
            local response = r and r.body
            local response_data = { { id, response } }
            client:notify("tsserver/response", response_data)
          end)
        end
      end,
      on_attach    = on_attach,  -- ← vue_ls 側の診断は生かす
      capabilities = capabilities,
    })

    ----------------------------------------------------------------
    -- その他の LSP
    ----------------------------------------------------------------
    for _, server in ipairs({ "lua_ls","ruby_lsp","rubocop","tailwindcss","yamlls","zk","gopls" }) do
      lspconfig[server].setup({
        on_attach = function(_, bufnr)
          vim.keymap.set("n", "<space>h", vim.lsp.buf.hover, { buffer = bufnr, desc = "LSP Hover" })
        end,
        capabilities = capabilities,
        root_dir = root,
      })
    end

    ----------------------------------------------------------------
    -- Sorbet
    ----------------------------------------------------------------
    lspconfig.sorbet.setup({
      cmd = { "srb", "tc", "--lsp" },
      on_attach = function(_, bufnr)
        vim.keymap.set("n", "<space>h", vim.lsp.buf.hover, { buffer = bufnr, desc = "LSP Hover" })
      end,
      capabilities = capabilities,
      root_dir = util.root_pattern("sorbet", ".git"),
    })
  end,
}
