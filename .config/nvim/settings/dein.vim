if &compatible
  set nocompatible " Be iMproved
endif

" Required:
set runtimepath+=/Users/kthatoto/.config/nvim/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('/Users/kthatoto/.config/nvim/dein/')
  call dein#begin('/Users/kthatoto/.config/nvim/dein/')

  " Let dein manage dein
  " Required:
  call dein#add('/Users/kthatoto/.config/nvim/dein/repos/github.com/Shougo/dein.vim')

  call dein#add('Shougo/neosnippet.vim')
  call dein#add('Shougo/neosnippet-snippets')

  call dein#add('Shougo/denite.nvim')
  call dein#add('Shougo/neomru.vim')
  call dein#add('scrooloose/nerdtree')
  call dein#add('Xuyuanp/nerdtree-git-plugin')
  call dein#add('mattn/emmet-vim')
  call dein#add('terryma/vim-smooth-scroll')
  call dein#add('nathanaelkane/vim-indent-guides')
  call dein#add('rhysd/accelerated-jk')
  call dein#add('vim-scripts/AnsiEsc.vim')
  call dein#add('simeji/winresizer') " https://qiita.com/simeji/items/e78cc0cf046acc93722=

  call dein#add('plasticboy/vim-markdown')
  call dein#add('kannokanno/previm')
  call dein#add('embear/vim-localvimrc')
  call dein#add('tyru/open-browser.vim')
  " call dein#add('terryma/vim-multiple-cursors')
  call dein#add('tomtom/tcomment_vim')
  call dein#add('sophacles/vim-processing')
  call dein#add('tpope/vim-surround')
  call dein#add('tpope/vim-fugitive')
  call dein#add('airblade/vim-gitgutter')

  call dein#add('elixir-editors/vim-elixir')
  call dein#add('slim-template/vim-slim')
  call dein#add('posva/vim-vue')
  call dein#add('leafgarland/typescript-vim')
  " call dein#add('mxw/vim-jsx')
  call dein#add('MaxMEllon/vim-jsx-pretty')
  " call dein#add('othree/yajs.vim')
  call dein#add('cakebaker/scss-syntax.vim')
  call dein#add('digitaltoad/vim-pug')
  call dein#add('iloginow/vim-stylus')
  call dein#add('justmao945/vim-clang')
  call dein#add('vim-scripts/gnuplot-syntax-highlighting')
  call dein#add('Shougo/vinarise.vim')
  call dein#add('vim-crystal/vim-crystal')
  call dein#add('jparise/vim-graphql')

  call dein#add('lervag/vimtex')
  call dein#add('thinca/vim-quickrun')

  call dein#add('neoclide/coc.nvim', { 'rev': 'release' })
  call dein#add('github/copilot.vim')

  call dein#add('adamheins/vim-highlight-match-under-cursor')

  " You can specify revision/branch/tag.
  call dein#add('Shougo/vimshell', { 'rev': '3787e5' })

  " Required:
  call dein#end()
  call dein#save_state()
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif
