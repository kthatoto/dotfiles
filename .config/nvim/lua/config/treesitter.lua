require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "typescript", "vue", "ruby", "lua", "tsx", "html", "json"
  },
  highlight = { enable = true },
})
