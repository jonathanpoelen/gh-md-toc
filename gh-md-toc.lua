#!/usr/bin/env lua

local argparse = require'argparse'

local parser = argparse(arg[0], "Github Markdown TOC (table of contents)")
function parser.flag2(_, f, ...)
  local name = f:match'%-%-([-_%w]+)'
  print(name)
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
--[[TODO]]parser:option('-n --empty-id-format', 'Table of contents item format for an empty id', '{idepth}. [{title}](#{id})'):argname'<format>'
--[[TODO]]parser:option('-f --format', 'Table of contents item format', '{idepth}. [{title}](#{id})'):argname'<format>'
--[[TODO]]parser:option('-f1 --format1', 'Same -f, but for only h1'):argname'<format>'
--[[TODO]]parser:option('-f2 --format2', 'Same -f, but for only h2'):argname'<format>'
--[[TODO]]parser:option('-f3 --format3', 'Same -f, but for only h3'):argname'<format>'
--[[TODO]]parser:option('-f4 --format4', 'Same -f, but for only h4'):argname'<format>'
--[[TODO]]parser:option('-f5 --format5', 'Same -f, but for only h5'):argname'<format>'
--[[TODO]]parser:option('-f6 --format6', 'Same -f, but for only h6'):argname'<format>'
parser:option('-d --maxdepth', 'Do not extract title at levels greater than level', 6):convert(tonumber)
parser:option('-D --mindepth', 'Do not extract title at levels less than level', 1):convert(tonumber)
--[[TODO]]parser:flag2('--origin-md', 'Title from original mardown, otherwise is HTML format (HTML by default)')
--[[TODO]]parser:flag2('--html-title', 'Add HTML title attribute (enabled by default)', true)
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

for k,v in pairs(args) do
  print(k,v,type(v))
  if type(v) == 'table' then
    print(#v)
    for k2,v2 in pairs(v) do
      print('',k2,v2,type(v2))
    end
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
  local pre='                     '
  local toc = {}
  for lvl, id, title in table.concat(html):gmatch('<h(.)>\n<a id="([^"]*).-</a>(.-)</h%1>\n') do
    lvl = tonumber(lvl)
    title = title:gsub('<a.->(.-)</a>', '%1'):gsub('\n', '')
    H[lvl] = (H[lvl] or 0) + 1
    H[lvl+1] = 0
    toc[#toc+1] = string.format('%s%d. [%s](#%s)\n',
      pre:sub(0, (lvl-1)*4),
      H[lvl],
      title,
      id:sub(14)
    )
  end

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
  print(is_print_filename, type(is_print_filename))
  if is_print_filename == nil and #filenames > 1 then
    is_print_filename = true
  end
  local istart = 1
  for i,iend in ipairs(titles_start_i) do
    if is_print_filename then
      print((i == 1 and '' or '\n') .. filenames[i] .. '\n')
    end
    print(table.concat(titles, '\n', istart, iend))
    istart = iend+1
  end
end
