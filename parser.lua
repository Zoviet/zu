local htmlparser = require("htmlparser")
local lfs = require("lfs")
local cURL = require("cURL")
local iconv = require("iconv")
local json = require("cjson")
cd, err = iconv.new('UTF-8', 'WINDOWS-1251')

-- настройки

htmlparser_looplimit = 10000 -- лимит для парсинга

local url = 'https://classinform.ru/classifikator-vidov-razreshennogo-ispolzovaniia-zemelnykh-uchastkov.html' -- исходный url

local results = {}

local csvfile = assert(io.open('cvrzu.csv', "w"))

local function get(url)
	local str=''
	local headers = {
		'Content-type: text/html',
		'User-Agent: Mozilla/5.0'
	}
	local c = cURL.easy{		
		url = url,	
		httpheader  = headers,	
		writefunction = function(st)	
			str = str..st
		end
	}
	local ok, err = c:perform()	
	c:close()	
	if not ok then return nil, err end
	return cd:iconv(str)
end

local function parse(url,first)
	local result = {}
	local root = htmlparser.parse(get(url))
	local divs = root:select(".full_width")	
	for _,div in ipairs(divs) do	
		local items = div:select("a")	
		if items and items[2] and string.find(items[1]:getcontent(),'%d+%.%d+') then 		
			local code = items[1]:getcontent():gsub('- ','')
			local name = items[2]:getcontent()
			if not first then csvfile:write(';'..code..';'..name..'\n') end
			result[code] = {name = name, url ='https:'..items[1].attributes["href"]}
		end
	end
	return result
end

local function save(filename,data)
	local file = io.open(filename,'w')
	file:write(tostring(data))
	file:close()
end

results = parse(url,true)

for code,data in pairs(results) do
	csvfile:write(code..';;'..data.name..'\n')
	results[code].sub = parse(data.url)
end

csvfile:close()

save('cvrzu.json',json.encode(results))
