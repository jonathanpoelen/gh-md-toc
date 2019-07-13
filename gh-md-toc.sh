#!/bin/sh
eval `luarocks path`
"$(dirname "$0")"/gh-md-toc.lua "$@"
