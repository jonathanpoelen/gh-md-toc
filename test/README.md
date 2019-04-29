# Test

```
# everything is optional
LUA=luajit ROCKS=--lua-version=5.1 DIFF=cmp ./test.sh [num test...]
```

# Github API

```bash
curl https://api.github.com/markdown/raw -X "POST" -H "Content-Type: text/plain" -d "$(cat file.md)" > out.txt
```
