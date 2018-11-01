require("stream")
require("dataparser");
require("process");
require("terminal")
require("strutil")
require("net")
require("time")


--Some Global Variables
today_items=0
week_items=0
total_items=0


function ParseReleaseRSS(N)
local Package={}
local T, token

Package.name="";
T=strutil.TOKENIZER( N:value("title"), "\\S")
token=T:next()
while (strutil.strlen(T:remaining()) > 0) 
do
	Package.name=Package.name..token.." "
	token=T:next()
end

Package.name=strutil.stripTrailingWhitespace(Package.name)

if token ~= nil then Package.version=token else Package.version="" end
Package.link=N:value("link")
Package.date=time.tosecs("%a, %d %b %Y %H:%M:%S", N:value("pubDate"))
return(Package)
end


function ParseFreshcodeItem(N)
local Package={}
local T

Package=ParseReleaseRSS(N)
T=strutil.TOKENIZER( N:value("description"), "Changes:")
Package.description=string.gsub(T:next(), "\n", " ")
Package.feed="freshcode"

return(Package)
end


function ParseFreshcode(items)

local S, P, doc, item;

S=stream.STREAM("http://freshcode.club/projects.rss");
doc=S:readdoc();
P=dataparser.PARSER("rss",doc);

N=P:open("/")
while N ~=nil
do
	if (string.sub(N:name(), 1, 5)=="item:") 
	then 
		item=ParseFreshcodeItem(N) 	
		if items[item.name] == nil then items[item.name]=item end
	end
	N=P:next();
end

end


function ParseFossiesLink(Html)
local Toks, tempstr, len, c

if Html ~= nil
then
	Toks=strutil.TOKENIZER(Html, "\\S")
	tempstr=Toks:next()
	while tempstr ~= nil
	do
	
	if string.sub(tempstr, 1, 5)=='href=' 
	then 
		tempstr=string.sub(tempstr,6)
		c=string.sub(tempstr, 1, 1)
		len=strutil.strlen(tempstr)
		if c=='"' or c=="'" 
		then 
				tempstr=string.sub(tempstr, 2, len-1) 
		end	
		return(tempstr)
	end
	
	tempstr=Toks:next()
	end
end

return("")
end


function ParseFossiesItem()
local Package={}
local tempstr, Toks

Package=ParseReleaseRSS(N)

Toks=strutil.TOKENIZER(strutil.htmlUnQuote(N:value("description")), "<|>", "m")

tempstr=Toks:next()
Package.link=ParseFossiesLink(string.lower(Toks:next()))
tempstr=tempstr..Toks:next()
Toks:next()
tempstr=tempstr..Toks:remaining()
Package.description=tempstr

Package.feed="fossies"

return(Package)
end


function ParseFossies(items)

local S, P, doc;

S=stream.STREAM("https://fossies.org/fresh.linux_misc.v.rss");
doc=S:readdoc();
P=dataparser.PARSER("rss",doc);

N=P:open("/")
while N ~=nil
do
	if (string.sub(N:name(), 1, 5)=="item:") 
	then 
		item=ParseFossiesItem(N) 	
		if items[item.name] == nil then items[item.name]=item end
	end
	N=P:next();
end
end


function ReleasesSortFunc(r1, r2)
return(r1.date > r2.date)
end


function GetReleases()
local items={}
local sorted={}
local i, item

ParseFossies(items)
ParseFreshcode(items)

--reorganize items into a table where the key values are numeric, so we can use table.sort
i=1
for k,item in pairs(items)
do
	sorted[i]=item
	i=i+1
end

table.sort(sorted, ReleasesSortFunc)
return(sorted)
end


function DisplaySingleRelease(settings, Package)
local Fmt, age, oldest

oldest=0
if tonumber(settings.days) > 0
then
	oldest=tonumber(settings.days) * 24 * 3600
end

age=Now - Package.date

if oldest == 0 or age <= oldest
then
	if age <= (24 * 3600) 
	then 
		Fmt="~e%Y/%m/%d~0"
		today_items=today_items + 1
		week_items=week_items + 1
	elseif age <= (24 * 2 * 3600) 
	then 
		Fmt="~y%Y/%m/%d~0"
		week_items=week_items + 1
	elseif age < (24 * 7 * 3600) then 
		Fmt="~c%Y/%m/%d~0"
		week_items=week_items + 1
	else Fmt="%Y/%m/%d"
	end

	total_items=total_items+1
	Out:puts(time.formatsecs(Fmt, Package.date))
	Out:puts("  ~e" .. Package.name .. "~0  ~m" .. Package.version .. "~0   " ..  "   ("..Package.feed..")  ~b"..Package.link.."\n~0")
	if settings.text == "y" then 
		Out:puts(Package.description.."\n") 
		Out:puts("\n")
	end
end

end


function DisplayReleases()
local items, n, Package

items=GetReleases()
for n, Package in pairs(items)
do
	DisplaySingleRelease(settings, Package)
end

Out:puts(string.format("~e%d~0 items returned: ~e%d~0 releases today ~e%d~0 releases this week\n", total_items, today_items, week_items))

end

function ProcessWatch(settings, watchlist)
local items, n, Package

items=GetReleases()
for n, Package in pairs(items)
do

if strutil.strlen(watchlist[string.lower(Package.name)]) > 0
then
	DisplaySingleRelease(settings, Package)
end

end


end


function	DisplayUsage()

print("usage:")
print("   lua releases.lua [options]                            - display latest releases");   
print("   lua releases.lua watch [options] [name] [name] ...    - display releases of named packages");   
print("   lua releases.lua help                                 - display this help");   
print("")
print("options:")
print("   -days <n>      - show results for the last 'n' days");
print("   -notext        - do not show text description of package");
print("   -?             - show this help");
print("   -h             - show this help");
print("   -help          - show this help");
print("   --help         - show this help");
print("")
print("examples:")
print("   lua releases.lua -days 2                - show releases for the last two days")
print("   lua releases.lua -days 1 -notext        - show releases for the last 24 hours without descriptions")
print("   lua releases.lua watch wine strace      - show releases for the programs 'wine' and 'strace'")
end


function ParseCommandLine(arg)
local act, days, color="y"
local watchlist={}
local settings={}

settings.days=0
settings.color="y"
settings.text="y"

if arg[1]=="help"
then
	act="help"
elseif arg[1]=="watch" 
then 
	act="watch"
	arg[1]=""
else act="releases" 
end

for i,v in ipairs(arg)
do
	if v=="-?" or v=="-h" or v=="-help" or v=="--help"
	then
		act="help"
	elseif v=="-days" 
	then 
	settings.days=arg[i+1]
	arg[i+1]=""
	elseif v=="-nocolor" 
	then 
		settings.color="n"
		arg[i]=""
	elseif v=="-notext" 
	then 
		settings.text="n"
		arg[i]=""
	else 
		watchlist[ string.lower(v) ]=v
	end
end

return act, settings, watchlist
end





-- MAIN STARTS HERE --
Now=time.secs()
Out=terminal.TERM()

act,settings,watchlist=ParseCommandLine(arg)
if act=="help"
then
	DisplayUsage()
elseif act=="watch" 
then
	ProcessWatch(settings, watchlist)
else
	DisplayReleases(settings)
end
