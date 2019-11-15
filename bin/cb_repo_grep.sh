#!/usr/bin/env bash

cd ~/Source/optoro-cookbooks/

for r in `find . -maxdepth 1 -name "optoro_*"`; do
  cd $r

  if git grep --quiet $1
  then
    echo "Hit in $r"
  fi

  cd ..
done
