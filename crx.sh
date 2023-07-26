#!/bin/bash

# 打印使用帮助
function usage() {
  echo "Usage:"
  echo "  cmd crxid <base64_pubkey>" 
  echo "  cmd allowid <base64_pubkey>"
}

# 解析base64编码的公钥
function parse_pubkey() {
  echo "$1" | base64 -d
}

# crxid子命令
function crxid() {
  id=$(parse_pubkey "$1" | shasum -a 256 | head -c32 | tr 0-9a-f a-p)
  echo "crxid: " ${id}  
}

# allowid子命令
function allowid() {
  id=$(parse_pubkey "$1" | shasum -a 256 | head -c32 | tr 0-9a-f a-p)
  echo "allowid: " $(sha1sum <(echo -n $id) | tr a-z A-z)
}

# 检查参数个数
if [ $# -ne 2 ]; then
  usage
  exit 1
fi

# 解析子命令和参数
subcommand=$1
pubkey=$2

# 调用对应的子命令
case $subcommand in
  crxid) crxid ${pubkey} ;;
  allowid)  allowid ${pubkey} ;;
  *)
    usage
    exit 1
    ;;
esac
