#!/usr/bin/env lua
local argparse = require'argparse'

local parser = argparse(arg[0], "Github Markdown TOC (table of contents)")
function parser.flag2(_, f, ...)
  local name = f:match'%-%-([-_%w]+)'
  _:flag('--no'..name, 'Disable --'..name)
    :target(name:gsub('%-', '_'))
    :action'store_false'
  return _:flag(f, ...)
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
--TODO parser:option('--', 'Input file'):args('*')
parser:flag2('-a --after-toc', 'Generates the table of contents with what is after value of --label-stop-toc')
parser:option('-i --inplace', 'Edit files in place (makes backup if SUFFIX supplied)')
  :argname'<suffix>':args('?')
  :action(function(args, _, suffix)
    args[_] = #suffix ~= 0 and suffix[1] or ''
  end)
parser:flag('--noinplace', 'Disable --in-place'):target'inplace':action('store_false')
parser:flag2('-p --print', 'Display table of contents on stdout', true)
parser:flag2('-P --print-filename', 'Display file name if --print')
parser:flag2('-g --one-toc', 'With --inplace, insert TOC into the first input file')
parser:option('-f --format', [[Table of contents item format:
  value:
    {idepth}  depth level of the title
    {title}  html title
    {id}  html id attribute
    {i}  title number
    {mdtitle}  original title
    {titleattr}  title attribute
    {*text}  text is duplicated by lvl-1
    {-n:sep1:sep2:...}  concat depth from `n` level with sep1, then sep2, etc.
      with {-} for lvl = 4
        1.2.3.4.
      with {-:\:: * :-} for lvl = 4
        1:2 * 3-4-
      with {-3} for lvl = 4
        3.4.

  condition:
    {?!cond:ok:ko}  if else
    {?cond:ok}  if
    {!cond:ko}  if not

  cond: id, titleattr, isfirst or a the depth level of the title (1,2,etc)

  specialchars:
    \t  tab
    \n  newline
    \x  x (where x is any character) represents the character x
]], '{idepth}. {?!id:[{title}](#{id}{?titleattr: {titleattr}}):{title}}\\n'):argname'<format>'
parser:option('-d --maxdepth', 'Do not extract title at levels greater than level', 6):convert(tonumber)
parser:option('-D --mindepth', 'Do not extract title at levels less than level', 1):convert(tonumber)
parser:option('-e --exclude', 'Exclude title', {}):argname'<title>':count('*'):action(append_key)
parser:option('-r --rename', 'Exclude title', {}):argname'<title> <newtitle>':count('*'):args(2):action(append_key_value)
parser:option('--label-ignore-title', 'Ignore the title under this line', '<!-- toc-ignore -->'):argname'<line>'
parser:option('--label-rename-title', 'Rename the title under this line', '<!-- toc-title (.*) -->'):argname'<line>'
parser:option('--label-start-toc', 'Writes the table of contents between label-start-toc and label-stop-toc (only with --inplace)', '<!-- toc -->'):argname'<line>'
parser:option('--label-stop-toc', 'Writes the table of contents between label-start-toc and label-stop-toc (only with --inplace)', '<!-- /toc -->'):argname'<line>'
parser:option('--url-api', 'Github API URL', 'https://api.github.com/markdown/raw'):argname'<url>'
parser:option('--version', 'Output version information and exit'):action(function()
  print('gh-md-toc 1.0.1') -- TODO
  os.exit(0)
end)

local args = parser:parse()

