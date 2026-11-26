-------------------------------------------------------------------------------
--  Nicknames - unit tooltips
--  Rewrites the name on the first line of a player's tooltip to the nickname,
--  or "Nickname (Name)" (setting tooltipStyle). Titles and colours on the line
--  are kept ("Sergeant Proto Col" -> "Sergeant Bob (Proto Col)").
--  Only the line's text is changed; Blizzard's tooltip code is not replaced.
--  Secret text (protected content in combat) is left alone.
-------------------------------------------------------------------------------
local _, ns = ...
local N = ns.N
local issecret = ns.issecret

local written = setmetatable({}, { __mode = "k" }) -- line -> text we last wrote

local function TooltipUnit(tt, data)
    if tt.GetUnit then
        local ok, _, unit = pcall(tt.GetUnit, tt)
        if ok and type(unit) == "string" and not issecret(unit) then return unit end
    end
    local guid = data and data.guid
    if type(guid) == "string" and not issecret(guid) and UnitTokenFromGUID then
        local ok, unit = pcall(UnitTokenFromGUID, guid)
        if ok and type(unit) == "string" and not issecret(unit) then return unit end
    end
end

local function Rewrite(tt, data)
    if not N:GetSetting("tooltips") then return end
    if not tt or (tt.IsForbidden and tt:IsForbidden()) then return end
    local unit = TooltipUnit(tt, data)
    if not unit then return end
    local nick = N:GetForUnit(unit)
    if not nick then return end
    local key, _, first, _, raw, second = ns.UnitKey(unit)
    if not key then return end
    local name = tt.GetName and tt:GetName()
    local line = name and _G[name .. "TextLeft1"]
    if not line or (line.IsForbidden and line:IsForbidden()) then return end
    local text = line:GetText()
    if type(text) ~= "string" or issecret(text) or text == written[line] then return end
    local new = ns.ReplaceName(text, nick, first, raw, second, N:GetSetting("tooltipStyle") == "both")
    if new == text then return end
    written[line] = new
    line:SetText(new)
    if tt:IsShown() then tt:Show() end -- re-fit the width to the longer line
end

local function SafeRewrite(tt, data)
    local ok, err = pcall(Rewrite, tt, data)
    if not ok and ns.chatStats then ns.chatStats.lastError = "tooltip: " .. tostring(err) end
end

-- Registered after login so we run AFTER tooltip addons that rebuild the
-- name line themselves (ElvUI registers its unit post-call at login).
local registered = false
local function Register()
    if registered then return end
    registered = true
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, SafeRewrite)
    elseif GameTooltip and GameTooltip:HasScript("OnTooltipSetUnit") then
        GameTooltip:HookScript("OnTooltipSetUnit", SafeRewrite)
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    C_Timer.After(1, Register)
end)
