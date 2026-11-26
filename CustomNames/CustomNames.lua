-------------------------------------------------------------------------------
--  CustomNames bridge for Nicknames
--
--  EllesmereUI's raid, party and unit frames read nicknames from the
--  "CustomNames" library (LibStub("CustomNames")) and refresh on its
--  Name_Added / Name_Update / Name_Removed callbacks, but only when an addon
--  called "CustomNames" is loaded. This tiny addon is that, serving the
--  names stored by Nicknames. No data of its own.
-------------------------------------------------------------------------------
local Nicknames = _G.Nicknames
if not (Nicknames and LibStub) then return end

local lib = LibStub:NewLibrary("CustomNames", 1)
if not lib then return end -- a newer real CustomNames is already loaded

local _issecret = _G.issecretvalue
local function issecret(v) return _issecret ~= nil and v ~= nil and _issecret(v) == true end

-- name ("Name" or "Name-Realm") -> nickname, or the name itself
function lib.Get(name)
    if type(name) ~= "string" or issecret(name) then return name end
    return Nicknames:Get(name) or name
end

function lib.Set(name, nick)
    return Nicknames:Set(name, nil, nick)
end

function lib.Exists(name)
    return type(name) == "string" and not issecret(name) and Nicknames:Get(name) ~= nil
end

-- Same returns as UnitName, with the nickname in place of the name.
-- Consumers (EllesmereUI) treat "result == UnitName" as "no nickname" and
-- then show the full "First Surname". A nickname that IS the first name
-- (Proto Col -> "Proto") would be ignored, so it gets a no-op "|r" suffix:
-- renders identically, compares different.
function lib.UnitName(unit)
    local name, second = UnitName(unit)
    if not name or issecret(name) then return name, second end
    local nick = Nicknames:GetForUnit(unit)
    if nick then
        if nick == name then nick = nick .. "|r" end
        return nick, second
    end
    return name, second
end

function lib.UnitFullName(unit)
    local name, realm = UnitFullName(unit)
    if not name or issecret(name) then return name, realm end
    local nick = Nicknames:GetForUnit(unit)
    return nick or name, realm
end

function lib.GetUnitName(unit, showServer)
    local nick = Nicknames:GetForUnit(unit)
    if nick then return nick end
    return GetUnitName(unit, showServer)
end

function lib.GetList()
    local out = {}
    for _, e in Nicknames:Iterate() do
        out[e.name] = e.nick
    end
    return out
end

-------------------------------------------------------------------------------
--  Callbacks (CallbackHandler-style, dot call):
--  lib.RegisterCallback("MyAddon", "Name_Update", function(event, name, nick) end)
-------------------------------------------------------------------------------
local callbacks = {}

function lib.RegisterCallback(owner, event, fn)
    if type(event) ~= "string" then return end
    if type(fn) == "string" and type(owner) == "table" then
        local methodName = fn
        fn = function(...) return owner[methodName](owner, ...) end
    elseif fn == nil and type(owner) == "table" and type(owner[event]) == "function" then
        local o = owner
        fn = function(...) return o[event](o, ...) end
    end
    if type(fn) ~= "function" then return end
    callbacks[event] = callbacks[event] or {}
    callbacks[event][owner] = fn
end

function lib.UnregisterCallback(owner, event)
    if callbacks[event] then callbacks[event][owner] = nil end
end

function lib.UnregisterAllCallbacks(owner)
    for _, list in pairs(callbacks) do list[owner] = nil end
end

local function Fire(event, ...)
    local list = callbacks[event]
    if not list then return end
    for _, fn in pairs(list) do
        local ok, err = pcall(fn, event, ...)
        if not ok then geterrorhandler()(err) end
    end
end

Nicknames.RegisterCallback("CustomNamesBridge", "NICKNAME_CHANGED", function(_, key, nick, oldNick, display)
    if nick and not oldNick then
        Fire("Name_Added", display, nick)
    elseif oldNick and not nick then
        Fire("Name_Removed", display)
    else
        Fire("Name_Update", display, nick)
    end
end)
