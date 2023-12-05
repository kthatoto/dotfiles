let s:current_window_id = win_getid()
function! Test() abort
  let empty_buf = nvim_create_buf(v:false, v:true)
  let window_id = nvim_open_win(empty_buf, v:true,
    \ {
    \   'row': 10, 'col': 20, 'width': 2, 'height': 1,
    \   'relative': 'editor', 'style': 'minimal',
    \ })
  highlight FireworkRed guibg=#FF0000
  call nvim_win_set_option(window_id, 'winhighlight', 'Normal:FireworkRed')

  function! s:remove_window(window_id, _timer_id) abort
    call nvim_win_close(a:window_id, v:true)
  endfunction

  " 3秒後(3000ms)に
  call timer_start(3000, function('s:remove_window', [window_id]))
endfunction



let empty_buf = nvim_create_buf(v:false, v:true)
let winconf = { 'width': 2, 'height': 1, 'relative': 'editor' }
function! s:FireworkFlash(x, y, color_name, ms) abort
  let l:firework_window_id = nvim_open_win(
        \ empty_buf, v:true,
        \ extend(winconf, { 'col': a:x, 'row': a:y })
        \ )
  call nvim_win_set_option(l:firework_window_id, 'winhighlight', a:color_name)
  call nvim_win_set_option(l:firework_window_id, 'winblend', 40)
  function! s:remove_window(firework_window_id, _timer_id) abort
    call nvim_win_close(a:firework_window_id, v:true)
  endfunction
  call nvim_set_current_win(s:current_window_id)
  call timer_start(a:ms, function('s:remove_window', [l:firework_window_id]))
endfunction
