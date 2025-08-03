-- ノーマルモードのキーマップ
local map = vim.keymap.set
map("n", ";", ":", { noremap = true })        -- 「;」でコマンドモードへ:contentReference[oaicite:14]{index=14}
map("n", ":", ";", { noremap = true })        -- 「:」で「;」を入力（上記との入替え）:contentReference[oaicite:15]{index=15}
map("n", "<C-h>", "<C-w>h", { silent = true }) -- 画面分割間移動 (左):contentReference[oaicite:16]{index=16}
map("n", "<C-j>", "<C-w>j", { silent = true }) -- 画面分割間移動 (下):contentReference[oaicite:17]{index=17}
map("n", "<C-k>", "<C-w>k", { silent = true }) -- 画面分割間移動 (上):contentReference[oaicite:18]{index=18}
map("n", "<C-l>", "<C-w>l", { silent = true }) -- 画面分割間移動 (右):contentReference[oaicite:19]{index=19}
map("n", "<C-c>", "<C-w>c", { silent = true }) -- 現在の分割を閉じる:contentReference[oaicite:20]{index=20}
map("n", "vs", "<cmd>vsplit<CR>", { silent = true })  -- 垂直分割:contentReference[oaicite:21]{index=21}
map("n", "ss", "<cmd>split<CR>", { silent = true })   -- 水平分割:contentReference[oaicite:22]{index=22}
map("n", "s=", "<C-w>=", { silent = true })    -- 分割サイズを均等化:contentReference[oaicite:23]{index=23}
map("n", "sn", "gt", { noremap = true })       -- 次のタブへ移動:contentReference[oaicite:24]{index=24}
map("n", "sp", "gT", { noremap = true })       -- 前のタブへ移動:contentReference[oaicite:25]{index=25}
map("n", "st", "<cmd>tabnew<CR>", { silent = true })   -- 新しいタブを開く:contentReference[oaicite:26]{index=26}

-- -- 検索時に'*'で最初の一致箇所に飛ばない設定 (init.vimでのnnoremap * のLua版)
-- map("n", "*", function()
--   vim.fn.setreg("/", "\\<" .. vim.fn.expand("<cword>") .. "\\>")
--   vim.opt.hlsearch = true
--   -- カーソル位置を動かさずにハイライトだけ有効にする
-- end, { silent = true })

-- -- ターミナルモードからEscでノーマルモードに戻る
-- map("t", "<Esc>", [[<C-\><C-n>]], { silent = true })  -- (init.vimのtnoremapと同等):contentReference[oaicite:27]{index=27}

-- 挿入モードのキーマップ
map("i", "jj", "<Esc>", { noremap = true, silent = true })  -- 挿入モード中 `jj` でノーマルモード復帰:contentReference[oaicite:28]{index=28}

-- Denite由来のキー操作をTelescopeで再現
map("n", "<C-t>", "<cmd>Telescope find_files<CR>", { noremap = true, silent = true })   -- ファイル検索 (Denite: file/rec):contentReference[oaicite:29]{index=29}
map("n", "<C-b>", "<cmd>Telescope oldfiles<CR>", { noremap = true, silent = true })     -- 最近使ったファイル (Denite: file_mru):contentReference[oaicite:30]{index=30}
map("n", "<C-g>", "<cmd>Telescope live_grep<CR>", { noremap = true, silent = true })    -- ファイル全文検索 (Denite: grep):contentReference[oaicite:31]{index=31}

-- Ctrl + - 2連打でコメント（Normalモード）
vim.keymap.set("n", "<C-_><C-_>", function()
  require("Comment.api").toggle.linewise.current()
end, { noremap = true, silent = true })

-- Ctrl + - 2連打でコメント（Visualモード）
vim.keymap.set("v", "<C-_><C-_>", function()
  local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
  vim.api.nvim_feedkeys(esc, "nx", false)
  require("Comment.api").toggle.linewise(vim.fn.visualmode())
end, { noremap = true, silent = true })
