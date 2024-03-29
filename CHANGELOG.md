# Change Log

## [v2.0.0](https://github.com/jonathanpoelen/gh-md-toc/tree/v2.0.0) (2022-10-08)

- fix parsing with latest github api
- add `--completion`
- add `--print-api-result`
- add `{md}` placeholder with `--cmd-api`
- replace `--use-cmd-api` with `--use-cmd`
- replace `--use-url-api` with `--use-lua-curl`
- replace `--no-` prefix instead of `--no` for inversion flag

## [v1.6.1](https://github.com/jonathanpoelen/gh-md-toc/tree/v1.6.1) (2020-11-11)

- fix `--use-cmd-api` with a title wich contains a `'`
- fallback to `--cmd-api` when lua-curl is not found

## [v1.6.0](https://github.com/jonathanpoelen/gh-md-toc/tree/v1.6.0) (2020-08-21)

- add `--use-url-api` that disable `--use-cmd-api`
- `--use-cmd-api` implicitly enabled by `--cmd-api`
- `--use-url-api` implicitly enabled by `--url-api`

## [v1.5.0](https://github.com/jonathanpoelen/gh-md-toc/tree/v1.5.0) (2020-01-15)

- `--all-title` becomes `--all-titles`

## [v1.4.1](https://github.com/jonathanpoelen/gh-md-toc/tree/v1.4.1) (2019-07-30)

- fix: last title is lost
- fix: unknown table.move with lua52/luajit

## [v1.4.0](https://github.com/jonathanpoelen/gh-md-toc/tree/v1.4.0) (2019-07-27)

- new format: `{=0:pad:expr}` padding of the size of expr
- enables `--all-title` if no TOC label is found

## [v1.3.0](https://github.com/jonathanpoelen/gh-md-toc/tree/v1.3.0) (2019-07-14)

- `--after-toc`/`-a` becomes `--all-title`/`-a`: the behavior is reversed
- add `--cmd-api` and `--cmd-rather-than-url`
- rockspec file for an installation with `luarocks`

## [v1.2.0](https://github.com/jonathanpoelen/gh-md-toc/tree/v1.2.0) (2019-07-13)

- add `{htmltitle}` with `--format`
- ignore title within a code block

## [v1.1.0](https://github.com/jonathanpoelen/gh-md-toc/tree/v1.1.0) (2019-04-29)

- fix `--inplace` always on
- add `{=n:pad:expr}` with `--format`
- support of utf8 with alignement
