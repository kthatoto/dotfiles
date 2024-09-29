#!/bin/zsh

if [ $# -ne 0 ]; then
  git branch $@
  return
fi

local branches=($(git branch --format='%(refname:short)'))
local current_branch=$(git branch --contains | awk '{print $2}')

local max=0
for line in "${branches[@]}"; do
  if [[ $max -lt ${#line} ]]; then
    max=${#line}
  fi
done

local sorted_branches=($(for branch in "${branches[@]}"; do
  local description=$(git config branch."$branch".description 2>/dev/null)
  echo "$description $branch"
done | sort | awk '{print $NF}'))

for line in "${sorted_branches[@]}"; do
  if [[ $line == $current_branch ]]; then
    echo -n "* "
    echo -n "\e[32m$line\e[0m"
  else
    echo -n "  "
    echo -n $line
  fi
  for i in $(seq $((${#line} - 1)) $max); do
    echo -n " "
  done
  echo $(git config branch.$line.description)
done
