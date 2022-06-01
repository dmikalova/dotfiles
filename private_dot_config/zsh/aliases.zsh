#!/bin/zsh

# atool
alias compress='apack'
alias expand='aunpack --subdir'

# builtins
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ai='sudo apt install'
alias as='apt-cache search'
alias au='sudo apt update && sudo apt upgrade && sudo apt autoremove && sudo apt autoclean'
alias cat='ccat'
alias cl='xclip -selection c'
alias cld='printf "%s" $(pwd) | cl'
alias cp='cp --interactive --recursive'
alias cdg='cd $(git rev-parse --show-toplevel)'
alias diff='colordiff'
alias fd='fdfind'
# alias grep='grep --color=auto --exclude-dir=.terragrunt-cache --exclude-dir=node_modules'
# alias g='grep --ignore-case --recursive'
alias grep='rg'
alias less='cless'
alias ls='ls --all --color=auto --human-readable'
alias mv='mv --interactive'
alias reboot='sudo reboot'
alias rm='trash'

# chezmoi
alias cza='chezmoi apply && zsh'
alias czr='chezmoi re-add'
alias czs='chezmoi status'

# git
alias gcpa='git-commit-push-all'
alias gs='git status'
alias ge='git commit --amend --no-edit && git push -f'

# npm
alias npmi='npm install'

# terraform
alias tf='terraform'
alias tfa="tf apply 'terraform.plan'"
alias tfi='tf init'
alias tfip='tfi && tfp'
alias tfla='tflint-all'
alias tfp="tf plan -out 'terraform.plan'"

# terragrunt
alias tg='terragrunt-alias'
alias tga="tg apply 'terraform.plan'"
alias tgd='tg destroy'
alias tgdc='terragrunt-delete-caches'
alias tgfmt='terragrunt-fmt-all'
alias tgi='tg init'
alias tgiu='tg init -upgrade'
alias tgip='tgi && tgp'
alias tgipa='tgi && tgp && tga'
alias tgo='tg output'
alias tgoj='tg output -json'
alias tgp="tg plan -out 'terraform.plan'"
alias tgpa='tgp && tga'
alias tgr='tg run-all'
alias tgra="tgr apply 'terraform.plan'"
alias tgranp='tgr apply'
alias tgrp="git pull && tgr plan -out 'terraform.plan'"
alias tgrpa='tgrp && tgra'
alias tgs='tg state'

# utilities
alias file-count='echo $PWD; for t in files links directories; do echo `find . -type ${t:0:1} | wc -l` $t; done 2> /dev/null'
alias flac2mp3='flac2mp3.pl --lameargs="-V 0" --processes=2'
alias rm-empty-subdirs='find . -type d -empty -print -delete'
alias serve-dir='python3 -m http.server 54003'

# vscode
alias cg='code $(git rev-parse --show-toplevel)'
alias ci='code ${HOME}/.config/Code/infrastructure.code-workspace'

# yarn
alias yarn='yarnpkg'
