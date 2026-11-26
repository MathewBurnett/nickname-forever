-------------------------------------------------------------------------------
--  Nicknames - Display
--  Swaps character names for nicknames on name FontStrings we don't own:
--    * nameplates (Blizzard's and any addon plate parented to the nameplate,
--      e.g. EllesmereUI Nameplates / friendly name overlays)
--    * Blizzard unit frames (target, focus, party, compact raid frames)
--  EllesmereUI unit/raid/party frames are NOT touched here: they read our
--  nicknames themselves through the CustomNames bridge addon.
--
--  Method: a post-hook on the FontString's SetText / SetFormattedText. After
--  the owner writes its text we look up the unit, and if it has a nickname
--  we replace the name inside the text (so "60 | Bob" -> "60 | Bobby").
--  The owner's last original text is remembered so a later nickname change
--  or removal can be re-applied without waiting for the owner to repaint.
--  Secret text (protected content) is never touched.
-------------------------------------------------------------------------------
local _, ns = ...
local N = ns.N
local issecret = ns.issecret

local resolvers = setmetatable({}, { __mode = "k" }) -- fs -> function(fs) return unit
local category  = setmetatable({}, { __mode = "k" }) -- fs -> settings key
local original  = setmetatable({}, { __mode = "k" }) -- fs -> owner's last text
local writing = false

local SURNAME_SEP = (Constants and Constants.CharacterNameSeparatorConsts
    and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR) or " "

local function IsWordByte(b)
    -- ASCII letters/digits, or any UTF-8 byte (part of an accented letter)
    return b and (b >= 128 or (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122))
end

local function FindWhole(text, needle)
    if not needle or needle == "" then return nil end
    local init = 1
    while true do
        local s, e = text:find(needle, init, true)
        if not s then return nil end
        local before = text:sub(1, s - 1)
        -- a colour code ("|cffaabbcc", "|cnNAME:") or "|r" right before the
        -- name counts as a word boundary
        local leftOK = not IsWordByte(text:byte(s - 1))
            or before:find("|c%x%x%x%x%x%x%x%x$") or before:find("|cn[^:|]*:$") or before:find("|r$")
        local after = text:sub(e + 1, e + 2)
        local rightOK = not IsWordByte(text:byte(e + 1)) or after == "|r"
        if leftOK and rightOK then
            return s, e
        end
        init = e + 1
    end
end

