-- 直前の「通常」ウィンドウを覚えておく
local last_normal_win = nil

local function is_float(win)
  local cfg = vim.api.nvim_win_get_config(win)
  return cfg and cfg.relative ~= ""
end

local function dim()
  local cur = vim.api.nvim_get_current_win()

  -- 今のウィンドウがフロートなら、直前の通常ウィンドウを「アクティブ」とみなす
  local active = cur
  if is_float(cur) then
    if last_normal_win and vim.api.nvim_win_is_valid(last_normal_win) then
      active = last_normal_win
    else
      -- バックアップ：最初に見つかった通常ウィンドウ
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if not is_float(w) then active = w; break end
      end
    end
  else
    -- 通常ウィンドウに入ったら更新
    last_normal_win = cur
  end

  -- すべての通常ウィンドウに反映（フロートは無視）
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if not is_float(win) then
      if win == active then
        vim.api.nvim_win_set_option(win, "colorcolumn", "")
        -- アクティブ側の見た目
        vim.api.nvim_win_set_option(win, "winhighlight", "Normal:ActiveWindow,NormalNC:InactiveWindow")
        vim.api.nvim_win_set_option(win, "cursorline", true)
      else
        local width = vim.api.nvim_win_get_width(win)
        vim.api.nvim_win_set_option(win, "colorcolumn", table.concat(vim.fn.range(1, width), ","))
        -- 非アクティブ側の見た目
        vim.api.nvim_win_set_option(win, "winhighlight", "Normal:InactiveWindow,NormalNC:InactiveWindow")
        vim.api.nvim_win_set_option(win, "cursorline", false)
      end
    end
  end
end

vim.api.nvim_set_hl(0, "ActiveWindow", { bg = "#0a0a0a" })
vim.api.nvim_set_hl(0, "InactiveWindow", { bg = "#222222" })
vim.api.nvim_set_hl(0, "ColorColumn",  { bg = "#222222" })

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  callback = function()
    -- ここで last_normal_win が更新され、hover などのフロート時でも dim が崩れない
    dim()
  end,
})

vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    -- WinLeave 直後にフロートへ入るケースがあるので、ここではいじらない方が安定
    -- （dim() が全体を再設定するため不要）
  end,
})

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme", "WinClosed", "WinScrolled", "VimResized", "TabEnter" }, {
  callback = dim,
})
