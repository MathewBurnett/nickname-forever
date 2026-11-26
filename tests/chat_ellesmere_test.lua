FOREVER=true
local root = os.getenv("NF_ROOT") or "./"
local frames, timers = {}, {}
local function obj() local o = {}; setmetatable(o,{__index=function(t,k) return function() return o end end}); return o end
CreateFrame = function() local f = obj(); f.SetScript=function(self,k,fn) rawset(self, "h_"..k, fn) end; frames[#frames+1]=f; return f end
GetBuildInfo = function() return "x","y","z",16001 end
GetNormalizedRealmName = function() return "" end
GetRealmName = function() return "" end
strtrim = function(s) return (s:gsub("^%s+",""):gsub("%s+$","")) end
strmatch = string.match
wipe = function(t) for k in pairs(t) do t[k]=nil end return t end
geterrorhandler = function() return function(e) print("ERR", e) end end
-- real-ish hooksecurefunc on tables
hooksecurefunc = function(t, name, fn) if type(t)=="string" then return end local o = t[name]; t[name] = function(...) local r = {o(...)}; fn(...); return unpack(r) end end
C_Timer = { After=function(_, fn) timers[#timers+1]=fn end, NewTicker=function() end }
SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage=function(_, m) end }
local units = { player = {"Proto","Col"} }
UnitExists = function(u) return units[u] ~= nil end
UnitIsPlayer = UnitExists
UnitName = function(u) local d = units[u]; if d then return d[1], d[2] end end
local function Buffer() local b = {items={}}; function b:Push(m) table.insert(self.items,1,{message=m}) end
  function b:GetEntryAtIndex(i) return self.items[i] end; function b:GetNumElements() return #self.items end; return b end
local function SMF(kind) local f = {historyBuffer=Buffer()}; function f:AddMessage(m) self.historyBuffer:Push(m) end
  function f:GetObjectType() return kind or "ScrollingMessageFrame" end; function f:GetID() return 1 end; return f end
-- Blizzard ChatFrame1 + EUI window WITHOUT a Lua history buffer (worst case)
local cf = SMF(); ChatFrame1 = cf; CHAT_FRAMES = {"ChatFrame1"}
local euiShown = {}
local eui = { GetObjectType=function() return "Frame" end, GetNumMessages=function() return 0 end }
function eui:AddMessage(m) euiShown[#euiShown+1] = m end
local bg = { GetChildren=function() return {GetObjectType=function() return "Button" end}, eui end }
local cfd = { [cf] = { bg = bg, visualsSuppressed = true } }
EllesmereUI = { _chatCFD = function(f) cfd[f] = cfd[f] or {}; return cfd[f] end }
-- EUI's bridge hook (installed before ours, like in game)
hooksecurefunc(cf, "AddMessage", function(self, m) eui:AddMessage(m) end)
NicknamesDB = { names = {}, settings = {} }
local ns = {}
for _, f in ipairs({"NicknameForever/Core.lua","NicknameForever/Display.lua","NicknameForever/Chat.lua"}) do assert(loadfile(root..f))("NicknameForever", ns) end
for _, f in ipairs(frames) do local h = rawget(f,"h_OnEvent"); if h then pcall(h, f, "ADDON_LOADED", "NicknameForever") end end
for _, f in ipairs(frames) do local h = rawget(f,"h_OnEvent"); if h then pcall(h, f, "PLAYER_ENTERING_WORLD") end end
local function run() local t = timers; timers = {}; for _, fn in ipairs(t) do fn() end end
run() -- installs hooks
local N = ns.N
local function eq(a,b,label) if a ~= b then print("FAIL "..label..": got ["..tostring(a).."] want ["..tostring(b).."]"); FAILED=true else print("ok   "..label) end end
N:SetForUnit("player", "Test")
local line = "|Hplayer:Proto Col:12:SAY|h[|cff3fc7ebProto Col|r]|h says: hi"
ChatFrame1:AddMessage(line)
run()
eq(euiShown[#euiShown], "|Hplayer:Proto Col:12:SAY|h[|cff3fc7ebTest|r]|h says: hi", "EUI window shows nickname")
eq(cf.historyBuffer:GetEntryAtIndex(1).message, euiShown[#euiShown], "Blizzard buffer matches")
N:SetForUnit("player", "Proto")
ChatFrame1:AddMessage(line)
eq(euiShown[#euiShown], "|Hplayer:Proto Col:12:SAY|h[|cff3fc7ebProto|r]|h says: hi", "nickname == first name")
eq(cf.historyBuffer:GetEntryAtIndex(2).message:find("%[|cff3fc7ebProto|r%]") ~= nil, true, "older line rescanned to new nick")
N:Set("Proto", nil, nil)
eq(N:GetForUnit("player"), nil, "remove by first name clears Proto Col")
eq(cf.historyBuffer:GetEntryAtIndex(1).message, line, "rescan restores original")
eq(ns.chatStats.errors, 0, "no errors")
if FAILED then error("tests failed") end
