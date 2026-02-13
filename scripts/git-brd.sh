#!/bin/zsh

# git-brd: Interactive branch deletion with fzf

# Check if fzf is available
if ! command -v fzf &> /dev/null; then
  echo "fzf is required but not installed."
  exit 1
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
        is_merged_map[$branch]="merged"
      else
        is_merged_map[$branch]="new"
      fi
    elif [[ -n "${merged_to_develop[$branch]}" ]]; then
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

# Build branch line for display
build_branch_line() {
  local line=$1
  local output=""
  local group="${branch_groups[$line]}"

  # Current branch marker
  if [[ $line == $current_branch ]]; then
    output+="*"
  else
    output+=" "
  fi

  # Origin count
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

  echo -e "$output"
}

# Generate fzf input with group headers
local fzf_input=""
local prev_group=""
for line in "${sorted_branches[@]}"; do
  local group="${branch_groups[$line]}"
  if [[ "$group" != "$prev_group" && -n "$group" ]]; then
    fzf_input+="── $group ──\n"
    prev_group="$group"
  elif [[ "$group" != "$prev_group" ]]; then
    prev_group="$group"
  fi
  fzf_input+="$(build_branch_line $line)\n"
done

if [[ -z "$fzf_input" ]]; then
  echo "No branches available."
  exit 0
fi

# Run fzf for multi-select
local selected=$(echo -e "$fzf_input" | fzf \
  --ansi \
  --multi \
  --layout=reverse \
  --bind='j:down,k:up' \
  --bind='enter:toggle+down' \
  --bind='ctrl-d:accept' \
  --header=$'ENTER: select | Ctrl+D: delete | j/k: move')

if [[ -z "$selected" ]]; then
  echo "No branches selected."
  exit 0
fi

# Extract branch names from selected lines
local selected_branches=()
while IFS= read -r sel_line; do
  # Skip group headers
  if [[ "$sel_line" =~ ^──.*──$ ]]; then
    continue
  fi
  # Remove ANSI codes and extract branch name
  local clean_line=$(echo "$sel_line" | sed 's/\x1b\[[0-9;]*m//g')
  # Parse: skip *, skip [n], skip dot, get first word that looks like a branch
  local branch_name=$(echo "$clean_line" | awk '{
    for (i=1; i<=NF; i++) {
      # Skip empty, *, dots, counts like [0]
      if ($i != "" && $i != "*" && $i !~ /^\[.*\]$/ && $i != "•") {
        print $i
        exit
      }
    }
  }')
  if [[ -n "$branch_name" && "$branch_name" != "$current_branch" ]]; then
    selected_branches+=("$branch_name")
  fi
done <<< "$selected"

if [[ ${#selected_branches[@]} -eq 0 ]]; then
  echo "No deletable branches selected (current branch cannot be deleted)."
  exit 0
fi

# Show selected branches and confirm
echo ""
echo "Branches to delete:"
echo ""
for branch in "${selected_branches[@]}"; do
  build_branch_line "$branch"
done
echo ""

# Confirmation (default yes)
echo -n "Delete these branches? [Y/n]: "
read -r confirm

if [[ -z "$confirm" || "$confirm" =~ ^[Yy]$ ]]; then
  for branch in "${selected_branches[@]}"; do
    echo "Deleting: $branch"
    git branch -d "$branch" 2>&1 || git branch -D "$branch"
  done
  echo "Done."
else
  echo "Cancelled."
fi
