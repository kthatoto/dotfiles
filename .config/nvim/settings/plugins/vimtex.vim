"lervag/vimtex
let g:vimtex_fold_envs = 0
augroup filetype
  autocmd!
  autocmd BufRead,BufNewFile *.tex set filetype=tex
augroup END
