#!/bin/false

if test -z "$_comp_dumpfile"; then
    autoload -Uz compinit && compinit
fi
autoload -Uz colors && colors
zmodload zsh/stat &>/dev/null && alias stat='builtin stat -ostnr'

export EDITOR=vim LESS='-FRX' SYSTEMD_LESS='-FRXK' PAGER=less LESSCHARSET=utf-8

if test -z "$LC_ALL" && test -z "$LC_TIME"; then
    export LC_ALL=en_US.UTF-8
fi

case "$TERM" in *256color) export COLORTERM=24bit;; esac

__prompt_hostname_cmd="%m "
__prompt_hostname_color="%U%m%u "
prompt="%(?..<%{$fg[cyan]%}%?%{$reset_color%}> )%{$reset_color$fg_bold[default]%}${__prompt_prefix}%{$reset_color%}${__prompt_hostname_color}%(1j.%{$fg_bold[yellow]%}%j%{$reset_color%} .)%3d %B%#%b "

setopt re_match_pcre

case "$TERM" in
    xterm-256color|xterm|screen-256color|screen|rxvt|rxvt-256color|konsole*)
        function precmd () {
            print -Pn "\e]0;${__prompt_hostname_cmd}%# %~\a"; git_set_prompt;
        }
        function preexec () {
            local cmd="$2"
            cmd="${cmd//\\n/?}"
            cmd="${cmd//\\r/?}"
            cmd="${cmd:gs/\\/\\\\}"
            local str="$(print -Pn "${__prompt_hostname_cmd}%#")"
            print -n "\e]0;$str $cmd\a";
        }
    ;;
esac

setopt appendhistory    #Append history to the history file (no overwriting)
setopt sharehistory     #Share history across terminals
setopt incappendhistory #Immediately append to the history file, not just when a term is killed
setopt incappendhistorytime
setopt histlexwords
setopt histfcntllock
setopt histexpiredupsfirst
setopt transientrprompt

setopt nobashautolist autolist listambiguous automenu nomenucomplete
setopt autocd beep listbeep notify
setopt autopushd completeinword listtypes listpacked
setopt autoparamslash autoremoveslash completealiases alwaystoend
setopt noextendedglob nonomatch nohup

setopt no_chase_links

eval $(dircolors -b 2>/dev/null)
LS_COLORS="$LS_COLORS:ow=0:"

alias grep='grep --color'
alias egrep='egrep --color'
alias fgrep='fgrep --color'
alias ls='ls --color=auto -A'
alias sl=ls
alias ccd=cd
alias cdd=cd
alias hahs=hash
alias lesss=less
alias les=less

{
    if type pacman && type pacaur && ! alias pacman; then
        compdef _pacaur pacman
        compdef _pacaur_all_packages pacinfo
        _pacman # for _packman_all_packages
        _pacaur
        if test $UID -eq 0; then
            umask 0002
            alias pacman='sudo -nHu sthalik pacaur --color=always'
            alias pacaur=pacman
        else
            umask 0077
            alias pacman='pacaur --color=always'
        fi
        test -z "$DEBUGINFOD_URLS" && export DEBUGINFOD_URLS="https://debuginfod.archlinux.org"
    fi

    if type apt; then
        function aptitude() {
            if test $# -eq 0; then
                command aptitude --help </dev/null
            else
                local up=0 pu="--purge-unused" a=""
                for k in "$@"; do
                    case "$k" in
                        purge) a="-D"; break ;;
                        *upgrade|*install|download|changelog) up=1; break ;;
                        #download|changelog|*'source'*|*src*) pu=""; up=0; break ;;
                        #[a-z][a-z]*) pu=""; up=0; break ;;
                        -*) ;;
                        *) pu=""; break ;;
                    esac
                done
                if test $up -eq 1; then
                    command aptitude -q=1 update || return $?
                fi
                command aptitude $pu $a "$@"
            fi
        }
        alias a=aptitude
        compdef _aptitude aptitude
        compdef _aptitude a
    fi
    if type systemctl; then
        if test $UID -ne 0; then
            alias systemctl='sudo -n systemctl'
        fi
    fi

} >/dev/null 2>&1 </dev/null

case "$OSTYPE" in
linux*)
    alias ls=ls\ --color=always -A
    alias gdb="gdb -q"
    ;;
freebsd*)
    function top() {
        if test $# = 0; then
            top -aStPs3
        else
            command top "$@"
        fi
    }
    function iotop()
    {
        top -HaStPmio -ototal -s3 "$@"
    }
    function mmsodrunk()
    {
        PAGER=cat command mergemaster -FviCP "$@"
    }

    alias ln='ln -wh'

    if which gnuls >/dev/null; then
        alias ls=gnuls\ --color=always\ -A
    else
        alias ls=ls --color\ -A
    fi
    alias iotop='top -aStPs3 -m io -o total 10'
    ;;
