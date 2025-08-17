return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "jay-babu/mason-null-ls.nvim",
  },
  config = function()
    local null_ls = require("null-ls")

    -- Masonと連携
    require("mason-null-ls").setup({
      ensure_installed = { "prettier" }, -- prettierをMasonで管理
      automatic_installation = true,
    })

    -- null-lsの設定
    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.prettier,
      },
    })

    -- キーマップ
    vim.keymap.set("n", "<leader>f", function()
      vim.lsp.buf.format({ async = true })
    end, { desc = "Format code" })

    -- 保存時に自動format
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.js", "*.ts", "*.tsx", "*.vue", "*.json", "*.css", "*.md" },
      callback = function()
        vim.lsp.buf.format({ async = false })
      end,
    })
  end,
}
