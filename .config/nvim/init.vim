let &shell='/bin/bash --login'

runtime! settings/dein.vim

" vue syntax highlight
autocmd FileType vue syntax sync fromstart
runtime! filetypes/*.vim

syntax on
colorscheme gruvbox
set background=dark

set number
" set relativenumber
" nnoremap <C-o> :set relativenumber!<CR>
set ruler
set cursorline
nnoremap ; :
nnoremap : ;
inoremap <silent> jj <ESC>
set list
set listchars=tab:»-,trail:-,nbsp:%
set title
set hlsearch
set foldmethod=indent
set foldlevel=30
set tabstop=2
set shiftwidth=2
set softtabstop=0
set expandtab
set autoindent
set smartindent
set clipboard=unnamed
set ignorecase
set smartcase

" statusline
set statusline=%F\ %m
set statusline+=%= "これ以降は右寄せ
set statusline+=[%l/%L]
set statusline+=[ENC=%{&fileencoding}]

" terminalモードの設定
tnoremap <Esc> <C-\><C-n>

" screen/split関連
nnoremap vs :vsplit<CR>
nnoremap ss :split<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-c> <C-w>c
nnoremap s= <C-w>=

" tab関連
nnoremap sn gt
nnoremap sp gT
nnoremap st :tabnew<CR>

" git関連
" cnoremap git Git

" *でカーソル下の単語検索をしても最初はカーソル移動させない
nnoremap <silent> * :let @/= '\<' . expand('<cword>') . '\>' <bar> set hls <cr>

runtime! settings/dim-inactive-panes.vim

runtime! settings/denite.vim

runtime! settings/plugins/*.vim

exec ":normal <C-[><C-[>"
