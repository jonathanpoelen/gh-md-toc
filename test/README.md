# Test

```
# everything is optional
PORT=12000 LUA=luajit ROCKS=--lua-version=5.1 DIFF=cmp ./test.sh
```

# Github API

```bash
curl https://api.github.com/markdown/raw -X "POST" -H "Content-Type: text/plain" -d "$(cat file.md)" > out.txt
```
