local M = {}

-- 文字リスト（vim.g.jumpcursor_marks があればそれを使う）
local default_marks = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@[;:],./_-^\\1234567890"

local function to_char_list(x)
  if type(x) == "table" then
    return x
  end
  local s = (type(x) == "string" and x or default_marks)
  -- Vimのsplit + \zs で1文字ごとに分割（UTF-8対応）
  return vim.fn.split(s, "\\zs")
end

local marks = to_char_list(vim.g.jumpcursor_marks)

local ns = vim.api.nvim_create_namespace("jumpcursor")
local mark_lnums = {} -- mark -> lnum (1-index)
local mark_cols  = {} -- mark -> col  (0-index)

-- ウィンドウ内の可視範囲にオーバレイ文字を配置（各行の全非空白に同じマークを置く＝元実装準拠）
local function fill_window()
  local start_line = vim.fn.line("w0")
  local end_line   = vim.fn.line("w$")
  local bufnr      = vim.api.nvim_get_current_buf()
  local mark_len   = #marks

  vim.api.nvim_buf_clear_namespace(bufnr, ns, start_line - 1, end_line)

  local mark_idx = 1
  for lnum = start_line, end_line do
    if mark_idx > mark_len then break end

    local text = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
    local mark = marks[mark_idx]

    -- 行内の全ての非空白文字に同じマークを重ねる
    for col = 0, #text - 1 do
      local ch = text:sub(col + 1, col + 1)
      if ch ~= " " and ch ~= "\t" then
        vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, col, {
          virt_text_pos = "overlay",
          virt_text = { { mark, "ErrorMsg" } },
        })
      end
    end

    -- そのマークはこの行を指す
    mark_lnums[mark] = lnum
    mark_idx = mark_idx + 1
  end
end
-- 行内の全非空白にマークを振る（2段階ジャンプ用・必要なら使う）
local function fill_specific_line(lnum)
  local bufnr = vim.api.nvim_get_current_buf()
  local text  = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  local mark_len = #marks
  local mark_idx = 1

  for col = 0, #text - 1 do
    if mark_idx > mark_len then break end
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

  -- 行ジャンプ
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })

  -- 2段階（行 -> 列）にしたい場合は以下を有効化
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
