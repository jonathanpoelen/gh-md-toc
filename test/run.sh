#!/bin/bash

cd "$(dirname "$0")"

./test.sh
LUA=luajit ROCKS=--lua-version=5.1 ./test.sh
