-------------------------------------------------------------------------------
--  Nicknames - Chat
--  Replaces the VISIBLE text of player links (|Hplayer:Bob-Realm|h[Bob]|h)
--  with the nickname. The link target is untouched, so clicking, whispering,
--  inviting and the right-click menu keep working on the real character.
--
--  Taint-safe approach (same lane EllesmereUI Chat uses for its own channel
--  abbreviations): a hooksecurefunc post-hook on each OPEN chat frame's
--  AddMessage rewrites the just-stored line in the frame's history buffer
--  before it is drawn. No Blizzard function is replaced, no field is written
--  on a Blizzard frame, and the secure message handler runs exactly as stock.
--
--  EllesmereUI Chat draws its own copy of every line; that copy is patched
--  the same way (immediately, and once more on the next frame in case its
--  hook ran after ours).
--
--  Secret lines (chat lockdown in encounters / M+ / PvP) pass through whole,
--  so inside protected content chat shows real names.
-------------------------------------------------------------------------------
local _, ns = ...
local N = ns.N
local issecret = ns.issecret

-- Debug counters (/nick debug)
local stats = { hooks = 0, calls = 0, links = 0, changed = 0, euiPatched = 0, rescans = 0, errors = 0, lastError = nil, sample = nil }
ns.chatStats = stats

-- produced line -> the original it came from. Lets a rescan redo a line
-- with a new nickname (or restore it) and keeps transforms idempotent.
local original, originalCount = {}, 0
local function Remember(out, orig)
    if originalCount > 4000 then wipe(original); originalCount = 0 end
    original[out] = orig
    originalCount = originalCount + 1
end

local function DisplayFor(display, first, nick)
    -- display is e.g. "[|cffc69b6dBob Smith|r]" or "[Bob-Realm]"
    local s, e
    local init = 1
    while true do
        s, e = display:find(first, init, true)
        if not s then return nil end
        local before = display:sub(1, s - 1)
        -- skip a hit inside a colour escape (|cffXXXXXX or |cnNAME:)
        if not before:find("|c%x?%x?%x?%x?%x?%x?%x?$") and not before:find("|cn[^:|]*$") then
            break
        end
        init = e + 1
    end
    -- Swallow the rest of the visible name ("-Realm", " Surname") up to the
    -- next escape code or closing bracket.
    local stop = display:find("[|%]]", e + 1) or (#display + 1)
    local shown = display:sub(s, stop - 1)
    local replacement = nick
    if N:GetSetting("chatStyle") == "both" then
        replacement = nick .. " (" .. shown .. ")"
    end
    return display:sub(1, s - 1) .. replacement .. display:sub(stop)
end

local function Transform(msg)
    if type(msg) ~= "string" or issecret(msg) then return msg end
    local base = original[msg] or msg
    if not N:GetSetting("chat") then return base end
    if not base:find("|Hplayer:", 1, true) then return base end
    local changed = false
    local out = base:gsub("(|Hplayer:([^|]*)|h)(.-)(|h)", function(open, data, display, close)
        local target = data:match("^([^:]+)")
        if not target then return nil end
        local key, _, first = ns.Parse(target)
        local nick = key and N:Get(target)
        if not nick then return nil end
        local newDisplay = DisplayFor(display, first, nick)
        if not newDisplay then return nil end
        changed = true
        return open .. newDisplay .. close
    end)
    if not changed then return base end
    Remember(out, base)
    return out
end
ns.TransformChatLine = Transform

-- Rewrite the newest `count` entries (nil = all) of a ScrollingMessageFrame's buffer.
local function PatchBuffer(smf, count)
    local hb = smf and smf.historyBuffer
    if not (hb and hb.GetEntryAtIndex) then return false end
    count = count or (hb.GetNumElements and hb:GetNumElements()) or 0
    local any = false
    for i = 1, count do
        local e = hb:GetEntryAtIndex(i)
        if not e then break end
        local m = e.message
        if type(m) == "string" and not issecret(m) then
            local new = Transform(m)
            if new ~= m then e.message = new; any = true end
        end
    end
    return any
end

-------------------------------------------------------------------------------
--  EllesmereUI Chat: its window is a ScrollingMessageFrame child of the
--  chat panel it keeps in EllesmereUI._chatCFD(cf).bg.
-------------------------------------------------------------------------------
local euiSMF = setmetatable({}, { __mode = "k" })
local wrapped = setmetatable({}, { __mode = "k" })

-- EllesmereUI's window is an addon-created frame (no Blizzard security on
-- it), so its AddMessage can simply be wrapped: every line EllesmereUI
-- draws -- live, rebuilt, or replayed from saved history -- passes through
-- Transform first. Secret lines are passed on untouched.
local function WrapEUIWindow(smf)
    if wrapped[smf] then return end
    local orig = smf.AddMessage
    if type(orig) ~= "function" then return end
    wrapped[smf] = true
    smf.AddMessage = function(self, msg, ...)
        if type(msg) == "string" and not issecret(msg) then
            local ok, out = pcall(Transform, msg)
            if ok then
                if out ~= msg then stats.euiPatched = stats.euiPatched + 1 end
                msg = out
            else
                stats.errors = stats.errors + 1; stats.lastError = out
            end
        end
        return orig(self, msg, ...)
    end
end

