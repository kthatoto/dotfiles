# OPENSPEC:START
# OpenSpec shell completions configuration
fpath=("/Users/kthatoto/.zsh/completions" $fpath)
autoload -Uz compinit
compinit
# OPENSPEC:END

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

dc() {
  local profile="core-backend"
  if ! docker compose ps --format '{{.Names}}' 2>/dev/null | grep -q 'app'; then
    profile="core-backend-test"
  fi
  bin/compose --profile "$profile" "$@"
}

db() { dc build "$@"; }
du() {
  local profile="core-backend"
  local dir_name=$(basename "$(pwd)")
  if [[ "$dir_name" =~ -[a-j]$ ]]; then
    profile="core-backend-test"
  fi
  bin/compose --profile "$profile" up -d "$@"
}
de() { dc exec "$@"; }
dr() { dc run "$@"; }
drs() { dc restart "$@"; }
dl() { dc logs -f --tail=100 "$@"; }
dd() { dc down "$@"; }

alias be='bundle exec'
alias brew-tree="brew deps --tree --installed"
alias ww='cd $(ghq root)/$(ghq list | peco)'
alias gg='git grep --heading'
alias rails='de spring rails'
alias format='pnpm format'
alias tree='tree -a -I "\.DS_Store|\.git|node_modules|vendor\/bundle" -N'
alias cop='rubocop-only-changed'
alias rspec='rspec-fzf'
alias rp='rspec-only-changed'
alias rss='rspec-select'
alias rpss='rspec-select-interactive'
alias cov-tp='de -e COVERAGE_TP=true spring bundle exec rspec packs/tp/spec; open coverage/index.html'
alias c='claude'
alias cc='claude --continue'
alias cdr='claude --dangerously-skip-permissions'
alias ccdr='claude --continue --dangerously-skip-permissions'
alias pp='pnpm'
alias label-deploy-peach='make label-deploy/stg-peach'
alias label-deploy-apple='make label-deploy/stg-apple'

source ~/dotfiles/scripts/update-types.sh
alias pr-tp="~/dotfiles/scripts/pr-tp.sh"

wt() {
  ~/dotfiles/scripts/worktree-sync "$@"
}
_wt() {
  local -a branches
  branches=(${(f)"$(git branch --format='%(refname:short)' 2>/dev/null)"})
  _describe -t branches 'branch' branches
}
compdef _wt wt

wr() {
  local name="$1"
  [[ -z "$name" ]] && { echo "Usage: wr <worktree-dir-name>"; return 1; }

  local git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || { echo "Not in a git repo"; return 1; }
  [[ -z "$git_common_dir" ]] && { echo "Not in a git repo"; return 1; }
  local original_repo=$(dirname "$git_common_dir")
  local parent_dir=$(dirname "$original_repo")
  local worktree_path="$parent_dir/$name"

  [[ ! -d "$worktree_path" ]] && { echo "Worktree not found: $worktree_path"; return 1; }

  echo "Stopping Docker in $name..."
  (cd "$worktree_path" && bin/compose --profile core-backend-test down 2>/dev/null) || true

  echo "Removing worktree $name..."
  git worktree remove "$worktree_path"
}
_wr() {
  local git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return
  [[ -z "$git_common_dir" ]] && return
  local original_repo=$(dirname "$git_common_dir")
  local base_name=${original_repo:t}

  local -a worktrees
  worktrees=(${(f)"$(git worktree list --porcelain 2>/dev/null | grep '^worktree ' | sed 's/^worktree //' | xargs -I{} basename {} | grep -v "^${base_name}$")"})
  _describe -t worktrees 'worktree' worktrees
}
compdef _wr wr

