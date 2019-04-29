# Gh-md-toc

Generates a github markdown TOC (table of contents).

## Dependency

- [Lua](https://www.lua.org/) 5.1 or greater
- [Lua-cURLv3](https://github.com/Lua-cURL/Lua-cURLv3)
- [argparse](https://github.com/mpeterv/argparse)
- [lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/)

### Installation

For `luajit`/`lua5.1`, used `--lua-version=5.1` with `luarocks`.

```bash
luarocks --local install Lua-cURL
luarocks --local install argparse
luarocks --local install lpeg
```

If necessary, added the paths of luarocks in your `.bashrc`/`.zshrc`

```bash
luarocks path >> ~/.bashrc
```

## Example

`README.md`:

```md
# My project

Lorem ipsum dolor sit amet, consectetur adipiscing elit.

<!-- toc -->
Here will be generated the table of contents.
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

Configure paths if they are not

```bash
eval `luarocks path`
```

Then run `./gh-md-toc.lua --inplace`. The `README.md` file now contains:

```
1. [My project](#my-project)
    1. [First Title](#first-title)
        1. [First Sub Title](#first-sub-title)
        2. [Second Sub Title](#second-sub-title)
    2. [Second Title](#second-title)
```

You can create a TOC without the titles above.

```
$ ./gh-md-toc.lua --after-toc --inplace
1. [First Title](#first-title)
    1. [First Sub Title](#first-sub-title)
    2. [Second Sub Title](#second-sub-title)
2. [Second Title](#second-title)
```

For for more option: `./gh-md-toc.lua -h`
