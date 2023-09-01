let s:current_window_id = win_getid()

let s:firework_matrix = [
    \   {
    \     'color_index': 1,
    \     'ms': 500,
    \     'positions': [
    \       { 'x': 0, 'y': -3 }, { 'x': 2, 'y': -2 }, { 'x': 3, 'y': 0 },
    \       { 'x': 2, 'y': 2 }, { 'x': 0, 'y': 3 }, { 'x': -2, 'y': 2 },
    \       { 'x': -3, 'y': 0 }, { 'x': -2, 'y': -2 },
    \     ],
    \   },
    \   {
    \     'color_index': 0,
    \     'ms': 300,
    \     'positions': [
    \       { 'x': 0, 'y': -6 }, { 'x': 2, 'y': -5 }, { 'x': 4, 'y': -4 },
    \       { 'x': 5, 'y': -2 }, { 'x': 6, 'y': 0 }, { 'x': 5, 'y': 2 },
    \       { 'x': 4, 'y': 4 }, { 'x': 2, 'y': 5 }, { 'x': 0, 'y': 6 },
    \       { 'x': -2, 'y': 5 }, { 'x': -4, 'y': 4 }, { 'x': -5, 'y': 2 },
    \       { 'x': -6, 'y': 0 }, { 'x': -5, 'y': -2 }, { 'x': -4, 'y': -4 },
    \       { 'x': -2, 'y': -5 },
    \     ],
    \   },
    \   {
    \     'color_index': 0,
    \     'ms': 200,
    \     'positions': [
    \       { 'x': 0, 'y': -7 }, { 'x': 5, 'y': -5 }, { 'x': 7, 'y': 0 },
    \       { 'x': 5, 'y': 5 }, { 'x': 0, 'y': 7 }, { 'x': -5, 'y': 5 },
    \       { 'x': -7, 'y': 0 }, { 'x': -5, 'y': -5 },
    \     ],
    \   },
    \   {
    \     'color_index': 1,
    \     'ms': 500,
    \     'positions': [
    \       { 'x': 0, 'y': -8 }, { 'x': 6, 'y': -6 }, { 'x': 8, 'y': 0 },
    \       { 'x': 6, 'y': 6 }, { 'x': 0, 'y': 8 }, { 'x': -6, 'y': 6 },
    \       { 'x': -8, 'y': 0 }, { 'x': -6, 'y': -6 },
    \     ],
    \   },
    \ ]

highlight FireworkYellow guibg=#FFF100
highlight FireworkOrange guibg=#FFA500
highlight FireworkBlue guibg=#0000FF
highlight FireworkGreen guibg=#7CFC00
highlight FireworkRed guibg=#FF0000
let s:color_sets = [
    \   ['Normal:FireworkYellow', 'Normal:FireworkOrange'],
    \   ['Normal:FireworkGreen', 'Normal:FireworkBlue'],
    \   ['Normal:FireworkYellow', 'Normal:FireworkBlue'],
    \   ['Normal:FireworkGreen', 'Normal:FireworkOrange'],
    \   ['Normal:FireworkYellow', 'Normal:FireworkRed'],
    \   ['Normal:FireworkGreen', 'Normal:FireworkRed'],
    \ ]

function! s:FireworkFlash(x, y, color_name, ms) abort
  let l:empty_buf = nvim_create_buf(v:false, v:true)
  let l:winconf = { 'width': 2, 'height': 1, 'relative': 'editor' }
  let l:firework_window_id = nvim_open_win(
        \ l:empty_buf, v:true,
        \ extend(l:winconf, { 'col': a:x, 'row': a:y })
        \ )
  call nvim_win_set_option(l:firework_window_id, 'winhighlight', a:color_name)
  call nvim_win_set_option(l:firework_window_id, 'winblend', 40)
  function! s:remove_window(firework_window_id, _timer_id) abort
    call nvim_win_close(a:firework_window_id, v:true)
  endfunction
  call nvim_set_current_win(s:current_window_id)
  call timer_start(a:ms, function('s:remove_window', [l:firework_window_id]))
endfunction

let s:fw_vertical_radius = 8
let s:fw_horizontal_radius = 16
let s:margin = 8

function! Firework() abort
  let l:color_set = s:color_sets[rand() % len(s:color_sets)]

  let l:max_y = nvim_get_option('lines')
  let l:max_x = nvim_get_option('columns')
  let l:center_y = rand() % (l:max_y - (s:fw_vertical_radius + s:margin) * 2) + s:fw_vertical_radius + s:margin
  let l:center_x = rand() % (l:max_x - (s:fw_horizontal_radius + s:margin) * 2) + s:fw_horizontal_radius + s:margin

  for i in range(0, (l:max_y - l:center_y) / 2)
    let l:y = l:max_y - i * 2
    call s:FireworkFlash(l:center_x, l:y, l:color_set[0], 300)
    sleep 50m
  endfor
  sleep 100m


  for i in range(0, len(s:firework_matrix) - 1)
    let l:firework_circle = s:firework_matrix[i]
    for j in range(0, len(l:firework_circle['positions']) - 1)
      let l:pos = l:firework_circle['positions'][j]
      call s:FireworkFlash(
        \   l:center_x + l:pos['x'] * 2,
        \   l:center_y + l:pos['y'],
        \   l:color_set[l:firework_circle['color_index']],
        \   l:firework_circle['ms'],
        \ )
    endfor

    sleep 100m
  endfor
endfunction

function! Fireworks(n) abort
  for i in range(0, a:n - 1)
    call Firework()
  endfor
endfunction
