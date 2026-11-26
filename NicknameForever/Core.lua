-------------------------------------------------------------------------------
--  Nicknames - Core
--  Storage, name normalisation, public API, callbacks and slash commands.
--
--  Identity:
--    * WoW Forever (regionally unique names): a character is "First Surname".
--      UnitName returns (first, surname); chat links carry the full name
--      (possibly with the surname joined by "-" and/or a trailing "-Realm").
--      Key = "first surname" (lower case), no realm.
--    * Retail / everything else: key = "first-realm" (lower case).
--  Secret values (12.x protected content) are never inspected: anything
--  secret simply shows its real name.
-------------------------------------------------------------------------------
local ADDON, ns = ...
ns.ADDON = ADDON
ns.TITLE = "Nickname Forever"
ns.ICON = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Icon"
ns.ICON_INLINE = "|T" .. ns.ICON .. ":16:16|t "
-- Public issue tracker; shown on the info page. Empty = "coming soon".
ns.ISSUES_URL = "https://github.com/MathewBurnett/nickname-forever/issues"

local Nicknames = {}
_G.Nicknames = Nicknames
ns.N = Nicknames

local _issecret = _G.issecretvalue
local function issecret(v)
    return _issecret ~= nil and v ~= nil and _issecret(v) == true
end
ns.issecret = issecret

local interface = select(4, GetBuildInfo()) or 0
ns.IS_FOREVER = (interface >= 16000 and interface < 20000)
    or (_G.EllesmereUI and _G.EllesmereUI.IS_FOREVER == true) or false

-- Names are "First Surname" (regionally unique) rather than "Name-Realm".
local regional = _G.RegionalUniqueNamesEnabled
ns.SURNAMES = (type(regional) == "function" and regional() == true) or ns.IS_FOREVER

ns.SURNAME_SEP = (Constants and Constants.CharacterNameSeparatorConsts
    and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR) or " "

local DEFAULT_SETTINGS = {
    chat       = true,   -- rewrite player names in chat
    chatStyle  = "nick", -- "nick" = Nickname, "both" = Nickname (Name)
    nameplates = true,   -- rewrite names on nameplates
    frames     = true,   -- rewrite names on unit/raid frames (Blizzard, Cell, ElvUI/oUF)
    meters     = true,   -- rewrite names on damage meters (EllesmereUI / EnhanceQoL)
    guild      = true,   -- rewrite names in the guild roster
    tooltips   = true,   -- rewrite the name on unit tooltips
    tooltipStyle = "both", -- "nick" = Nickname, "both" = Nickname (Name)
    menu       = true,   -- add the right-click menu entries
    minimap    = true,   -- show the minimap button
    minimapAngle = 225,  -- minimap button position (degrees around the minimap)
}

local db -- NicknamesDB once loaded

-------------------------------------------------------------------------------
--  Printing
-------------------------------------------------------------------------------
local PREFIX = "|cff66ccffNickname Forever|r: "
ns.PREFIX = PREFIX
function ns.Print(fmt, ...)
    local msg = select("#", ...) > 0 and fmt:format(...) or fmt
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
end

-------------------------------------------------------------------------------
--  Name normalisation
-------------------------------------------------------------------------------
local function plain(v) return type(v) == "string" and not issecret(v) and v ~= "" end

local ownRealm
function ns.OwnRealm()
    if ownRealm then return ownRealm end
    local r = GetNormalizedRealmName and GetNormalizedRealmName()
    if not plain(r) then
        r = (GetRealmName and GetRealmName() or ""):gsub("[%s%-]", "")
    end
    if r ~= "" then ownRealm = r end
    return r
end

-- Trailing "-X" pieces that are a realm / ruleset tag, not a surname.
local RULESETS = { pve = true, pvp = true, rp = true, hc = true }
local function IsRealmSuffix(s)
    local l = s:lower()
    local own = (ns.OwnRealm() or ""):lower()
    return (own ~= "" and l == own) or l:find("^camwow") ~= nil or RULESETS[l] == true
