return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    keys = {
      { "<C-n>", "<CMD>NvimTreeToggle<CR>", desc = "ファイルツリーを開く" },
      { "<C-i>", "<CMD>NvimTreeFindFile<CR>", desc = "現在のファイルをツリーで表示" },
    },
    config = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      vim.opt.termguicolors = true
      require("nvim-tree").setup({
        view = { width = 40 },
        update_focused_file = { enable = true },
      })
    end
  }
}
