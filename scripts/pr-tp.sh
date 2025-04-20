#!/usr/bin/env bash

set -euo pipefail

pr-tp() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not inside a Git repository."
    return 1
  fi

  local branches=($(git branch --format='%(refname:short)'))
  local current_branch=$(git branch --show-current)

  local sorted_branches=($(for branch in "${branches[@]}"; do
    description=$(git config branch."$branch".description 2>/dev/null)
    if [[ -n "$description" ]]; then
      echo "$description $branch"
    fi
  done | sort | awk '{print $NF}'))

  local prev_branch=""
  for i in "${!sorted_branches[@]}"; do
    if [[ "${sorted_branches[$i]}" == "$current_branch" ]]; then
      if (( i == 0 )); then break; fi
      prev_branch="${sorted_branches[$((i - 1))]}"
      break
    fi
  done

  if [[ -z "$prev_branch" ]]; then
    prev_branch="develop"
  fi

  local current_desc=$(git config branch."$current_branch".description)
  local prev_desc=$(git config branch."$prev_branch".description)

  if [[ "$current_branch" =~ _([0-9]+)_ ]]; then
    local issue_number="${BASH_REMATCH[1]}"
  else
    echo "Failed to extract issue number from branch name: $current_branch"
    return 1
  fi

  local issue_title
  if ! issue_title=$(gh issue view "$issue_number" --json title -q .title 2>/dev/null); then
    echo "Failed to retrieve issue title for issue #$issue_number"
    return 1
  fi

  local cleaned_title
  cleaned_title=$(echo "$issue_title" | sed -E 's/^\[[^]]+\] *//')
  local pr_title="[TP#${issue_number}] ${cleaned_title}"

  local GREEN='\033[1;32m'
  local CYAN='\033[1;36m'
  local MAGENTA='\033[1;35m'
  local RESET='\033[0m'

  echo
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "      PR Preview"
  echo -e "━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${GREEN}${current_branch}${RESET}: $current_desc"
  echo -e "↓"
  echo -e "${GREEN}${prev_branch}${RESET}: $prev_desc"
  echo
  echo -e "${CYAN}PR Title:${RESET} ${MAGENTA}${pr_title} (${current_desc})${RESET}"
  echo

  echo -n "Proceed with PR? [Y/n]: "
  read -r confirm
  if [[ "$confirm" =~ ^[nN]$ ]]; then
    echo "PR creation cancelled."
    return 1
  fi

  echo "Creating pull request..."
  local work_dir=/tmp/pr-tp/$(date +"%Y-%m-%d_%H%M%S")
  local pr_body=$work_dir/pr_body.txt
  mkdir -p $work_dir

  cat <<EOS >> $pr_body
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
EOS

  pr_url=$(gh pr create --base "$prev_branch" --head "$current_branch" --title "$pr_title ($current_desc)" --body "$(cat ${pr_body})" --assignee "@me")

  echo
  echo -e "${GREEN}✨ Pull request created successfully! ✨${RESET}"
  echo -n "Open pull request in browser? [Y/n]: "
  read -r open_confirm
  if [[ "$open_confirm" =~ ^[nN]$ ]]; then
    echo "Not opening browser."
  else
    open "$pr_url"
  fi
  rm -rf $work_dir
}

rm -rf /tmp/pr-tp
pr-tp
