-------------------------------------------------------------------------------
--  Nickname Forever - manager window (/nick)
--  Settings toggles, add-by-name, and the list of everyone you've nicknamed.
-------------------------------------------------------------------------------
local _, ns = ...
local N = ns.N

local ROWS, ROW_H = 10, 24
local win

local function Label(parent, text, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    fs:SetText(text)
    return fs
end

local function Check(parent, text, settingKey, x, y, isValue)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", x, y)
    local lbl = cb.text or cb.Text
    if not lbl then
        lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    end
    lbl:SetFontObject("GameFontHighlightSmall")
    lbl:SetText(text)
    cb.Refresh = function()
        if isValue then cb:SetChecked(N:GetSetting(settingKey) == isValue)
        else cb:SetChecked(N:GetSetting(settingKey) and true or false) end
    end
    cb:SetScript("OnClick", function(self)
        if isValue then N:SetSetting(settingKey, self:GetChecked() and isValue or "nick")
        else N:SetSetting(settingKey, self:GetChecked() and true or false) end
    end)
    return cb
end

local function SortedEntries()
    local list = {}
    for key, e in N:Iterate() do list[#list + 1] = { key = key, e = e } end
    table.sort(list, function(a, b) return a.e.name:lower() < b.e.name:lower() end)
    return list
end

local function Refresh()
    if not win or not win:IsShown() then return end
    for _, cb in ipairs(win.checks) do cb.Refresh() end
    local list = SortedEntries()
    local maxOffset = math.max(0, #list - ROWS)
    win.offset = math.min(win.offset or 0, maxOffset)
    for i = 1, ROWS do
        local row = win.rows[i]
        local item = list[i + win.offset]
        if item then
            local e = item.e
            row.key = item.key
            row.entry = e
            row.name:SetText(e.name)
            row.nick:SetText(e.nick)
            row:Show()
        else
            row:Hide()
        end
    end
    win.empty:SetShown(#list == 0)
    win.count:SetText(#list > ROWS and ("%d-%d of %d (scroll)"):format(win.offset + 1, math.min(#list, win.offset + ROWS), #list) or "")
end
ns.RefreshManager = Refresh

-- A titled, faintly bordered box that groups related controls.
local function Group(parent, title, x, y, w, h)
    local g = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    g:SetPoint("TOPLEFT", x, y)
    g:SetSize(w, h)
    g:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    g:SetBackdropColor(1, 1, 1, 0.03)
    g:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.35)
    local t = Label(g, title, "GameFontNormalSmall")
    t:SetPoint("TOPLEFT", 8, -6)
    return g
end

local function CreateWindow()
    local f = CreateFrame("Frame", "NicknamesManager", UIParent, "BackdropTemplate")
    f:SetSize(440, 566)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    f:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
    f:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
    f:Hide()
    tinsert(UISpecialFrames, "NicknamesManager")

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("TOPLEFT", 12, -9)
    icon:SetTexture(ns.ICON)
    local title = Label(f, ns.TITLE, "GameFontNormalLarge")
    title:SetPoint("LEFT", icon, "RIGHT", 6, 0)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    -- Options page and info page share the window; the "i" button swaps them.
    local main = CreateFrame("Frame", nil, f)
    main:SetAllPoints()
    local info = ns.CreateInfoPage(f, Group, Label)
    info:Hide()

    local infoBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    infoBtn:SetSize(20, 20)
    infoBtn:SetPoint("RIGHT", close, "LEFT", -4, 0)
    infoBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    infoBtn:SetBackdropColor(0.3, 0.6, 0.9, 0.15)
    infoBtn:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.9)
    local infoGlyph = infoBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoGlyph:SetPoint("CENTER", 0, 0)
    infoGlyph:SetTextColor(0.6, 0.85, 1)
    local function ShowPage(showInfo)
        info:SetShown(showInfo)
        main:SetShown(not showInfo)
        infoGlyph:SetText(showInfo and "x" or "i")
        if not showInfo then Refresh() end
    end
    infoBtn:SetScript("OnClick", function() ShowPage(not info:IsShown()) end)
    infoBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.6, 0.9, 0.35)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(info:IsShown() and "Back to options" or "Info & commands")
        GameTooltip:Show()
    end)
    infoBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.3, 0.6, 0.9, 0.15)
        GameTooltip:Hide()
    end)
    f.ShowPage = ShowPage
    f.mainPage, f.infoPage, f.infoButton, f.infoGlyph = main, info, infoBtn, infoGlyph
    ShowPage(false)

    -- Settings, grouped
    local where = Group(main, "Show nicknames in", 12, -38, 416, 68)
    local style = Group(main, "Name style", 12, -112, 204, 68)
    local iface = Group(main, "Interface", 224, -112, 204, 68)
    f.checks = {
        Check(where, "Chat",          "chat",       6, -18),
        Check(where, "Nameplates",    "nameplates", 144, -18),
        Check(where, "Unit frames",   "frames",     282, -18),
        Check(where, "Tooltips",      "tooltips",   6, -40),
        Check(where, "Damage meters", "meters",     144, -40),
        Check(where, "Guild roster",  "guild",      282, -40),

        Check(style, "Chat: \"Nickname (Name)\"",    "chatStyle",    6, -18, "both"),
        Check(style, "Tooltip: \"Nickname (Name)\"", "tooltipStyle", 6, -40, "both"),

        Check(iface, "Right-click menu", "menu",    6, -18),
        Check(iface, "Minimap button",   "minimap", 6, -40),
    }

    local note = Label(main, "EllesmereUI frames: turn on |cffffd100Show Nicknames|r in EllesmereUI Unit Frames.", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", 16, -186)
    note:SetWidth(410)
    note:SetJustifyH("LEFT")

    -- Add by name
    local add = Group(main, "Add a nickname", 12, -202, 416, 64)
    local addName = CreateFrame("EditBox", nil, add, "InputBoxTemplate")
    addName:SetSize(120, 22); addName:SetPoint("TOPLEFT", 14, -34); addName:SetAutoFocus(false)
    local addNick = CreateFrame("EditBox", nil, add, "InputBoxTemplate")
    addNick:SetSize(120, 22); addNick:SetPoint("LEFT", addName, "RIGHT", 14, 0); addNick:SetAutoFocus(false)
    addNick:SetMaxLetters(40)
    local l1 = Label(add, ns.SURNAMES and "Character (First Surname)" or "Character name"); l1:SetPoint("BOTTOMLEFT", addName, "TOPLEFT", -4, 2)
    local l2 = Label(add, "Nickname"); l2:SetPoint("BOTTOMLEFT", addNick, "TOPLEFT", -4, 2)
    local addBtn = CreateFrame("Button", nil, add, "UIPanelButtonTemplate")
    addBtn:SetSize(64, 22); addBtn:SetPoint("LEFT", addNick, "RIGHT", 8, 0); addBtn:SetText(ADD or "Add")
    local function DoAdd()
        local who, nick = strtrim(addName:GetText() or ""), strtrim(addNick:GetText() or "")
        if who == "" or nick == "" then return end
        N:Set(who, nil, nick)
        addName:SetText(""); addNick:SetText(""); addName:ClearFocus(); addNick:ClearFocus()
    end
    addBtn:SetScript("OnClick", DoAdd)
    addNick:SetScript("OnEnterPressed", DoAdd)
    addName:SetScript("OnEnterPressed", function() addNick:SetFocus() end)
    addName:SetScript("OnTabPressed", function() addNick:SetFocus() end)
    addName:SetScript("OnEscapePressed", addName.ClearFocus)
    addNick:SetScript("OnEscapePressed", addNick.ClearFocus)
    local tgtBtn = CreateFrame("Button", nil, add, "UIPanelButtonTemplate")
    tgtBtn:SetSize(64, 22); tgtBtn:SetPoint("LEFT", addBtn, "RIGHT", 4, 0); tgtBtn:SetText(TARGET or "Target")
    tgtBtn:SetScript("OnClick", function()
        local key, display = ns.UnitKey("target")
        if key then addName:SetText(display); addNick:SetFocus() end
    end)

    -- Nickname list
    local box = Group(main, "Your nicknames", 12, -274, 416, 266)
    local hName = Label(box, "Character", "GameFontDisableSmall"); hName:SetPoint("TOPLEFT", 16, -22)
    local hNick = Label(box, "Nickname", "GameFontDisableSmall"); hNick:SetPoint("TOPLEFT", 188, -22)

    local list = CreateFrame("Frame", nil, box)
    list:SetPoint("TOPLEFT", 6, -34)
    list:SetPoint("BOTTOMRIGHT", -6, 4)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        f.offset = math.max(0, (f.offset or 0) - delta * 3)
        Refresh()
    end)

    f.rows = {}
    for i = 1, ROWS do
        local row = CreateFrame("Frame", nil, list)
        row:SetSize(404, ROW_H - 2)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * (ROW_H - 2))
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.04 or 0)
        row.name = Label(row, "", "GameFontHighlight")
        row.name:SetPoint("LEFT", 8, 0); row.name:SetWidth(168); row.name:SetJustifyH("LEFT")
        row.nick = Label(row, "", "GameFontNormal")
        row.nick:SetPoint("LEFT", 180, 0); row.nick:SetWidth(136); row.nick:SetJustifyH("LEFT")
        local edit = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        edit:SetSize(46, 20); edit:SetPoint("RIGHT", -34, 0); edit:SetText(EDIT or "Edit")
        edit:SetScript("OnClick", function()
            local e = row.entry
            if e then ns.ShowEditDialog(e.name) end
        end)
        local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        del:SetSize(26, 20); del:SetPoint("RIGHT", -4, 0); del:SetText("X")
        del:SetScript("OnClick", function() if row.key then N:RemoveKey(row.key) end end)
        f.rows[i] = row
    end

    f.empty = Label(list, "No nicknames yet.\nRight-click a player (frame, chat name, party) and choose |cffffd100Set Nickname|r.", "GameFontDisable")
    f.empty:SetPoint("TOP", 0, -40)
    f.count = Label(main, "", "GameFontDisableSmall")
    f.count:SetPoint("BOTTOMRIGHT", -14, 10)

    f:SetScript("OnShow", Refresh)
    f:SetScript("OnHide", function() ShowPage(false) end) -- always reopen on the options
    return f