-- for k,v in pairs(args) do
--   print(k,v,type(v))
--   if type(v) == 'table' then
--     print(#v)
--     for k2,v2 in pairs(v) do
--       print('',k2,v2,type(v2))
--     end
--   end
-- end

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
      t[#t+1] = datas.H[datas.lvl]
    end
  end

  local toprefixlvl = function(x)
    local n = #x
    x = x:rep(5)
    return function(t, datas)
      t[#t+1] = x:sub(1, (datas.lvl-1)*n)
    end
  end

  local toarbonum = function(n, seps)
    x = tonumber(x)
    local sep = seps[#seps] or '.'
    return function(t, datas)
      local ts = {}
      local it = #t + 1
      for i=n,datas.lvl do
        t[it] = datas.H[i]
        t[it+1] = seps[i-n+1] or sep
        it = it + 2
      end
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

  local ifelse = function(is, yes, no)
    return function(t, datas)
      local ts = is(datas) and yes or no
      for _,f in pairs(ts) do
        f(t, datas)
      end
    end
  end

  local toifelse = function(t) return ifelse(table.unpack(t)) end
  local toif = function(is, yes) return ifelse(is, yes, {}) end
  local toifnot = function(is, no) return ifelse(is, {}, no) end

  local lpeg = require'lpeg'
  local C = lpeg.C
  local P = lpeg.P
  local R = lpeg.R
  local S = lpeg.S
  local V = lpeg.V
  local Cc = lpeg.Cc
  local Cf = lpeg.Cf
  local Cg = lpeg.Cg
  local Cs = lpeg.Cs
  local Ct = lpeg.Ct
  local specialchars = {t='\t',n='\n'}
  local tospechar = function(x) return specialchars[x] or x end
  local exclude = function(c)
    return Cs((S'\\' * C(1)) / tospechar ) + (1-S(c))
  end
  local CUntil = function(c) return Ct((V'P' + (exclude('{'..c)^1 + S'{') / tos)^0) end
  local UntilClose = CUntil('}')
  local PrefixLvl = '*' * (exclude'}'^0 / toprefixlvl)
  local ArboNum = '-' * Cf((R'16' + Cc(1)) / tonumber * Ct((S':' * exclude'}:'^0)^0), toarbonum)
  local NameList = P'idepth' / toidepth
    + (P'titleattr' + 'id' + 'title' + 'mdtitle' + 'i') / todata
  local NamedCondList = R'16' / toislvl
    + (P'id' + 'titleattr' + 'isfirst') / toisdata
  local IfElse = '?!' * Ct(NamedCondList * ':' * CUntil(':') * ':' * UntilClose) / toifelse
  local IfYes = '?' * Cf(NamedCondList * ':' * UntilClose, toif)
  local IfNo = '!' * Cf(NamedCondList * ':' * UntilClose, toifnot)

  local M = P{
    "S";
    S = CUntil(''),
    P = '{' * (NameList + PrefixLvl + ArboNum + IfElse + IfYes + IfNo) * '}',
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

function readtitles(filename, contents, titles, tocfound)
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

    if incode and line:find(incode) then
      incode = nil
    else
      incode = line:match'^ ? ? ?(```+)'
      if incode then
        incode = '^ ? ? ?'..incode..'[ \t]*$'
      elseif tocfound then
        if not incode then
          local lvl, title = line:match'^ ? ? ?(#+ )[ \t]*(.*)[ \t]*$'
          local prev = previous
          if not title then
            prev = previous2
            if line:find'^ ? ? ?=+[ \t]*$' then
              title = previous:match'^ ? ? ?([^ ].*)[ \t]*$'
              lvl = '# '
            elseif line:find'^ ? ? ?%-+[ \t]*$' then
              title = previous:match'^ ? ? ?([^ ].*)[ \t]*$'
              lvl = '## '
            end
          end

          if title
          and #lvl < maxdepth+2
          and #lvl > mindepth
          and not excluded[title]
          and prev ~= label_ignore_title
          then
            title = renamed[title] or title
            title = (label_rename_title and prev:match(label_rename_title)) or title
            titles[#titles+1] = lvl .. title
          end
        end
      elseif line == tocstop then
        tocfound = true
      end
    end

    previous2 = previous
    previous = line
  end
end

local nullcontents = setmetatable({},{__len=function() return 0 end})

local filenames = args.input
if #filenames == 0 then
  filenames = {'README.md'}
end

local tocfound = not args.after_toc
local inplace = args.inplace
local one_toc = args.one_toc
local titles = {}
local titles_start_i = {}
local contents_first_file = {}
local contents = inplace and contents_first_file or nullcontents

for _,filename in ipairs(filenames) do
  readtitles(filename, contents, titles, tocfound)
  titles_start_i[#titles_start_i+1] = #titles
  contents = nullcontents
  tocfound = tocfound or one_toc
end

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

  local H = {}
  local datas = {
    i=0,
    H=H,
    isfirst=true
  }
  local toc = {}
  local format = Formater(args.format)
  for lvl, id, title in table.concat(html):gmatch('<h(.)>\n<a id="user%-content%-([^"]*).-</a>(.-)</h%1>\n') do
    lvl = tonumber(lvl)
    datas.i = datas.i + 1
    datas.id = id
    datas.lvl = lvl
    datas.title = title:gsub('<a.->(.-)</a>', '%1'):gsub('\n', '')
    -- TODO datas.mdtitle
    -- TODO datas.titleattr
    H[lvl] = (H[lvl] or 0) + 1
    H[lvl+1] = 0
    toc[#toc+1] = format(datas)
    datas.isfirst = false
  end

  titles = toc
  print_ln = nil

  if inplace then
    local toc_start = args.label_start_toc:gsub('[-?*+%[%]%%()]', '%%%1')
    local toc_stop = args.label_stop_toc:gsub('[-?*+%[%]%%()]', '%%%1')
    local contents, n = table.concat(contents_first_file, '\n'):gsub(
      '('..toc_start..'\n).-('..toc_start..')',
      '%1' .. table.concat(toc):gsub('%%', '%%%%') .. '%2'
    )
    if n ~= 0 then
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
