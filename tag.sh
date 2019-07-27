#!/bin/bash

set -e

if [ $# -lt 3 ] ; then
  echo "$0 major minor revision" >&2
  vers=$(sed -E 's/^  print\('\''gh-[^ ]+ ([^'\'']+).*/\1/;tq;d;:q;q' gh-md-toc.lua)
  echo "current version: $vers"
  exit 1
fi

TMPDIR=${TMPDIR:-/tmp}
EDITOR=${EDITOR:-nano}

projectname='gh-md-toc'
change="$TMPDIR/gh-md-toc-change.txt"
oldfile=(*.rockspec)
oldfile=${oldfile[0]}
old_rock_vers=${oldfile:$((${#projectname}+1)):-9}
new_rock_vers="$1.$2-$3"
new_std_vers="$1.$2.$3"
newfile="$projectname-$new_rock_vers.rockspec"

echo "# Change Log

## [v$new_std_vers](https://github.com/jonathanpoelen/gh-md-toc/tree/v$new_std_vers) ($(date +'%Y-%m-%d'))

- " > "$change"
"$EDITOR" "$change"
tail -n+2 CHANGELOG.md >> "$change"
cat "$change"
mv "$change" CHANGELOG.md

sed -i "s/^  print('gh-md-toc .*/  print('gh-md-toc $new_std_vers')/" gh-md-toc.lua
sed -i "s/$old_rock_vers/$new_rock_vers/;s/${old_rock_vers/-/\\.}/$new_std_vers/" "$oldfile"
sed -i "s/${oldfile//./\\.}/$newfile/" README.md
mv "$oldfile" "$newfile"

git add "$oldfile" "$newfile" README.md CHANGELOG.md gh-md-toc.lua
git commit -vm "update version to $new_std_vers"
git tag "v$new_std_vers"
git push --tags
git push
