FOREVER=true
local root = os.getenv("NF_ROOT") or "./"
local frames = {}
local function obj() local o = {}; setmetatable(o,{__index=function(t,k) return function() return o end end}); return o end
CreateFrame = function() local f = obj(); f.SetScript=function(self,k,fn) rawset(self, "h_"..k, fn) end; frames[#frames+1]=f; return f end
GetBuildInfo = function() return "x","y","z", FOREVER and 16001 or 120001 end
GetNormalizedRealmName = function() return "MyRealm" end
strtrim = function(s) return (s:gsub("^%s+",""):gsub("%s+$","")) end
strmatch = string.match
wipe = function(t) for k in pairs(t) do t[k]=nil end return t end
geterrorhandler = function() return function(e) print("ERR", e) end end
hooksecurefunc = function() end
C_Timer = { After=function() end, NewTicker=function() end }
SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage=function(_, m) print(m) end }
local units = { target = {"Bob", FOREVER and "Smith" or nil} }
UnitExists = function(u) return units[u] ~= nil end
UnitIsPlayer = UnitExists
UnitName = function(u) local d = units[u]; if d then return d[1], d[2] end end
local ns = {}
for _, f in ipairs({"NicknameForever/Core.lua","NicknameForever/Display.lua","NicknameForever/Chat.lua"}) do
  assert(loadfile(root..f))("NicknameForever", ns)
end
for _, f in ipairs(frames) do local h = rawget(f,"h_OnEvent"); if h then pcall(h, f, "ADDON_LOADED", "NicknameForever") end end
local N = ns.N
local function eq(a,b,label) if a ~= b then print("FAIL "..label..": got ["..tostring(a).."] want ["..tostring(b).."]"); FAILED=true else print("ok   "..label) end end
local changes = 0
N.RegisterCallback("t","NICKNAME_CHANGED", function() changes = changes + 1 end)
eq(N:SetForUnit("target","Bobby"), true, "set via unit")
eq(N:GetForUnit("target"), "Bobby", "get via unit")
eq(N:Get("bob"), "Bobby", "get lower")
eq(N:Get("Bob-MyRealm"), "Bobby", "get name-realm")
eq(N:Get(FOREVER and "Bob Smith" or "Bob-My Realm"), "Bobby", "get alt form")
eq(changes, 1, "callback fired")
-- display replace
local key, _, first, _, raw, second = ns.UnitKey("target")
eq(ns.ReplaceName("Bob", "Bobby", first, raw, second), "Bobby", "plate plain")
eq(ns.ReplaceName("60 | Bob", "Bobby", first, raw, second), "60 | Bobby", "plate level")
if FOREVER then eq(ns.ReplaceName("Bob Smith", "Bobby", first, raw, second), "Bobby", "plate surname") end
eq(ns.ReplaceName("Bobcat", "Bobby", first, raw, second), "Bobcat", "no partial")
-- chat
local T = ns.TransformChatLine
eq(T("|Hplayer:Bob-MyRealm:123:PARTY|h[|cffc69b6dBob|r]|h: hi Bob"), "|Hplayer:Bob-MyRealm:123:PARTY|h[|cffc69b6dBobby|r]|h: hi Bob", "chat colored")
eq(T("|Hplayer:Bob-MyRealm:1|h[Bob-MyRealm]|h says"), "|Hplayer:Bob-MyRealm:1|h[Bobby]|h says", "chat realm swallow")
eq(T("|Hplayer:Bob:1|h[|cFFBOB000Bob Smith|r]|h"), "|Hplayer:Bob:1|h[|cFFBOB000Bobby|r]|h", "chat skip color + surname")
eq(T("|Hplayer:Alice-MyRealm:1|h[Alice]|h"), "|Hplayer:Alice-MyRealm:1|h[Alice]|h", "chat no nick")
N:SetSetting("chatStyle","both")
local once = T("|Hplayer:Bob-MyRealm:9|h[Bob]|h x")
eq(once, "|Hplayer:Bob-MyRealm:9|h[Bobby (Bob)]|h x", "chat both")
eq(T(once), once, "idempotent")
N:Set("Bob", nil, "")
eq(N:Get("Bob"), nil, "cleared with empty")
eq(changes, 2, "clear callback")
if FAILED then error("tests failed") end
