" 折りたたみの設定
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
set foldlevel=1

" RSpecのdescribeやcontextだけを折りたたみ表示
augroup rspec_folds
  autocmd!
  autocmd FileType ruby setlocal foldmethod=syntax
augroup END

syntax region rspecFold start="^\s*describe\s\+\|^\s*context\s\+" end="^\s*end\s*$" fold
