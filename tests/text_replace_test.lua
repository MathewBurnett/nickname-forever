FOREVER=true
local root = os.getenv("NF_ROOT") or "./"
local frames = {}
local function obj() local o = {}; setmetatable(o,{__index=function(t,k) return function() return o end end}); return o end
CreateFrame = function() local f = obj(); f.SetScript=function(self,k,fn) rawset(self, "h_"..k, fn) end; frames[#frames+1]=f; return f end
GetBuildInfo = function() return "x","y","z",16001 end
GetNormalizedRealmName = function() return "" end
strtrim = function(s) return (s:gsub("^%s+",""):gsub("%s+$","")) end
strmatch = string.match
wipe = function(t) for k in pairs(t) do t[k]=nil end return t end
geterrorhandler = function() return function(e) print("ERR", e) end end
hooksecurefunc = function(t, name, fn) if type(t)=="string" then return end local o = t[name]; t[name] = function(...) o(...); fn(...) end end
C_Timer = { After=function() end, NewTicker=function() end }
SlashCmdList = {}
local units = { player = {"Proto","Col"} }
UnitExists = function(u) return units[u] ~= nil end
UnitIsPlayer = UnitExists
UnitName = function(u) local d = units[u]; if d then return d[1], d[2] end end
NicknamesDB = { names = {}, settings = {} }
local ns = {}
for _, f in ipairs({"NicknameForever/Core.lua","NicknameForever/Display.lua"}) do assert(loadfile(root..f))("NicknameForever", ns) end
for _, f in ipairs(frames) do local h = rawget(f,"h_OnEvent"); if h then pcall(h, f, "ADDON_LOADED", "NicknameForever") end end
local N = ns.N
local function eq(a,b,label) if a ~= b then print("FAIL "..label..": got ["..tostring(a).."] want ["..tostring(b).."]"); FAILED=true else print("ok   "..label) end end
N:SetForUnit("player", "Boss")
N:Set("Zugzug Doug", nil, "Zug")
local R = ns.ReplaceKnownNames
eq(R("Proto Col"), "Boss", "meter full name")
eq(R("|cff3fc7ebProto Col|r"), "|cff3fc7ebBoss|r", "class coloured")
eq(R("|cffffd1001.|r Proto Col"), "|cffffd1001.|r Boss", "EQOL rank prefix")
eq(R("Proto"), "Boss", "first-name format (unique)")
eq(R("Protoss"), "Protoss", "no partial word")
eq(R("Zugzug Doug"), "Zug", "second entry")
eq(R("Damage Done"), "Damage Done", "header untouched")
N:Set("Proto Other", nil, "Twin")
eq(R("Proto"), "Proto", "first-name ambiguous -> untouched")
eq(R("Proto Other"), "Twin", "other Proto by full name")
-- fake fontstring hooked as text-only, owner repaint + nickname change
local fs = { text = "" }
function fs:GetObjectType() return "FontString" end
function fs:SetText(t) self.text = t end
function fs:SetFormattedText(f, ...) self.text = f:format(...) end
function fs:GetText() return self.text end
ns.HookTextFontString(fs, "meters")
fs:SetText("Proto Col")
eq(fs:GetText(), "Boss", "hooked fontstring swaps on owner SetText")
fs:SetFormattedText("|c%s%d.|r %s", "ffffd100", 1, "Proto Col")
eq(fs:GetText(), "|cffffd1001.|r Boss", "SetFormattedText path")
N:SetForUnit("player", "Chief")
eq(fs:GetText(), "|cffffd1001.|r Chief", "nickname change repaints")
N:SetSetting("meters", false)
eq(fs:GetText(), "|cffffd1001.|r Proto Col", "setting off restores")
-- nameplate path with class colour
local _, _, first, _, raw, second = ns.UnitKey("player")
eq(ns.ReplaceName("|cff3fc7ebProto Col|r", "Chief", first, raw, second), "|cff3fc7ebChief|r", "plate coloured name")
if FAILED then error("tests failed") end
