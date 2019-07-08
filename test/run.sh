#!/bin/bash

cd "$(dirname "$0")"

echo lua:
./test.sh "$@" && echo -e "Ok\n" || err=$?
echo luajit:
LUA=luajit ROCKS=--lua-version=5.1 ./test.sh "$@" && echo Ok || err=$?
exit $err
