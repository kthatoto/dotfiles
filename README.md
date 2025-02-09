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
$ git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1

$ asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
$ asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
$ asdf plugin add bun
$ asdf plugin add python

$ asdf install ruby latest
$ asdf install nodejs latest
$ asdf install bun 1.0.17
$ asdf install python latest
```

## Configure applications

- iTerm2
  - Profiles > Colors
    - Import `~/dotfiles/assets/hybrid.itermcolors` into "Color Presets" and select it
    - Set `#3e65b3` to "Selection"
- Neovim

```
$ cd ~/dotfiles/.config/nvim/dein
$ ./dein_installer.sh .
$ pip install neovim // for denite.vim
$ vi
:call dein#update()
:UpdateRemotePlugins

[required]
:CocInstall coc-tsserver
:CocInstall coc-json
:CocInstall coc-pairs
:CocInstall coc-solargraph
:CocInstall coc-eslint
:CocInstall @yaegassy/coc-volar

[optional]
:CocInstall coc-prettier
:TSInstall typespec

$ sudo gem install solargraph
$ bun add -g @typespec/compiler
$ npm install -g neovim
```

## gcloud

```
$ curl https://sdk.cloud.google.com | zsh
```

## etc

```
// to display dotfiles on finder
command + shift + .

$ mkdir -p ~/assets/screenshots; defaults write com.apple.screencapture location ~/assets/screenshots
$ defaults write com.apple.screencapture name "screenshot"
$ defaults write -g ApplePressAndHoldEnabled -bool false
$ defaults write /Library/Preferences/FeatureFlags/Domain/UIKit.plist redesigned_text_cursor -dict-add Enabled -bool NO
```
