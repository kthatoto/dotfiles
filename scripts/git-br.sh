#!/bin/zsh

if [ $# -ne 0 ]; then
  git branch $@
  return
fi

# Show loading spinner
local spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
local spin_idx=0
spin() {
  printf "\r${spinner[$((spin_idx % 10 + 1))]}"
  spin_idx=$((spin_idx + 1))
}
spin

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
      worktree_color[$wt_branch]="37;48;5;19"
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

# Pre-calculate all data in one pass
typeset -A branch_descriptions
typeset -A branch_groups
typeset -A origin_counts
typeset -A commits_ahead_map
typeset -A commits_behind_map
typeset -A is_merged_map

local count_length_max=0
local branch_length_max=0
local worktree_length_max=0

for branch in "${branches[@]}"; do
  spin

  # Description
  local desc=$(git config branch."$branch".description 2>/dev/null)
  branch_descriptions[$branch]="$desc"
  if [[ "$desc" == *-* ]]; then
    branch_groups[$branch]="${desc%-*}"
  else
    branch_groups[$branch]="$desc"
  fi

  # Origin count
  if git rev-parse --verify --quiet origin/$branch > /dev/null 2>&1; then
    local cnt=$(git rev-list --count origin/$branch..$branch)
    origin_counts[$branch]="$cnt"
    local count_length=$((${#cnt} + 2))
    [[ $count_length_max -lt $count_length ]] && count_length_max=$count_length
  fi

  # Branch name length
  [[ $branch_length_max -lt ${#branch} ]] && branch_length_max=${#branch}

  # Worktree length
  if [[ -n "${worktree_map[$branch]}" ]]; then
    local wt_len=$((${#worktree_map[$branch]} + 3))
    [[ $worktree_length_max -lt $wt_len ]] && worktree_length_max=$wt_len
  fi

  # Develop comparison
  if [[ -n "$develop_exists" && "$branch" != "develop" ]]; then
    local behind=$(git rev-list --count $branch..develop 2>/dev/null)
    commits_behind_map[$branch]="$behind"
    local merge_base=$(git merge-base $branch develop 2>/dev/null)
    local branch_head=$(git rev-parse $branch 2>/dev/null)
    if [[ "$merge_base" == "$branch_head" ]]; then
      if [[ "$behind" -gt 0 ]]; then
        # マージ済み（squash merge後developが進んだ）
        is_merged_map[$branch]="merged"
      else
        # 作ったばかり（独自コミットなし）
        is_merged_map[$branch]="new"
      fi
    elif [[ -n "${merged_to_develop[$branch]}" ]]; then
      # マージ済み
      is_merged_map[$branch]="merged"
    fi
  fi
done

# Clear loading spinner
printf "\r\033[K"

# Sort branches
local sorted_branches=($(for branch in "${branches[@]}"; do
  echo "${branch_groups[$branch]}	${branch_descriptions[$branch]}	$branch"
done | sort | cut -f3))

# Build output buffer
local output=""
local prev_group=""

for line in "${sorted_branches[@]}"; do
  local group="${branch_groups[$line]}"

  # Group header
  if [[ "$group" != "$prev_group" && -n "$group" ]]; then
    output+="\e[33m── $group ──\e[0m\n"
    prev_group="$group"
  elif [[ "$group" != "$prev_group" ]]; then
    prev_group="$group"
  fi

  # Current branch marker
  if [[ $line == $current_branch ]]; then
    output+="*"
  else
    output+=" "
  fi

  # Origin count - total width = count_length_max + 1 (for space after])
  local count="${origin_counts[$line]}"
  local total_width=$((count_length_max + 1))
  [[ $total_width -lt 4 ]] && total_width=4

  if [ $line = "develop" ]; then
    local str="[0]"
    local pad=$((total_width - 3))
    output+="\e[30m${str}\e[0m$(printf "%${pad}s" "")"
  elif [[ -n "$count" ]]; then
    local str="[$count]"
    local pad=$((total_width - ${#str}))
    if [[ $count -eq 0 ]]; then
      output+="${str}$(printf "%${pad}s" "")"
    else
      output+="\e[31m${str}\e[0m$(printf "%${pad}s" "")"
    fi
  else
    output+="$(printf "%${total_width}s" "")"
  fi

  # Dot indicator
  if [[ -n "$develop_exists" ]]; then
    if [ $line = "develop" ]; then
      output+="  "
    else
      local merge_status="${is_merged_map[$line]}"
      local commits_behind="${commits_behind_map[$line]:-0}"

      if [[ "$merge_status" == "merged" ]]; then
        output+="\e[32m•\e[0m "
      elif [[ "$merge_status" == "new" ]]; then
        output+="\e[34m•\e[0m "
      elif [[ $commits_behind -gt 0 ]]; then
        output+="\e[31m•\e[0m "
      else
        output+="  "
      fi
    fi
  else
    output+="  "
  fi

  # Branch name
  if [[ $line == $current_branch ]]; then
    output+="\e[32m$line\e[0m"
  else
    output+="$line"
  fi

  # Branch name padding
  local branch_pad=$((branch_length_max - ${#line} + 1))
  output+="$(printf "%${branch_pad}s" "")"

  # Worktree indicator
  local wt_display_len=0
  if [[ -n "${worktree_map[$line]}" ]]; then
    local color="${worktree_color[$line]}"
    output+=" \e[${color}m[${worktree_map[$line]}]\e[0m"
    wt_display_len=$((${#worktree_map[$line]} + 3))
  fi

  # Worktree padding
  local wt_pad=$((worktree_length_max - wt_display_len))
  [[ $wt_pad -gt 0 ]] && output+="$(printf "%${wt_pad}s" "")"

  # Description
  local desc="${branch_descriptions[$line]}"
  if [[ -n "$desc" ]]; then
    output+=" $desc"
  fi
  output+="\n"
done

# Output all at once
echo -n "$output"
