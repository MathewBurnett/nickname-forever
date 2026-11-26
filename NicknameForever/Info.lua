-------------------------------------------------------------------------------
--  Nickname Forever - info page (the "i" button in the /nick window)
--  What the addon does, the slash commands, and where to send feedback.
-------------------------------------------------------------------------------
local ADDON, ns = ...

local NAME = ns.SURNAMES and "First Surname" or "Name-Realm"

local COMMANDS = {
    { "/nick", "Open or close this window." },
    { "/nick target <nickname>", "Nickname your current target. Leave it blank to clear." },
    { "/nick set " .. NAME .. " = <nickname>", "Nickname a player by name." },
    { "/nick remove " .. NAME, "Remove a player's nickname." },
    { "/nick list", "Print every nickname to chat." },
    { "/nick minimap", "Show or hide the minimap button." },
    { "/nick debug", "Diagnostic details - include these in bug reports." },
}

local function Version()
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local v = get and get(ADDON, "Version")
    if type(v) ~= "string" or v == "" then return "?" end
    if v:find("@", 1, true) then return "dev build" end -- unpackaged source copy
    return v
end

function ns.CreateInfoPage(parent, Group, Label)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    -- About
    local about = Group(page, "About", 12, -38, 416, 92)
    local text = Label(about, "Give any player a nickname that only you see. Right-click them and choose "
        .. "|cffffd100Set Nickname|r - the nickname then shows on nameplates, unit frames, chat, tooltips, "
        .. "damage meters and the guild roster. You can also open this window from the minimap button "
        .. "or the AddOns menu next to the minimap.", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", 10, -22)
    text:SetWidth(396)
    text:SetJustifyH("LEFT")
    text:SetSpacing(2)
    local ver = Label(about, "Version " .. Version(), "GameFontDisableSmall")
    ver:SetPoint("BOTTOMRIGHT", -10, 8)

    -- Slash commands
    local ROW = 28
    local cmds = Group(page, "Slash commands", 12, -138, 416, 30 + #COMMANDS * ROW + 18)
    for i, c in ipairs(COMMANDS) do
        local y = -22 - (i - 1) * ROW
        local cmd = Label(cmds, c[1], "GameFontNormalSmall")
        cmd:SetPoint("TOPLEFT", 10, y)
        local desc = Label(cmds, c[2], "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", 22, y - 12)
        desc:SetWidth(384)
        desc:SetJustifyH("LEFT")
    end
    local alias = Label(cmds, "|cffffd100/nickname|r and |cffffd100/nicknames|r work the same as |cffffd100/nick|r.", "GameFontDisableSmall")
    alias:SetPoint("BOTTOMLEFT", 10, 10)

    -- Feedback
    local fbY = -138 - (30 + #COMMANDS * ROW + 18) - 8
    local fb = Group(page, "Feedback & issues", 12, fbY, 416, 104)
    local fbText = Label(fb, "Found a bug or have an idea? Please raise an issue on GitHub. "
        .. "For bugs, include the output of |cffffd100/nick debug|r and what you were doing.", "GameFontHighlightSmall")
    fbText:SetPoint("TOPLEFT", 10, -22)
    fbText:SetWidth(396)
    fbText:SetJustifyH("LEFT")
    fbText:SetSpacing(2)
    if ns.ISSUES_URL ~= "" then
        -- WoW can't open links, so offer the address in a box to copy from
        local box = CreateFrame("EditBox", nil, fb, "InputBoxTemplate")
        box:SetSize(390, 20)
        box:SetPoint("BOTTOMLEFT", 16, 26)
        box:SetAutoFocus(false)
        box:SetText(ns.ISSUES_URL)
        box:SetCursorPosition(0)
        box:SetScript("OnTextChanged", function(self, user) if user then self:SetText(ns.ISSUES_URL); self:HighlightText() end end)
        box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        box:SetScript("OnEscapePressed", box.ClearFocus)
        local hint = Label(fb, "Click the address, then press Ctrl+C to copy it.", "GameFontDisableSmall")
        hint:SetPoint("BOTTOMLEFT", 10, 8)
    else
        local soon = Label(fb, "A public GitHub page is coming soon.", "GameFontNormalSmall")
        soon:SetPoint("BOTTOMLEFT", 10, 12)
    end

    return page
end
