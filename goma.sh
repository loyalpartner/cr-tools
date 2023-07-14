#!/bin/bash

exec_config_file='
version_id:"1",
configs: [{
  target: {
          addr:"192.168.31.21:8980",
  },
  remoteexec_platform: {
    properties:{
      name: "OSFamily",
      value: "Linux"
    },
    rbe_instance_basename: "default_instance",
    has_nsjail: false
  },
  dimensions: ["os:linux"]
}]
'

check_deps(){
  local deps=(go remoteexec_proxy goma_ctl lxc)
  for dep in ${deps[@]}; do
    if ! which $dep &> /dev/null; then
      echo "$dep 不存在"
    fi
  done
}


check_deps

start_goma_rbe(){
  if ! lxc info goma &> /dev/null; then
    echo goma instance not found
    return
  fi

  local restart_command="docker-compose -f ~/bb-deployments/docker-compose/docker-compose.yml restart"
  # lxc exec goma -- pgrep -vx docker-compose > /dev/null
  lxc exec goma -- docker-compose -f ~/bb-deployments/docker-compose/docker-compose.yml restart
}

start_goma_server(){
  REMOTEEXEC_ADDR=${REMOTEEXEC_ADDR:-192.168.31.59:8980}
  export REDISHOST=localhost

  # --exec-execute-timeout 10m0s \
  # -exec-max-retry-count 10 \
  remoteexec_proxy -port 5050 -remoteexec-addr $REMOTEEXEC_ADDR  \
    -insecure-remoteexec \
    -allowed-users "charlselee59@gmail.com"  \
    -max-digest-cache-entries 200000000 \
    -exec-response-timeout 0 \
    -exec-check-missing-timeout 20s \
    -exec-missing-input-limit 0 \
    -exec-config-file <(echo $exec_config_file)
}

start_goma_client(){
  # 这些环境变量来自 goma-client 的 goma_flags.cc
  goma_ctl ensure_stop

  export GOMA_USE_LOCAL=false
  export GOMA_FALLBACK=false
  # export GOMA_MAX_LONG_TASKS=100

  export GOMA_SERVER_HOST=localhost GOMA_SERVER_PORT=5050
  # 注意: 如果是远程服务器, GOMA_SERVER_PORT 必须设置成 80 或者 443
  # export GOMA_SERVER_HOST=10.72.230.129 GOMA_SERVER_PORT=80
  # export GOMA_SERVER_HOST=192.168.31.21 GOMA_SERVER_PORT=80
  export GOMA_USE_SSL=false
  export GOMA_ARBITRARY_TOOLCHAIN_SUPPORT=true

  GOMACTL_USE_PROXY=false goma_ctl ensure_start
}

# start_goma_rbe
start_goma_client &
start_goma_server

