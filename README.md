# Gh-md-toc

Generates a github markdown TOC (table of contents).

<!-- toc -->
1. [Installation](#installation)
    1. [Using LuaRocks](#using-luarocks)
        1. [Note for Ubuntu and Debian](#note-for-ubuntu-and-debian)
2. [Example](#example)
<!-- /toc -->

## Installation

- [Lua](https://www.lua.org/) 5.1 or greater
- [Lua-cURLv3](https://github.com/Lua-cURL/Lua-cURLv3)
- [argparse](https://github.com/mpeterv/argparse)
- [lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/)

### Using LuaRocks

For `luajit`, add `--lua-version=5.1` with `luarocks`.

/!\\ See next chapter if an error occurs with Lua-cURL or lpeg.

```bash
luarocks --local install Lua-cURL
luarocks --local install argparse
luarocks --local install lpeg
```

Configure your environment with `eval $(luarock path)` before running `gh-md-toc.lua`.

Or you can use `gh-md-toc.sh` to configure the environment and launch `gh-md-toc.lua`.

#### Note for Ubuntu and Debian

Install `libcurl4-gnutls-dev` and run

```bash
ln -s /usr/include/x86_64-linux-gnu/ /tmp/include
luarocks --local install Lua-cURL CURL_DIR=/tmp/
```

Install `lua-lpeg` with `apt` if luarocks fails.


## Example

`README.md`:

```md
# My project

<!-- toc -->
Here will be inserted the table of contents with `--inplace`.
<!-- /toc -->

## First Title

Proin suscipit vestibulum lacinia. Praesent in ultricies nunc.

### First Sub Title

Quisque leo eros, feugiat ut magna a, tristique iaculis ligula.

### Second Sub Title

Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.

## Second Title

Cras condimentum ultricies vehicula. Integer sed nisi vel metus lobortis scelerisque eu dapibus magna.
```

Run `./gh-md-toc.lua.sh --inplace`. The `README.md` file now contains:

```
1. [First Title](#first-title)
    1. [First Sub Title](#first-sub-title)
    2. [Second Sub Title](#second-sub-title)
2. [Second Title](#second-title)
```

By default, the titles above TOC are ignored. But you can take all the titles with the parameter `--all-title`.

```
$ ./gh-md-toc.lua --inplace --all-title
1. [My project](#my-project)
    1. [First Title](#first-title)
        1. [First Sub Title](#first-sub-title)
        2. [Second Sub Title](#second-sub-title)
    2. [Second Title](#second-title)
```

For for more option: `./gh-md-toc.sh -h`