darwin*)
    if which gnuls >/dev/null; then
        alias ls=gnuls\ --color\ -A
    else
        alias ls='ls -FG'
    fi
    ;;
esac

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _oldlist _expand _complete _ignored _match _correct _approximate _prefix
zstyle ':completion:*' completions 1
zstyle ':completion:*' expand prefix suffix
zstyle ':completion:*' file-sort name
zstyle ':completion:*' format '%B%d%b'
zstyle ':completion:*' glob 1
zstyle ':completion:*' group-name ''
zstyle ':completion:*' ignore-parents parent pwd
zstyle ':completion:*' insert-unambiguous true
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt '--- More ---'
zstyle ':completion:*' list-suffixes true
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[._-]=** r:|=**' 'm:{[:lower:]}={[:upper:]} m:{[:lower:][:upper:]}={[:upper:][:lower:]} r:|[._-]=** r:|=** l:|=*'
zstyle ':completion:*' match-original both
zstyle ':completion:*' max-errors 1 not-numeric
zstyle ':completion:*' menu select
zstyle ':completion:*' original true
zstyle ':completion:*' preserve-prefix '//[^/]##/'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' substitute 1
zstyle ':completion:*' verbose true
#zstyle :compinstall filename "$HOME/.zshrc"

bindkey -e
#case "$TERM" in
#screen|screen-256color)
    bindkey "^[[1~"   beginning-of-line
    bindkey "^[[4~"   end-of-line
    bindkey "^[[3~"   delete-char
    # ;;
#xterm|xterm-256color)
    bindkey "^[[1;3D" backward-word
    bindkey "^[[1;3C" forward-word
    bindkey "^[[H"    beginning-of-line
    bindkey "^[[F"    end-of-line
    bindkey "^[[5D"   backward-word
    bindkey "^[[5C"   forward-word
    bindkey "^[O5D"   backward-word
    bindkey "^[O5C"   forward-word
    bindkey "^[OH"    beginning-of-line
    bindkey "^[OF"    end-of-line
    bindkey "^[[1;5D" backward-word
    bindkey "^[[1;5C" forward-word
    # ;;
#?*)
#esac

bindkey "^[Od"    backward-word
bindkey "^[^[[D"  backward-word
bindkey "^[[D"    backward-char
bindkey "^[Oc"    forward-word
bindkey "^[^[[C"  forward-word
bindkey "^[[C"    forward-char
bindkey "^[[5~"   beginning-of-history
bindkey "^[[6~"   end-of-history
bindkey "^[[B"    down-line-or-history
bindkey "^[[A"    up-line-or-history
bindkey "^R"      history-incremental-search-backward
bindkey "^F"      history-incremental-search-forward
bindkey "^?"      backward-delete-char
bindkey "^H"      backward-delete-char
bindkey "^W"      backward-kill-word
bindkey "^U"      backward-kill-line
bindkey "^K"      kill-line
bindkey "^[[3~"   delete-char
bindkey "^E"      kill-word
bindkey "^Y"      yank
bindkey "^L"      clear-screen
bindkey "^I"      expand-or-complete
bindkey "^V"      quoted-insert
bindkey "^X"      end-of-list

WORDCHARS='*?.~;!#%^_-' # XXX

# git prompt only

# Adapted from code found at <https://gist.github.com/1712320>.

setopt prompt_subst
autoload -U colors && colors # Enable colors in prompt

# Modify the colors and symbols in these variables as desired.
GIT_PROMPT_NOCOLOR="%{$reset_color%}"
case "$LC_ALL $LC_CTYPE" in
    " C"|"C "*) GIT_PROMPT_OK="%{$fg[green]%}" ;;
    *) GIT_PROMPT_OK="%{$fg[green]%}✓" ;;
esac
GIT_PROMPT_PREFIX="%{$fg[green]%}["
GIT_PROMPT_SUFFIX="%{$fg[green]%}]"
GIT_PROMPT_AHEAD="%{$fg[red]%}ANUM"
GIT_PROMPT_BEHIND="%{$fg[cyan]%}BNUM"
GIT_PROMPT_MERGE="%{$fg_bold[default]%}STATE "

