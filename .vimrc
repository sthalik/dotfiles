let skip_defaults_vim=1
let g:netrw_dirhistmax=0

"set t_Co=256
"set t_Co=65535
set t_Co=16777216

"set directory=.
set nocompatible ai scs ic showcmd wildmenu
set et smarttab shiftwidth=4 softtabstop=4 tabstop=8 nohls shortmess=atI
set splitbelow splitright
set modeline nosecure virtualedit=onemore
set nocindent noincsearch
"set exrc

"set list
"set listchars=tab:>-,trail:!
set listchars=trail:!

set matchpairs+=<:>
"set iskeyword+=:

filetype indent on
filetype indent plugin on
"set cindent

set numberwidth=5 ruler
"set number
set showmatch
set matchtime=1
set scrolloff=3
set backspace=indent,eol,start

set wildmode=longest:full,list

set history=200

set viminfo+=:5000
set viminfo+=/500
set switchbuf=useopen
"set noswapfile
set swapfile

"set viminfo=""
"set dir=~/.vim-tmp/swapfiles
"set backupdir=~/.vim-tmp/backupdir
set fileformat=unix
set nobackup
"set backup
"set autowrite

set guifont=Fira\ Code\ 9

syntax on

au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
\| exe "normal! g'\"" | endif

imap <F5> <Esc>:set invpaste<CR>:echo "Paste mode now " . &paste<CR>
map <F5> <Esc>:set invpaste<CR>:echo "Paste mode now " . &paste<CR>

command! Conflicts /^\(|||\|<<<\|>>>\)

imap <F4> :Conficts<CR><CR>
map <F4> :Conflicts<CR>

function s:do_files()
    bp!
    bn!
    file
endfunction

autocmd VimEnter,BufFilePost,FileReadPost,BufNewFile * silent! call s:do_files()

highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE
highlight DiffAdd    cterm=bold ctermfg=10 ctermbg=17 gui=none guifg=bg guibg=Red
highlight DiffDelete cterm=bold ctermfg=10 ctermbg=17 gui=none guifg=bg guibg=Red
highlight DiffChange cterm=bold ctermfg=10 ctermbg=17 gui=none guifg=bg guibg=Red
highlight DiffText   cterm=bold ctermfg=10 ctermbg=88 gui=none guifg=bg guibg=Red

source ~/.vim/plugin/file_line.vim