ch() {
  local force=false
  if [[ "$1" == "-f" ]]; then
    force=true
  fi

  local current_branch=$(git branch --show-current)
  local current_worktree=$(basename "$(pwd)")
  local header_info="[$current_worktree] $current_branch"

  local selected=$(git-br-list | fzf \
    --ansi \
    --layout=reverse \
    --bind='j:down,k:up' \
    --header="$header_info | j/k: move | ENTER: select")

  [[ -z "$selected" ]] && return

  # Skip group headers
  if [[ "$selected" =~ ^.*──.*──.*$ ]]; then
    echo "Group header selected, please select a branch."
    return
  fi

  local branch=$(echo "$selected" | sed 's/\x1b\[[0-9;]*m//g' | awk '{
    for (i=1; i<=NF; i++) {
      if ($i != "" && $i != "*" && $i != "•") {
        print $i
        exit
      }
    }
  }')
  [[ -z "$branch" ]] && return

  local worktree_path=$(git worktree list | grep "\[$branch\]" | awk "{print \$1}")

  if [[ "$force" == true ]]; then
    if [[ -n "$worktree_path" ]]; then
      if [[ -n "$(git -C "$worktree_path" status --porcelain)" ]]; then
        echo "Uncommitted changes exist in worktree: $worktree_path"
        return 1
      fi
      git -C "$worktree_path" checkout --detach
    fi
    git switch "$branch"
    return
  fi

  if [[ -n "$worktree_path" && "$worktree_path" != "$(pwd)" ]]; then
    if [[ -n "$(git status --porcelain)" ]]; then
      echo "Uncommitted changes exist. Use 'ch -f' to force switch."
      return 1
    fi
    cd "$worktree_path"
  else
    git switch "$branch"
  fi
}

rubocop-only-changed() {
  git diff --name-only --diff-filter=d develop | grep "\.rb$"
  echo
  docker compose exec -T spring rubocop --color $(git diff --name-only --diff-filter=d develop | grep "\.rb$") "$@"
}
rspec-fzf() {
  local file="$1"
  if [[ -n "$file" ]]; then
    de spring bundle exec rspec "$file"
    return
  fi
  local selected=$(find spec packs/tp/spec -type f 2>/dev/null | fzf --layout=reverse-list)
  if [[ -z "$selected" ]]; then
    echo "No selection made."
    return 1
  fi
  echo "rspec $selected"
  de spring bundle exec rspec "$selected"
}
rspec-only-changed() {
  git diff --name-only --diff-filter=d develop | grep "_spec\.rb$"
  echo
  docker compose exec -T spring bash -c "RUBYOPT='-W0' bundle exec rspec --color --tty $(git diff --name-only --diff-filter=d develop | grep '_spec\.rb$' | tr '\n' ' ')"
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
    docker compose exec -T spring bash -c "RUBYOPT='-W0' bundle exec rspec --color --tty $file"
    return
  fi

  local line_number
  line_number=$(echo "$selected" | cut -d: -f1)
  echo $file:$line_number
  echo $selected
  docker compose exec -T spring bash -c "RUBYOPT='-W0' bundle exec rspec --color --tty $file:$line_number"
}
rspec-select-interactive() {
  rspec-select $(find spec packs/tp/spec -type f 2>/dev/null | fzf --layout=reverse-list)
}

