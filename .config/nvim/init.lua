require("config.lazy")
require("config.cmp")
require("config.treesitter")
require("config.keymaps")
require("config.dim_inactive")

-- 1. 基本オプションの設定 (init.vimから移行)
vim.o.number = true               -- 行番号を表示 (init.vim: set number)
vim.o.relativenumber = false      -- 相対行番号 (必要なら true)
vim.o.cursorline = true           -- カーソル行のハイライト (init.vim: set cursorline)
vim.o.termguicolors = true        -- 24bit カラーを有効化 (init.vim: set termguicolors)
vim.o.clipboard = "unnamedplus"   -- システムクリップボードと共有:contentReference[oaicite:0]{index=0}

-- 他にも init.vim で設定していたオプションは同様に vim.o や vim.opt で設定
vim.o.ignorecase = true           -- 検索時に大文字小文字を無視:contentReference[oaicite:1]{index=1}
vim.o.smartcase = true            -- 大文字を含む検索では区別する:contentReference[oaicite:2]{index=2}
vim.o.splitbelow = true           -- 横分割を下に配置:contentReference[oaicite:3]{index=3}
vim.o.splitright = true           -- 縦分割を右に配置:contentReference[oaicite:4]{index=4}

-- 2. <Leader>キーの定義 (必要であれば)
vim.g.mapleader = " "   -- リーダーキーをスペースに設定 (Lazy.nvim読込前に設定)
vim.g.maplocalleader = "\\"

-- インデント幅の設定
vim.o.tabstop = 2        -- タブ文字の幅（見た目）
vim.o.shiftwidth = 2     -- 自動インデントの幅
vim.o.softtabstop = 2    -- <Tab>/<BS> の幅
vim.o.expandtab = true   -- タブ入力をスペースに変換
