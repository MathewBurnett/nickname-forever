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
C_Timer = { After=function(_, fn) fn() end, NewTicker=function() end }
SlashCmdList = {}
local units = { player = {"Proto","Col"}, mouseover = {"Zugzug","Doug"} }
UnitExists = function(u) return units[u] ~= nil end
UnitIsPlayer = UnitExists
UnitName = function(u) local d = units[u]; if d then return d[1], d[2] end end
local postcall
Enum = { TooltipDataType = { Unit = 2 } }
TooltipDataProcessor = { AddTooltipPostCall = function(t, fn) assert(t == 2); postcall = fn end }
local line = { text = "" }
function line:GetText() return self.text end
function line:SetText(t) self.text = t end
GameTooltipTextLeft1 = line
local shown = 0
local tt = { unit = "mouseover" }
function tt:GetName() return "GameTooltip" end
function tt:GetUnit() return "x", self.unit end
function tt:IsShown() return true end
function tt:Show() shown = shown + 1 end
NicknamesDB = { names = {}, settings = {} }
local ns = {}
for _, f in ipairs({"NicknameForever/Core.lua","NicknameForever/Display.lua","NicknameForever/Tooltip.lua"}) do assert(loadfile(root..f))("NicknameForever", ns) end
for _, f in ipairs(frames) do local h = rawget(f,"h_OnEvent"); if h then pcall(h, f, "ADDON_LOADED", "NicknameForever") end end
for _, f in ipairs(frames) do local h = rawget(f,"h_OnEvent"); if h then pcall(h, f, "PLAYER_ENTERING_WORLD") end end
assert(postcall, "tooltip post-call registered after login")
local N = ns.N
local function eq(a,b,label) if a ~= b then print("FAIL "..label..": got ["..tostring(a).."] want ["..tostring(b).."]"); FAILED=true else print("ok   "..label) end end
local function show(text) line.text = text; postcall(tt, {}); return line.text end
eq(show("Zugzug Doug"), "Zugzug Doug", "no nickname -> untouched")
N:Set("Zugzug Doug", nil, "Zug")
eq(show("Zugzug Doug"), "Zug (Zugzug Doug)", "default style both")
eq(show("|cffc69b6dSergeant Zugzug Doug|r"), "|cffc69b6dSergeant Zug (Zugzug Doug)|r", "title + colour kept")
postcall(tt, {})
eq(line.text, "|cffc69b6dSergeant Zug (Zugzug Doug)|r", "refresh without reset -> not doubled")
N:SetSetting("tooltipStyle", "nick")
eq(show("Zugzug Doug"), "Zug", "style nick")
N:Set("Zugzug Doug", nil, "Big Zugzug")
eq(show("Zugzug Doug"), "Big Zugzug", "nick containing first name")
postcall(tt, {})
eq(line.text, "Big Zugzug", "nick containing first name not re-replaced")
N:SetSetting("tooltips", false)
eq(show("Zugzug Doug"), "Zugzug Doug", "setting off")
N:SetSetting("tooltips", true)
tt.unit = nil
eq(show("Zugzug Doug"), "Zugzug Doug", "no unit -> untouched")
eq(shown > 0, true, "tooltip re-fitted")
if FAILED then error("tests failed") end
