#!/bin/sh
eval `luarocks path`
"$(dirname "$(realpath "$0")")"/gh-md-toc.lua "$@"
