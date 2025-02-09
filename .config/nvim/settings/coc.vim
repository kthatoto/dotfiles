highlight CocErrorSign guifg=#ff0000
highlight CocWarningSign guifg=#fabd2f
highlight CocHintSign guifg=#15aabf

nnoremap <silent> <space>h :<C-u>call CocActionAsync('doHover')<CR>

function! ChoseAction(actions) abort
  echo join(map(copy(a:actions), { _, v -> v.text }), ", ") .. ": "
  let result = getcharstr()
  let result = filter(a:actions, { _, v -> v.text =~# printf(".*\(%s\).*", result)})
  return len(result) ? result[0].value : ""
endfunction
function! CocJumpAction() abort
  let actions = [
        \ {"text": "(s)plit", "value": "split"},
        \ {"text": "(v)split", "value": "vsplit"},
        \ {"text": "(t)ab", "value": "tabedit"},
        \ ]
  let action = ChoseAction(actions)
  call CocActionAsync('jumpDefinition', action)
endfunction
nnoremap <silent> <C-f> :<C-u>call CocJumpAction()<CR>
inoremap <silent><expr> <cr> coc#pum#visible() ? coc#_select_confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
