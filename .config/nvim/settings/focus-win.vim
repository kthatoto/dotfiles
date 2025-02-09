function FocusToFloatingWin()
  for _, win in iparis(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative == "win" then
      vim.api.nvim_set_current_win(win)
      return
    endif
  endfor
endfunction
