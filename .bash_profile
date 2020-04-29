if [ -f ~/.bashrc ]; then
source ~/.bashrc
fi

alias cdd='cd ~/Desktop'
alias jj='cd ..'
alias jjj='cd ../..'
alias jjjj='cd ../../..'
alias o='open .'
alias ls='ls -alG'
alias search-find='find . -type f -print | xargs grep'
alias vi='nvim'
alias docker-prune='docker system prune -f'
alias de='docker-compose exec'
alias dr='docker-compose run'
alias drs='docker-compose restart'
alias dl='docker-compose logs -f --tail=100'
alias be='bundle exec'
alias pwdp='pwd | pbcopy'
alias cdp='cd $(pbpaste)'
alias postgresql='postgres -D /usr/local/var/postgres'

################## often use directory shortcut ######################
declare -a directories=(
  "Desktop/projects/browser-mario"
  "Desktop/projects/base-frontend"
  "Desktop/projects/base-api"
  "Desktop/projects/routee-frontend"
  "Desktop/projects/routee-api"
  "Desktop/projects/hatoto"
  "Desktop/projects/mokumoku-online"
  ""
)
directories_line=""
for directory in "${directories[@]}"; do
  directories_line="${directories_line}\n${directory}"
done
alias ww='cd "$(echo $HOME)$(echo -e \"$directories_line\" | peco)"'
######################################################################

peco-history-exec() {
  local l=$(HISTTIMEFORMAT= history | sort -k1,1nr | perl -ne 'BEGIN { my @lines = (); } s/^\s*\d+\s*//; $in=$_; if (!(grep {$in eq $_} @lines)) { push(@lines, $in); print $in; }' | peco --query "$READLINE_LINE")
  READLINE_LINE="$l"
  READLINE_POINT=${#l}
  if [ -n "$l" ] ; then
    history -s $l
    if type osascript > /dev/null 2>&1 ; then
      (osascript -e 'tell application "System Events" to keystroke (ASCII character 30)' &)
    fi
  else
    history -d $((HISTCMD-1))
  fi
}
bind -x '"\C-r": peco-history-exec'

export PATH=${HOME}/bin:${PATH}

eval "$(anyenv init -)"
export PATH=${HOME}/.rbenv/bin:${PATH}
eval "$(rbenv init -)"

if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

if [ -x "`which go`" ]; then
  export GOROOT=`go env GOROOT`
  export GOPATH=$HOME/go
  export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
fi

source ~/.git-completion.bash
