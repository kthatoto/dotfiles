return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = {
        "vtsls",
        "lua_ls",
        "ruby_lsp",
        "rubocop",
        "tailwindcss",
        "tsp_server",
        "yamlls",
        "zk",
      },
    })

    local lspconfig = require("lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    local on_attach = function(_, bufnr)
      local map = vim.keymap.set
      map("n", "<space>h", vim.lsp.buf.hover, { desc = "ホバー情報表示", buffer = bufnr })
      map("n", "<C-f>", function()
        local choices = {
          s = "split",
          v = "vsplit",
          t = "tabedit",
        }

        local prompt = "(s)plit, (v)split, (t)ab を入力して Enter: "
        vim.ui.input({ prompt = prompt }, function(input)
          if not input then
            vim.notify("キャンセルされました", vim.log.levels.INFO)
            return
          end

          local key = input:lower():sub(1, 1)
          local cmd = choices[key]
          if cmd then
            vim.cmd(cmd)
            -- deferでウィンドウ分割完了を待ってからジャンプ
            vim.defer_fn(function()
              vim.lsp.buf.definition()
            end, 20)
          else
            vim.notify("無効な入力: " .. input, vim.log.levels.WARN)
          end
        end)
      end, { desc = "定義ジャンプ方法を選択", buffer = bufnr })
    end

    -- Volar (vue-language-server)
    lspconfig.volar.setup({
      filetypes = { "vue" },
      init_options = {
        vue = { hybridMode = false },
      },
      on_attach = on_attach,
      capabilities = capabilities,
    })

    -- vtsls (TypeScript用 + vue plugin)
    lspconfig.vtsls.setup({
      filetypes = { "vue", "typescript", "javascript", "javascriptreact", "typescriptreact" },
      init_options = {
        plugins = {
          {
            name = "@vue/typescript-plugin",
            location = vim.fn.stdpath("data")
              .. "/mason/packages/vue-language-server/node_modules/@vue/language-server/node_modules/@vue/typescript-plugin",
            languages = { "vue" },
          },
        },
      },
      on_attach = on_attach,
      capabilities = capabilities,
    })

    -- その他のLSP
    local servers = {
      "lua_ls",
      "ruby_lsp",
      "rubocop",
      "tailwindcss",
      "tsp_server",
      "yamlls",
      "zk",
    }

    for _, server in ipairs(servers) do
      lspconfig[server].setup({
        on_attach = on_attach,
        capabilities = capabilities,
      })
    end

    -- Sorbet (手動設定)
    lspconfig.sorbet.setup({
      cmd = { "srb", "tc", "--lsp" },
      on_attach = on_attach,
      capabilities = capabilities,
      root_dir = lspconfig.util.root_pattern("sorbet", ".git"),
    })
  end,
}
