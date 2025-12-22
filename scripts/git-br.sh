#!/bin/zsh

if [ $# -ne 0 ]; then
  git branch $@
  return
fi

local branches=($(git branch --format='%(refname:short)'))
local current_branch=$(git branch --contains | grep '*' | awk '{print $2}')

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
    # 色を決定: -a, -b, -c... → 固定色、それ以外 → 白(37)
    local wt_colors=(31 34 33 32 35 36 91 94 93 92 95 96)  # a b c d e f g h i j k l
    if [[ "$wt_name" =~ -([a-z])$ ]]; then
      local suffix="${match[1]}"
      local idx=$(( $(printf '%d' "'$suffix") - 96 ))  # a=1, b=2, ...
      worktree_color[$wt_branch]="${wt_colors[$idx]}"
    else
      worktree_color[$wt_branch]="37"  # 白
    fi
  fi
done <<< "$worktree_info"

local count_length_max=0
local branch_length_max=0
local develop_not_merged_exists=false
for line in "${branches[@]}"; do
  local count_length=0
  if git rev-parse --verify --quiet origin/$line > /dev/null; then
    local count=$(git rev-list --count origin/$line..$line)
    count_length=$((${#count} + 2))
  fi

  if [[ $count_length_max -lt $count_length ]]; then
    count_length_max=$count_length
  fi

  if [[ $branch_length_max -lt ${#line} ]]; then
    branch_length_max=${#line}
  fi

  local develop_merged=$(git branch --merged $line | awk '{print $1}' | grep '^develop$')
  if [[ -z "$develop_exists" ]]; then
    develop_not_merged_exists=true
  fi
done

local sorted_branches=($(for branch in "${branches[@]}"; do
  local description=$(git config branch."$branch".description 2>/dev/null)
  echo "$description $branch"
done | sort | awk '{print $NF}'))

for line in "${sorted_branches[@]}"; do
  if [[ $line == $current_branch ]]; then
    echo -n "*"
  else
    echo -n " "
  fi

  local count=0
  local count_length=0
  if git rev-parse --verify --quiet origin/$line > /dev/null; then
    count=$(git rev-list --count origin/$line..$line)
    count_length=$((${#count} + 2))
  fi
  for i in $(seq $((${#count} + 2)) $count_length_max); do
    echo -n " "
  done
  if [ $line = "develop" ]; then
    echo -n "\e[30m[0]\e[0m "
  elif [[ $count_length -gt 0 ]]; then
    if [[ $count -eq 0 ]]; then
      echo -n "[$count] "
    else
      echo -n "\e[31m[$count]\e[0m "
    fi
  else
    echo -n "    "
  fi

  if [[ -n "$develop_not_merged_exists" ]]; then
    local merged_to_develop=$(git branch --contains $line | awk '{print $1}' | grep '^develop$')
    local develop_merged=$(git branch --merged $line | awk '{print $1}' | grep '^develop$')
    if [ $line = "develop" ]; then
      echo -n "  "
    elif [[ -n "$merged_to_develop" ]]; then
      echo -n "\e[32m•\e[0m "
    elif [[ -z "$develop_merged" ]]; then
      echo -n "\e[31m•\e[0m "
    else
      echo -n "  "
    fi
  fi

  if [[ $line == $current_branch ]]; then
    echo -n "\e[32m$line\e[0m"
  else
    echo -n $line
  fi

  for i in $(seq $((${#line} - 1)) $branch_length_max); do
    echo -n " "
  done

  # Show worktree indicator if branch is checked out in another worktree
  if [[ -n "${worktree_map[$line]}" ]]; then
    local color="${worktree_color[$line]}"
    echo -n " \e[${color}m[${worktree_map[$line]}]\e[0m "
  fi

  echo $(git config branch.$line.description)
done
