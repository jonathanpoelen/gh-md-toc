#!/bin/bash

./test.sh
LUA=luajit ROCKS=--lua-version=5.1 ./test.sh
