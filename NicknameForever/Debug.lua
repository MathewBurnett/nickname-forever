-------------------------------------------------------------------------------
--  Nicknames - /nick debug
--  Prints what the addon can see, to diagnose "nickname not showing".
-------------------------------------------------------------------------------
local _, ns = ...
local N = ns.N

local function esc(s)
    if s == nil then return "nil" end
    if ns.issecret(s) then return "<secret>" end
    return tostring(s):gsub("|", "||")
end

local function yn(v) return v and "|cff00ff00yes|r" or "|cffff4040no|r" end

function ns.Debug()
    local P = ns.Print
    P("---- debug ----")
    P("interface %s  forever=%s  surnames=%s  RegionalUniqueNames=%s",
        tostring(select(4, GetBuildInfo())), tostring(ns.IS_FOREVER), tostring(ns.SURNAMES),
        tostring(RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled()))
    local n1, n2 = UnitName("player")
    local u1, u2 = (UnitNameUnmodified or UnitName)("player")
    P("UnitName(player) = [%s] [%s]   unmodified = [%s] [%s]", esc(n1), esc(n2), esc(u1), esc(u2))
    local key, display = ns.UnitKey("player")
    P("player key = [%s] display = [%s] nickname = [%s]", esc(key), esc(display), esc(N:GetForUnit("player")))
    if UnitExists("target") then
        local tk, td = ns.UnitKey("target")
        P("target key = [%s] display = [%s] nickname = [%s]", esc(tk), esc(td), esc(N:GetForUnit("target")))
        if ns.NameplateReport then
            P("target name texts (nameplates setting %s):", N:GetSetting("nameplates") and "on" or "off")
            for _, line in ipairs(ns.NameplateReport("target")) do P("%s", line) end
        end
    end
    local count = 0
    for k, e in N:Iterate() do
        count = count + 1
        if count <= 8 then P("  saved [%s] name=[%s] nick=[%s]", esc(k), esc(e.name), esc(e.nick)) end
    end
    P("saved entries: %d", count)

    -- EllesmereUI frames bridge
    local CN = LibStub and LibStub("CustomNames", true)
    local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("CustomNames")
    P("CustomNames bridge loaded=%s  lib=%s", yn(loaded), yn(CN ~= nil))
    if CN and CN.UnitName then
        local r = CN.UnitName("player")
        P("  bridge UnitName(player) = [%s]  differs from real name: %s (must be yes for EllesmereUI to use it)",
            esc(r), yn(r ~= (UnitName("player"))))
    end
    if not loaded and C_AddOns and C_AddOns.GetAddOnEnableState then
        P("  CustomNames enable state: %s (0 = disabled in the AddOns list)",
            tostring(C_AddOns.GetAddOnEnableState("CustomNames", UnitName("player"))))
    end

    -- Chat
    local s = ns.chatStats
    if s then
        P("chat: frames hooked=%d  messages seen=%d  with player links=%d  rewritten=%d  EUI patched=%d  rescans=%d  errors=%d",
            s.hooks, s.calls, s.links, s.changed, s.euiPatched, s.rescans, s.errors)
        if s.lastError then P("  last error: %s", esc(s.lastError)) end
        if s.sample then
            local function vis(x) return esc(x):gsub("||", "!") end
            P("  last line (| shown as !): %s", vis(s.sample))
            P("  transformed: %s", vis(ns.TransformChatLine(s.sample)))
        end
    end
    local cf1 = _G.ChatFrame1
    if cf1 then
        P("ChatFrame1 historyBuffer=%s  EUI window=%s", yn(cf1.historyBuffer ~= nil),
            yn(ns.FindEUIChatWindow and ns.FindEUIChatWindow(cf1) ~= nil))
        local smf = ns.FindEUIChatWindow and ns.FindEUIChatWindow(cf1)
        if smf then
            P("  EUI window type=%s historyBuffer=%s", tostring(smf:GetObjectType()), yn(smf.historyBuffer ~= nil))
        else
            local CFD = EllesmereUI and EllesmereUI._chatCFD
            local d = CFD and CFD(cf1)
            if d and d.bg then
                for i, c in ipairs({ d.bg:GetChildren() }) do
                    P("  panel child %d: type=%s AddMessage=%s", i, tostring(c:GetObjectType()), yn(type(c.AddMessage) == "function"))
                end
            else
                P("  no EllesmereUI chat panel on ChatFrame1")
            end
        end
    end
    -- Other unit frames
    local fs = ns.frameStats
    if fs then
        P("Cell: %s   oUF/ElvUI frames=%d  name texts hooked=%d",
            _G.Cell and (fs.cell and "|cff00ff00hooked|r" or "|cffff4040found, not hooked|r") or "not loaded",
            fs.oufObjects, fs.oufStrings)
    end
    -- Performance
    if UpdateAddOnMemoryUsage and GetAddOnMemoryUsage then
        UpdateAddOnMemoryUsage()
        P("memory: %.0f KB", GetAddOnMemoryUsage(ns.ADDON) or 0)
    end
    local prof = C_AddOnProfiler
    local M = Enum and Enum.AddOnProfilerMetric
    if prof and prof.GetAddOnMetric and M then
        local function ms(metric) local ok, v = pcall(prof.GetAddOnMetric, ns.ADDON, metric); return ok and v or 0 end
        P("cpu: recent avg %.3f ms/frame, peak %.2f ms (session avg %.3f)",
            ms(M.RecentAverageTime), ms(M.PeakTime), ms(M.SessionAverageTime))
    end
    P("---- end ----")
end
