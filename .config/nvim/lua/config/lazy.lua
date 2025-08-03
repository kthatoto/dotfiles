-- Lazy.nvimをブートストラップ
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "--branch=stable", "https://github.com/folke/lazy.nvim.git", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "  -- (念のため再確認) <Leader>キー設定
vim.g.maplocalleader = "\\"

require("lazy").setup({
  install = { colorscheme = { "gruvbox" } },  -- プラグインインストール時にGruvboxを適用 (例)
  checker = { enabled = true },  -- 起動時にアップデートチェック

  -- LSP
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim", config = true },
  { "williamboman/mason-lspconfig.nvim" },
 
  -- 補完
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "rafamadriz/friendly-snippets" },

  -- Fuzzy finder
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  -- Git
  { "lewis6991/gitsigns.nvim", config = true },
  -- UI
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
})
