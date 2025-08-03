return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup()

    local lspconfig = require("lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    local on_attach = function(_, bufnr)
      local opts = { buffer = bufnr }
      local map = vim.keymap.set

      -- もともとのCoc操作の再現
      map("n", "<space>h", vim.lsp.buf.hover, { desc = "ホバー情報表示", buffer = bufnr })

      map("n", "<C-f>", function()
        local options = {
          s = "split",
          v = "vsplit",
          t = "tabedit",
        }
        vim.ui.select({ "(s)plit", "(v)split", "(t)ab" }, {
          prompt = "どの方法で開きますか？",
        }, function(choice)
          if not choice then return end
          local cmd = options[string.sub(choice, 2, 2)]
          if cmd then
            vim.cmd(cmd)
            vim.lsp.buf.definition()
          end
        end)
      end, { desc = "定義ジャンプ方法を選択", buffer = bufnr })
    end

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
      lspconfig[server].setup {
        on_attach = on_attach,
        capabilities = capabilities,
      }
    end

    -- Sorbet
    lspconfig.sorbet.setup({
      cmd = { "srb", "tc", "--lsp" },
      on_attach = on_attach,
      capabilities = capabilities,
      root_dir = lspconfig.util.root_pattern("sorbet", ".git"),
    })

    -- Volar (Vue 3)
    lspconfig.volar.setup({
      on_attach = on_attach,
      capabilities = capabilities,
      filetypes = { "vue" },
      init_options = {
        vue = {
          hybridMode = false,
        },
      },
      root_dir = lspconfig.util.root_pattern(
        "vite.config.ts",
        "vite.config.js",
        "package.json",
        "tsconfig.json",
        "jsconfig.json",
        ".git"
      ),
    })
  end,
}
