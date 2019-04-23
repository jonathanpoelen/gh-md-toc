#!/usr/bin/env lua

local curl = require'cURL'

function usage(status)
  print(arg[0] .. [[ -u -a [README.md]
  -a  Summarise full file, otherwise only titles after <!-- /toc -->
  -u  Update file, replaces the toc between <!-- toc --> and <!-- /toc -->
]])
  os.exit(status or 0)
end

local foundtoc = false
local update = false
local iarg= #arg + 1

for i=1,#arg do
  local opt = arg[i]
  if opt == '-h' or opt == '-?' or opt == '--help' then
    usage()
  elseif opt == '-a' then
    foundtoc = true
  elseif opt == '-u' then
    update = true
  else
    iarg=i
    break
  end
end

if #arg - iarg > 0 then
  usage(1)
end


local README = arg[iarg] or 'README.md'

local f, err = io.open(README)
if not f then
  error(err)
end


local titles = {}
local contents = update and {} or setmetatable({},{__len=function() return 0 end})
local incode = false

while true do
  local line = f:read()
  if not line then
    break
  end

  contents[#contents+1] = line

  if line:find'^```' then
    incode = not incode
  elseif foundtoc then
    if not incode and line:find'^#' then
      titles[#titles+1] = line
    end
  elseif line == '<!-- /toc -->' then
    foundtoc = true
  end
end


local html = {}
curl.easy{ 
  url='https://api.github.com/markdown/raw',
  writefunction=function(s) html[#html+1] = s end,
  httpheader={
    'User-Agent: toc-md',
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


toc = table.concat(toc)
print(toc)

if update then
  local contents = table.concat(contents, '\n'):gsub(
    '(<!%-%- toc %-%->\n).-(<!%-%- /toc %-%->)',
    '%1' .. toc .. '%2'
  )
  io.open(README, 'w'):write(contents .. '\n')
end