local function FindEUIWindow(cf)
    local cached = euiSMF[cf]
    if cached then return cached end
    local EUI = _G.EllesmereUI
    local CFD = EUI and EUI._chatCFD
    if type(CFD) ~= "function" then return nil end
    local ok, d = pcall(CFD, cf)
    if not ok or type(d) ~= "table" or not d.bg then return nil end
    -- Lua-created ScrollingMessageFrames are intrinsics and report their
    -- object type as plain "Frame", so recognise the window by its methods.
    local children = { d.bg:GetChildren() }
    for i = 1, #children do
        local c = children[i]
        if c ~= cf and type(c.AddMessage) == "function" and type(c.GetNumMessages) == "function"
            and not (c.IsForbidden and c:IsForbidden()) then
            euiSMF[cf] = c
            WrapEUIWindow(c)
            return c
        end
    end
    return nil
end
ns.FindEUIChatWindow = FindEUIWindow

local function Redraw(smf)
    if smf.MarkDisplayDirty then smf:MarkDisplayDirty()
    elseif smf.RefreshDisplay then smf:RefreshDisplay() end
end

local pendingEUI = {}
local function DeferredEUIPass()
    for cf in pairs(pendingEUI) do
        pendingEUI[cf] = nil
        local smf = FindEUIWindow(cf)
        if smf and PatchBuffer(smf, 6) then Redraw(smf) end
        -- Blizzard's own (invisible under EUI) copy keeps its click zones in
        -- step with the visible text; it redraws with the next line.
        PatchBuffer(cf, 6)
    end
end

-------------------------------------------------------------------------------
--  The AddMessage post-hook
-------------------------------------------------------------------------------
local function OnAddMessageBody(cf, msg)
    stats.calls = stats.calls + 1
    if type(msg) ~= "string" or issecret(msg) then return end
    if not msg:find("|Hplayer:", 1, true) then return end
    if msg:find(ns.PREFIX, 1, true) == 1 then return end -- our own prints
    stats.links = stats.links + 1
    stats.sample = msg
    if not N:GetSetting("chat") then return end
    if PatchBuffer(cf, 1) then stats.changed = stats.changed + 1 end
    local smf = FindEUIWindow(cf)
    if smf then
        PatchBuffer(smf, 1)
        if not next(pendingEUI) then C_Timer.After(0, DeferredEUIPass) end
        pendingEUI[cf] = true
    end
end

local function OnAddMessage(cf, msg)
    local ok, err = pcall(OnAddMessageBody, cf, msg)
    if not ok then stats.errors = stats.errors + 1; stats.lastError = err end
end

-- Only hook frames Blizzard considers open: hooking an unopened temporary
-- window would run our code inside Blizzard's pop-out copy loop.
local hooked = setmetatable({}, { __mode = "k" })
local function IsOpen(cf)
    if cf.isTemporary then return cf.inUse == true end
    local id = cf.GetID and cf:GetID()
    if not id or id <= 0 then return false end
    if FCF_IsChatWindowIndexActive then return FCF_IsChatWindowIndexActive(id) and true or false end
    return true
end

local function ChatFrames()
    local names = _G.CHAT_FRAMES
    if type(names) ~= "table" then
        names = {}
        for i = 1, (NUM_CHAT_WINDOWS or 10) do names[i] = "ChatFrame" .. i end
    end
    local out = {}
    for _, fname in ipairs(names) do
        local cf = _G[fname]
        if cf and cf.AddMessage and fname ~= "ChatFrame2" -- combat log
            and not (cf.IsForbidden and cf:IsForbidden()) then
            out[#out + 1] = cf
        end
    end
    return out
end

local function HookOpenFrames()
    for _, cf in ipairs(ChatFrames()) do
        FindEUIWindow(cf) -- wraps EllesmereUI's window as soon as it exists
        if not hooked[cf] and IsOpen(cf) then
            hooked[cf] = true
            stats.hooks = stats.hooks + 1
            hooksecurefunc(cf, "AddMessage", OnAddMessage)
        end
    end
end

-- Re-apply nicknames to every stored line (old lines, EllesmereUI's replayed
-- history, and after a nickname is added/changed/removed).
function ns.RescanChat()
    stats.rescans = stats.rescans + 1
    for _, cf in ipairs(ChatFrames()) do
        if hooked[cf] then
            pcall(PatchBuffer, cf, nil)
            local smf = FindEUIWindow(cf)
            if smf then
                local ok, any = pcall(PatchBuffer, smf, nil)
                if ok and any then Redraw(smf) end
            end
        end
    end
end

-- Install late (after EllesmereUI Chat bridges its frames, so our hook runs
-- after its copy and both are patched in the same frame), then keep an eye
-- out for newly opened whisper windows.
local starter = CreateFrame("Frame")
starter:RegisterEvent("PLAYER_ENTERING_WORLD")
starter:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    C_Timer.After(2, function()
        HookOpenFrames()
        ns.RescanChat()
        C_Timer.NewTicker(2, HookOpenFrames)
        -- EllesmereUI replays its saved session history a little later
        C_Timer.After(3, ns.RescanChat)
        C_Timer.After(8, ns.RescanChat)
    end)
end)

N.RegisterCallback("NicknamesChat", "NICKNAME_CHANGED", function() ns.RescanChat() end)
N.RegisterCallback("NicknamesChat", "SETTINGS_CHANGED", function(_, k)
    if k == "chat" or k == "chatStyle" then ns.RescanChat() end
end)