end

local SEP_PATTERN = ns.SURNAME_SEP:gsub("%p", "%%%0")

-- Parse any form of a character name into its identity.
--   name:   "Bob", "Bob-Realm", "Proto Col", "Proto-Col", "Proto Col-Realm"
--   second: UnitName's second return (Forever: surname, retail: realm), optional
-- Returns key, display, first, surname, realm  (nil if unusable)
function ns.Parse(name, second)
    if not plain(name) then return nil end
    if not plain(second) then second = nil end

    if ns.SURNAMES then
        local s = name
        -- strip a trailing realm/ruleset tag ("Proto Col-Realm")
        local base, suffix = s:match("^(.-)%-([^%-]+)$")
        if suffix and base ~= "" and IsRealmSuffix(suffix) then s = base end
        if SEP_PATTERN ~= "" and SEP_PATTERN ~= " " then s = s:gsub(SEP_PATTERN, " ") end
        local first, surname = s:match("^([^%s%-_]+)[%s%-_]+([^%s%-_]+)")
        if not first then first = s:match("^([^%s%-_]+)") end
        if not first then return nil end
        surname = surname or second
        local display = surname and (first .. ns.SURNAME_SEP .. surname) or first
        local key = surname and (first:lower() .. " " .. surname:lower()) or first:lower()
        return key, display, first, surname, nil
    end

    local first, realm = name:match("^([^%-]+)%-(.+)$")
    first = first or name
    first = first:match("^(%S+)") or first
    realm = realm or second or ns.OwnRealm() or ""
    realm = realm:gsub("[%s%-]", "")
    return first:lower() .. "-" .. realm:lower(), first .. "-" .. realm, first, nil, realm
end

-- Kept for callers that only want the key.
function ns.Key(name, second)
    local key, display, first = ns.Parse(name, second)
    return key, first, display
end

