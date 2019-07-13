#!/bin/bash

set -e

if [ $# -lt 3 ] ; then
  echo "$0 major minor revision" >&2
  vers=$(sed -E 's/^  print\('\''gh-[^ ]+ ([^'\'']+).*/\1/;tq;d;:q;q' gh-md-toc.lua)
  echo "current version: $vers"
  exit 1
fi

new_version="$1.$2.$3"
echo update version to $new_version

sed -E "s/^  print\('gh-md-toc .*/  print('gh-md-toc $new_version')/" -i gh-md-toc.lua

git add gh-md-toc.lua
git commit -vm "update version to $new_version"
git tag "v$new_version"
git push --tags
git push
