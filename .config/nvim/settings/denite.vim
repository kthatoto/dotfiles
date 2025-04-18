let g:python3_host_prog = expand('/Users/kthatoto/.asdf/installs/python/3.13.2/bin/python')
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

augroup transparent-windows
  autocmd!
  autocmd FileType denite set winblend=30
  autocmd FileType denite-filter set winblend=30
augroup END

let s:denite_win_width_percent = 0.85
let s:denite_win_height_percent = 0.3
let s:denite_default_options = {
    \ 'split': 'floating',
    \ 'winwidth': float2nr(&columns * s:denite_win_width_percent),
    \ 'wincol': float2nr(&columns - (&columns * s:denite_win_width_percent)),
    \ 'winheight': float2nr(&lines * s:denite_win_height_percent),
    \ 'winrow': float2nr(&lines - ((&lines) * s:denite_win_height_percent) - 2),
    \ 'highlight_matched_char': 'None',
    \ 'highlight_matched_range': 'Search',
    \ 'match_highlight': v:true,
    \ 'prompt': '$ ',
    \ 'start_filter': v:true,
    \ }
call denite#custom#option('default', s:denite_default_options)

if executable('rg')
  call denite#custom#var('file/rec', 'command', [
    \ 'rg',
    \ '--files',
    \ '--glob', '!.git',
    \ '--glob', '!node_modules',
    \ ])
  call denite#custom#var('grep', {
    \ 'command': ['rg', '--glob', '!.git', '--glob', '!node_modules'],
    \ })
end
