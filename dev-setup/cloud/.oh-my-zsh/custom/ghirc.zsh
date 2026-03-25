export TERM=xterm-256color
eval "$(~/.local/bin/oh-my-posh init zsh --config 'https://raw.githubusercontent.com/cghirardi/cghirardi/refs/heads/main/dev-setup/.oh-my-posh/themes/aws.json')"

cd ~/workplace
export JSII_DEPRECATED=quiet

# region Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"
# endregion

# region Custom Variables

# Cloud Desktop Host
# export CLOUD_HOST="ghirc-clouddesk.aka.corp.amazon.com"
export CLOUD_HOST="dev-dsk-ghirc-1e-a5d4184c.us-east-1.amazon.com"

# endregion

# region Apps
# lets you type any folder name in ~/workplace and it will automatically
# CD into that folder
setopt auto_cd
cdpath+=~/workplace

# region Simple Aliases
alias aws="/apollo/bin/env -e AmazonAwsCli aws"
alias b="eda b" # eda build brazil-build release
alias bs="eda bs" # eda build --silent brazil-build release
alias bbcr="brazil-build clean && brazil-build release"
alias bbb="brc --allPackages brazil-build"
alias bbr="bb release"
alias brazil-recursive-cmd="brazil-recursive-cmd-parallel"
alias brc="brazil-recursive-cmd-parallel"
alias build="bb build"
alias bvs="brazil vs"
alias bws="brazil ws"
alias cdk-warnings-on="export JSII_DEPRECATED=error"
alias cdk-warnings-off="export JSII_DEPRECATED=quiet"
alias dcv="~/bin/dcv-cdd.py connect ghirc-clouddesk.aka.corp.amazon.com"
alias dev="cd /Volumes/development"
alias host="echo -e '${GREEN}$CLOUD_HOST${NOCOLOR}'"
alias k="kinit -f"
alias third-party-promote='~/.toolbox/bin/brazil-third-party-tool promote'
alias third-party='~/.toolbox/bin/brazil-third-party-tool'
alias wp="cd ~/workplace"
# endregion

# region tmux
alias tfrontend="tmux new-session -A -s tfrontend"
alias tp="tmux new-session -A -s tp"
alias tservice="tmux new-session -A -s tservice"
alias tweb="tmux new-session -A -s tweb"
# endregion

# region Function Aliases
backup() {
  git push backup --force "refs/heads/*:refs/heads/*"
}

bb() {
  if [[ $@ == "integ" ]]; then
    command brazil-build development-integ-tests
  else
    command brazil-build "$@"
  fi
}

login() {
  kinit -f
  mwinit -o
}

sshkill() {
  ps aux | grep 8080
}
# endregion