-- Replace the unit's displayed name inside text with nick. Tries the longest
-- form first ("First Surname"), then the raw UnitName value, then the first name.
-- keepName: write "nick (name)" instead of just "nick".
function ns.ReplaceName(text, nick, first, raw, second, keepName)
    local candidates = {}
    if type(second) == "string" and second ~= "" then
        candidates[#candidates + 1] = first .. SURNAME_SEP .. second
        candidates[#candidates + 1] = first .. "-" .. second
    end
    if raw and raw ~= first then candidates[#candidates + 1] = raw end
    candidates[#candidates + 1] = first
    for i = 1, #candidates do
        local s, e = FindWhole(text, candidates[i])
        if s then
            local found = text:sub(s, e)
            local rep = (keepName and found ~= nick) and (nick .. " (" .. found .. ")") or nick
            return text:sub(1, s - 1) .. rep .. text:sub(e + 1)
        end
    end
    return text
end

-------------------------------------------------------------------------------
--  Text-only FontStrings (damage meters, guild roster): no unit to ask, so
--  look for any saved character's name in the text itself. Full names first;
--  a bare first name only when exactly one saved character has it.
-------------------------------------------------------------------------------
local known -- cached list, rebuilt when nicknames change
local function KnownNames()
    if known then return known end
    known = {}
    local firstCount = {}
    for _, e in N:Iterate() do
        local first = e.name and e.name:match("^([^%s%-]+)")
        if first then firstCount[first] = (firstCount[first] or 0) + 1 end
    end
    for _, e in N:Iterate() do
        local first = e.name and e.name:match("^([^%s%-]+)")
        if first then
            known[#known + 1] = { full = e.name, first = first, nick = e.nick, firstUnique = firstCount[first] == 1 }
        end
    end
    return known
end

function ns.ReplaceKnownNames(text)
    local list = KnownNames()
    if #list == 0 then return text end
    for i = 1, #list do
        local k = list[i]
        local s, e = FindWhole(text, k.full)
        if not s and k.firstUnique and k.first ~= k.full then s, e = FindWhole(text, k.first) end
        if s then
            -- one name per text: stop so a nickname is never re-replaced
            return text:sub(1, s - 1) .. k.nick .. text:sub(e + 1)
        end
    end
    return text
end

local TEXT = "text" -- resolver marker for text-only FontStrings

local function Apply(fs, text)
    if type(text) ~= "string" or issecret(text) then return end
    local want = text
    if N:GetSetting(category[fs]) then
        local resolver = resolvers[fs]
        local unit = resolver ~= TEXT and resolver and resolver(fs)
        if resolver == TEXT then
            want = ns.ReplaceKnownNames(text)
        elseif unit then
            local key, _, first, _, raw, second = ns.UnitKey(unit)
            local nick = key and N:GetForUnit(unit)
            if nick then want = ns.ReplaceName(text, nick, first, raw, second) end
        end
    end
    local cur = fs:GetText()
    if issecret(cur) or cur == want then return end
    writing = true
    fs:SetText(want)
    writing = false
end

local function OnOwnerSetText(fs)
    if writing then return end
    local text = fs:GetText()
    if type(text) ~= "string" or issecret(text) then
        original[fs] = nil
        return
    end
    original[fs] = text
    Apply(fs, text)
end

local function IsFontString(obj)
    return type(obj) == "table" and type(obj.GetObjectType) == "function"
        and not (obj.IsForbidden and obj:IsForbidden())
        and obj:GetObjectType() == "FontString"
end

function ns.HookNameFontString(fs, resolver, settingKey)
    if not IsFontString(fs) then return end
    if not resolvers[fs] then
        hooksecurefunc(fs, "SetText", OnOwnerSetText)
        if fs.SetFormattedText then hooksecurefunc(fs, "SetFormattedText", OnOwnerSetText) end
    end
    resolvers[fs] = resolver
    category[fs] = settingKey
    OnOwnerSetText(fs)
end

function ns.HookTextFontString(fs, settingKey)
    if resolvers[fs] then return end
    ns.HookNameFontString(fs, TEXT, settingKey)
end

-- Every FontString under frame (to a small depth), hooked as text-only.
function ns.HookTextTree(frame, settingKey, depth)
    if not frame or (frame.IsForbidden and frame:IsForbidden()) then return end
    depth = depth or 8
    local regions = { frame:GetRegions() }
    for i = 1, #regions do
        local r = regions[i]
        if not resolvers[r] and IsFontString(r) then ns.HookNameFontString(r, TEXT, settingKey) end
    end
    if depth <= 0 then return end
    local children = { frame:GetChildren() }
    for i = 1, #children do ns.HookTextTree(children[i], settingKey, depth - 1) end
end

function ns.IsHooked(fs) return resolvers[fs] ~= nil end

function ns.RefreshDisplay()
    for fs in pairs(resolvers) do
        local text = original[fs]
        if text then Apply(fs, text) end
    end
end

-------------------------------------------------------------------------------
--  Unit resolvers
-------------------------------------------------------------------------------
-- Walk up from the FontString to the first frame that knows its unit.
local function ParentUnit(fs)
    local f = fs:GetParent()
    for _ = 1, 6 do
        if not f or (f.IsForbidden and f:IsForbidden()) then return nil end
        local u = f.namePlateUnitToken or f.displayedUnit or f.unit
        if type(u) == "string" and not issecret(u) then return u end
        f = f:GetParent()
    end
end

ns.ParentUnit = ParentUnit

-------------------------------------------------------------------------------
--  Nameplates
-------------------------------------------------------------------------------
local function NameplateUnit(fs)
    -- Plates are pooled: always resolve the unit at paint time.
    return ParentUnit(fs)
end

local function ScanNameplate(np)
    if not np or (np.IsForbidden and np:IsForbidden()) then return end
    local uf = np.UnitFrame
    if uf and not (uf.IsForbidden and uf:IsForbidden()) then
        ns.HookNameFontString(uf.name, NameplateUnit, "nameplates")
    end
    -- Addon plates (EllesmereUI etc.) parented to the nameplate, exposing .name
    local children = { np:GetChildren() }
    for i = 1, #children do
        local child = children[i]
        if child ~= uf and not (child.IsForbidden and child:IsForbidden()) then
            ns.HookNameFontString(child.name, NameplateUnit, "nameplates")
            ns.HookNameFontString(child.Name, NameplateUnit, "nameplates")
        end
    end
end

local function ScanAllNameplates()
    if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
    for _, np in ipairs(C_NamePlate.GetNamePlates() or {}) do ScanNameplate(np) end
end

-------------------------------------------------------------------------------
--  Blizzard unit frames
-------------------------------------------------------------------------------
local function FrameUnit(fs) return ParentUnit(fs) end

local BLIZZ_FRAMES = {
    "PlayerFrame", "TargetFrame", "FocusFrame", "TargetFrameToT", "FocusFrameToT",
    "PartyMemberFrame1", "PartyMemberFrame2", "PartyMemberFrame3", "PartyMemberFrame4",
}

local function ScanBlizzardFrames()
    for _, gname in ipairs(BLIZZ_FRAMES) do
        local f = _G[gname]
        if f and not (f.IsForbidden and f:IsForbidden()) then
            ns.HookNameFontString(f.name or f.Name, FrameUnit, "frames")
        end
    end
    local pf = _G.PartyFrame
    if pf then
        for i = 1, 4 do
            local m = pf["MemberFrame" .. i]
            if m and not (m.IsForbidden and m:IsForbidden()) then
                ns.HookNameFontString(m.name or m.Name, FrameUnit, "frames")
            end
        end
    end
end

-- Blizzard compact raid/party frames (and Blizzard nameplates, which are
-- compact unit frames too).
if type(_G.CompactUnitFrame_UpdateName) == "function" then
    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if not frame or (frame.IsForbidden and frame:IsForbidden()) then return end
        local fs = frame.name
        if not fs or resolvers[fs] then return end
        local unit = frame.unit
        local isPlate = type(unit) == "string" and not issecret(unit) and unit:find("^nameplate") ~= nil
        ns.HookNameFontString(fs, ParentUnit, isPlate and "nameplates" or "frames")
    end)
end

-------------------------------------------------------------------------------
--  Events
-------------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ev:RegisterEvent("GROUP_ROSTER_UPDATE")
ev:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        -- Let the plate addon finish building its frame first.
        C_Timer.After(0, function()
            if issecret(unit) then return end
            local np = C_NamePlate.GetNamePlateForUnit(unit)
            if np then ScanNameplate(np) end
        end)
    elseif event == "GROUP_ROSTER_UPDATE" then
        C_Timer.After(0.2, ScanBlizzardFrames)
    else
        ScanBlizzardFrames()
        C_Timer.After(1, function() ScanBlizzardFrames(); ScanAllNameplates() end)
    end
end)

N.RegisterCallback("NicknamesDisplay", "NICKNAME_CHANGED", function() known = nil; ns.RefreshDisplay() end)
N.RegisterCallback("NicknamesDisplay", "SETTINGS_CHANGED", function() ns.RefreshDisplay() end)
