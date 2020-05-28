let g:python3_host_prog = expand('/Users/kthatoto/.anyenv/envs/pyenv/shims/python')
nnoremap <silent> <C-t> :<C-u>Denite file/rec<CR>
nnoremap <silent> <C-b> :<C-u>Denite file_mru<CR>
nnoremap <silent> <C-g> :<C-u>Denite grep<CR>

autocmd FileType denite call s:denite_settings()
function! s:denite_settings() abort
  nnoremap <silent><buffer><expr> <CR>  denite#do_map('do_action')
  nnoremap <silent><buffer><expr> p     denite#do_map('do_action', 'preview')
  nnoremap <silent><buffer><expr> i     denite#do_map('open_filter_buffer')
  nnoremap <silent><buffer><expr> <Esc> denite#do_map('quit')
endfunction

autocmd FileType denite-filter call s:denite_filter_setting()
function! s:denite_filter_setting() abort
  nnoremap <silent><buffer><expr> <Esc>   denite#do_map('quit')
endfunction

let s:denite_win_width_percent = 0.85
let s:denite_win_height_percent = 0.3
let s:denite_default_options = {
    \ 'split': 'floating',
    \ 'winwidth': float2nr(&columns * s:denite_win_width_percent),
    \ 'wincol': float2nr(&columns - (&columns * s:denite_win_width_percent)),
    \ 'winheight': float2nr(&lines * s:denite_win_height_percent),
    \ 'winrow': float2nr(&lines - ((&lines) * s:denite_win_height_percent) - 2),
    \ 'highlight_filter_background': 'DeniteFilter',
    \ 'prompt': '$ ',
    \ 'start_filter': v:true,
    \ }
" let s:denite_option_array = []
" for [key, value] in items(s:denite_default_options)
"   call add(s:denite_option_array, '-'.key.'='.value)
" endfor
call denite#custom#option('default', s:denite_default_options)
