#!/bin/sh

if ! [ "$(id -u)" = 0 ]; then
  echo 'You must be root to do this.' 1>&2
  exit 1
fi

##
# When installing we would install as root, however on
# BSD based systems (such as OSX) this is not a valid
# group / user for install so we use the numberic value
##
ROOT="0"

echo "Install ngxl"
install -g $ROOT -o $ROOT -m 0755 ngxl.rb /usr/local/bin/ngxl
