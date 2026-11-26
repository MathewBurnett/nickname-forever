-------------------------------------------------------------------------------
--  Nicknames - damage meters and guild roster
--
--  Neither gives us a unit, so their name FontStrings are hooked "text-only"
--  (see ns.ReplaceKnownNames): any saved character's name found in the text
--  is swapped for the nickname.
--
--  Damage meters: EllesmereUI Damage Meters (EllesmereUIDMFrame1..) and
--  EnhanceQoL Damage Meter (EnhanceQoLDamageMeterFrame1..). Blizzard makes
--  meter names SECRET during combat, so mid-fight bars show real names; they
--  switch to nicknames once the meter repaints out of combat.
--
--  Guild roster: the Communities guild list (and the standalone guild roster
--  where a client has one). Rows are found by polling while the window is
--  open, never by hooking Blizzard's list code.
-------------------------------------------------------------------------------
local _, ns = ...
local N = ns.N

local METER_PREFIXES = { "EllesmereUIDMFrame", "EnhanceQoLDamageMeterFrame" }

local function ScanMeters()
    if InCombatLockdown() then return end -- names are secret now anyway
    if not N:GetSetting("meters") then return end
    for _, prefix in ipairs(METER_PREFIXES) do
        for i = 1, 10 do
            local f = _G[prefix .. i]
            if not f then break end
            if f:IsShown() then ns.HookTextTree(f, "meters", 10) end
        end
    end
end

local function RosterScrollBoxes()
    local boxes = {}
    local cf = _G.CommunitiesFrame
    if cf and cf:IsShown() and cf.MemberList and cf.MemberList.ScrollBox then
        boxes[#boxes + 1] = cf.MemberList.ScrollBox
    end
    local gr = _G.GuildRosterContainer
    if gr and gr:IsVisible() and gr.ScrollBox then
        boxes[#boxes + 1] = gr.ScrollBox
    end
    return boxes
end

local function ScanRoster()
    if not N:GetSetting("guild") then return end
    for _, box in ipairs(RosterScrollBoxes()) do
        if not (box.IsForbidden and box:IsForbidden()) then
            local frames
            if box.GetFrames then
                local ok, list = pcall(box.GetFrames, box)
                if ok then frames = list end
            end
            if type(frames) ~= "table" and box.ScrollTarget then
                frames = { box.ScrollTarget:GetChildren() }
            end
            for _, row in ipairs(frames or {}) do
                ns.HookTextTree(row, "guild", 3)
            end
        end
    end
end

-- Damage meter bars get created as more players show up: look every 2s
-- (out of combat, only while a meter is shown). The roster only while open.
local started = false
local function Start()
    if started then return end
    started = true
    C_Timer.NewTicker(2, ScanMeters)
    C_Timer.NewTicker(0.5, ScanRoster)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(3, function() Start(); ScanMeters() end)
    else
        -- combat ended: meters repaint with plain names; catch new bars
        C_Timer.After(0.5, ScanMeters)
    end
end)
