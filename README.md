# Gh-md-toc

Generates a github markdown TOC (table of contents).

<!-- toc -->
1. [Features](#features)
2. [Installation](#installation)
    1. [Using LuaRocks](#using-luarocks)
        1. [Error with lua-curl or lpeg](#error-with-lua-curl-or-lpeg)
    2. [Manual installation](#manual-installation)
3. [Example](#example)
    1. [Sample format](#sample-format)
<!-- /toc -->

## Features

- Can insert the TOC directly into the file.
- Fully customizable output format.
- Options to rename or ignore titles.
- Can use a command or another server other than the github API to generate the markdown of titles.

## Installation

- [Lua](https://www.lua.org/) 5.1 or greater
- [Lua-cURLv3](https://github.com/Lua-cURL/Lua-cURLv3)
- [argparse](https://github.com/mpeterv/argparse)
- [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/)

### Using LuaRocks

(Luarocks can be installed with the package manager on most distributions.)

For `luajit`, add `--lua-version=5.1` with `luarocks`.

/!\\ See next chapter if an error occurs with Lua-cURL or LPeg.

```bash
luarocks install --local https://raw.githubusercontent.com/jonathanpoelen/gh-md-toc/master/gh-md-toc-1.5-0.rockspec

# Or in your local directory

luarocks make --local gh-md-toc-1.5-0.rockspec
```

If this is not done, configure your environment with `eval $(luarock path)`. You can now run `gh-md-toc`.

Or you can use `gh-md-toc.sh` to configure the environment and launch `gh-md-toc`.

#### Error with lua-curl or lpeg

On Ubuntu and possibly other distributions, the installation of `Lua-cURL` and` LPeg` fail. If possible, install them from the package manager:

```bash
apt install lua-lpeg
```

`Lua-cURL` is not available and requires more manipulation because it is incompatible with some versions of `libcurl*` packages. Still for Ubuntu, the following commands should alleviate the problem:

```bash
apt install libcurl4-gnutls-dev
ln -s /usr/include/x86_64-linux-gnu/ /tmp/include
luarocks --local install Lua-cURL CURL_DIR=/tmp/
```

As a last resort, you can remove the dependency on Lua-cURL and add `-c` to the `gh-md-toc` launch. If you do not have the `curl` program, you will also need to configure a command with `--cmd-api`.

Now you can restart the installation commands from the previous chapter.

### Manual installation

`lua` and `lua-lpeg` can be installed from the package manager.

`argparse` is a pure Lua library, just configure `LUA_PATH` environment variable.

`lua-curl` is more complicated, but the library can be ignored by adding `-c` or `--use-cmd-api` when launching `gh-md-toc` (you will need to have the `curl` program installed).

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

Run `gh-md-toc --inplace`. The `README.md` file now contains:

```
1. [First Title](#first-title)
    1. [First Sub Title](#first-sub-title)
    2. [Second Sub Title](#second-sub-title)
2. [Second Title](#second-title)
```

By default, the titles above TOC are ignored. But you can take all the titles with the parameter `--all-titles`.

```
$ gh-md-toc --inplace --all-titles
1. [My project](#my-project)
    1. [First Title](#first-title)
        1. [First Sub Title](#first-sub-title)
        2. [Second Sub Title](#second-sub-title)
    2. [Second Title](#second-title)
```

Titles without formatting can be displayed with `gh-md-toc --url-api= --all-titles`.

For for more option: `gh-md-toc -h`

### Sample format

- `--format='{?!1:{<26:-:}\n| {^22:=: {title} } |\n{<26:-:}\n:{<25:-:{?!2:{idepth}: } {title} } {-2}}\n'`

```
--------------------------
| ===== My project ===== |
--------------------------

1 First Title ----------- 1.
  First Sub Title ------- 1.1.
  Second Sub Title ------ 1.2.
2 Second Title ---------- 2.
```

- `--format='{?!1:{title}\n{=0:=:{title}}:{?!2:{title}\n{=0:-:{title}}:{+#} {title}}}\n\n'`

```md
My project
==========

First Title
-----------

## First Sub Title

## Second Sub Title

Second Title
------------
```
