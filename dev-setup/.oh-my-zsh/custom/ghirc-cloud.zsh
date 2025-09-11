eval "$(oh-my-posh init zsh --config 'https://raw.githubusercontent.com/cghirardi/cghirardi/refs/heads/main/dev-setup/.oh-my-posh/themes/capr4n.ghirc.json')"

export PATH=/apollo/env/envImprovement/bin:$HOME/.toolbox/bin:$HOME/.cargo/bin:$PATH
export PATH=/apollo/env/ApolloCommandLine/bin:$PATH

# region Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"
# endregion

# export ANT_ARGS="$ANT_ARGS -logger org.apache.tools.ant.listener.AnsiColorLogger"
# export ANT_OPTS="$ANT_OPTS -Dant.logger.defaults=$HOME/.ant.colors"

# region Apps
# lets you type any folder name in ~/workplace and it will automatically
# CD into that folder
setopt auto_cd
cdpath+=~/workplace

# region Simple Aliases
alias bbcr="brazil-build clean && brazil-build release"
alias bbb="brc --allPackages brazil-build"
alias bbr="bb release"
alias brc='brazil-recursive-cmd'
alias build="bb build"
alias bvs="brazil vs"
alias bws="brazil ws"
alias cdk-warnings-on="export JSII_DEPRECATED=error"
alias cdk-warnings-off="export JSII_DEPRECATED=quiet"
alias k="kinit -f"
alias tmux-cr='tmux -CC'
alias tmux-at='tmux -CC attach'
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

refresh_creds() {
  PROFILE_NAME=${1:-"personal"}
  aws_json=$(ada credentials print --profile "$PROFILE_NAME") export AWS_ACCESS_KEY_ID=$(echo $aws_json | jq -r .AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo $aws_json | jq -r .SecretAccessKey) AWS_SESSION_TOKEN=$(echo $aws_json | jq -r .SessionToken)
  echo "Personal account credentials loaded."
}

login() {
  mwinit -o
  refresh_creds
  # ssh-add ~/.ssh/id_rsa --apple-use-keychain > /dev/null 2>&1
}

check_midway() {
  midway_response="$(curl -s -b ~/.midway/cookie -k https://midway-auth.amazon.com/api/session-status | jq .)"
  is_authed=$(echo $midway_response | jq -r '.authenticated')

  if [ $is_authed != "true" ]; then
    echo "Your midway cookie has expired!"
  else
    midway_date=$(echo $midway_response | jq -r '.expires_at')
    midway_date_formatted=$(TZ="America/New_York" date -d "@$midway_date" +"%a %b %d %r %Z %Y")
    # midway_date_formatted=$(date -j -f %s $midway_date '+%a %b %d %r %Z %Y')
    echo "Your midway cookie is valid until ${midway_date_formatted}!"
    refresh_creds
  fi
}
# endregion

# region Startup
cd ~/workplace
export JSII_DEPRECATED=quiet
check_midway

#tmux new-session -As persistent # attaches to or creates a long-lived session
# endregion
