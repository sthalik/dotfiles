let skip_defaults_vim=1
let g:netrw_dirhistmax=0

set t_Co=256

"set directory=.
set nocompatible ai scs ic showcmd wildmenu
set et smarttab shiftwidth=4 softtabstop=4 tabstop=8 nohls shortmess=atI
set splitbelow splitright
set modeline nosecure exrc virtualedit=onemore
set nocindent noincsearch

"set list
"set listchars=tab:>-,trail:!
set listchars=trail:!

set matchpairs+=<:>

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
set noswapfile
"set viminfo=""
"set dir=~/.vim-tmp/swapfiles
"set backupdir=~/.vim-tmp/backupdir
set fileformat=unix
set nobackup

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

:highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE

source ~/.vim/plugin/file_line.vim