-- name, second for a player unit, using the unmodified name where it exists
-- (UnitName can hide your own surname depending on Blizzard's preference).
function ns.UnitNames(unit)
    if not unit or issecret(unit) then return nil end
    local exists = UnitExists(unit)
    if issecret(exists) or not exists then return nil end
    local isPlayer = UnitIsPlayer(unit)
    if issecret(isPlayer) or not isPlayer then return nil end
    local name, second = (UnitNameUnmodified or UnitName)(unit)
    if not plain(name) then return nil end
    if not plain(second) then second = nil end
    return name, second
end

-- key, display, first, surname, rawName, second   for a player unit
function ns.UnitKey(unit)
    local name, second = ns.UnitNames(unit)
    if not name then return nil end
    local key, display, first, surname = ns.Parse(name, second)
    if not key then return nil end
    return key, display, first, surname, name, second
end

-------------------------------------------------------------------------------
--  Callbacks.  Dot-call: Nicknames.RegisterCallback("MyAddon", event, fn)
--  Events: NICKNAME_CHANGED (key, newNick, oldNick, displayName)
--          SETTINGS_CHANGED (settingKey, value)
-------------------------------------------------------------------------------
local registry = {}

function Nicknames.RegisterCallback(owner, event, fn)
    assert(owner ~= nil and type(event) == "string" and type(fn) == "function",
        "Usage: Nicknames.RegisterCallback(owner, event, func)")
    registry[event] = registry[event] or {}
    registry[event][owner] = fn
end

function Nicknames.UnregisterCallback(owner, event)
    if registry[event] then registry[event][owner] = nil end
end

local function Fire(event, ...)
    local list = registry[event]
    if not list then return end
    for _, fn in pairs(list) do
        local ok, err = pcall(fn, event, ...)
        if not ok then geterrorhandler()(err) end
    end
end
ns.Fire = Fire

-------------------------------------------------------------------------------
--  Lookup.  A first-name-only entry (typed without a surname, or saved by
--  v1.0) is adopted by the first full "First Surname" that asks for it.
-------------------------------------------------------------------------------
local function Find(key, display, first, surname)
    if not (db and key) then return nil end
    local e = db.names[key]
    if e then return e, key end
    if ns.SURNAMES and surname then
        local loose = first:lower()
        e = db.names[loose]
        if e then
            db.names[loose] = nil
            e.name = display
            db.names[key] = e
            return e, key
        end
    elseif ns.SURNAMES and first then
        -- Only a first name to go on: accept it if exactly one saved
        -- character has that first name.
        local want, hit, hitKey = first:lower(), nil, nil
        for k, entry in pairs(db.names) do
            local f = entry.name and entry.name:match("^([^%s%-]+)")
            if f and f:lower() == want then
                if hit then return nil end
                hit, hitKey = entry, k
            end
        end
        return hit, hitKey
    end
    return nil
end

-------------------------------------------------------------------------------
--  Public API
-------------------------------------------------------------------------------
function Nicknames:GetByKey(key)
    local e = db and key and db.names[key]
    return e and e.nick or nil
end

-- name may be any form ("Bob", "Bob-Realm", "Proto Col", "Proto-Col")
function Nicknames:Get(name, second)
    local e = Find(ns.Parse(name, second))
    return e and e.nick or nil
end

function Nicknames:GetForUnit(unit)
    local key, display, first, surname = ns.UnitKey(unit)
    local e = Find(key, display, first, surname)
    return e and e.nick or nil
end

-- Returns the nickname if set, else the name you passed in.
function Nicknames:Resolve(name, second)
    return self:Get(name, second) or name
end

function Nicknames:Set(name, second, nick)
    if not db then return false end
    local key, display, first, surname, realm = ns.Parse(name, second)
    if not key then return false end
    if type(nick) == "string" then
        nick = strtrim(nick):gsub("|", "")   -- no escape codes in nicknames
        if nick == "" then nick = nil end
    else
        nick = nil
    end
    local old, oldKey = Find(key, display, first, surname)
    local oldNick = old and old.nick
    if nick == oldNick then return true end
    -- "Bob" typed for a saved "Bob Smith": act on that saved character
    if old and oldKey and oldKey ~= key and not surname then
        key, display = oldKey, old.name
    end
    if nick then
        db.names[key] = { nick = nick, name = display, realm = realm }
    else
        db.names[key] = nil
    end
    Fire("NICKNAME_CHANGED", key, nick, oldNick, display)
    return true
end

function Nicknames:SetForUnit(unit, nick)
    local name, second = ns.UnitNames(unit)
    if not name then return false end
    return self:Set(name, second, nick)
end

function Nicknames:RemoveKey(key)
    local e = db and db.names[key]
    if not e then return end
    db.names[key] = nil
    Fire("NICKNAME_CHANGED", key, nil, e.nick, e.name)
end

-- Iterator over key, entry (entry = { nick, name = display name, realm })
function Nicknames:Iterate()
    return pairs(db and db.names or {})
end

function Nicknames:GetSetting(k)
    if db and db.settings[k] ~= nil then return db.settings[k] end
    return DEFAULT_SETTINGS[k]
end

function Nicknames:SetSetting(k, v)
    if not db then return end
    db.settings[k] = v
    Fire("SETTINGS_CHANGED", k, v)
end

-------------------------------------------------------------------------------
--  Load + migration
-------------------------------------------------------------------------------
-- v1 (Forever) keyed everyone as "first-realm" without the surname.
local function MigrateV1()
    if not ns.SURNAMES then return end
    local old = {}
    for key, e in pairs(db.names) do
        if key:find("-", 1, true) then old[key] = e end
    end
    local myName, mySurname = ns.UnitNames("player")
    local myFirst = myName and myName:match("^([^%s%-]+)")
    for key, e in pairs(old) do
        db.names[key] = nil
        local first = (e.name or key):match("^([^%s%-]+)")
        if first then
            if myFirst and mySurname and first:lower() == myFirst:lower() then
                local k, display = ns.Parse(myFirst, mySurname)
                db.names[k] = { nick = e.nick, name = display }
            else
                -- surname unknown yet: adopted by the first full match seen
                db.names[first:lower()] = { nick = e.nick, name = first }
            end
        end
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
    if name ~= ADDON then return end
    self:UnregisterEvent("ADDON_LOADED")
    NicknamesDB = NicknamesDB or {}
    db = NicknamesDB
    db.names = db.names or {}
    db.settings = db.settings or {}
    if (db.version or 1) < 2 then MigrateV1() end
    db.version = 2
    ns.db = db
    for _, fn in ipairs(ns.OnLoaded) do
        local ok, err = pcall(fn)
        if not ok then geterrorhandler()(err) end
    end
end)

