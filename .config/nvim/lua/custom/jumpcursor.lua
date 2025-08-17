local M = {}

-- 文字リスト（vim.g.jumpcursor_marks があればそれを使う）
local default_marks = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@[;:],./_-^\\1234567890"
local marks = vim.g.jumpcursor_marks
if type(marks) == "string" then
  -- 文字列なら1文字ずつ分解
  local t = {}
  for p, c in utf8.codes(marks) do
    t[#t + 1] = utf8.char(c)
  end
  marks = t
elseif type(marks) == "table" then
  -- そのまま使う
else
  local t = {}
  for p, c in utf8.codes(default_marks) do
    t[#t + 1] = utf8.char(c)
  end
  marks = t
end

local ns = vim.api.nvim_create_namespace("jumpcursor")
local mark_lnums = {} -- mark -> lnum (1-index)
local mark_cols  = {} -- mark -> col  (0-index), 今回未使用だが残しておく

-- ウィンドウ内の可視範囲にオーバレイ文字を配置
local function fill_window()
  local start_line = vim.fn.line("w0")
  local end_line   = vim.fn.line("w$")
  local bufnr      = vim.api.nvim_get_current_buf()
  local mark_len   = #marks

  -- クリアしてから描画（ちらつき防止のため一旦全クリア）
  vim.api.nvim_buf_clear_namespace(bufnr, ns, start_line - 1, end_line)

  local mark_idx = 1
  local i = start_line
  while i <= end_line do
    if mark_idx > mark_len then
      break
    end
    local text = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1] or ""
    local mark = marks[mark_idx]
    -- 行内の非空白の最初の位置に印を置く（元実装は行内すべてに置いていたが、
    -- すぐにマーク不足になりやすいので1行1つに最適化。全箇所に置きたい場合は下の loop を有効化）
    local placed = false
    for col = 0, #text - 1 do
      local ch = text:sub(col + 1, col + 1)
      if ch ~= " " and ch ~= "\t" then
        vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, col, {
          virt_text_pos = "overlay",
          virt_text = { { mark, "ErrorMsg" } },
        })
        mark_lnums[mark] = i
        mark_cols[mark]  = col
        placed = true
        break
      end
    end
    if placed then
      mark_idx = mark_idx + 1
    end
    i = i + 1
  end
end

-- 行内の全ての非空白にマークを振りたい場合はこれを使う（オリジナルに近い挙動）
local function fill_specific_line(lnum)
  local bufnr = vim.api.nvim_get_current_buf()
  local text  = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  local mark_idx = 1
  local mark_len = #marks

  for col = 0, #text - 1 do
    if mark_idx > mark_len then
      break
    end
    local ch = text:sub(col + 1, col + 1)
    if ch ~= " " and ch ~= "\t" then
      local mark = marks[mark_idx]
      vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, col, {
        virt_text_pos = "overlay",
        virt_text = { { mark, "ErrorMsg" } },
      })
      mark_cols[mark] = col
      mark_idx = mark_idx + 1
    end
  end
  vim.cmd("redraw!")
end

local function clear_window_ns()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, vim.fn.line("w0") - 1, vim.fn.line("w$"))
end

function M.jump()
  mark_lnums = {}
  mark_cols  = {}
  fill_window()
  vim.cmd("redraw!")

  local ok, key = pcall(vim.fn.getcharstr)
  clear_window_ns()
  if not ok or key == "" or key == " " then
    return
  end

  local lnum = mark_lnums[key]
  if not lnum then
    return
  end

  -- 行ジャンプ（列までやりたい場合は下を有効化）
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })

  -- 2段階ジャンプ（行→列）を使いたい場合：
  -- fill_specific_line(lnum)
  -- ok, key = pcall(vim.fn.getcharstr)
  -- clear_window_ns()
  -- if ok and key ~= "" and key ~= " " and mark_cols[key] then
  --   vim.api.nvim_win_set_cursor(0, { lnum, mark_cols[key] + 1 })
  -- end

  mark_lnums = {}
  mark_cols  = {}
end

return M
