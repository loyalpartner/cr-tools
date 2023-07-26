#!/bin/sh

api_dirs=(
  extensions/common/api
  chrome/common/extensions/api
  chrome/common/apps/platform_apps/api
)

rg "$@" $api_dirs -g '*.{idl,json}' 
