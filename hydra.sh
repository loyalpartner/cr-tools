#!/bin/bash

WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}
VMODULE_FILTER=${VMODULE_FILTER:-}
WAYLAND_OPTION=(
    --enable-features=UseOzonePlatform 
    --ozone-platform=wayland
  )
TTY=${TTY:-}

executable_args=$@
win_release_dirs=(win_nodcheck)
index_added=true
target_dir=""
target_executable=""

info(){
  echo -e "\033[0;32m[INFO] $@\033[0m"
}

add_gdb_index(){
  if $index_added; then return; fi
  local executable=$1
  build/gdb-add-index $executable
  index_added=true
}

build_and_run(){
  local dir=$1
  build $dir && run $dir
}

build(){
  local dir=$1
  local target_dir="out/$dir"

  if [[ ! -f "$target_dir/args.gn" ]]; then
    gn args $target_dir
  fi

  index_added=false

  local cmd=(autoninja -C $target_dir $target_executable)

  local goma_options=(GOMA_DISABLED=true)
  if curl --fail http://127.0.0.1:8088 &>/dev/null; then
    goma_options=(GOMA_USE_LOCAL=false GOMA_FALLBACK=false)
    cmd+=(-j 300)
  fi

  cmd=(${goma_options[@]} ${cmd[@]})

  info "${cmd[@]}"
  echo "${cmd[@]}" | $SHELL
}

run(){
  local executable=out/$target_dir/$target_executable
  local cmd=($executable)
  if [[ -n $VMODULE_LOG_OPTION ]]; then
    cmd+=(--v=-3 --vmodule=\"$VMODULE_FILTER\")
  fi

  if grep 'target_os = "chromeos"' out/$target_dir/args.gn; then
    cmd+=(--login-manager)
  else
    [[ $XDG_SESSION_TYPE == wayland ]] && cmd+=(${WAYLAND_OPTION[@]})
  fi


  if [[ $executable =~ .*content_shell$ ]]; then
    read -p "是否等待调试器附加渲染器进程？[y/n]: " answer
    if [[ $answer == [Yy] || $answer == [Yy][Ee][Ss] ]]; then
      cmd+=(--wait-for-debugger-on-navigation)
    fi
  else
    cmd+=(--user-data-dir=out/data)
  fi
  info ${cmd[@]} ${executable_args[@]}
  ${cmd[@]} ${executable_args[@]}
}

debug(){
  local executable=out/$target_dir/$target_executable
  add_gdb_index $executable

  # init_eval_commands
  local cmd+=(
    cgdb
    -iex=\"source -v tools/gdb/gdbinit\"
    -ex=\"tty /dev/null\"
    -ex=\"source my.breaks\"
  )
  if [[ -n $TTY ]]; then
    cmd+=(-ex=\"tty $TTY\")
  fi
  cmd+=(--args $executable)

  [[ $XDG_SESSION_TYPE == wayland ]] && cmd+=(${WAYLAND_OPTION[@]})

  if [[ $executable =~ .*content_shell$ ]]; then
    # cmd+=(--wait-for-debugger-on-navigation)
    echo ""
  else
    cmd+=(--user-data-dir=out/data)
  fi
  info ${cmd[@]} ${executable_args[@]}
  $SHELL -c "${cmd[*]} ${executable_args[@]}"
}

clean_data(){
  [[ -d "out/data" ]] && rm -r out/data
}

update_extension_histograms(){
  info "update extension histograms"
  tools/metrics/histograms/update_extension_histograms.py
}

format_code(){
  info "format code"
  git cl format
}

is_release_version(){
  if [[ "$target_dir" == "Release" || "$target_dir" == "win_nodcheck" ]]; then
    return 0
  fi
  return 1
}

need_out_dir_and_executable(){
  action=$1

  case $action in
    build_and_run | build | run | debug) return 0 ;;
    *) return 1 ;;
  esac
}

select_action(){
  actions=(
    build_and_run build run debug 
    format_code update_extension_histograms
    clean_data 
    rechoose quit
  )
  while true; do
    clear
    select action in ${actions[@]}; do
      case $action in
        rechoose)
          target_dir=""
          target_executable=""
          ;;
        quit) exit 0; ;;
        clean_data) $action;;
        *)
          if need_out_dir_and_executable $action; then
            select_out_dir
            select_executable
          fi

          if is_release_version; then
            format_code
            update_extension_histograms
          fi
          $action $target_dir;
          ;;
      esac
      break
    done
  done
}

select_out_dir(){
  clear
  out_dirs=()
  for p in out/*/args.gn; do
    out_dirs+=($(basename $(dirname $p)))
  done
  out_dirs+=(quit)
  [[ -n $target_dir ]] && return
  select dirname in ${out_dirs[@]}; do
    [[ -z $dirname ]] && break
    [[ $dirname == "quit" ]] && return
    target_dir="$dirname"
    break
  done
}

select_executable(){
  clear
  target_executables=(chrome content_shell mini_installer unittest quit)
  [[ -n $target_executable ]] && return
  select executable in ${target_executables[@]}; do
    case $executable in
      chrome | content_shell | mini_installer) target_executable=$executable ;;
      unittest) 
        target_executable=$(gn ls out/$target_dir/ --type=executable --testonly=true --as=output | fzf)
        ;;
      quit | *) target_executable="";;
    esac

    if [[ -z $target_executable ]]; then
      return
    fi
    break
  done
}

main() {
  select_action
}

main
