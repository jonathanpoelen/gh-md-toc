#!/usr/bin/env lua
local argparse = require'argparse'

local parser = argparse(arg[0], "Github Markdown TOC (table of contents)")
function parser.flag2(_, f, desc, default)
  local name = f:match'%-%-([-_%w]+)'
  _:flag(f, desc)
  return _:flag('--no'..name, 'Disable --'..name, default)
    :target(name:gsub('%-', '_'))
    :action'store_false'
end

function append_key(args, _, x)
  local t = args[_]
  t[x] = true
end

function append_key_value(args, _, xs)
  local t = args[_]
  t[xs[1]] = xs[2]
end

parser:argument('input', 'Input file'):args'*'
parser:flag2('-a --after-toc', 'Generates the table of contents with what is after value of --label-stop-toc')
parser:flag2('-g --one-toc', '--after-toc only for the first file')
parser:flag2('-i --inplace', 'Edit files in place')
parser:option('-s --suffix', 'backup rather editing file (involved --inplace)', '')
  :argname'<suffix>'
  :action(function(args, _, suffix)
    args.inplace = true
    args.suffix = suffix
  end)
parser:flag2('-p --print', 'Display table of contents on stdout', true)
parser:flag2('-P --print-filename', 'Display file name if --print')
parser:option('-f --format', [[Table of contents item format:
  value:
    {idepth}  depth level of the title
    {title}  html title
    {id}  html id attribute
    {i}  title number
    {i1} to {i6}  title number of first level, second level, etc
    {mdtitle}  original title
    {*text}  text is duplicated by depth-1
      with {*--} and depth = 4
        ------
    {n*text}  text is duplicated by depth-n
    {+text}  text is duplicated by depth-min_depth_title
    {-n:sep1:sep2:...}  concat depth from `n` level with sep1, then sep2, etc.
      with {-} (equivalent to {-1:.}) and depth = 4
        1.2.3.4.
      with {-:\:: * :-:} and depth = 4
        1:2 * 3-4
      with {-3} and depth = 4
        3.4.
    {>n:pad:expr} align right
    {<n:pad:expr} align left
    {^n:pad:expr} align center

  condition:
    {?!cond:ok:ko}  if else
    {?cond:ok}  if
    {!cond:ko}  if not

  cond: id, isfirst, i2 to i6 and the depth level of the title (1 to 6)

  specialchars:
    \t  tab
    \n  newline
    \x  x (where x is any character) represents the character x
]], '{+    }{idepth}. {?!id:[{title}](#{id}):{title}}\\n'):argname'<format>'
parser:option('-d --maxdepth', 'Do not extract title at levels greater than level', 6):convert(tonumber)
parser:option('-D --mindepth', 'Do not extract title at levels less than level', 1):convert(tonumber)
parser:option('-e --exclude', 'Exclude a title', {}):argname'<title>':count('*'):action(append_key)
parser:option('-r --rename', 'Rename a title', {}):argname'<title> <newtitle>':count('*'):args(2):action(append_key_value)
parser:option('--label-ignore-title', 'Ignore the title under this line', '<!-- toc-ignore -->'):argname'<line>'
parser:option('--label-rename-title', 'Rename the title under this line that match the lua pattern', '<!%-%- toc%-title (.+) %-%->'):argname'<line>'
parser:option('--label-start-toc', 'Writes the table of contents between label-start-toc and label-stop-toc (only with --inplace)', '<!-- toc -->'):argname'<line>'
parser:option('--label-stop-toc', 'Writes the table of contents between label-start-toc and label-stop-toc (only with --inplace)', '<!-- /toc -->'):argname'<line>'
parser:option('--url-api', 'Github API URL', 'https://api.github.com/markdown/raw'):argname'<url>'
parser:option('--version', 'Output version information and exit'):action(function()
  print('gh-md-toc 1.0.1') -- TODO
  os.exit(0)
end)

local args = parser:parse()


local lpeg = require'lpeg'
local C = lpeg.C
local P = lpeg.P
local R = lpeg.R
local S = lpeg.S
local V = lpeg.V
local Cc = lpeg.Cc
local Cf = lpeg.Cf
local Cs = lpeg.Cs
local Ct = lpeg.Ct


local mindepth = args.mindepth
local maxdepth = args.maxdepth
local toc_stop = args.label_stop_toc
local excluded = args.exclude
local renamed = args.rename
local label_ignore_title = args.label_ignore_title
local label_rename_title = args.label_rename_title
if #label_ignore_title == 0 then
  label_ignore_title = nil
end
label_rename_title = label_rename_title and '^'..label_rename_title..'$' or nil

local MdPrefix = P' '^-3
local MdSpace = S' \t'
local MdSpace0 = MdSpace^0
local MdSpace1 = MdSpace^1
local MdNotSpace1 = (1-MdSpace)^1
local MdSuffix = MdSpace0 * P(-1)
local MdCode = MdPrefix * C(P'`'^3)
local MdTitleText = MdSpace0 * C(MdNotSpace1 * (MdSpace1 * MdNotSpace1)^0) * MdSuffix
local MdTitle = MdPrefix * C(S'#'^1 * ' ') * MdTitleText
local MdAltH1 = MdPrefix * S'='^1 * MdSuffix
local MdAltH2 = MdPrefix * S'-'^1 * MdSuffix
local MdAltTitle = MdPrefix * MdTitleText

