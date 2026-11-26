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
DEFAULT_CHAT_FRAME = { AddMessage=function(_, m) print("  chat> "..m) end }
local units = FOREVER and { player = {"Proto","Col"}, target = {"Bob","Smith"} } or { player={"Proto"}, target={"Bob"} }
UnitExists = function(u) return units[u] ~= nil end
UnitIsPlayer = UnitExists
UnitName = function(u) local d = units[u]; if d then return d[1], d[2] end end
-- v1 saved data
NicknamesDB = { names = { ["proto-myrealm"] = {nick="Me", name="Proto", realm="MyRealm"},
                          ["bob-myrealm"]   = {nick="Bobby", name="Bob", realm="MyRealm"} }, settings = {} }
local ns = {}
for _, f in ipairs({"NicknameForever/Core.lua","NicknameForever/Display.lua","NicknameForever/Chat.lua"}) do
  assert(loadfile(root..f))("NicknameForever", ns)
end
for _, f in ipairs(frames) do local h = rawget(f,"h_OnEvent"); if h then pcall(h, f, "ADDON_LOADED", "NicknameForever") end end
local N = ns.N
local function eq(a,b,label) if a ~= b then print("FAIL "..label..": got ["..tostring(a).."] want ["..tostring(b).."]"); FAILED=true else print("ok   "..label) end end
if FOREVER then
  eq(NicknamesDB.names["proto col"] and NicknamesDB.names["proto col"].name, "Proto Col", "migrated own char w/ surname")
  eq(NicknamesDB.names["proto-myrealm"], nil, "old key gone")
  eq(N:GetForUnit("player"), "Me", "own nick via unit")
  eq(N:GetForUnit("target"), "Bobby", "legacy adopted by Bob Smith")
  eq(NicknamesDB.names["bob smith"] and NicknamesDB.names["bob smith"].name, "Bob Smith", "rekeyed full")
  eq(N:Get("Proto Col"), "Me", "get full")
  eq(N:Get("Proto-Col"), "Me", "get link form")
  eq(N:Get("Proto Col-MyRealm"), "Me", "get full+realm")
  eq(N:Get("Proto"), "Me", "first only, unique")
  N:Set("Proto Other", nil, "Other")
  eq(N:Get("Proto"), nil, "first only, ambiguous -> nil")
  eq(N:Get("Proto Other"), "Other", "different surname distinct")
  eq(N:Get("Proto Col"), "Me", "still mine")
  local key, display, first, _, raw, second = ns.UnitKey("player")
  eq(ns.ReplaceName("Proto Col", "Me", first, raw, second), "Me", "plate full")
  eq(ns.ReplaceName("60 | Proto", "Me", first, raw, second), "60 | Me", "plate first only")
  local T = ns.TransformChatLine
  eq(T("|Hplayer:Proto-Col:1:SAY|h[|cff3fc7ebProto Col|r]|h: hi"), "|Hplayer:Proto-Col:1:SAY|h[|cff3fc7ebMe|r]|h: hi", "chat link form")
  eq(T("|Hplayer:Proto Col-MyRealm:2|h[Proto Col]|h"), "|Hplayer:Proto Col-MyRealm:2|h[Me]|h", "chat full+realm")
  local n=0; for _, e in N:Iterate() do n=n+1 end; eq(n, 3, "entry count")
  SlashCmdList.NICKNAMES("set Proto Other = Twin")
  eq(N:Get("Proto Other"), "Twin", "slash set with =")
  SlashCmdList.NICKNAMES("list")
else
  eq(N:Get("Bob-MyRealm"), "Bobby", "retail untouched by migration")
  eq(N:GetForUnit("target"), "Bobby", "retail unit")
  eq(ns.TransformChatLine("|Hplayer:Bob-MyRealm:1|h[Bob]|h"), "|Hplayer:Bob-MyRealm:1|h[Bobby]|h", "retail chat")
end
if FAILED then error("tests failed") end
