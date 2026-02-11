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
      worktree_color[$wt_branch]="37;48;5;19"  # 濃い青背景に白文字
    fi
  fi
done <<< "$worktree_info"

local count_length_max=0
local branch_length_max=0
local worktree_length_max=0
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

  # Track max worktree name length
  if [[ -n "${worktree_map[$line]}" ]]; then
    local wt_len=$((${#worktree_map[$line]} + 3))  # +3 for " []"
    if [[ $worktree_length_max -lt $wt_len ]]; then
      worktree_length_max=$wt_len
    fi
  fi
done

# Build sorted list with descriptions for grouping
typeset -A branch_descriptions
typeset -A branch_groups
for branch in "${branches[@]}"; do
  local desc=$(git config branch."$branch".description 2>/dev/null)
  branch_descriptions[$branch]="$desc"
  # Group by removing last -segment (tp01-04 -> tp01)
  if [[ "$desc" == *-* ]]; then
    branch_groups[$branch]="${desc%-*}"
  else
    branch_groups[$branch]="$desc"
  fi
done

local sorted_branches=($(for branch in "${branches[@]}"; do
  local group="${branch_groups[$branch]}"
  local desc="${branch_descriptions[$branch]}"
  echo "$group	$desc	$branch"
done | sort | cut -f3))

# Check if develop branch exists
local develop_exists=$(git rev-parse --verify --quiet develop 2>/dev/null && echo "yes")

local prev_group=""
for line in "${sorted_branches[@]}"; do
  local group="${branch_groups[$line]}"

  # Group header when group changes
  if [[ "$group" != "$prev_group" && -n "$group" ]]; then
    echo "\e[33m── $group ──\e[0m"
    prev_group="$group"
  elif [[ "$group" != "$prev_group" ]]; then
    prev_group="$group"
  fi

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

  # Dot indicator based on develop status
  if [[ -n "$develop_exists" ]]; then
    if [ $line = "develop" ]; then
      echo -n "  "
    else
      # Check commits ahead of develop (branch's own commits)
      local commits_ahead=$(git rev-list --count develop..$line 2>/dev/null)
      commits_ahead=${commits_ahead:-0}
      # Check commits behind develop (develop has new commits)
      local commits_behind=$(git rev-list --count $line..develop 2>/dev/null)
      commits_behind=${commits_behind:-0}

      if [[ $commits_ahead -eq 0 ]]; then
        # Blue: no own commits yet (just created from develop)
        echo -n "\e[34m•\e[0m "
      elif git merge-base --is-ancestor $line develop 2>/dev/null; then
        # Green: merged to develop (has commits but they're in develop)
        echo -n "\e[32m•\e[0m "
      elif [[ $commits_behind -gt 0 ]]; then
        # Red: develop has commits not in this branch
        echo -n "\e[31m•\e[0m "
      else
        # No dot: up to date with develop, has own commits, not merged
        echo -n "  "
      fi
    fi
  else
    echo -n "  "
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
  local wt_display_len=0
  if [[ -n "${worktree_map[$line]}" ]]; then
    local color="${worktree_color[$line]}"
    echo -n " \e[${color}m[${worktree_map[$line]}]\e[0m"
    wt_display_len=$((${#worktree_map[$line]} + 3))
  fi
  # Pad to align descriptions
  for i in $(seq $wt_display_len $((worktree_length_max - 1))); do
    echo -n " "
  done

  # Show description
  local desc="${branch_descriptions[$line]}"
  if [[ -n "$desc" ]]; then
    echo " $desc"
  else
    echo ""
  fi
done
