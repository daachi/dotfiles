execute pathogen#infect()

let mapleader="\\"

set number
set ruler
set hidden

filetype plugin indent on
" indent is nice, but shiftwidth is 4 by default (I belive)
" which is too, too much
set shiftwidth=2
set autoindent
set expandtab
set background=dark

set incsearch
set hlsearch

set backupdir=/home/daachi/tmp/vim-backup
set backup
set writebackup

set list listchars=tab:\ \ ,trail:·

map <leader>c :set cursorcolumn!<cr> :set cursorline!<cr>
map <leader>t :NERDTreeToggle<CR>
