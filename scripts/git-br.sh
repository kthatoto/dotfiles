#!/bin/zsh

if [ $# -ne 0 ]; then
  git branch $@
  return
fi

local max=0
for line in $(git branch); do
  if [[ $line != "*" ]]; then
    if [[ $max -lt ${#line} ]]; then
      max=${#line}
    fi
  fi
done

current_branch=$(git branch | grep \* | cut -d ' ' -f2)
for line in $(git branch); do
  if [[ $line == "*" ]]; then
    continue
  else
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
    description=$(git config branch.$line.description)
    echo "$description"
  fi
done
