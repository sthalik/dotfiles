if test -z "$_comp_dumpfile"; then
    # -C trusts the existing dump: it skips both the fpath security scan (84 ms
    # here, most of shell startup) and the check for newly installed completion
    # functions. After installing one, rm ~/.zcompdump and start a new shell.
    autoload -Uz compinit && compinit -C
fi
autoload -Uz colors && colors
zmodload zsh/stat &>/dev/null && alias stat='builtin stat -ostnr'

export EDITOR=vim LESS='-FRX' SYSTEMD_LESS='-FRXK' PAGER=less LESSCHARSET=utf-8

if test -z "$LC_ALL" && test -z "$LC_TIME"; then
    export LC_ALL=C.UTF-8
fi

case "$TERM" in *256color) export COLORTERM=24bit;; esac

export CMAKE_COLOR_DIAGNOSTICS=1

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
            # two steps: inside ${...} a bare % is the suffix-removal operator, so
            # ${(%%)"${x}%#"} silently eats the %#
            local str="${__prompt_hostname_cmd}%#"
            str="${(%%)str}"
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

# dircolors was the only fork left at startup. Cache its output; it only changes
# when ~/.dircolors does, or when coreutils is upgraded -- rm the cache for that.
() {
    local cache=~/.zsh-dircolors.cache
    if whence -p dircolors >/dev/null; then
        if [[ ! -s $cache || ( -e ~/.dircolors && ~/.dircolors -nt $cache ) ]]; then
            dircolors -b > $cache 2>/dev/null
        fi
        source $cache 2>/dev/null
    fi
}
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
alias camke=cmake
alias tocuh=touch

type realpath &>/dev/null && alias relapath=realpath

zmodload zsh/zselect

__b() {
    for i in {1.."$1"}; do
        printf \\a;
        zselect -t 12
    done
}
b() {
    local last=$?
    if test $# -gt 0; then
        __b "$1"
    else
        __b 7
    fi
    return $last
}

{
    if type pacman && type pacaur && ! alias pacman; then
        alias pacmna=pacman
        alias pacmam=pacman
        alias pacma=pacman
        alias pacm=pacman
        alias pacmam=pacman
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
        if type debuginfod && test -z "$DEBUGINFOD_URLS"; then
            export DEBUGINFOD_URLS="https://debuginfod.archlinux.org"
        fi
    fi

    if type apt; then
        function aptitude() {
            zmodload zsh/datetime
            zmodload zsh/stat

            if test $# -eq 0; then
                command aptitude --help </dev/null
            else
                if (set -u
                    while test $# -ne 0; do
                        case "$1" in
                        -*); shift ;;
                        update) return 1 ;;
                        *) return 0 ;;
                        esac
                        return 0
                    done)
                then
                    local mtime=0 info
                    zstat -H info ~/.aptitude-update.stamp 2>/dev/null && mtime=$info[mtime]
                    if (( $mtime < $EPOCHSECONDS - 3600 )); then
                        command aptitude -q=1 update || return $?
                        :> ~/.aptitude-update.stamp
                    fi
                fi
                command aptitude --purge-unused "$@"
            fi
        }
        alias a=aptitude
        compdef _aptitude=_aptitude
        compdef _aptitude a
    fi
    if type systemctl; then
        if test $UID -ne 0; then
            alias systemctl='sudo -n systemctl'
        fi
    fi

} >/dev/null 2>&1 </dev/null

case "$OSTYPE" in
    Windows_NT)
        umask 022
        compdef -d start
        compdef _nice msvc
        compdef _nice msvc64
        compdef _nice clang64
        compdef _nice mingw64
        zstyle ':completion:*:-command-:*' ignored-patterns '*.dll'
        alias ls=ls\ --color=always -A
        alias gdb="gdb -q"
        alias find='find -O3'
    ;;
esac

case "$OSTYPE" in
linux*)
    alias ls=ls\ --color=always -A
    alias gdb="gdb -q"
    alias find='find -O3'
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

