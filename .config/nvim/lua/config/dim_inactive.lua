local function dim()
  local cur = vim.api.nvim_get_current_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win == cur then
      vim.api.nvim_win_set_option(win, "colorcolumn", "")
    else
      local width = vim.api.nvim_win_get_width(win)
      vim.api.nvim_win_set_option(win, "colorcolumn", table.concat(vim.fn.range(1, width), ","))
    end
  end
end

vim.api.nvim_set_hl(0, "ActiveWindow", { bg = "#0a0a0a" })
vim.api.nvim_set_hl(0, "InactiveWindow", { bg = "#222222" })
vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#222222" })

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  callback = function()
    dim()
    vim.wo.winhighlight = "Normal:ActiveWindow,NormalNC:InactiveWindow"
    vim.wo.cursorline = true
  end
})
vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    vim.wo.cursorline = false
  end
})
vim.api.nvim_create_autocmd("VimEnter", {
  callback = dim
})
