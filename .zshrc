PROMPT="%F{blue}`date "+%m/%d(%a)"`%f%F{yellow}:%*%f%F{magenta}:%~%f
$ "
precmd() {
  vcs_info
  RPROMPT=$vcs_info_msg_0_
}

export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8

fpath=(~/.zsh/completion $fpath)
autoload -U compinit
compinit -u
zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}'

autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'

export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=2000
export SAVEHIST=10000
# export HISTORY_IGNORE="(cd|ls|jj|ls|vi|git)"
setopt hist_ignore_dups
setopt EXTENDED_HISTORY

setopt no_beep # ビープ音を無効
setopt ignore_eof # Ctrl+Dで終了しない
setopt interactive_comments # '#'以降をコマンドとして扱う

alias cdd='cd ~/Desktop'
alias jj='cd ..'
alias jjj='cd ../..'
alias jjjj='cd ../../..'
alias o='open .'
alias ls='ls -alG'
alias search-find='find . -type f -print | xargs grep'
alias vi='nvim'
alias docker-prune='docker system prune -f'
alias de='docker-compose exec'
alias dr='docker-compose run'
alias drs='docker-compose restart'
alias dl='docker-compose logs -f --tail=100'
alias brew-tree="brew deps --tree --installed"
alias raku-staging-tag='git tag staging-$(git rev-parse HEAD)'
alias repo='cd $(ghq root)/$(ghq list | peco)'

# for homebrew
export PATH="/usr/local/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
source "${HOME}/google-cloud-sdk/path.zsh.inc"
# The next line enables shell command completion for gcloud.
source "${HOME}/google-cloud-sdk/completion.zsh.inc"

eval "$(anyenv init -)"

export GOROOT=`go env GOROOT`
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

function _peco-history-exec() {
  local l=$(history 1 | tail -r | ruby -e "while b=gets;puts b.split[1..-1].join(' ');end" | peco)
  BUFFER=$l
  CURSOR=9999
  zle redisplay
}
zle -N _peco-history-exec
bindkey '^r' _peco-history-exec
