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
local units = { player = {"Proto","Col"}, party1 = {"Zugzug","Doug"} }
UnitExists = function(u) return units[u] ~= nil end
UnitIsPlayer = UnitExists
UnitName = function(u) local d = units[u]; if d then return d[1], d[2] end end
local function FS(parent)
  local fs = { text = "", parent = parent }
  function fs:GetObjectType() return "FontString" end
  function fs:SetText(t) self.text = t end
  function fs:SetFormattedText(f, ...) self.text = f:format(...) end
  function fs:GetText() return self.text end
  function fs:GetParent() return nil end
  return fs
end
-- fake Cell: name indicator asks F.GetNickname, then trims to 8 chars
local cellBtn = { states = { name = "Zugzug", fullName = "Zugzug Doug-", unit = "party1", isPlayer = true } }
cellBtn.indicators = { nameText = { name = FS() } }
function cellBtn.indicators.nameText:UpdateName()
  local n = Cell.funcs.GetNickname(cellBtn.states.name, cellBtn.states.fullName)
  self.name:SetText(n:sub(1, 8))
end
Cell = { vars = { names = { ["Zugzug Doug-"] = "party1" }, nicknameCustoms = {} }, funcs = {} }
function Cell.funcs.GetNickname(short, full) return Cell.vars.nicknameCustoms[full] or short end
function Cell.funcs.IterateAllUnitButtons(fn) fn(cellBtn) end
-- fake ElvUI oUF frame with a name tag and a health tag
local elvFrame = { unit = "party1", __tags = {} }
elvFrame.Name = FS(elvFrame); elvFrame.Health = FS(elvFrame)
elvFrame.__tags[elvFrame.Name] = true; elvFrame.__tags[elvFrame.Health] = true
local initCb
ElvUF = { objects = { elvFrame }, RegisterInitCallback = function(self, fn) initCb = fn end }
NicknamesDB = { names = {}, settings = {} }
local ns = {}
for _, f in ipairs({"NicknameForever/Core.lua","NicknameForever/Display.lua","NicknameForever/Frames.lua"}) do assert(loadfile(root..f))("NicknameForever", ns) end
for _, f in ipairs(frames) do local h = rawget(f,"h_OnEvent"); if h then pcall(h, f, "ADDON_LOADED", "NicknameForever") end end
local N = ns.N
local function eq(a,b,label) if a ~= b then print("FAIL "..label..": got ["..tostring(a).."] want ["..tostring(b).."]"); FAILED=true else print("ok   "..label) end end
-- before login: Cell has its own custom nickname for someone else
Cell.vars.nicknameCustoms["Other Guy-"] = "CellNick"
for _, f in ipairs(frames) do local h = rawget(f,"h_OnEvent"); if h then h(f, "PLAYER_ENTERING_WORLD") end end
eq(ns.frameStats.cell, true, "Cell hooked")
eq(ns.frameStats.oufStrings, 2, "ElvUI tagged texts hooked")
cellBtn.indicators.nameText:UpdateName()
eq(cellBtn.indicators.nameText.name.text, "Zugzug", "Cell: no nickname -> real name")
eq(Cell.funcs.GetNickname("Other", "Other Guy-"), "CellNick", "Cell's own list still works")
N:Set("Zugzug Doug", nil, "Zug")
eq(cellBtn.indicators.nameText.name.text, "Zug", "Cell: nickname change repaints")
elvFrame.Name:SetFormattedText("|cff%s%s|r", "c69b6d", "Zugzug Doug")
eq(elvFrame.Name.text, "|cffc69b6dZug|r", "ElvUI: name tag swapped")
elvFrame.Health:SetFormattedText("%d%%", 87)
eq(elvFrame.Health.text, "87%", "ElvUI: health tag untouched")
elvFrame.Name:SetText("Zugzug")
eq(elvFrame.Name.text, "Zug", "ElvUI: first-name-only tag ([name:short])")
N:SetSetting("frames", false)
eq(cellBtn.indicators.nameText.name.text, "Zugzug", "Cell: setting off restores")
eq(elvFrame.Name.text, "Zugzug", "ElvUI: setting off restores")
N:SetSetting("frames", true)
-- a frame spawned later (raid header child)
local late = { unit = "party1", __tags = {} }; late.Name = FS(late); late.__tags[late.Name] = true
initCb(late)
late.Name:SetText("Zugzug Doug")
eq(late.Name.text, "Zug", "ElvUI: late-spawned frame hooked via init callback")
if FAILED then error("tests failed") end
