# macOS setup

## Register ssh-key to github.com
```
$ chsh -s /bin/zsh
$ xcode-select --install
$ ssh-keygen -t rsa
$ cat ~/.ssh/id_rsa.pub | pbcopy
// register the ssh-key to github.com
```

## Use setup scripts in dotfiles
```
$ git clone git@github.com:kthatoto/dotfiles.git
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
$ brew bundle --file ~/dotfiles/assets/Brewfile
```

## Symblic links
```
$ ln -s ~/dotfiles/.zshrc     ~/.zshrc
$ ln -s ~/dotfiles/.zsh       ~/.zsh
$ ln -s ~/dotfiles/.config    ~/.config
$ ln -s ~/dotfiles/.gitconfig ~/.gitconfig
```

## Install langs
```
$ anyenv install --init
$ anyenv install goenv
$ anyenv install nodenv
$ anyenv install rbenv
$ anyenv install pyenv
```

## Configure applications
* iTerm2
  * Profiles > Colors
    * Import `~/dotfiles/assets/hybrid.itermcolors` into "Color Presets" and select it
    * Set `#3e65b3` to "Selection"
* Neovim
```
$ cd ~/dotfiles/.config/nvim/dein
$ ./dein_installer.sh .
$ pyenv install <version>
$ pyenv global <version>
$ pip install neovim // for denite.vim
$ vi
:call dein#update()
:UpdateRemotePlugins

:CocInstall coc-tsserver
:CocInstall coc-json
:CocInstall coc-pairs
:CocInstall coc-solargraph

$ rbenv install <version>
$ rbenv global <version>
$ sudo gem install solargraph
```

## gcloud
```
$ curl https://sdk.cloud.google.com | zsh
```

## etc
```
// to display dotfiles on finder
command + shift + .
```
