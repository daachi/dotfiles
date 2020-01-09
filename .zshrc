ZSH=$HOME/.oh-my-zsh

# ZSH_THEME=xiong-chiamiov-plus
ZSH_THEME=sammy

CASE_SENSITIVE="true"

fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

# autocomplete for vault
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /home/daachi/bin/vault vault

plugins=(git pass)

source $ZSH/oh-my-zsh.sh

alias cls=clear
alias more=less
alias h='fc -lin 0'
alias hg='h|ag'

# https://askubuntu.com/questions/65951/how-to-disable-the-touchpad
# list devices with `xinput list`
alias fak_off_touchpad='xinput set-prop 14 "Device Enabled" 0'

unsetopt auto_name_dirs

setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_ignore_dups

export EDITOR=vim

set -o vi
bindkey -v
bindkey "^R" history-incremental-search-backward

export SLACK_TOKEN="xoxp-3016978776-14661715477-39734653985-226cdfbbfc"

# removing git to use sammy theme 2019-10-03
# export RPROMPT='$(git_prompt_info) $(triton_profile) $(nvm_prompt_info) $(rvm_prompt_info)'
# export RPROMPT='$(triton_profile) $(nvm_prompt_info) $(rvm_prompt_info)'

function clone () {
  org=$1
  repo=$2

  git clone git@github.com:$org/$repo
}

# am I available to do something on a particular date?
function avail () {
  a=`date --date="$1" +%V` 
  if (( $a % 2 )) > 0
  then
    echo "Yaas"
  else
    echo "Nope"
  fi
}

# https://serverfault.com/questions/661978/displaying-a-remote-ssl-certificate-details-using-cli-tools#661982
function check_certificate () {
  if [ $# -eq 0 ]
  then
    echo "Need a hostname to operate on..."
    return 85
  else
    echo |\
      openssl s_client -showcerts -connect $1:443 2>/dev/null |\
      openssl x509 -inform pem -noout -dates
  fi
}

function slack-notification () {
  curl -X POST --data-urlencode "payload={\"channel\": \"@daachi\", \"username\": \"cli\", \"text\": \"$1\", \"icon_emoji\": \":ghost:\"}" https://hooks.slack.com/services/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
}

function ec2_id () {
  host=$1
  aws ec2 describe-instances --filters Name=tag-value,Values=$host |\
  jq -M -r .Reservations[].Instances[].InstanceId
}

# old Optoro VPN, no longer operational 2017/08/28
function vpn_status () {
  if [ $# -ne 1 ]
  then
    echo "Need a username to operate on (e.g. aburton)"
    return 85
  fi

  ssh openvpn-001.optoro.io "sudo grep $1 /etc/openvpn/openvpn-status.log"
}

function notes () {
  if [ $# -eq 1 ]
  then
    cd ~/doc/notes/$1
  else
    cd ~/doc/notes/
  fi
}

# alias tpsc="triton profile set-current"
function tpsc () {
  # triton profile set-current $1
  # export TRITON_PROFILE=$1
  # eval "$(triton env)"

  case $1 in
     profile)
       export TRITON_PROFILE=$2
       eval "$(triton env)"
       ;;
     local-dev)
       unset DOCKER_CERT_PATH
       unset DOCKER_HOST
       unset DOCKER_TLS_VERIFY
       unset COMPOSE_HTTP_TIMEOUT
       unset SDC_ACCOUNT
       unset SDC_KEY_ID
       unset SDC_URL
       ;;
     *)
       echo "Usage: tpsc profile <name> or local-dev"
       echo "  Profile for a specific environment (e.g. prod-optiturn)"
       echo "  or local-dev to clear your env variables."
       ;;
  esac
}

# use this to lookup a hostname, since we don't do DNS well
function reverse () {
  if [ $# -ne 2 ]
  then
   echo "Usage: reverse <host,dig,triton> <ip>"
    return 85
  fi

  case $1 in
    host)
      host $2 10.1.4.100 | tail -n1 | awk '{ print $5 }' | sed 's/\.inst.*//'
      ;;
    dig)
      dig -x $2 @10.1.4.100 +short | sed 's/\.inst.*//'
      ;;
    triton)
      ## TODO: need to do better here
      #  should look for this env var, or get one from triton
      echo "Searching in $TRITON_PROFILE environment..."
      tls -l | grep $1 | awk '{ print $2 }'
      ;;
    *)
      echo "Use one of host, dig or triton for reversing IP addresses."
      ;;
  esac
}

