return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "jay-babu/mason-null-ls.nvim",
  },
  config = function()
    local null_ls = require("null-ls")

    require("mason-null-ls").setup({
      ensure_installed = { "prettier" }, -- prettierをMasonで管理
      automatic_installation = true,
    })

    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.prettier,
      },
    })

    -- :Format コマンドを定義
    vim.api.nvim_create_user_command("Format", function()
      vim.lsp.buf.format({ async = true })
    end, { desc = "Format current buffer" })
  end,
}
