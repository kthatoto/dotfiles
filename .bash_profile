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
alias pwdp='pwd | pbcopy'
alias cdp='cd $(pbpaste)'

export PATH=${HOME}/bin:${PATH}

export PATH=${HOME}/.rbenv/bin:${PATH}
eval "$(rbenv init -)"

export PATH=$HOME/.nodebrew/current/bin:$PATH
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

if [ -x "`which go`" ]; then
  export GOROOT=`go env GOROOT`
  export GOPATH=$HOME/code/go-local
  export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
fi
