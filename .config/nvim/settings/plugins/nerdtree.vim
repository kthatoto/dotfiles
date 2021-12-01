let g:NERDTreeShowBookmarks=1
let g:NERDTreeShowHidden=1
let g:NERDTreeIgnore=['node_modules']

nnoremap <C-n> :NERDTreeFocus<CR>

" vim起動時にNERDTreeを最初から表示(session指定じゃない時)
autocmd VimEnter * if v:this_session == '' | NERDTree | wincmd p | endif

" TabにNERDTreeのwindowだけ残ってる場合Tabを閉じる
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" 全タブで同じNERDTreeの状態を共有
autocmd BufWinEnter * if getcmdwintype() == '' | silent NERDTreeMirror | endif
