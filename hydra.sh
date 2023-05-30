#!/bin/bash

build_dirs=(Debug Release Default win win_nodcheck)
WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}

VMODULE_FILTER=${VMODULE_FILTER:-}

info(){
  echo -e "\033[0;32m[INFO] $@\033[0m"
}

build(){
  local dir=$1
  local target_dir="out/$dir"

  if [[ ! -f "$target_dir/args.gn" ]]; then
    gn args $target_dir
  fi

  autoninja -C $target_dir chrome
}

dispatch(){
  local target_dir="out/$1"
  local actions=(run debug)
  select action in ${actions[@]}; do
    $action $target_dir
    break
  done
}

run(){
  local executable=$1/chrome
  local cmd="$executable --ozone-platform-hint=auto --user-data-dir=out/data"
  if [[ -n $VMODULE_LOG_OPTION ]]; then
    cmd="$cmd --v=-3 --vmodule=\"$VMODULE_FILTER\""
  fi
  info $cmd
  $cmd
}

debug(){
  build/gdb-add-index $executable

  local executable=$1/chrome
  local cmd="$executable --ozone-platform-hint=auto --user-data-dir=out/data"
  local debug_cmd="gdb -iex='source -v tools/gdb/gdbinit' --args $cmd"
  info "debug $debug_cmd"
  $debug_cmd
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
  local dirname=$1

  if [[ "$dirname" == "Release" || "$dirname" == "win_nodcheck" ]]; then
    return 0
  fi
  return 1
}

main() {
  select dirname in ${build_dirs[@]}; do
    is_release_version $dirname && format_code
    is_release_version $dirname && update_extension_histograms
    build $dirname && dispatch $dirname
    break
  done
}

main

