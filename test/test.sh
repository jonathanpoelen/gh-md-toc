#!/bin/bash

set -e

LUA=${LUA:-lua}
$LUA -v

eval `luarocks $ROCKS path`

cd "$(dirname "$0")"

TMPDIR="${TMPDIR:-/tmp/}"
OUT="$TMPDIR/gh-md-toc-query.txt"
DIFF="${DIFF:-diff}"
INTS="${*:-1 2 3 4}"

test1() {
  local i=${1:-1}
  socat tcp-l:$PORT,reuseaddr 'system:cat response'$i'.txt!!open:'"$OUT",creat,trunc &
  shift
  sleep .4
  $LUA ../gh-md-toc.lua --url-api=localhost:$PORT -a "${@:-test1.md}"
  $DIFF input$i.txt "$OUT" || err=$(($err+1))
}
test2() {
  local fname=test2.md
  cp "$fname" "$TMPDIR/$fname"
  test1 2 \
    --label-ignore-title '<!-- NOOooo -->' \
    -f '{i} {<30:_:{-:/:.:-:.} {title}} {idepth}{?i2:*{?i3:{!i4:*}}}\n' \
    --label-start-toc='<!-- start -->' \
    --label-stop-toc='<!-- stop -->' \
    --no-all-titles -i \
    "$TMPDIR/$fname"
  $DIFF "$fname".inplace "$TMPDIR/$fname" >&2 || err=$(($err+1))
}
test3() { test1 3 "test3.md" ; }
test4() { $LUA ../gh-md-toc.lua -c --cmd-api='./cmd4.sh' input4.txt input4.txt ; }

err=0
PORT=12010

for i in $INTS ; do
  echo -e "\e[31mtest$i\e[0m"
  $DIFF output$i.txt <(test$i) || err=$(($err+1))
done

if [ $err -ne 0 ]; then
  echo -----------
  echo KO = $err
  kill %1 ||:
  exit $err
fi
