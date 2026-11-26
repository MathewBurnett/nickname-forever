local root = os.getenv("NF_ROOT") or "./"
local created = {}
local function newobj(kind, name)
  local o = { _kind = kind, _scripts = {}, _shown = (kind ~= "Frame" or not name) }
  setmetatable(o, { __index = function(t, k)
    if type(k) == "string" and k:match("^[A-Z]") then return function(self, ...) return self end end
  end })
  function o:SetScript(k, fn) self._scripts[k] = fn end
  function o:GetScript(k) return self._scripts[k] end
  function o:HookScript(k, fn) self._scripts[k] = fn end
  function o:CreateFontString() local fs = newobj("FontString"); function fs:SetText(t) self.text = t end; function fs:GetText() return self.text end; return fs end
  function o:CreateTexture() local t = newobj("Texture"); function t:SetTexture(p) self.tex = p end; return t end
  function o:Show() local was = self._shown; self._shown = true; if not was and self._scripts.OnShow then self._scripts.OnShow(self) end end
  function o:Hide() self._shown = false end
  function o:IsShown() return self._shown end
  function o:SetShown(v) if v then self:Show() else self:Hide() end end
  function o:SetChecked(v) self.checked = v end
  function o:GetChecked() return self.checked end
  function o:GetWidth() return 140 end
  function o:GetHeight() return 140 end
  function o:GetText() return self.text or "" end
  function o:SetText(t) self.text = t end
  if name then _G[name] = o end
  created[#created + 1] = o
  return o
end
CreateFrame = function(kind, name, parent, template)
  local f = newobj(kind, name); f.template = template
  if template == "UICheckButtonTemplate" then f.text = f:CreateFontString() end
  return f
end
Minimap = newobj("Frame")
UIParent = newobj("Frame")
GameTooltip = newobj("GameTooltip")
local tipLines = {}
function GameTooltip:AddLine(t) tipLines[#tipLines + 1] = t end
UISpecialFrames = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) print("  chat> " .. m) end }
tinsert = table.insert
GetBuildInfo = function() return "x","y","z",16001 end
GetNormalizedRealmName = function() return "" end
strtrim = function(s) return (s:gsub("^%s+",""):gsub("%s+$","")) end
strmatch = string.match
wipe = function(t) for k in pairs(t) do t[k]=nil end return t end
geterrorhandler = function() return function(e) print("ERR", e) end end
hooksecurefunc = function() end
C_Timer = { After=function(_, fn) fn() end, NewTicker=function() end }
SlashCmdList = {}
UnitExists = function() return false end
UnitName = function() return "Proto", "Col" end
NicknamesDB = { names = {}, settings = {} }
local ns = {}
for _, f in ipairs({"Core.lua","Minimap.lua","Info.lua","Options.lua"}) do assert(loadfile(root.."NicknameForever/"..f))("NicknameForever", ns) end
for _, f in ipairs(created) do local h = f._scripts.OnEvent; if h then pcall(h, f, "ADDON_LOADED", "NicknameForever") end end
local N = ns.N
local function eq(a,b,label) if a ~= b then print("FAIL "..label..": got ["..tostring(a).."] want ["..tostring(b).."]"); FAILED=true else print("ok   "..label) end end
eq(ns.ICON, "Interface\\AddOns\\NicknameForever\\Media\\Icon", "icon path")
local mb = _G.NicknameForeverMinimapButton
eq(mb ~= nil and mb:IsShown(), true, "minimap button shown by default")
SlashCmdList.NICKNAMES("minimap")
eq(mb:IsShown(), false, "/nick minimap hides it")
SlashCmdList.NICKNAMES("minimap")
eq(mb:IsShown(), true, "/nick minimap shows it again")
mb._scripts.OnClick(mb)
local win = _G.NicknamesManager
eq(win ~= nil and win:IsShown(), true, "minimap click opens window")
eq(#win.checks, 10, "10 option checkboxes")
local byKey = {}
for _, cb in ipairs(win.checks) do byKey[cb.text.text] = cb end
local mm = byKey["Minimap button"]
eq(mm ~= nil and mm.checked, true, "Minimap button checkbox ticked")
mm.checked = false; mm._scripts.OnClick(mm)
eq(mb:IsShown(), false, "unticking hides the button")
eq(N:GetSetting("minimap"), false, "setting saved")
NicknameForever_OnAddonCompartmentClick()
eq(win:IsShown(), false, "compartment click toggles window")
NicknameForever_OnAddonCompartmentEnter("NicknameForever", newobj("Button"))
eq(tipLines[1], "|TInterface\\AddOns\\NicknameForever\\Media\\Icon:16:16|t Nickname Forever", "tooltip title has icon")
NicknameForever_OnAddonCompartmentClick()
eq(win:IsShown(), true, "window reopened")
eq(win.mainPage:IsShown() and not win.infoPage:IsShown(), true, "opens on options page")
eq(win.infoGlyph.text, "i", "button shows i")
win.infoButton._scripts.OnClick(win.infoButton)
eq(win.infoPage:IsShown() and not win.mainPage:IsShown(), true, "i shows info page")
eq(win.infoGlyph.text, "x", "button becomes x")
win.infoButton._scripts.OnClick(win.infoButton)
eq(win.mainPage:IsShown() and not win.infoPage:IsShown(), true, "x returns to options")
win.infoButton._scripts.OnClick(win.infoButton)
win:Hide(); win._scripts.OnHide(win); win:Show()
eq(win.mainPage:IsShown(), true, "reopening the window starts on options")
if FAILED then error("tests failed") end
