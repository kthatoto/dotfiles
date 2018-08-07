
"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=/Users/tk1to/.config/nvim/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('/Users/tk1to/.config/nvim/dein/')
  call dein#begin('/Users/tk1to/.config/nvim/dein/')

  " Let dein manage dein
  " Required:
  call dein#add('/Users/tk1to/.config/nvim/dein/repos/github.com/Shougo/dein.vim')

  call dein#add('Shougo/neosnippet.vim')
  call dein#add('Shougo/neosnippet-snippets')

  " Add or remove your plugins here:
  call dein#add('mattn/emmet-vim')
  call dein#add('terryma/vim-smooth-scroll')
  call dein#add('nathanaelkane/vim-indent-guides')
  call dein#add('rhysd/accelerated-jk')
  call dein#add('vim-scripts/AnsiEsc.vim')

  call dein#add('plasticboy/vim-markdown')
  call dein#add('kannokanno/previm')
  call dein#add('embear/vim-localvimrc')
  call dein#add('tyru/open-browser.vim')
  call dein#add('cohama/lexima.vim')
  call dein#add('terryma/vim-multiple-cursors')
  call dein#add('tomtom/tcomment_vim')
  call dein#add('sophacles/vim-processing')
  call dein#add('tpope/vim-surround')
  call dein#add('scrooloose/nerdtree')

  call dein#add('elixir-editors/vim-elixir')
  call dein#add('slim-template/vim-slim')
  call dein#add('posva/vim-vue')
  call dein#add('cakebaker/scss-syntax.vim')
  call dein#add('digitaltoad/vim-pug')

  call dein#add('lervag/vimtex')
  call dein#add('thinca/vim-quickrun')

  " You can specify revision/branch/tag.
  call dein#add('Shougo/vimshell', { 'rev': '3787e5' })

  " Required:
  call dein#end()
  call dein#save_state()
endif

" Required:
filetype plugin indent on
syntax enable

" vue re syntax highlight
autocmd FileType vue syntax sync fromstart

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

"End dein Scripts-------------------------

"#################
"# plugin config #
"#################

"nathanaelkane/vim-indent-guides
let g:indent_guides_enable_on_vim_startup = 1
"terryma/vim-smooth-scroll
noremap <silent> <c-u> :call smooth_scroll#up(&scroll, 10, 2)<CR>
noremap <silent> <c-d> :call smooth_scroll#down(&scroll, 10, 2)<CR>
noremap <silent> <c-b> :call smooth_scroll#up(&scroll*2, 10, 4)<CR>
noremap <silent> <c-f> :call smooth_scroll#down(&scroll*2, 10, 4)<CR>

nnoremap <silent><C-e> :NERDTreeToggle<CR>

nmap j <Plug>(accelerated_jk_gj)
nmap k <Plug>(accelerated_jk_gk)

let g:vim_markdown_folding_disabled = 1
au BufRead,BufNewFile *.md   set filetype=markdown
au BufNewFile,BufRead *.twig set filetype=html

"load lvimrc without ask
let g:localvimrc_ask=0

syntax on
colorscheme gruvbox
set background=dark

set number "行数表示
set ruler
nnoremap ; :
nnoremap : ;
inoremap <silent> jj <ESC>
" 不可視文字表示
set list
set listchars=tab:»-,trail:-,nbsp:%

set title

set hlsearch

set tabstop=2
set shiftwidth=2
set softtabstop=0
set expandtab

set expandtab "タブを空白にする
set autoindent "改行した時に前の行のインデントを継承
set smartindent

set clipboard=unnamed

"大文字小文字の区別をしない
set ignorecase
"大文字で検索時は大文字のみ
set smartcase




" Plugin (managed by NeoBundle)
"==============================
" for LaTeX
let g:vimtex_fold_envs = 0
" autocmd
"==============================
augroup filetype
  autocmd!
  " tex file (I always use latex)
  autocmd BufRead,BufNewFile *.tex set filetype=tex
augroup END
" disable the conceal function
" let g:tex_conceal=''
