#!/bin/bash

set -e

eval `luarocks $ROCKS path`

cd "$(dirname "$0")"

TMPDIR="${TMPDIR:-/tmp/}"
OUT="$TMPDIR/gh-md-toc-query.txt"
DIFF="${DIFF:-diff}"
INTS="${*:-1 2 3}"

test1() { ${LUA:-lua} ../gh-md-toc.lua --url-api=localhost:$PORT "$@" ; }
test2() {
  cp "$1" "$TMPDIR/$1"
  test1 \
    --label-ignore-title '<!-- NOOooo -->' \
    -f '{i} {<30:_:{-:/:.:-:.} {title}} {idepth}{?i2:*{?i3:{!i4:*}}}\n' \
    --label-start-toc='<!-- start -->' \
    --label-stop-toc='<!-- stop -->' \
    -ai \
    "$TMPDIR/$1"
  $DIFF "$1".inplace "$TMPDIR/$1" >&2 || err=$(($err+1))
}
test3() { test1 "$@" ; }

err=0
PORT=12010

for i in $INTS ; do
  echo $i
  socat tcp-l:$PORT,reuseaddr 'system:cat response'$i'.txt!!open:'"$OUT",creat,trunc &
  $DIFF output$i.txt <(test$i test$i.md) || err=$(($err+1))
  $DIFF input$i.txt "$OUT" || err=$(($err+1))
done

if [ $err -ne 0 ]; then
  echo KO = $err
  kill %1 ||:
  exit $err
fi
