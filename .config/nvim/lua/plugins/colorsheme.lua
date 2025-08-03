return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      vim.o.background = "dark"
      require("gruvbox").setup({})
      vim.cmd("colorscheme gruvbox")
    end
  }
}