end

function ns.ToggleManager()
    win = win or CreateWindow()
    win:SetShown(not win:IsShown())
end

N.RegisterCallback("NicknamesManager", "NICKNAME_CHANGED", Refresh)
N.RegisterCallback("NicknamesManager", "SETTINGS_CHANGED", Refresh)

-------------------------------------------------------------------------------
--  Esc > Options > AddOns entry (just a launcher)
-------------------------------------------------------------------------------
ns.AfterLoad(function()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
    local panel = CreateFrame("Frame")
    local ic = panel:CreateTexture(nil, "ARTWORK")
    ic:SetSize(32, 32); ic:SetPoint("TOPLEFT", 16, -12); ic:SetTexture(ns.ICON)
    local t = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("LEFT", ic, "RIGHT", 8, 0); t:SetText(ns.TITLE)
    local d = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    d:SetPoint("TOPLEFT", ic, "BOTTOMLEFT", 0, -10); d:SetWidth(560); d:SetJustifyH("LEFT")
    d:SetText("Right-click any player and choose Set Nickname. Manage everything with /nick.")
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetSize(180, 24); b:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -12); b:SetText("Open " .. ns.TITLE)
    b:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        win = win or CreateWindow()
        win:Show()
    end)
    pcall(function()
        local cat = Settings.RegisterCanvasLayoutCategory(panel, ns.TITLE)
        Settings.RegisterAddOnCategory(cat)
    end)
end)
