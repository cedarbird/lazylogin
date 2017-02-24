#!/bin/bash

MAX_WIDTH=256
MAX_HEIGHT=72
SLEEP_INTERVAL=1
SESSION_NAME=autologin
LOGININFO="/usr/local/etc/loginproxy/loginproxy.info"

#get nat ip address by hostname
function getNATIP() {
  cat ${LOGININFO} | grep -v "^\s*#" | egrep "^${1}" | awk '{print $3}'
}

#get real ip address by hostname
function getREALIP() {
  cat ${LOGININFO} | grep -v "^\s*#" | egrep "^${1}" | awk '{print $2}'
}

#get login user by hostname
function getUSER() {
  cat ${LOGININFO} | grep -v "^\s*#" | egrep "^${1}" | awk '{print $4}'
}

#get login password by hostname
function getPASSWORD() {
  cat ${LOGININFO} | grep -v "^\s*#" | egrep "^${1}" | awk '{print $5}'
}

#get login template
function getTEMPLATE() {
  cat ${LOGININFO} | grep -v "^\s*#" | egrep "^${1}" | awk '{print $6}'
}

#send command to pane
function send_cmd() {
  TARGET=${1}
  HOST_REALIP=${2}
  HOST_NATIP=${3}
  HOST_USER=${4}
  HOST_PASSWORD=${5}
  TEMPLATE=${6}
  HOST_NAME=${7}
  while read CMD;
  do
    if [[ "${CMD}" =~ ^#.*$ ]]; then
      CMD=`echo ${CMD} | sed -e 's/^#//g'`
      ${CMD}
    else
      tmux send-keys -t ${TARGET} "`eval echo -E ${CMD}`" C-m
    fi
    sleep ${SLEEP_INTERVAL}
  done < "/usr/local/etc/loginproxy/template/"${TEMPLATE}
}

#login all hosts
function loginall() {
  NUMS_PAR=${#}
  for ((i = 0; i < ${NUMS_PAR}; i++)) {
    WIN_NAME=Group#$((i+1))
    if [[ $((i)) -eq 0 ]]; then
      tmux new-session -s ${SESSION_NAME} -n ${WIN_NAME} -x ${MAX_WIDTH} -y ${MAX_HEIGHT} -d
    else
      tmux new-window -t ${SESSION_NAME} -n ${WIN_NAME}
    fi
    loginwindow ${WIN_NAME} ${1} &
    shift
  }
  wait
  #avoid screen corruption
  tmux new-window -t ${SESSION_NAME} -n GOMI && tmux kill-window -t ${SESSION_NAME}:GOMI
}

#login a window's hosts
function loginwindow() {
  WIN_NAME=${1}
  HOSTSTR=${2}
  declare -a hostptns=(`echo ${HOSTSTR} | sed -e 's/,/ /g'`)
  declare -a hosts=()
  for ((i = 0; i < ${#hostptns[@]}; i++)) {
    hosts+=(`grep -v "^\s*#" "${LOGININFO}" | egrep "${hostptns[i]}" | awk '{print $1}'`)
  }
  hosts=(`echo "${hosts[@]}" | tr ' ' '\n' | sort -u`)
  width=${MAX_WIDTH}
  for ((i = 0; i < ${#hosts[@]}; i++)) {
    if [[ $((i)) -ne 0 ]]; then
      tmux split-window -h -l $((width-6*i)) -t ${SESSION_NAME}:${WIN_NAME}
    fi
    printf "`date "+%Y-%m-%d_%H:%M:%S"` Connecting to ${hosts[i]}(TMUXID: ${SESSION_NAME}:${WIN_NAME}.$((i+1))).\n"
    send_cmd ${SESSION_NAME}:${WIN_NAME}.$((i+1)) \
             `getREALIP ${hosts[i]}`              \
             `getNATIP ${hosts[i]}`               \
             `getUSER ${hosts[i]}`                \
             `getPASSWORD ${hosts[i]}`            \
             `getTEMPLATE ${hosts[i]}`            \
             ${hosts[i]}                          &
  }
  wait
  if [[ ${#hosts[@]} -ne 0 ]]; then
    tmux select-layout -t ${SESSION_NAME}:${WIN_NAME} tiled
    tmux set-window-option -t ${SESSION_NAME}:${WIN_NAME} synchronize-panes on
  else
    tmux kill-window -t ${SESSION_NAME}:${WIN_NAME}
  fi
}

#eof
