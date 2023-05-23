precmd() {
  vcs_info
  PROMPT="%F{blue}`date "+%m/%d(%a)"`%f%F{yellow}:%*%f%F{magenta}:%~%f:$vcs_info_msg_0_
$ "
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
export HISTSIZE=5000
export SAVEHIST=10000
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt EXTENDED_HISTORY
setopt inc_append_history # 履歴をインクリメンタルに追加
setopt hist_reduce_blanks # 余分な空白は詰めて記録
setopt hist_no_store # historyコマンドは履歴に登録しない
zshaddhistory() {
  local line=${1%%$'\n'}
  local cmd=${line%% *}
  [[ true
    && ${cmd} != (cd|ls|vi)
    && ${cmd} != (ww|jj|jjj|jjjj)
  ]]
}

hey() {
  local line=${1%%$'\n'}
  local cmd=${line%% *}
  echo $line
  echo $cmd
}

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
alias db='docker compose build'
alias du='docker compose up -d'
alias de='docker compose exec'
alias dr='docker compose run'
alias drs='docker compose restart'
alias dl='docker compose logs -f --tail=20'
alias dd='docker compose down'
alias be='bundle exec'
alias brew-tree="brew deps --tree --installed"
alias ww='cd $(ghq root)/$(ghq list | peco)'
alias ch='git switch $(git branch --format="%(refname:short)" | peco)'
alias gg='git grep --heading'
alias pugtohtml='npx @plaidev/pug-to-html'
alias rails='de app rails'
alias format='npm run format:only-changed'
alias tree='tree -a -I "\.DS_Store|\.git|node_modules|vendor\/bundle" -N'

# for homebrew
export PATH="/usr/local/bin:$PATH"
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"

export PATH="$HOME/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
source "${HOME}/google-cloud-sdk/path.zsh.inc"
# The next line enables shell command completion for gcloud.
source "${HOME}/google-cloud-sdk/completion.zsh.inc"

eval "$(anyenv init -)"

eval "$(direnv hook zsh)"

export GOROOT=`go env GOROOT`
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

function _peco-history-exec() {
  local l=$(history 1 | tail -r | $HOME/.anyenv/envs/rbenv/shims/ruby -e "while b=gets;puts b.split[1..-1].join(' ');end" | peco)
  BUFFER=$l
  CURSOR=9999
  zle redisplay
}
zle -N _peco-history-exec
bindkey '^r' _peco-history-exec

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/kthatoto/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/kthatoto/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/kthatoto/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/kthatoto/google-cloud-sdk/completion.zsh.inc'; fi