WORDCHARS='*?.~;!#%^_-'
#setopt no_hist_expand # XXX

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
  local merge
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

  # @{u} needs HEAD on a branch. Detached it can only fatal, so skip the fork
  # rather than pay 29 ms for a guaranteed 0/0. Not keyed on merge/rebase/cherry:
  # git am and git merge both keep HEAD attached, and there the count is real.
  if test -n "$git_head_ref"; then
    _gitp_ahead_behind "$dir" "$_gs[commondir]" "${git_head_ref#refs/heads/}" "$_gs[head]"
  fi

  if [ $_gitp_ahead -gt 0 ]; then
    pos="${GIT_PROMPT_AHEAD//NUM/$_gitp_ahead}"
  fi

  if [ $_gitp_behind -gt 0 ]; then
    pos="$pos${GIT_PROMPT_BEHIND//NUM/$_gitp_behind}"
  fi

  if test -z "$pos"; then
      pos="$GIT_PROMPT_OK"
  else
      pos="$GIT_PROMPT_PREFIX$pos$GIT_PROMPT_SUFFIX"
  fi

  _RPROMPT_GIT_STATE="$merge$pos$nc"
}

git_prompt_string() {
  # 1 = not a repo; 2 = repo, no rebase; 0 = rebase in progress
  typeset -A _gs
  git_rebase_state _gs
  local rc=$?
  test $rc -eq 1 && return 0

  local nc="$GIT_PROMPT_NOCOLOR"
  # parse_git_state reads $dir; the old ".git" walk broke on submodules and
  # linked worktrees, where .git is a file and "$dir/rebase-merge" never exists
  local dir="$_gs[gitdir]"
  local git_where="" git_head_ref="$_gs[head_ref]"
  # declared here so the helpers' assignments land in this scope and leak nothing
  local _gitp_ahead=0 _gitp_behind=0 _gitp_base="" _gitp_name=""
  local _gitp_u_sha="" _gitp_r_sha=""

  # Show Git branch/tag, or name-rev if on detached head
  if test -n "$git_head_ref"; then
    git_where="${git_head_ref#refs/heads/}"
  elif test -n "$_gs[branch]"; then
    # detached mid-rebase: head-name names the branch being replayed. name-rev
    # would only echo the short HEAD that the triple below already prints.
    git_where="$_gs[branch]"
  else
    _gitp_name_rev "$dir" "$_gs[head]"
    git_where="${_gitp_name:-${_gs[head][1,8]}}"
    git_where="${git_where#(refs/heads/|tags/)}"
  fi

  local git_rebase_triple=""
  # plain git am records no commit being applied, so there is no triple to draw --
  # only the REBASE indicator from parse_git_state
  if test $rc -eq 0 -a -n "$_gs[applying]"; then
    # merge-base is the only value here not recoverable from the state files;
    # it needs object traversal, so this one has to fork -- memoised on its pair
    _gitp_merge_base "$dir" "$_gs[head]" "$_gs[applying]"
    test -n "$_gitp_base" || _gitp_base="$_gs[onto]"
    # U+00B7, not ".." / U+2025 / U+2026: mintty passes the wchar to
    # strchr(), so only its low byte counts, and 0x25/0x26/0x24 alias onto
    # word chars, gluing the three hashes into one double-click selection
    git_rebase_triple="${_gitp_base[1,8]}·${_gs[head][1,8]}·${_gs[applying][1,8]} "
  fi

  parse_git_state

  local inner="%{$fg[cyan]%}${git_rebase_triple}${git_where}$nc"

  RPS1="$_RPROMPT_GIT_STATE$nc$GIT_PROMPT_PREFIX$inner$GIT_PROMPT_SUFFIX$nc"
  unset _RPROMPT_GIT_STATE
}

if test $UID -eq 0; then
    umask 022
else
    #umask 027
    umask 022
fi

case "$OS" in
    Windows_NT)
        umask 022
        #compdef -d start
        compdef _nice start
        compdef _nice vc
        compdef _nice msvc
        compdef _nice msvc64
        compdef _nice clang64
        compdef _nice mingw64
        zstyle ':completion:*:*:*:*:commands' ignored-patterns '*.(exe|dll)'
        alias ls=ls\ --color=always -A
        alias gdb="gdb -q"
        alias find='find -O3'

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
fi
if which service &>/dev/null; then
    alias sv=service
    compdef _service sv
    compdef _service service
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
    alias gcps='git cherry-pick --skip'
    alias gcpa='git cherry-pick --abort'
    alias gcp='git cherry-pick'
    alias gd='git diff -w --word-diff'
    alias gbc='git branch --contains'
    alias gsu='git submodule update --init --recursive'
    #type python &>/dev/null && alias pythom=python
fi

if which axel &>/dev/null; then
    alias axel='axel -c --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"'
fi

if which meson &>/dev/null; then
    autoload -U _meson
    compdef _meson meson
fi

if which rg &>/dev/null; then
    compdef rg=_rg
fi

zmodload -i zsh/mapfile