function readtitles(filename, contents, titles, tocfound, min_depth_title)
  local f, err = io.open(filename)
  if not f then
    error(err)
  end

  local incode = false
  local previous, previous2 = '', ''

  while true do
    local line = f:read()
    if not line then
      break
    end

    contents[#contents+1] = line

    if incode and incode:match(line) then
      incode = nil
    else
      incode = MdCode:match(line)
      if incode then
        incode = MdPrefix * P(incode) * MdSuffix
      elseif tocfound then
        if not incode then
          local lvl, title = MdTitle:match(line)
          local prev = previous
          if not title then
            prev = previous2
            if MdAltH1:match(line) then
              title = MdAltTitle:match(previous)
              lvl = '# '
            elseif MdAltH2:match(line) then
              title = MdAltTitle:match(previous)
              lvl = '## '
            end
          end

          if title then
            local lvllen = #lvl
            if lvllen < maxdepth+2 and lvllen > mindepth
            and not excluded[title] and prev ~= label_ignore_title
            then
              title = renamed[title] or title
              title = (label_rename_title
                       and prev:match(label_rename_title)
                      ) or title
              titles[#titles+1] = lvl .. title
              if lvllen < min_depth_title then
                min_depth_title = lvllen
              end
            end
          end
        end
      elseif line == toc_stop then
        tocfound = true
      end
    end

    previous2 = previous
    previous = line
  end

  return min_depth_title
end

local nullcontents = setmetatable({},{__len=function() return 0 end})

local filenames = args.input
if #filenames == 0 then
  filenames = {'README.md'}
end

local tocfound = not args.after_toc
local inplace = args.inplace and args.suffix
local one_toc = args.one_toc
local titles = {}
local titles_start_i = {}
local contents_first_file = {}
local contents = inplace and contents_first_file or nullcontents
local min_depth_title = 7

for _,filename in ipairs(filenames) do
  min_depth_title = readtitles(filename, contents, titles, tocfound, min_depth_title)
  titles_start_i[#titles_start_i+1] = #titles
  contents = nullcontents
  tocfound = tocfound or one_toc
end
min_depth_title = min_depth_title - 1

local url_api = args.url_api
local print_ln = '\n'

if url_api ~= '' then
  local curl = require'cURL'

  local html = {}
  curl.easy{
    url=url_api,
    writefunction=function(s) html[#html+1] = s end,
    httpheader={
      'User-Agent: gh-md-toc',
      'Content-Type: text/plain'
    },
    postfields=table.concat(titles, '\n'),
  }
  :perform()
  :close()

  function Formater(str)
    local tos = function(x)
      return function(t)
        t[#t+1] = x
      end
    end

    local todata = function(x)
      return function(t, datas)
        t[#t+1] = datas[x] or ''
      end
    end

    local toidepth = function()
      return function(t, datas)
        t[#t+1] = datas.hn[datas.lvl]
      end
    end

    local tohi = function(i)
      i = tonumber(i)
      return function(t, datas)
        t[#t+1] = i <= datas.lvl and datas.hn[datas.lvl] or 0
      end
    end

    local tomdtitle = function()
      return function(t, datas)
        t[#t+1] = datas.titles[datas.i]:sub(datas.lvl+2)
      end
    end

    local toprefixlvl = function(ge, x)
      local n = #x
      x = x:rep(5)
      return function(t, datas)
        local lvl = datas.lvl
        if lvl >= ge then
          t[#t+1] = x:sub(1, (lvl-ge)*n)
        end
      end
    end

    local tominprefixlvl = function(x) return toprefixlvl(min_depth_title, x) end

    local toarbonum = function(n, seps)
      x = tonumber(x)
      local sep = seps[#seps] or '.'
      return function(t, datas)
        local ts = {}
        local it = #t + 1
        for i=n,datas.lvl do
          t[it] = datas.hn[i]
          t[it+1] = seps[i-n+1] or sep
          it = it + 2
        end
      end
    end

    local topad = function(a, n, s, xs)
      local floor = math.floor -- rather that // for lua 5.1 compatibility
      s = (#s == 0 and ' ' or s)
      s = s:rep(floor((n+#s) / #s))
      local pad = (a == '<') and function(contents)
        local len = #contents
        return len < n and contents .. s:sub(1, n - len) or contents
      end or (a == '>') and function(contents)
        local len = #contents
        return len < n and s:sub(1, n - len) .. contents or contents
      end or function(contents)
        local len = #contents
        if len < n then
          local dist = n - len
          local dist2 = floor(dist / 2)
          contents = s:sub(1, dist2)
                  .. contents
                  .. s:sub(1, dist - dist2)
        end
        return contents
      end

      return function(t, datas)
        local ts = {}
        for _,f in pairs(xs) do
          f(ts, datas)
        end
        t[#t+1] = pad(table.concat(ts))
      end
    end

    local toisdata = function(x)
      return function(datas)
        return datas[x]
      end
    end

    local toislvl = function(x)
      x = tonumber(x)
      return function(datas)
        return datas.lvl == x
      end
    end

    local toislelvl = function(i)
      i = tonumber(i)
      return function(datas)
        return i <= datas.lvl
      end
    end

    local toifelse = function(is, yes, no)
      return function(t, datas)
        local ts = is(datas) and yes or no
        for _,f in pairs(ts) do
          f(t, datas)
        end
      end
    end

    local toif = function(is, yes) return toifelse(is, yes, {}) end
    local toifnot = function(is, no) return toifelse(is, {}, no) end


    local specialchars = {t='\t',n='\n'}
    local tospechar = function(x) return specialchars[x] or x end
    local exclude = function(c)
      return Cs(S'\\' * C(1) / tospechar) + (1-S(c))
    end
    local exclude0 = function(c) return Cs(exclude(c)^0) end
    local CPUntil = function(c)
      return Ct((V'P' + Cs(exclude('{'..c)^1 + S'{') / tos)^0)
    end
    local UntilClose = CPUntil('}')
    local MulLvl = (R'16' + Cc(1)) / tonumber * '*' * exclude0'}' / toprefixlvl
    local MulMinLvl = '+' * exclude0'}' / tominprefixlvl
    local ArboNum = '-' * Cf((R'16' + Cc(1)) / tonumber * Ct((S':' * exclude0'}:')^0), toarbonum)
    local Padding = (
        C(S'<^>' )
      * (R'09'^1 / tonumber) * S':'
      * exclude0':' * S':'
      * UntilClose
    ) / topad
    local NameList = P'idepth' / toidepth
      + P'mdtitle' / tomdtitle
      + 'i' * (R'16' / tohi)
      + (P'id' + 'title' + 'i') / todata
    local NamedCondList = R'16' / toislvl
      + 'i' * (R'26' / toislelvl)
      + (P'id' + 'isfirst') / toisdata
    local IfElse = '?!' * (NamedCondList * ':' * CPUntil(':') * ':' * UntilClose / toifelse)
    local IfYes = '?' * (NamedCondList * ':' * UntilClose / toif)
    local IfNo = '!' * (NamedCondList * ':' * UntilClose / toifnot)

    local M = P{
      "S";
      S = CPUntil(''),
      P = '{' * (
        NameList + MulLvl + MulMinLvl + ArboNum + Padding
      + IfElse + IfYes + IfNo
      ) * '}',
    }

    local formats = M:match(str)

    return function(datas)
      local r = {}
      for _,f in ipairs(formats) do
        f(r, datas)
      end
      return table.concat(r)
    end
  end

  local format = Formater(args.format)
  local hn = {}
  local datas = {
    i=0,
    hn=hn,
    titles=titles,
    isfirst=true,
  }
  local toc = {}
  local Cgsub = function(patt, repl) return Cs((patt / repl + 1)^0) end
  local Una = Cgsub('<a' * (1-S'>')^0 * '>' * C((1-P'</a>')^0) * '</a>',
                    function(x) return x end)
  local GhMdTitle = ((2 * C(1) * 22 * C((1-S'"')^0) * ((1-S'>')^1 * '>')^-4 * C((1-(S'\n'^-1 * P'</h' * R'16'))^1) * S'\n'^-1 * 6)
  / function(lvl, id, title)
    lvl = tonumber(lvl)
    datas.i = datas.i + 1
    datas.id = id
    datas.lvl = lvl
    datas.title = Una:match(title)
    hn[lvl] = (hn[lvl] or 0) + 1
    hn[lvl+1] = 0
    toc[#toc+1] = format(datas)
    datas.isfirst = false
  end)^1
  GhMdTitle:match(table.concat(html))

  titles = toc
  print_ln = nil

  if inplace then
    local toc_start = args.label_start_toc
    local toc_stop = args.label_stop_toc
    local ReplaceToc = Cs(
      (1 - P(toc_start))^0
    * P(toc_start) * S'\n'
    * ((1-P(toc_stop))^0 / table.concat(toc))
    * P(toc_stop)
    * (1-S'')^0)
    local filecontents = table.concat(contents_first_file, '\n')
    local contents = ReplaceToc:match(filecontents)
    if contents then
      io.open(filenames[1]..inplace, 'w'):write(contents .. '\n')
    end
  end
end

if args.print then
  local is_print_filename = args.print_filename
  if is_print_filename == nil and #filenames > 1 then
    is_print_filename = true
  end
  local istart = 1
  for i,iend in ipairs(titles_start_i) do
    if is_print_filename then
      print((i == 1 and '' or '\n') .. filenames[i] .. '\n')
    end
    local out = table.concat(titles, print_ln, istart, iend)
    if out:byte(-1) ~= 10 --[[\n]] then
      print(out)
    else
      io.stdout:write(out)
    end
    istart = iend+1
  end
end