# Show different symbols as appropriate for various Git repository states
parse_git_state() {
  local branch_pos=""
  local merge
  local behind=0
  local ahead=0
  local line=""
  local nc="$GIT_PROMPT_NOCOLOR"
  local pos=""

  local git_merge=""

  if test -d "$dir/rebase-apply" -o -d "$dir/rebase-merge"; then
    git_merge="REBASE"
  elif test -e "$dir/MERGE_HEAD" -a -e "$dir/MERGE_MSG"; then
    git_merge="MERGE"
  elif test -e "$dir/CHERRY_PICK_HEAD"; then
    git_merge="CHERRY"
  fi

  if test -n "$git_merge"; then
    merge="${GIT_PROMPT_MERGE//STATE/$git_merge}$nc"
  fi

  git rev-list --left-right @{u}... 2>/dev/null | while read line; do
    case "$line" in
        \>*) (( ahead += 1 )) ;;
        \<*) (( behind += 1 )) ;;
    esac
  done

  if [ $ahead -gt 0 ]; then
    pos="${GIT_PROMPT_AHEAD//NUM/$ahead}"
  fi

  if [ $behind -gt 0 ]; then
    pos="$pos${GIT_PROMPT_BEHIND//NUM/$behind}"
  fi

  if test -z "$pos"; then
      pos="$GIT_PROMPT_OK"
  else
      pos="$GIT_PROMPT_PREFIX$pos$GIT_PROMPT_SUFFIX"
  fi

  _RPROMPT_GIT_STATE="$merge$pos$nc"
}

git_prompt_string() {
  if test -e "./.git" -o -e "./.git/index" -o -e "../.git/index" -o -e "../../.git/index" -o -e "../../../.git/index"
  local dir=""
  local nc="$GIT_PROMPT_NOCOLOR"
  for dir in "./.git" "../.git" "../../.git" "../../../.git" "../../../../.git"; do
    local git_where=""
    #test -f "$dir/index" -o -f "$dir/refs" || continue

    # Show Git branch/tag, or name-rev if on detached head
    { git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD; } 2>/dev/null | read git_where

    test -n "$git_where" || continue

    parse_git_state
    git_where="%{$fg[cyan]%}${git_where#(refs/heads/|tags/)}$nc"

    RPS1="$_RPROMPT_GIT_STATE$nc$GIT_PROMPT_PREFIX$git_where$GIT_PROMPT_SUFFIX$nc"
    break
  done
  unset _RPROMPT_GIT_STATE
}

if test $UID -eq 0; then
    umask 022
else
    umask 027
fi

case "$OS,$OSTYPE" in
    Windows_NT,msys)
        umask 022
        compdef -d start
        compdef _nice msvc
        compdef _nice msvc64
        killall() {
            local param='' i=0 ret=0
            case "$1" in
                -9) shift; param='-f' ;;
                -15) shift; param='' ;;
                -*) echo "killall: unknown signal '$1'" >&2; return 64 ;;
            esac
            for i in "$@"; do
                case "$i" in
                    *.*) ;;
                    *) i="$i.exe" ;;
                esac
                taskkill $param -im "$i" || ret=1
            done
            return $ret
        }
        mklink() {
            ( set -e
            local src="$1" dest="$2" local sw=""
            if test $# -ne 2 || test -z "$src" || test -z "$dest"; then
                echo "usage: mklink src dest" >&2
                return 64
            fi
            if test -d "$dest" && ! test -d "$src"; then
                dest="$dest/$(basename -- "$src")"
            fi
            if test -d "$src"; then
                sw="/d"
            fi
            src="$(cygpath -w -- "$src")"
            dest="$(cygpath -w -- "${dest:a}")"
            mklink.bat $sw $dest $src
            )
        }
        zstyle ':completion:*:-command-:*' ignored-patterns '*.dll'
    ;;
esac

git_set_prompt()
{
    unset RPS1
    whence git &>/dev/null || return 0
    git_prompt_string
}

_popd-widget() {
    if popd -q 2>/dev/null; then
        zle reset-prompt
        zle redisplay
        if test $#dirstack -ne 0; then
            typeset -a stack=($dirstack[0,5])
            if test $#dirstack -ge 5; then
                zle -M "stack: $stack ..."
            else
                zle -M "stack: $stack"
            fi
        fi
    else
        zle -M "no stack"
        zle beep
    fi
}
zle -N _popd-widget
bindkey \^P _popd-widget

if which systemctl &>/dev/null; then
    alias sc=systemctl
    compdef sc=systemctl
else
    compdef _service service
fi

if which highlight &>/dev/null; then
    highlight() {
        command highlight -O ansi "$@" </dev/null | less
    }
    alias hl=highlight
fi

if which git &>/dev/null; then
    alias gti='git'
    alias gc='git commit'
    alias ga='git add'
    alias gr='git rebase -i'
    alias grc='git rebase --cont'
    alias gra='git rebase --abort'
    alias gco='git checkout'
    alias gs='git status'
    alias g='git status'
    alias gp='git pull'
    alias gf='git fetch'
    alias gl='git log'
    alias grc='git rebase --continue'
    alias gra='git rebase --abort'
    alias gb='git switch'
    type git-dag &>/dev/null && alias gd='git dag'
    type python &>/dev/null && alias pythom=python
fi

if which git &>/dev/null; then
    alias axel='axel -c --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"'
fi

# eof

