# Dependency

- Lua
- [Lua-cURLv3](https://github.com/Lua-cURL/Lua-cURLv3)
- argparse

# Installation

```bash
luarocks install Lua-cURL
luarocks install argparse
```

<!-- luarocks install Lua-cURL --server=https://luarocks.org/dev -->

or for luajit:

```bash
luarocks --lua-version 5.1 install Lua-cURL
```

Then

```bash
eval `luarocks path`
```

# Usage

```bash
./gh-md-toc [OPTIONS] [README.md [...]]
```
