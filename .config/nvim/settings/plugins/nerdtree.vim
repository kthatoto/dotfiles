let g:NERDTreeShowBookmarks=1
let g:NERDTreeShowHidden=1
let g:NERDTreeIgnore=['node_modules']
let g:NERDTreeWinSize=40

" vim起動時にNERDTreeを最初から表示(git commit message or session指定じゃない時)
autocmd VimEnter * if &filetype !=# 'gitcommit' && v:this_session == '' | NERDTree | wincmd p | endif

" TabにNERDTreeのwindowだけ残ってる場合Tabを閉じる
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" 全タブで同じNERDTreeの状態を共有
autocmd BufWinEnter * if getcmdwintype() == '' | silent NERDTreeMirror | endif

" NERDTreeの対象WindowをHighlight
let s:highlight_window = 0
let s:target_window_id = 0
let s:target_window = { 'row': 0, 'col': 0, 'width': 0, 'height': 0 }
function! s:SetWindowInfo() abort
  if &filetype != 'nerdtree'
    let s:target_window_id = win_getid()
    let l:winnr = winnr()
    let s:target_window.width = winwidth(l:winnr)
    let s:target_window.height = winheight(l:winnr)
    let l:screenpos = win_screenpos(l:winnr)
    let s:target_window.row = l:screenpos[0] - 1
    let s:target_window.col = l:screenpos[1] - 1
  endif
endfunction
function! s:HighlightNerdtreeTarget() abort
  if &filetype == 'nerdtree'
    if s:highlight_window > 0
      call nvim_win_close(s:highlight_window, v:true)
    endif
    if winnr('$') > 1
      let l:empty_buf = nvim_create_buf(v:false, v:true)
      let s:highlight_window = nvim_open_win(l:empty_buf, v:false, extend(s:target_window, { 'relative': 'editor' }))
      highlight NERDTreeTargetFocus guifg=#000000 guibg=#770000
      call nvim_win_set_option(s:highlight_window, 'winhighlight', 'Normal:NERDTreeTargetFocus')
      call nvim_win_set_option(s:highlight_window, 'winblend', 60)
    endif
  else
    if s:highlight_window > 0
      call nvim_win_close(s:highlight_window, v:true)
      let s:highlight_window = 0
    endif
  endif
endfunction
augroup HighlightNerdtreeTarget
  autocmd!
  autocmd WinLeave * call s:SetWindowInfo()
  autocmd WinEnter,BufEnter * call s:HighlightNerdtreeTarget()
augroup END

function! NERDTreeFocusOrBack() abort
  if &filetype == 'nerdtree' && s:target_window_id > 0
    call win_gotoid(s:target_window_id)
  else
    call NERDTreeFocus()
  endif
endfunction
nnoremap <C-n> :call NERDTreeFocusOrBack()<CR>
