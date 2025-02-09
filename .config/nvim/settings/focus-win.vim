lua << EOF
function _G.FocusToFloatingWin()
  local target_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative == "win" and config.width > 1 then
      target_win = win
    end
  end

  if target_win then
    vim.api.nvim_set_current_win(target_win)
  else
    print("No suitable floating window found")
  end
end
EOF

function! FocusToFloatingWin()
  lua FocusToFloatingWin()
endfunction

nnoremap <C-w> :call FocusToFloatingWin()<CR>
