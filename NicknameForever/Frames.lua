-------------------------------------------------------------------------------
--  Nicknames - Cell and ElvUI (oUF) unit frames
--
--  Cell: Cell looks every name up through its own Cell.funcs.GetNickname
--  (an addon function, not Blizzard's, so wrapping it is taint-free). Our
--  nickname is returned first, so Cell's width trimming and group numbers
--  still apply to it. Cell's own nickname list is used for anyone we don't have.
--
--  ElvUI: frames are oUF (global ElvUF; any other oUF layout via the oUF
--  global too). Every tagged FontString (frame.Name and custom texts) is
--  post-hooked like the nameplates: the unit's name inside the tag text is
--  swapped for the nickname, everything else in the text is kept. ElvUI
--  nameplates count under the "Nameplates" setting.
--
--  Both follow the "Unit frames" setting.
-------------------------------------------------------------------------------
local _, ns = ...
local N = ns.N
local issecret = ns.issecret

local stats = { cell = false, oufObjects = 0, oufStrings = 0 }
ns.frameStats = stats

local function Plain(v) return type(v) == "string" and not issecret(v) and v ~= "" end

-------------------------------------------------------------------------------
--  Cell
-------------------------------------------------------------------------------
local Cell

local function CellNick(short, full)
    if not N:GetSetting("frames") then return end
    local names = Cell.vars and Cell.vars.names
    if type(names) == "table" then
        for i = 1, 2 do
            local n = (i == 1) and full or short
            if Plain(n) then
                local unit = names[n]
                if Plain(unit) then
                    local nick = N:GetForUnit(unit)
                    if nick then return nick end
                end
            end
        end
    end
    if Plain(full) then
        local nick = N:Get(full)
        if nick then return nick end
    end
    if Plain(short) then return N:Get(short) end -- only if that first name is unique
end

local function RefreshCell()
    if not stats.cell then return end
    local F = Cell.funcs
    if type(F.IterateAllUnitButtons) ~= "function" then return end
    pcall(F.IterateAllUnitButtons, function(b)
        local nt = b and b.indicators and b.indicators.nameText
        if nt and nt.UpdateName then pcall(nt.UpdateName, nt) end
    end)
end

local function SetupCell()
    if stats.cell then return end
    Cell = _G.Cell
    local F = type(Cell) == "table" and Cell.funcs
    if type(F) ~= "table" or type(F.GetNickname) ~= "function" then return end
    local orig = F.GetNickname
    F.GetNickname = function(short, full)
        local ok, nick = pcall(CellNick, short, full)
        if ok and nick then return nick end
        return orig(short, full)
    end
    stats.cell = true
    RefreshCell()
end

-------------------------------------------------------------------------------
--  oUF (ElvUI and other oUF layouts)
-------------------------------------------------------------------------------
local OUF_GLOBALS = { "ElvUF", "oUF" }
local initHooked = {}

local function OUFUnit(fs)
    local f = fs.parent -- oUF sets this on every tagged FontString
    local u = type(f) == "table" and (f.unit or f.__unit)
    if Plain(u) then return u end
    return ns.ParentUnit(fs)
end

local function HookOUFObject(obj)
    if type(obj) ~= "table" or (obj.IsForbidden and obj:IsForbidden()) then return end
    local cat = (obj.isNamePlate or obj.isNameplate) and "nameplates" or "frames"
    local fs = obj.Name
    if fs and not ns.IsHooked(fs) then
        ns.HookNameFontString(fs, OUFUnit, cat)
        if ns.IsHooked(fs) then stats.oufStrings = stats.oufStrings + 1 end
    end
    if type(obj.__tags) == "table" then
        for tagged in pairs(obj.__tags) do
            if not ns.IsHooked(tagged) then
                ns.HookNameFontString(tagged, OUFUnit, cat)
                if ns.IsHooked(tagged) then stats.oufStrings = stats.oufStrings + 1 end
            end
        end
    end
end

local function ScanOUF()
    local total = 0
    for _, g in ipairs(OUF_GLOBALS) do
        local o = _G[g]
        if type(o) == "table" and type(o.objects) == "table" then
            for _, obj in ipairs(o.objects) do HookOUFObject(obj) end
            total = total + #o.objects
            -- frames spawned later (group members joining, raid headers)
            if not initHooked[o] and type(o.RegisterInitCallback) == "function" then
                initHooked[o] = true
                pcall(o.RegisterInitCallback, o, function(obj)
                    C_Timer.After(0, function() HookOUFObject(obj) end)
                end)
            end
        end
    end
    stats.oufObjects = total
end

-------------------------------------------------------------------------------
--  Events
-------------------------------------------------------------------------------
local function ScanAll()
    SetupCell()
    ScanOUF()
end

local started = false
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("GROUP_ROSTER_UPDATE")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        ScanAll()
        C_Timer.After(2, ScanAll)
        if not started then
            started = true
            -- ElvUI adds custom texts / tags when settings change
            C_Timer.NewTicker(5, ScanOUF)
        end
    else
        C_Timer.After(0.5, ScanOUF)
    end
end)

N.RegisterCallback("NicknamesFrames", "NICKNAME_CHANGED", RefreshCell)
N.RegisterCallback("NicknamesFrames", "SETTINGS_CHANGED", function(_, k)
    if k == "frames" then RefreshCell() end
end)
