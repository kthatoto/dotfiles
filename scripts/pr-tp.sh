#!/bin/bash

local branches=($(git branch --format='%(refname:short)'))
local current_branch=$(git branch --contains | awk '{print $2}')
local sorted_branches=($(for branch in "${branches[@]}"; do
  description=$(git config branch."$branch".description 2>/dev/null)
  if [[ -n "$description" ]]; then
    echo "$description $branch"
  fi
done | sort | awk '{print $NF}'))

local prev_branch=""
for i in "${!sorted_branches[@]}"; do
  if [[ "${sorted_branches[$i]}" == "$current_branch" ]]; then
    prev_branch="${sorted_branches[$((i - 1))]}"
    break
  fi
done

if [[ -z "$prev_branch" ]]; then
  echo "No previous branch found."
  return 1
fi

local current_desc=$(git config branch."$current_branch".description)
local prev_desc=$(git config branch."$prev_branch".description)

local GREEN='\033[1;32m'
local CYAN='\033[1;36m'
local RESET='\033[0m'

echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━"
echo -e "      🔍 ${GREEN}PR Preview${CYAN}"
echo -e "━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}${current_branch}${RESET}: $current_desc"
echo -e "↓"
echo -e "${GREEN}${prev_branch}${RESET}: $prev_desc"
echo
echo -n "Proceed with PR? [y/N]: "
read -r confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Canceled"
  return 1
fi

if [[ "$current_branch" =~ _([0-9]+)_ ]]; then
  local issue_number="${match[1]}"
else
  echo "Failed to extract issue number from branch name: $current_branch"
  return 1
fi

local issue_title
if ! issue_title=$(gh issue view "$issue_number" --json title -q .title 2>/dev/null); then
  echo "Failed to retrieve issue title for issue #$issue_number"
  return 1
fi

local cleaned_title=$(echo "$issue_title" | sed -E 's/^\[[^]]+\] *//')
local pr_title="[TP#${issue_number}] ${cleaned_title}"

echo "Creating pull request..."
gh pr create \
  --base "$prev_branch" \
  --head "$current_branch" \
  --title "$pr_title" \
  --body - <<EOF
Deploy Info
---------------------

$pr_title

Affected Users
---------------------

- [ ] 一般ユーザーへの外部仕様面での変更あり
- [ ] システム管理者のみ外部仕様面での変更あり
- [x] 外部仕様面での変更なし

Issue link or Description
--------------------------
issue: #$issue_number

PdM check Status
-----------------

- [ ] Checked by PdM

Staging test Status
--------------------

- [ ] Checked on Staging

Screenshot / GIF
----------------
EOF
