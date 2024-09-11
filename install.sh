#!/bin/sh

BINARY='/usr/local/bin'

echo "Building ngxl"
go build ngxl.go

echo "Installing ngxl to $BINARY"
install -v ngxl $BINARY

echo "Removing the build"
rm ngxl