git-br-list() {
  local branches=($(git branch --format='%(refname:short)'))
  local current_branch=$(git branch --show-current)

  # Get worktree information
  typeset -A worktree_map
  typeset -A worktree_color
  local worktree_info=$(git worktree list --porcelain 2>/dev/null)
  local wt_path=""
  while IFS= read -r wt_line; do
    if [[ "$wt_line" =~ ^worktree\ (.+)$ ]]; then
      wt_path="${match[1]}"
    elif [[ "$wt_line" =~ ^branch\ refs/heads/(.+)$ ]]; then
      local wt_branch="${match[1]}"
      local wt_name="${wt_path##*/}"
      worktree_map[$wt_branch]="$wt_name"
      local wt_colors=(31 34 33 32 35 36 91 94 93 92 95 96)
      if [[ "$wt_name" =~ -([a-z])$ ]]; then
        local suffix="${match[1]}"
        local idx=$(( $(printf '%d' "'$suffix") - 96 ))
        worktree_color[$wt_branch]="${wt_colors[$idx]}"
      else
        worktree_color[$wt_branch]="37"
      fi
    fi
  done <<< "$worktree_info"

  # Check if develop branch exists
  local develop_exists=$(git rev-parse --verify --quiet develop 2>/dev/null && echo "yes")

  # Get branches merged to develop
  typeset -A merged_to_develop
  if [[ -n "$develop_exists" ]]; then
    for b in $(git branch --merged develop 2>/dev/null | sed 's/^[* ]*//'); do
      merged_to_develop[$b]="yes"
    done
  fi

  # Pre-calculate all data
  typeset -A branch_descriptions
  typeset -A branch_groups
  typeset -A commits_behind_map
  typeset -A is_merged_map

  local branch_length_max=0
  local worktree_length_max=0

  for branch in "${branches[@]}"; do
    local desc=$(git config branch."$branch".description 2>/dev/null)
    branch_descriptions[$branch]="$desc"
    if [[ "$desc" == *-* ]]; then
      branch_groups[$branch]="${desc%-*}"
    else
      branch_groups[$branch]="$desc"
    fi

    [[ $branch_length_max -lt ${#branch} ]] && branch_length_max=${#branch}

    if [[ -n "${worktree_map[$branch]}" ]]; then
      local wt_len=$((${#worktree_map[$branch]} + 3))
      [[ $worktree_length_max -lt $wt_len ]] && worktree_length_max=$wt_len
    fi

    if [[ -n "$develop_exists" && "$branch" != "develop" ]]; then
      local behind=$(git rev-list --count $branch..develop 2>/dev/null)
      commits_behind_map[$branch]="$behind"
      local merge_base=$(git merge-base $branch develop 2>/dev/null)
      local branch_head=$(git rev-parse $branch 2>/dev/null)
      if [[ "$merge_base" == "$branch_head" ]]; then
        # developのライン上にいる
        if git reflog show $branch 2>/dev/null | grep -q "commit:"; then
          # 過去にコミットしてマージ済み = 緑
          is_merged_map[$branch]="merged"
        else
          # コミットしたことがない = 青
          is_merged_map[$branch]="new"
        fi
      elif [[ -n "${merged_to_develop[$branch]}" ]]; then
        # 独自コミットがあり、developにマージ済み = 緑
        is_merged_map[$branch]="merged"
      fi
    fi
  done

  local sorted_branches=($(for branch in "${branches[@]}"; do
    echo "${branch_groups[$branch]}	${branch_descriptions[$branch]}	$branch"
  done | sort | cut -f3))

  local prev_group=""
  for line in "${sorted_branches[@]}"; do
    local group="${branch_groups[$line]}"

    # Group header
    if [[ "$group" != "$prev_group" && -n "$group" ]]; then
      echo "\e[33m── $group ──\e[0m"
      prev_group="$group"
    elif [[ "$group" != "$prev_group" ]]; then
      prev_group="$group"
    fi

    if [[ $line == $current_branch ]]; then
      echo -n "* "
    else
      echo -n "  "
    fi

    # Dot indicator
    if [[ -n "$develop_exists" ]]; then
      if [ $line = "develop" ]; then
        echo -n "  "
      else
        local merge_status="${is_merged_map[$line]}"
        local commits_behind="${commits_behind_map[$line]:-0}"
        if [[ "$merge_status" == "merged" ]]; then
          echo -n "\e[32m•\e[0m "
        elif [[ "$merge_status" == "new" ]]; then
          echo -n "\e[34m•\e[0m "
        elif [[ $commits_behind -gt 0 ]]; then
          echo -n "\e[31m•\e[0m "
        else
          echo -n "  "
        fi
      fi
    else
      echo -n "  "
    fi

    echo -n $line

    local branch_pad=$((branch_length_max - ${#line} + 1))
    printf "%${branch_pad}s" ""

    # Show worktree indicator
    local wt_display_len=0
    if [[ -n "${worktree_map[$line]}" ]]; then
      local color="${worktree_color[$line]}"
      echo -n " \e[${color}m[${worktree_map[$line]}]\e[0m"
      wt_display_len=$((${#worktree_map[$line]} + 3))
    fi

    local wt_pad=$((worktree_length_max - wt_display_len))
    [[ $wt_pad -gt 0 ]] && printf "%${wt_pad}s" ""

    local desc="${branch_descriptions[$line]}"
    if [[ -n "$desc" ]]; then
      echo " $desc"
    else
      echo ""
    fi
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

export GOROOT="$(asdf where golang)/go"
export GOPATH="$HOME/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/kthatoto/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/kthatoto/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/kthatoto/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/kthatoto/google-cloud-sdk/completion.zsh.inc'; fi

_git-br() { _git-branch "$@" }

export PATH="$PATH:$HOME/.bun/bin"
export PATH="$PATH":"$HOME/.pub-cache/bin"

source ~/completion-for-pnpm.bash

# bun completions
[ -s "/Users/kthatoto/.bun/_bun" ] && source "/Users/kthatoto/.bun/_bun"

source "$HOME/dotfiles/scripts/terminal-bg/main.sh"