# Memo tables for the three prompt values that cannot be computed without git.
# Loose objects are zlib-deflated and zsh has no inflate module, so ahead/behind,
# merge-base and name-rev must fork. They are pure functions of their input SHAs
# over an append-only object database, so keying on those SHAs is exact rather
# than merely fresh-ish; one entry per gitdir keeps the tables bounded.
typeset -gA _gitp_ab _gitp_mb _gitp_nr

# First line of $1 into $REPLY, minus the trailing CR. Returns 1 if there was
# nothing to read. Most callers probe paths that are legitimately absent, and
# $mapfile[$f] on a missing $f is a fatal expansion error, not an empty string.
_gitp_first_line() {
    REPLY=
    [[ -f $1 ]] || return 1
    REPLY=${${mapfile[$1]%%$'\n'*}%$'\r'}
    [[ -n $REPLY ]]
}

# Ref name -> SHA: loose file, per-worktree then common, then packed-refs.
# Sets _gitp_r_sha; returns 1 when the ref does not exist.
_gitp_resolve_ref() {
    emulate -L zsh
    local gd=$1 cd=$2 rn=$3 ln
    _gitp_first_line $gd/$rn || _gitp_first_line $cd/$rn
    _gitp_r_sha=$REPLY
    if [[ -z $_gitp_r_sha && -f $cd/packed-refs ]]; then
        for ln in ${(f)mapfile[$cd/packed-refs]}; do
            ln=${ln%$'\r'}
            case $ln in '#'* | '^'*) continue ;; esac
            if [[ ${ln#* } == "$rn" ]]; then
                _gitp_r_sha=${ln%% *}
                break
            fi
        done
    fi
    [[ -n $_gitp_r_sha ]]
}

# Reads the git config at $1 into the assoc array named $2, keyed "section.sub.key".
# This is a small INI reader, not git's: it returns 1 the moment it meets anything
# whose exact meaning it cannot reproduce, so a caller can fall back to forking.
_gitp_read_config() {
    emulate -L zsh
    setopt extended_glob
    local line sec= key val
    local -A _gitp_o

    [[ -e $1 ]] || return 1
    for line in ${(f)mapfile[$1]}; do
        line=${${${line%$'\r'}##[[:space:]]#}%%[[:space:]]#}
        [[ -z $line || $line == ('#'|';')* ]] && continue
        # a trailing backslash continues the value onto the next line
        [[ $line == *\\ ]] && return 1
        case $line in
            \[*\])
                line=${${${line#\[}%\]}%%[[:space:]]#}
                case $line in
                    *\\*)                       return 1 ;;
                    [[:alnum:].-]##[[:space:]]##\"*\")
                        sec="${${line%%[[:space:]]*}:l}.${${line#*\"}%\"*}" ;;
                    [[:alnum:].-]##)            sec="${line:l}" ;;
                    *)                          return 1 ;;
                esac
                # include/includeIf pull in other files with their own precedence
                [[ $sec == include* ]] && return 1
                ;;
            *)
                [[ -n $sec ]] || return 1
                if [[ $line == *=* ]]; then
                    key=${${line%%=*}%%[[:space:]]#}
                    val=${${line#*=}##[[:space:]]#}
                else
                    key=$line val=true
                fi
                if [[ $val == *[\\\"]* ]]; then
                    # quoting and escapes need git's own unquoting rules, so poison
                    # the value: only a caller that reads this key has to give up
                    val=$'\x01'
                else
                    # an unquoted # or ; starts a comment
                    val=${${val%%[\#\;]*}%%[[:space:]]#}
                fi
                [[ $key == [[:alnum:]-]## ]] || return 1
                # keys are multi-valued (remote.*.fetch routinely repeats), so keep
                # every one newline-joined; single-valued readers take the last
                key=${sec}.${key:l}
                if [[ -n ${_gitp_o[$key]} ]]; then
                    _gitp_o[$key]=${_gitp_o[$key]}$'\n'$val
                else
                    _gitp_o[$key]=$val
                fi
                ;;
        esac
    done
    set -A $2 "${(@kv)_gitp_o}"
}

# Upstream SHA of branch $3, without forking. Sets _gitp_u_sha.
# 0 with a SHA = upstream found; 0 with "" = branch genuinely has no upstream,
# so ahead/behind are 0/0 forever; 1 = cannot tell, the caller must ask git.
_gitp_upstream_sha() {
    emulate -L zsh
    local gd=$1 cd=$2 br=$3 remote merge ref spec found=
    local -A cfg

    _gitp_u_sha=
    [[ -e $gd/config.worktree || -e $cd/config.worktree ]] && return 1
    _gitp_read_config $cd/config cfg || return 1

    remote=${cfg[branch.$br.remote]##*$'\n'}
    merge=${cfg[branch.$br.merge]##*$'\n'}
    [[ -n $remote && -n $merge ]] || return 0
    [[ $remote$merge == *$'\x01'* ]] && return 1

    if [[ $remote == . ]]; then
        ref=$merge
    else
        # only the default refspec puts the branch at refs/remotes/<remote>/<name>;
        # a repo may carry extra ones (refs/pull/* is common) alongside it
        for spec in ${(f)cfg[remote.$remote.fetch]}; do
            if [[ $spec == "+refs/heads/*:refs/remotes/$remote/*" ||
                  $spec == "refs/heads/*:refs/remotes/$remote/*" ]]; then
                found=1
                break
            fi
        done
        [[ -n $found ]] || return 1
        ref=refs/remotes/$remote/${merge#refs/heads/}
    fi
    _gitp_resolve_ref $gd $cd $ref || return 1
    _gitp_u_sha=$_gitp_r_sha
}

# Sets _gitp_ahead / _gitp_behind for branch $3 at SHA $4.
_gitp_ahead_behind() {
    emulate -L zsh
    local gd=$1 cd=$2 br=$3 lsha=$4 usha rc ahead behind xx
    local -a f

    _gitp_ahead=0 _gitp_behind=0

    _gitp_upstream_sha $gd $cd $br
    rc=$?
    usha=$_gitp_u_sha
    (( rc == 0 )) && [[ -z $usha ]] && return 0

    if (( rc == 0 )); then
        f=(${=_gitp_ab[$gd]})
        if [[ $f[1] == $lsha && $f[2] == $usha ]]; then
            _gitp_ahead=$f[3] _gitp_behind=$f[4]
            return 0
        fi
    fi

    git rev-list --count --left-right '@{u}...' 2>/dev/null | read behind ahead xx
    [[ -n $behind ]] || behind=0
    [[ -n $ahead ]] || ahead=0
    _gitp_ahead=$ahead _gitp_behind=$behind
    (( rc == 0 )) && _gitp_ab[$gd]="$lsha $usha $ahead $behind"
    return 0
}

# Sets _gitp_base to merge-base(HEAD=$2, REBASE_HEAD=$3), empty if git can't say.
_gitp_merge_base() {
    emulate -L zsh
    local gd=$1 head=$2 rh=$3
    local -a f

    f=(${=_gitp_mb[$gd]})
    if [[ $f[1] == $head && $f[2] == $rh ]]; then
        _gitp_base=$f[3]
        return 0
    fi
    _gitp_base=
    git merge-base HEAD REBASE_HEAD 2>/dev/null | read _gitp_base
    [[ -n $_gitp_base ]] && _gitp_mb[$gd]="$head $rh $_gitp_base"
    return 0
}

# Sets _gitp_name to a readable name for the detached HEAD at $2.
_gitp_name_rev() {
    emulate -L zsh
    local gd=$1 head=$2
    local -a f

    f=(${=_gitp_nr[$gd]})
    if [[ $f[1] == $head ]]; then
        _gitp_name=$f[2]
        return 0
    fi
    _gitp_name=
    git name-rev --name-only --no-undefined --always HEAD 2>/dev/null | read _gitp_name
    [[ -n $_gitp_name ]] && _gitp_nr[$gd]="$head $_gitp_name"
    return 0
}

# Fills the associative array named by $1 (default: git_rebase_state).
# 0 = rebase/am in progress, 2 = repo but no rebase (gitdir/commondir/head still
# set), 1 = not a repo.
git_rebase_state() {
    emulate -L zsh
    setopt extended_glob

    local -A st
    local dir=$PWD prev line p d gitdir= commondir= rdir= kind=

    # emptied up front so a caller that ignores the return value never sees
    # values left over from the last directory that was mid-rebase
    local name=${1:-git_rebase_state}
    typeset -gA $name
    set -A $name

    if [[ -n $GIT_DIR ]]; then
        gitdir=$GIT_DIR
    else
        while true; do
            # at the filesystem root $dir is "/", and "//name" is a UNC path on
            # Windows: stat blocks ~1.1 s resolving "name" as a host, once per
            # prompt in every directory that is not inside a repository
            d=${dir%/}
            if [[ -d $d/.git ]]; then
                gitdir=$d/.git
                break
            elif [[ -f $d/.git ]]; then
                line=${${mapfile[$d/.git]%%$'\n'*}%$'\r'}
                [[ $line == gitdir:* ]] || return 1
                p=${${line#gitdir:}##[[:space:]]#}
                # a relative gitdir: is anchored at the .git file, not at $PWD
                case $p in
                    /* | [A-Za-z]:[/\\]*) gitdir=$p ;;
                    *)                    gitdir=$d/$p ;;
                esac
                break
            elif [[ -d $d/objects && -e $d/HEAD ]]; then
                gitdir=$dir
                break
            fi
            prev=$dir
            dir=${dir:h}
            [[ $dir == "$prev" ]] && return 1
        done
    fi

    # :a prepends $PWD to anything not starting with /, so a git-for-windows
    # drive-letter path has to have the prefix split off before normalising
    case $gitdir in
        [A-Za-z]:/*) gitdir=${gitdir[1,2]}${${gitdir[3,-1]}:a} ;;
        [A-Za-z]:*)  ;;
        *)           gitdir=${gitdir:a} ;;
    esac

    if [[ -n $GIT_COMMON_DIR ]]; then
        commondir=$GIT_COMMON_DIR
    elif [[ -e $gitdir/commondir ]]; then
        p=${${mapfile[$gitdir/commondir]%%$'\n'*}%$'\r'}
        case $p in
            /* | [A-Za-z]:[/\\]*) commondir=$p ;;
            *)                    commondir=$gitdir/$p ;;
        esac
    else
        commondir=$gitdir
    fi
    case $commondir in
        [A-Za-z]:/*) commondir=${commondir[1,2]}${${commondir[3,-1]}:a} ;;
        [A-Za-z]:*)  ;;
        *)           commondir=${commondir:a} ;;
    esac

    st[gitdir]=$gitdir
    st[commondir]=$commondir

    local head= rn rv ln
    _gitp_first_line $gitdir/HEAD && head=$REPLY
    local -i depth=0
    while [[ $head == ref:* ]]; do
        if (( ++depth > 8 )); then
            head=
            break
        fi
        rn=${${head#ref:}##[[:space:]]#}
        st[head_ref]=$rn
        # per-worktree refs live in gitdir; refs/heads and packed-refs in commondir
        _gitp_first_line $gitdir/$rn || _gitp_first_line $commondir/$rn
        rv=$REPLY
        if [[ -z $rv && -f $commondir/packed-refs ]]; then
            for ln in ${(f)mapfile[$commondir/packed-refs]}; do
                ln=${ln%$'\r'}
                case $ln in '#'* | '^'*) continue ;; esac
                if [[ ${ln#* } == "$rn" ]]; then
                    rv=${ln%% *}
                    break
                fi
            done
        fi
        head=$rv
        [[ -n $head ]] || break
    done
    st[head]=$head

    if [[ -d $gitdir/rebase-merge ]]; then
        rdir=$gitdir/rebase-merge
        if [[ -e $rdir/interactive ]]; then
            kind=rebase-i
        else
            kind=rebase-merge
        fi
    elif [[ -d $gitdir/rebase-apply ]]; then
        rdir=$gitdir/rebase-apply
        if [[ -e $rdir/rebasing ]]; then
            kind=rebase-apply
        elif [[ -e $rdir/applying ]]; then
            kind=am
        else
            kind=am-or-rebase
        fi
    else
        set -A $name "${(@kv)st}"
        return 2
    fi

    st[state_dir]=$rdir
    st[kind]=$kind

    _gitp_first_line $rdir/head-name; st[head_name]=$REPLY
    st[branch]=${st[head_name]#refs/heads/}
    _gitp_first_line $rdir/onto;      st[onto]=$REPLY
    # pre-2.6 interactive rebase called it "head"
    _gitp_first_line $rdir/orig-head || _gitp_first_line $rdir/head
    st[orig_head]=$REPLY

    if [[ $kind == rebase-(i|merge) ]]; then
        _gitp_first_line $rdir/msgnum; st[step]=$REPLY
        _gitp_first_line $rdir/end;    st[total]=$REPLY
    else
        _gitp_first_line $rdir/next;   st[step]=$REPLY
        _gitp_first_line $rdir/last;   st[total]=$REPLY
    fi

    # abbreviated in git < 2.29, full-length since; REBASE_HEAD is a ref, so it is a
    # loose file only under the "files" backend
    _gitp_first_line $rdir/stopped-sha || _gitp_first_line $rdir/original-commit ||
        _gitp_first_line $gitdir/REBASE_HEAD
    st[applying]=$REPLY

    set -A $name "${(@kv)st}"
}

# vim: et shiftwidth=4 softtabstop=4 tabstop=8 shortmess=atI
