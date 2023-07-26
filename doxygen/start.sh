#!/usr/bin/env bash

CONDIG_DIR=$(pwd)

CHROMIUM_SRC=${CHROMIUM_SRC:-$HOME/modous/R113/chromium/src}

cd $CHROMIUM_SRC

docs=(extension)

for doc in ${docs[@]}; do
  mkdir -p $HOME/doxygen/$doc
  while true; do
    running=$(jobs -r | wc -l)
    if [ "$running" -lt "5" ]; then
      doxygen  $CONDIG_DIR/$doc.DOXYFILE
      break
    else
      wait -n
    fi
  done
done
