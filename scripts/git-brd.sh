#!/bin/zsh

# git-brd: Interactive branch deletion with fzf

# Check if fzf is available
if ! command -v fzf &> /dev/null; then
  echo "fzf is required but not installed."
  exit 1
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

# Build branch list with formatting (same as git-br.sh)
build_branch_line() {
  local line=$1
  local output=""

  if [[ $line == $current_branch ]]; then
    output+="*"
  else
    output+=" "
  fi

  local count=0
  local count_length=0
  if git rev-parse --verify --quiet origin/$line > /dev/null; then
    count=$(git rev-list --count origin/$line..$line)
    count_length=$((${#count} + 2))
  fi
  for i in $(seq $((${#count} + 2)) $count_length_max); do
    output+=" "
  done
  if [ $line = "develop" ]; then
    output+="\e[30m[0]\e[0m "
  elif [[ $count_length -gt 0 ]]; then
    if [[ $count -eq 0 ]]; then
      output+="[$count] "
    else
      output+="\e[31m[$count]\e[0m "
    fi
  else
    output+="    "
  fi

  if [[ -n "$develop_not_merged_exists" ]]; then
    local merged_to_develop=$(git branch --contains $line | awk '{print $1}' | grep '^develop$')
    local develop_merged=$(git branch --merged $line | awk '{print $1}' | grep '^develop$')
    if [ $line = "develop" ]; then
      output+="  "
    elif [[ -n "$merged_to_develop" ]]; then
      output+="\e[32m•\e[0m "
    elif [[ -z "$develop_merged" ]]; then
      output+="\e[31m•\e[0m "
    else
      output+="  "
    fi
  fi

  if [[ $line == $current_branch ]]; then
    output+="\e[32m$line\e[0m"
  else
    output+="$line"
  fi

  for i in $(seq $((${#line} - 1)) $branch_length_max); do
    output+=" "
  done

  if [[ -n "${worktree_map[$line]}" ]]; then
    local color="${worktree_color[$line]}"
    output+=" \e[${color}m[${worktree_map[$line]}]\e[0m "
  fi

  output+="$(git config branch.$line.description)"
  echo -e "$output"
}

# Generate fzf input (same order as git br)
local fzf_input=""
for line in "${sorted_branches[@]}"; do
  fzf_input+="$(build_branch_line $line)\n"
done

if [[ -z "$fzf_input" ]]; then
  echo "No branches available."
  exit 0
fi

# Run fzf for multi-select
# - reverse layout (top)
# - j/k for navigation
# - enter to toggle selection
# - ctrl-d to proceed to deletion
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

# Show selected branches and confirm (git br style)
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