function ci () {
  if [ $# -ne 1 ]
  then
    echo "Need an action to preform (e.g. build, run_tests, clean, cb_run)"
    return 85
  fi

  BUILD_NAME=$(basename `pwd`)

  case $1 in
    build)
      if [ -e Dockerfile ]
      then
        docker pull docker-registry.optoro.io/chef_infra_base:latest
        docker build -t ${BUILD_NAME}_build .
      else
        notify-send "There's no Dockerfile here, bro. Do you know what you're doing?"
      fi
      ;;
    run_tests)
      # check gemset?
      if [ -e Dockerfile ] && [ -e Gemfile ]
      then
        "[[ ! -x $(which bundler) ]] && gem install bundler"
        bundle install
        docker run -d --name ${BUILD_NAME} ${BUILD_NAME}_build
        bundle exec inspec exec test/ -t docker://${BUILD_NAME}
      else
        notify-send "Bro, what the fuck. Where even are you?"
      fi
      ;;
    cleanup)
      if [ -e Dockerfile ]
      then
        echo -n "Stopping ${BUILD_NAME}..."
        docker stop ${BUILD_NAME}
        echo "done."

        echo -n "Removing ${BUILD_NAME}..."
        docker rm ${BUILD_NAME}
        echo "done."

        echo -n "Removing build image..."
        docker rmi ${BUILD_NAME}_build
        echo "done."
      else
        echo "Bro, there's no Dockerfile. Are you high?"
      fi
      ;;
    cb_run)
      if [ -e Dockerfile ]
      then
        echo -n "Starting docker instance for ${BUILD_NAME}..."
        docker run -d --name ${BUILD_NAME} ${BUILD_NAME}_build:latest
        echo "done."
      else
        notify-send "Bruh, seriously, stop."
      fi
      ;;
    *)
      echo "Use one of build, run_tests or cleanup."
      ;;
  esac
}

function instance_ip () {
  if [ $# -ne 1 ]
  then
    echo "Need a hostname to operate on (e.g. app-007.blinq.com)"
    return 85
  fi

  triton instance get -j $1 | jq -r .primaryIp
}

# journal
function j () {
  year=`date +%Y`
  month=`ruby -e 'puts %x(date +%b).downcase'`
  day=`date +%e`
  journal_dir="$HOME/Dropbox/journal/$year/$month"

  if [[ -d $journal_dir ]] {
    pushd $journal_dir
  } else {
    mkdir -p $journal_dir
    pushd $journal_dir
  }

  vim $day.txt
  popd
}

amtool-conf () {
  case $1 in
    (set)
      unset AMTOOL_CONFIG
      export AMTOOL_CONFIG=~/.config/amtool/$2.yml
      ;;
    (*)
      echo -n "Current amtool config: "
      echo $AMTOOL_CONFIG
      echo "--------------------------"
      ls -1 ~/.config/amtool ;;
  esac
}

## no more, now we have koo bear ne taes
# chef
## alias k='kitchen'
## alias kv='k verify'
## alias kl='k list'
## alias kt='k test'
## alias kd='k destroy'
## alias ks='knife ssh -t2'
## alias kdbe='knife data bag edit --secret-file'

# vagrant
alias vd='vagrant destroy -f'
alias vs='vagrant ssh'
alias vu='vagrant up'

# i3 on ThinkPad
alias nocaps='setxkbmap -option ctrl:nocaps'
alias monitorme='xrandr --output DP2 --mode 1920x1080 --left-of eDP1'

# triton
alias tls='triton ls'
alias tpls='triton profile list'
alias tils='triton image list'

## terraform
alias tf=terraform

# docker
alias dps='docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}"'
alias dils='docker image ls'
alias de='docker exec -it'

# koo bear ne taes
alias k=kubectl
alias kx=kubectx

export NVM_DIR="/home/daachi/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

## sdc-*
## manta
export MANTA_USER=optoro;
export MANTA_SUBUSER=aburton;
export MANTA_KEY_ID=ab:1b:48:6c:33:13:77:ae:18:6c:d8:8c:89:de:90:fb;
export MANTA_URL=https://us-east.manta.joyent.com;

# export GOPATH="${HOME}/src/go-work"
# path+=(/usr/local/go/bin:${GOPATH}/bin)

#dart
path+=(/usr/lib/dart/bin)

if [ -f /home/daachi/src/tfenv/bin/tfenv ]; then
  path+=(/home/daachi/src/tfenv/bin $path)
fi

path+=(~/bin)

source /usr/share/virtualenvwrapper/virtualenvwrapper.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
# export PATH="$PATH:$HOME/.rvm/bin"
# export GOPATH="$HOME/go"; export GOROOT="$HOME/.go"; PATH="$GOPATH/bin:$PATH"; # g-install: do NOT edit, see https://github.com/stefanmaric/g

. $HOME/.asdf/asdf.sh
