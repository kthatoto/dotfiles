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

setopt no_beep # ビープ音を無効
setopt ignore_eof # Ctrl+Dで終了しない
setopt interactive_comments # '#'以降をコマンドとして扱う

alias jj='cd ..'
alias jjj='cd ../..'
alias jjjj='cd ../../..'
alias o='open .'
alias ls='ls -alG'
alias vi='nvim'
alias docker-prune='docker system prune -f'
alias db='docker compose --profile core build'
alias du='docker compose --profile core up -d'
alias de='docker compose --profile core exec'
alias dr='docker compose --profile core run'
alias drs='docker compose --profile core restart'
alias dl='docker compose --profile core logs -f --tail=100'
alias dd='docker compose --profile core down'
alias be='bundle exec'
alias brew-tree="brew deps --tree --installed"
alias ww='cd $(ghq root)/$(ghq list | peco)'
alias ch='git switch $(git-br-list | peco | sed "s/^\* //" | awk "{print \$1}")'
alias gg='git grep --heading'
alias rails='de app rails'
alias format='npm run format:only-changed'
alias tree='tree -a -I "\.DS_Store|\.git|node_modules|vendor\/bundle" -N'
alias rspec-cov='docker compose exec -e SIMPLE_COV_ENABLED=true app rspec'
alias cop='rubocop-only-changed'
alias rspec='rspec-fzf'
alias rp='rspec-only-changed'
alias rss='rspec-select'
alias rpss='rspec-select-interactive'
alias ai='aider --model gpt-4o --api-key openai=$MY_OPENAI_KEY --no-auto-commits'

source ~/dotfiles/scripts/update-types.sh
alias pr-tp="~/dotfiles/scripts/pr-tp.sh"

rubocop-only-changed() {
  git diff --name-only develop | grep "\.rb$"
  echo
  docker compose exec -T app rubocop --color $(git diff --name-only develop | grep "\.rb$") $@
}
rspec-fzf() {
  local file="$1"
  if [[ -n "$file" ]]; then
    de app rspec "$file"
    return
  fi
  local selected=$(find spec | fzf --layout=reverse-list)
  if [[ -z "$selected" ]]; then
    echo "No selection made."
    return 1
  fi
  echo "rspec $selected"
  de app rspec "$selected"
}
rspec-only-changed() {
  git diff --name-only develop | grep "_spec\.rb$"
  echo
  docker compose exec -T app bash -c "RUBYOPT='-W0' bundle exec rspec --color --tty $(git diff --name-only develop | grep '_spec\.rb$' | tr '\n' ' ')"
}
rspec-select() {
  local fzf_bind="j:down,k:up,ctrl-d:half-page-down,ctrl-u:half-page-up,g:first,G:last"
  local file="$1"
  if [[ -z "$file" ]]; then
    local selected_history
    selected_history=$(history 1 | grep 'rss ' | fzf --bind "$fzf_bind" --no-sort --layout=reverse-list)
    if [[ -z "$selected_history" ]]; then
      echo "No selection made."
      return 1
    fi
    local command
    command=$(echo "$selected_history" | sed 's/^[ 0-9]*//')  # Remove line numbers from history
    eval "$command"
    return
  fi

  if [[ ! -f "$file" ]]; then
    echo "File not found: $file"
    return 1
  fi

  local selected
  selected=$( (echo "File: $file"; grep -n -E '^\s*(describe|context)' "$file") | fzf --bind "$fzf_bind" --no-sort --layout=reverse-list)
  if [[ -z "$selected" ]]; then
    echo "No selection made."
    return 1
  fi

  if [[ "$selected" == "File: $file" ]]; then
    echo "File: $file"
    docker compose exec -T app bash -c "RUBYOPT='-W0' rspec --color --tty $file"
    return
  fi

  local line_number
  line_number=$(echo "$selected" | cut -d: -f1)
  echo $file:$line_number
  echo $selected
  docker compose exec -T app bash -c "RUBYOPT='-W0' rspec --color --tty $file:$line_number"
}
rspec-select-interactive() {
  rspec-select $(find spec -type f | fzf --layout=reverse-list)
}

git-br-list() {
  local branches=($(git branch --format='%(refname:short)'))
  local current_branch=$(git branch --contains | awk '{print $2}')
  local max=0
  for line in "${branches[@]}"; do
    if [[ $max -lt ${#line} ]]; then
      max=${#line}
    fi
  done

  local sorted_branches=($(for branch in "${branches[@]}"; do
    description=$(git config branch."$branch".description 2>/dev/null)
    echo "$description $branch"
  done | sort | awk '{print $NF}'))

  for line in "${sorted_branches[@]}"; do
    if [[ $line == $current_branch ]]; then
      echo -n "* "
    else
      echo -n "  "
    fi
    echo -n $line
    for i in $(seq $((${#line} - 1)) $max); do
      echo -n " "
    done
    echo $(git config branch.$line.description)
  done
}
search-find() {
  find . -type f -print | xargs grep $1 | awk 'length($0) < 500'
}

# for homebrew
export PATH="/usr/local/bin:$PATH"

# for uv / aider
export PATH="/Users/kthatoto/.local/bin:$PATH"

BREW_PREFIX=$(brew --prefix)
export LDFLAGS="-L${BREW_PREFIX}/opt/openssl/lib -L${BREW_PREFIX}/lib"
export CPPFLAGS="-I${BREW_PREFIX}/opt/openssl/include -I${BREW_PREFIX}/include"
# export MYSQLCLIENT_LDFLAGS="${LDFLAGS} -L${BREW_PREFIX}/opt/zlib/lib"
# export MYSQLCLIENT_CFLAGS="${CPPFLAGS} -I${BREW_PREFIX}/opt/zlib/include"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

export PATH="$HOME/bin:$PATH"

# eval "$(anyenv init -)"
# export GOROOT=`go env GOROOT`
# export GOPATH=$HOME/go
# export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

eval "$(direnv hook zsh)"

function _peco-history-exec() {
  local l=$(history 1 | tail -r | $HOME/.asdf/shims/ruby -e "while b=gets;puts b.split[1..-1].join(' ');end" | peco)
  BUFFER=$l
  CURSOR=9999
  zle redisplay
}
zle -N _peco-history-exec
bindkey '^r' _peco-history-exec

# asdf
. "$HOME/.asdf/asdf.sh"
fpath=(${ASDF_DIR}/completions $fpath)
autoload -Uz compinit && compinit

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/kthatoto/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/kthatoto/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/kthatoto/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/kthatoto/google-cloud-sdk/completion.zsh.inc'; fi

_git_br() {
  branches=(${(f)"$(git branch --format='%(refname:short)')"})
  compadd "${branches[@]}"
}

export PATH="$PATH:$HOME/.bun/bin"
