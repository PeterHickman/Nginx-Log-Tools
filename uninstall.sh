#!/bin/sh

if ! [ "$(id -u)" = 0 ]; then
  echo 'You must be root to do this.' 1>&2
  exit 1
fi

remove_file() {
  if [ -r "$1" ]; then
    echo "Removing $1"
    rm -f "$1"
  fi
}

remove_file /usr/local/bin/ngxl
