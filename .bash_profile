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
alias bungu='cd ~/Desktop/bungu'
alias pwdp='pwd | pbcopy'
alias cdp='cd $(pbpaste)'
alias postgresql='postgres -D /usr/local/var/postgres'

alias api='cd /Users/tk1to/Desktop/sorahune/sorahune-api'
alias front='cd /Users/tk1to/Desktop/sorahune/sorahune-front'
alias raku='cd /Users/tk1to/Desktop/xbit/rakushifu'

export PATH=${HOME}/bin:${PATH}

export PATH=${HOME}/.rbenv/bin:${PATH}
eval "$(rbenv init -)"

export PATH=$HOME/.nodebrew/current/bin:$PATH
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/tk1to/google-cloud-sdk/path.bash.inc' ]; then source '/Users/tk1to/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/tk1to/google-cloud-sdk/completion.bash.inc' ]; then source '/Users/tk1to/google-cloud-sdk/completion.bash.inc'; fi

if [ -x "`which go`" ]; then
  export GOROOT=`go env GOROOT`
  export GOPATH=$HOME/go
  export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
fi

export DB_DATABASE=torb
export DB_HOST=127.0.0.1
export DB_PORT=3306
export DB_USER=isucon
export DB_PASS=isucon

source ~/.git-completion.bash
