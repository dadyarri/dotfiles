" =============================
"     BASIC SETTINGS
" ==============================

set nocompatible        " Disable Vi compatibility mode
set encoding=utf-8      " Set UTF-8 encoding
set fileformats=unix,dos,mac " Handle different file formats
set backspace=indent,eol,start " Allow backspacing over everything
set hidden             " Allow switching buffers without saving
set history=1000       " Increase command history size

" ==============================
"      UI IMPROVEMENTS
" ==============================

set number             " Show line numbers
set relativenumber     " Use relative line numbers for easy movement
set cursorline         " Highlight current line
set showmatch          " Highlight matching brackets
set colorcolumn=80     " Mark column 80 for better readability
set scrolloff=8        " Keep 8 lines above/below cursor when scrolling
set lazyredraw         " Optimize screen redraw for performance

" ==============================
"      SEARCH & EDITING
" ==============================
set ignorecase         " Case-insensitive search
set smartcase          " Case-sensitive if uppercase letters are used
set incsearch          " Incremental search
set hlsearch           " Highlight search results
set autoindent         " Enable auto-indentation
set smartindent        " Smart indentation
set expandtab          " Use spaces instead of tabs
set shiftwidth=4       " Set indentation width to 4 spaces
set tabstop=4          " Tab width of 4 spaces
set softtabstop=4      " Soft tab width of 4 spaces
set nowrap             " Disable line wrapping

" ==============================
"      PERFORMANCE OPTIMIZATIONS
" ==============================

set updatetime=300     " Faster response for CursorHold events
set ttyfast            " Speed up terminal rendering
set swapfile           " Enable swap file for recovery
set undofile           " Enable persistent undo
set undodir=~/.vim/undo " Set undo file directory

" ==============================
"      KEY MAPPINGS
" ==============================

nnoremap <Space> :nohlsearch<CR> " Space clears search highlight
nnoremap <C-s> :w<CR>            " Ctrl+S to save
inoremap jk <Esc>                " Exit insert mode quickly with 'jk'
nnoremap <leader>e :bd<CR>:Rexplore<CR> " Close current buffer and open netrw

" ==============================
"      AUTOCOMMANDS
" ==============================

autocmd FileType python setlocal expandtab shiftwidth=4 softtabstop=4
autocmd FileType javascript setlocal expandtab shiftwidth=2 softtabstop=2
autocmd BufWritePre * :%s/\s\+$//e  " Remove trailing spaces on save

" ==============================
"      FINAL TOUCHES
" ==============================
syntax on             " Enable syntax highlighting
set termguicolors     " Enable 24-bit color
colorscheme slate