ns.OnLoaded = {}
function ns.AfterLoad(fn) table.insert(ns.OnLoaded, fn) end

-------------------------------------------------------------------------------
--  Slash commands
-------------------------------------------------------------------------------
local NAME_HINT = ns.SURNAMES and "<First Surname>" or "<Name[-Realm]>"

local function Usage()
    ns.Print("commands:")
    ns.Print("  /nick  - open the nickname list")
    ns.Print("  /nick target <nickname>  - nickname your target (blank clears)")
    ns.Print("  /nick set %s = <nickname>", NAME_HINT)
    ns.Print("  /nick remove %s", NAME_HINT)
    ns.Print("  /nick list")
    ns.Print("  /nick minimap  - show/hide the minimap button")
end

SLASH_NICKNAMES1 = "/nick"
SLASH_NICKNAMES2 = "/nickname"
SLASH_NICKNAMES3 = "/nicknames"
SlashCmdList.NICKNAMES = function(input)
    input = strtrim(input or "")
    local cmd, rest = input:match("^(%S+)%s*(.-)$")
    cmd = cmd and cmd:lower()
    if not cmd then
        if ns.ToggleManager then ns.ToggleManager() end
    elseif cmd == "target" or cmd == "t" then
        local key, display = ns.UnitKey("target")
        if not key then return ns.Print("target a player first.") end
        Nicknames:SetForUnit("target", rest)
        if rest ~= "" then ns.Print("%s is now |cffffd100%s|r.", display, rest)
        else ns.Print("cleared nickname for %s.", display) end
    elseif cmd == "set" then
        -- "/nick set Proto Col = Boss"  (or "/nick set Bob Bobby" for one-word names)
        local who, nick = rest:match("^(.-)%s*=%s*(.+)$")
        if not who then who, nick = rest:match("^(%S+)%s+(.+)$") end
        if not who or who == "" then return Usage() end
        local _, display = ns.Parse(who)
        if Nicknames:Set(who, nil, nick) then ns.Print("%s is now |cffffd100%s|r.", display or who, nick) end
    elseif cmd == "remove" or cmd == "clear" or cmd == "del" then
        if rest == "" then return Usage() end
        Nicknames:Set(rest, nil, nil)
        ns.Print("cleared nickname for %s.", rest)
    elseif cmd == "minimap" then
        local on = not Nicknames:GetSetting("minimap")
        Nicknames:SetSetting("minimap", on)
        ns.Print("minimap button %s.", on and "shown" or "hidden")
    elseif cmd == "debug" then
        if ns.Debug then ns.Debug() end
    elseif cmd == "list" then
        local n = 0
        for _, e in Nicknames:Iterate() do
            n = n + 1
            ns.Print("  %s -> |cffffd100%s|r", e.name, e.nick)
        end
        if n == 0 then ns.Print("no nicknames yet - right-click a player and choose Set Nickname.") end
    else
        Usage()
    end
end
