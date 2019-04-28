#!/bin/bash

set -e

eval `luarocks $ROCKS path`

cd "$(dirname "$0")"

OUT="${TMPDIR:-/tmp/}/gh-md-toc-query.txt"
DIFF="${DIFF:-diff}"
PORT=${PORT:-12010}
err=0

socat tcp-l:$PORT,reuseaddr 'system:cat response1.txt!!open:'"$OUT",creat,trunc &
$DIFF output1.txt <(${LUA:-lua} ../gh-md-toc.lua --url-api=localhost:$PORT test1.md) || err=1
$DIFF input1.txt "$OUT" || err=1

exit $err
