#!/bin/bash

printf "`date "+%Y-%m-%d_%H:%M:%S"` starting.\n"

source /usr/local/etc/loginproxy/functions.sh

#if not set proxy user/password, read from stdin
if [[ -z ${PROXY_USER} ]]; then
  read -p "proxy user: " PROXY_USER
  export PROXY_USER
fi
if [[ -z ${PROXY_PASSWORD} ]]; then
  read -s -p "proxy password: " PROXY_PASSWORD
  export PROXY_PASSWORD && echo ""
fi

#kill or attach old session
tmux has-session -t ${SESSION_NAME} 2>/dev/null
if [[ $? -eq 0 ]]; then
  read -p "session(${SESSION_NAME}) has existed, kill(k) or new(n) or attach(a)? " ANSWER
  while [[ ! "${ANSWER}" =~ ^[aAkKnN]$ ]];
  do
    read -p "please input a/A(attach) or k/K(kill&new) or n/N(new): " ANSWER
  done
  if [[ "${ANSWER}" =~ ^[kK]$ ]]; then
    tmux kill-session -t ${SESSION_NAME}
  elif [[ "${ANSWER}" =~ ^[nN]$ ]]; then
    export SESSION_NAME="${SESSION_NAME}""$$"
  else
    tmux attach -t ${SESSION_NAME}
    exit 0
  fi
fi

printf "tmux session name: ${SESSION_NAME}\n"

#create window + pane and login hosts
loginall ${@}

printf "`date "+%Y-%m-%d_%H:%M:%S"` end.\n"

#attach to tmux
tmux attach -t ${SESSION_NAME}

#eof
