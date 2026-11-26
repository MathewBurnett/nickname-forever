-- A nameplate owner that re-lays out its name by writing GetText() back
-- (EllesmereUI's ReflowFontString: SetText("") then SetText(old)).
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
local units = { player = {"Proto","Col"}, nameplate1 = {"Siren","Soulweaver"} }
UnitExists = function(u) return units[u] ~= nil end
UnitIsPlayer = UnitExists
UnitName = function(u) local d = units[u]; if d then return d[1], d[2] end end
NicknamesDB = { names = {}, settings = {} }
local ns = {}
for _, f in ipairs({"NicknameForever/Core.lua","NicknameForever/Display.lua"}) do assert(loadfile(root..f))("NicknameForever", ns) end
for _, f in ipairs(frames) do local h = rawget(f,"h_OnEvent"); if h then pcall(h, f, "ADDON_LOADED", "NicknameForever") end end
local N = ns.N
local function eq(a,b,label) if a ~= b then print("FAIL "..label..": got ["..tostring(a).."] want ["..tostring(b).."]"); FAILED=true else print("ok   "..label) end end

local fs = { text = "" }
function fs:GetObjectType() return "FontString" end
function fs:SetText(t) self.text = t end
function fs:SetFormattedText(f, ...) self.text = f:format(...) end
function fs:GetText() return self.text end
local function reflow() local t = fs:GetText(); fs:SetText(""); fs:SetText(t) end
ns.HookNameFontString(fs, function() return "nameplate1" end, "nameplates")

-- nickname containing the first name
N:Set("Siren Soulweaver", nil, "Little Siren")
fs:SetText("Siren Soulweaver")
eq(fs:GetText(), "Little Siren", "nickname applied")
reflow(); reflow(); reflow()
eq(fs:GetText(), "Little Siren", "re-layout does not replace inside the nickname")
N:Set("Siren Soulweaver", nil, "Bob")
eq(fs:GetText(), "Bob", "nickname change after re-layout uses the real name")
reflow()
N:Set("Siren Soulweaver", nil, nil)
eq(fs:GetText(), "Siren Soulweaver", "removal after re-layout restores the real name")

-- multi-word nickname, level prefix, re-layout without a blank first
N:Set("Siren Soulweaver", nil, "Milly is not")
fs:SetFormattedText("%d | %s", 60, "Siren Soulweaver")
eq(fs:GetText(), "60 | Milly is not", "multi-word nickname with level prefix")
fs:SetText(fs:GetText())
eq(fs:GetText(), "60 | Milly is not", "plain re-set keeps it")
N:Set("Siren Soulweaver", nil, nil)
eq(fs:GetText(), "60 | Siren Soulweaver", "removal restores")

-- pooled plate: blanked, then reused for another unit
N:Set("Siren Soulweaver", nil, "Milly is not")
fs:SetText("Siren Soulweaver")
fs:SetText("")
units.nameplate1 = {"Zugzug","Doug"}
fs:SetText("Zugzug Doug")
eq(fs:GetText(), "Zugzug Doug", "recycled plate shows the new unit")
units.nameplate1 = {"Siren","Soulweaver"}

-- pure functions are idempotent
eq(ns.ReplaceName("Little Siren", "Little Siren", "Siren", "Siren", "Soulweaver"), "Little Siren", "ReplaceName idempotent")
N:Set("Siren Soulweaver", nil, "Little Siren")
eq(ns.ReplaceKnownNames("Little Siren"), "Little Siren", "ReplaceKnownNames idempotent")
eq(ns.ReplaceKnownNames("Siren Soulweaver"), "Little Siren", "ReplaceKnownNames still replaces")
if FAILED then error("tests failed") end
