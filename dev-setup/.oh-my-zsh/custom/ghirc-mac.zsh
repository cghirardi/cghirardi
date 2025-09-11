export JSII_DEPRECATED=quiet

# Toolbox
export PATH=$HOME/.toolbox/bin:$PATH

# JDK
# export JAVA_HOME=/Library/Java/JavaVirtualMachines/amazon-corretto-8.jdk/Contents/Home
# export
JAVA_HOME=/Library/Java/JavaVirtualMachines/amazon-corretto-11.jdk/Contents/Home

# AWS Command Completion
export PATH=/usr/local/bin/aws_completer:$PATH

# RDE Completion
fpath=($ZSH/completion $fpath)
autoload -Uz compinit && compinit -i

# Isengard CLI
eval "$(isengardcli shell-profile)"

# region Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"
# endregion

# region Custom Variables

# Cloud Desktop Host
export CLOUD_HOST="ghirc-clouddesk.aka.corp.amazon.com" # dev-dsk-ghirc-1d-c9741c5d.us-east-1.amazon.com

# endregion

# region Apps
# lets you type any folder name in ~/workplace and it will automatically
# CD into that folder
setopt auto_cd
cdpath+=~/workplace

# region Simple Aliases
alias b="eda b"
alias bbcr="brazil-build clean && brazil-build release"
alias bbr="brazil-build release"
alias bbb="brc --allPackages brazil-build"
alias brc="brazil-recursive-cmd"
alias build="bb build"
alias bvs="brazil vs"
alias bws="brazil ws"
# alias cloud="axe connect --instance-id i-04751f89bd90a32be"
# alias cloudssh="ssh cdm"
alias cloud="ssh -A dev-dsk-ghirc-1d-c9741c5d.us-east-1.amazon.com"
alias dev="cd /Volumes/development"
alias "eda b"="eda brazil-build release"
alias host="echo -e '${GREEN}$CLOUD_HOST${NOCOLOR}'"
alias isengard="isengardcli"
alias k="kinit -f"
alias rdp="cloudtun 3389"
alias wp="cd ~/workplace"
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

cloudtun() {
  PORT=${1:-8080}
  ssh -f -N -L "$PORT:127.0.0.1:$PORT" "$CLOUD_HOST"
  echo "Created tunnel to $CLOUD_HOST:$PORT"
}

config() {
  code ~/.zshrc
  code $ZSH/custom/*.zsh
  code /Users/ghirc/.config/ninja-dev-sync.json
  code ~/.gitconfig
  code ~/.config/eda/config.toml
  code ~/.ssh/config
}

# traverse directories upward until a workspace file is found
# and open it in VS Code if found
codews() {
  count=0
  filename="workspace.code-workspace"
  dir=""
  while [ $count -le 5 ]
  do
    if [ -f "${dir}${filename}" ]; then
      code "${dir}${filename}"
      dir="${dir}${filename}"
      break
    fi

    dir="../${dir}"
    count=$(( $count + 1 ))
  done

  if [ -z "${dir}" ]; then
    echo "No workspace file found!"
  fi
}

createws() {
  eda create "$@"
  bemol --generate-vscode-ws ./workspace.code-workspace
}

login() {
  command="mwinit -f -s"
  echo $command
  eval "$command"
  # ssh-add ~/.ssh/id_rsa --apple-use-keychain > /dev/null 2>&1
}

check_midway() {
  midway_response="$(curl -s -b ~/.midway/cookie -k https://midway-auth.amazon.com/api/session-status | jq .)"
  is_authed=$(echo $midway_response | jq -r '.authenticated')

  if [ $is_authed != "true" ]; then
    echo "Your midway cookie has expired!"
  else
    midway_date=$(echo $midway_response | jq -r '.expires_at')
    midway_date_formatted=$(date -j -f %s $midway_date '+%a %b %d %r %Z %Y')
    echo "Your midway cookie is valid until ${midway_date_formatted}!"
  fi
}

# Alias for Ninja Dev Sync
ninja() {
  echo -e "The non-aliased command is: ${GREEN}ninja-dev-sync${NOCOLOR}"
  ninja-dev-sync "$@"
}

sshkill() {
  ps aux | grep 8080
}

# Lists out all of the Amazon Brew taps
taps() {
  TAP=amazon/homebrew-amazon; \
  TAP_PREFIX=$(brew --prefix)/Homebrew/Library/Taps; \
  ls $TAP_PREFIX/$TAP/Formula/*.rb 2>/dev/null || ls $TAP_PREFIX/$TAP/*.rb 2>/dev/null | \
  xargs -I{} basename {} .rbI
}
# endregion


# region Startup
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
cd ~/workplace
check_midway

# fixes "Connection closed by UNKNOWN port 65535" issue that occurs every morning 🤷‍♂️
eval $(ssh-agent) > /dev/null 2>&1
ssh-add -D > /dev/null 2>&1
# endregion

