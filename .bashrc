function _get_weekday() {
  weekdays=(Sun Mon Tue Wed Thu Fri Sat)
  echo ${weekdays[`date +%w`]}
}

PS1="\[\033[34m\]\D{%m-%d}($(_get_weekday))\[\033[33m\]:\D{%H:%M:%S}\[\033[35m\]:\w\n\[\033[0m\]\$ "

export HISTSIZE=2000
export HISTCONTROL=ignoredups
export HISTIGNORE="cd *:ls:jj*:ls *:vi *:git push:git st:git add *"
