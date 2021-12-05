" Dim when splited pane is inactive
function! s:DimInactivePanes()
  for i in range(1, tabpagewinnr(tabpagenr(), '$'))
    let l:range = ""
    if i != winnr()
      if &wrap
        " HACK: when wrapping lines is enabled, we use the maximum number
        " of columns getting highlighted. This might get calculated by
        " looking for the longest visible line and using a multiple of
        " winwidth().
        let l:width=256 " max
      else
        let l:width=winwidth(i)
      endif
      let l:range = join(range(1, l:width), ',')
    endif
    call setwinvar(i, '&colorcolumn', l:range)
  endfor
endfunction
augroup DimInactivePanes
  au!
  au WinEnter * call s:DimInactivePanes()
  au WinEnter * set cursorline
  au WinLeave * set nocursorline
augroup END

" Background colors for active vs inactive windows
highlight ActiveWindow guibg=#0a0a0a
highlight InactiveWindow guibg=#222222
highlight ColorColumn guibg=#222222

" Call method on window enter
augroup WindowManagement
  autocmd!
  autocmd WinEnter,BufEnter * call Handle_Win_Enter()
augroup END

" Change highlight group of active/inactive windows
function! Handle_Win_Enter()
  setlocal winhighlight=Normal:ActiveWindow,NormalNC:InactiveWindow
endfunction
