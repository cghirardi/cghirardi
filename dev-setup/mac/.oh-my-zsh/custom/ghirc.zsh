# eval "$(oh-my-posh init zsh --config 'https://raw.githubusercontent.com/cghirardi/cghirardi/refs/heads/main/dev-setup/.oh-my-posh/themes/macos.json')"
eval "$(oh-my-posh init zsh --config '~/.cache/oh-my-posh/themes/capr4n.ghirc.json')"

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
export CLOUD_HOST="ghirc-clouddesk.aka.corp.amazon.com" # dev-dsk-ghirc-1e-b8d99532.us-east-1.amazon.com

# endregion

# region Apps
# lets you type any folder name in ~/workplace and it will automatically
# CD into that folder
setopt auto_cd
cdpath+=~/workplace

# region Simple Aliases
alias b="eda b" # eda build brazil-build release
alias bs="eda bs" # eda build --silent brazil-build release
alias bbcr="brazil-build clean && brazil-build release"
alias bbr="brazil-build release"
alias bbb="brc --allPackages brazil-build"
alias bbs="bb build && bb server"
alias brc="brazil-recursive-cmd"
alias build="bb build"
alias bvs="brazil vs"
alias bws="brazil ws"
# alias cloud="axe connect --instance-id i-04751f89bd90a32be"
# alias cloudssh="ssh cdm"
# alias cloud="ssh -A ${CLOUD_HOST}"
alias cloudnew="ssh -A dev-dsk-ghirc-1e-12b90b33.us-east-1.amazon.com"
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

cloud() {
  if [[ -z $1 ]]; then
    # no command passed -> open interactive session
    ssh -A "$CLOUD_HOST"
  else
    # command passed -> run it on remote
    ssh -A "$CLOUD_HOST" ${1:+"tmux new-session -As $@"}
  fi
}

cloudtun() {
  PORT=${1:-8080}
  ssh -f -N -L "$PORT:127.0.0.1:$PORT" "$CLOUD_HOST"
  echo "Created tunnel to $CLOUD_HOST:$PORT"
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
      kiro "${dir}${filename}"
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

config() {
  kiro ~/.zshrc
  kiro $ZSH/custom/*.zsh
  kiro /Users/ghirc/.config/ninja-dev-sync.json
  kiro ~/.gitconfig
  kiro ~/.config/eda/config.toml
  kiro ~/.ssh/config
  kiro ~/.cache/oh-my-posh/themes/capr4n.ghirc.json
}

cloudcopy() {
  local remote_dir="$1"
  local local_dir="$2"
  scp -r ghirc@ghirc-clouddesk.aka.corp.amazon.com:${remote_dir} ${local_dir}
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

trebtun() {
  cloudtun 5173
  cloudtun 1443
  cloudtun 9001
}
# endregion


# region Trebuchet
function get_aws_credentials() {
  local creds_response=$(curl -s http://127.0.0.1:9911/)

  if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch credentials" >&2
    return 1
  fi

  # Parse credentials
  local access_key=$(echo $creds_response | jq -r '.AccessKeyId')
  local secret_key=$(echo $creds_response | jq -r '.SecretAccessKey')
  local session_token=$(echo $creds_response | jq -r '.Token')

  if [ -z "$access_key" ] || [ -z "$secret_key" ] || [ -z "$session_token" ]; then
    echo "Error: Failed to parse credentials" >&2
    return 1
  fi

  # Return as JSON to easily pass multiple values
  echo "{\"access_key\": \"$access_key\", \"secret_key\": \"$secret_key\", \"session_token\": \"$session_token\"}"
}

function make_trebuchet_call() {
  local host="${1}"
  local api_name="${2}"
  local payload="${3}"
  local access_key="${4}"
  local secret_key="${5}"
  local session_token="${6}"
  local headers_only="${7:-false}"

  local curl_opts=(
    -k
    -s
    --request POST
    "${host}"
    --header 'Content-Encoding: amz-1.0'
    --header 'Content-Type: application/json'
    --aws-sigv4 "aws:amz:us-east-1:trebuchet"
    --user "${access_key}:${secret_key}"
    --header "X-Amz-Security-Token: ${session_token}"
    --header "X-Amz-Target: com.amazonaws.trebuchet.TrebuchetService.${api_name}"
    --data "${payload}"
  )

  if [ "${headers_only}" = true ]; then
    mcurl -v "${curl_opts[@]}" -i 2>&1
  else
    mcurl -v "${curl_opts[@]}" | jq .
  fi
}

function handle_midway_auth() {
  local midway_url="$1"

  echo "Detected Midway authentication required. Authenticating..."

  curl --request GET \
    --cookie-jar ~/.midway/cookie \
    --cookie ~/.midway/cookie \
    --location-trusted \
    -k "$midway_url"
}

function call_trebuchet() {
  local env="${1:-local}"
  local api_name="${2}"
  local payload="${3}"

  # Map environment to host URL
  local host
  case "${env}" in
    local)
      host="https://ghirc-clouddesk.aka.corp.amazon.com:9001"
      ;;
    beta)
      host="https://beta.trebuchet.aws.dev"
      ;;
    gamma)
      host="https://gamma.trebuchet.aws.dev"
      ;;
    prod)
      host="https://trebuchet.aws.dev"
      ;;
    *)
      echo "Error: Invalid environment '${env}'. Use: local, beta, gamma, or prod"
      return 1
      ;;
  esac

  if [ -z "${api_name}" ]; then
    echo "Usage: call_trebuchet <ENV> <API_NAME> [PAYLOAD]"
    echo "ENV: local, beta, gamma, or prod"
    echo "Example: call_trebuchet local GetFeature '{\"featureArn\": \"arn\"}'"
    return 1
  fi

  # Default to empty JSON object if no payload provided
  if [ -z "${payload}" ]; then
    payload="{}"
  fi

  # Get and parse credentials
  local creds_json=$(get_aws_credentials)
  if [ $? -ne 0 ]; then
    echo "${creds_json}"
    return 1
  fi

  local access_key=$(echo "${creds_json}" | jq -r '.access_key')
  local secret_key=$(echo "${creds_json}" | jq -r '.secret_key')
  local session_token=$(echo "${creds_json}" | jq -r '.session_token')

  # Make initial request and capture full response with headers
  local response=$(make_trebuchet_call "${host}" "${api_name}" "${payload}" "${access_key}" "${secret_key}" "${session_token}" true)

  # Check if we got a Midway redirect (even with 200 status)
  if echo "${response}" | grep -q "Location: https://midway-auth.amazon.com/SSO/redirect?"; then
    # Extract the Location URL
    local midway_url=$(echo "${response}" | grep "Location: " | sed 's/Location: //' | tr -d '\r\n')

    echo "Detected Midway authentication required. Authenticating..."

    # Handle Midway authentication
    handle_midway_auth "${midway_url}"

    echo "Retrying original request after Midway authentication..."

    # Retry the original request
    make_trebuchet_call "${host}" "${api_name}" "${payload}" "${access_key}" "${secret_key}" "${session_token}" false
  else
    # If no Midway redirect, make the call and return JSON response
    make_trebuchet_call "${host}" "${api_name}" "${payload}" "${access_key}" "${secret_key}" "${session_token}" false
  fi
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
