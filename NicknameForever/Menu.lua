-------------------------------------------------------------------------------
--  Nicknames - right-click menu entries + the edit dialog
--  Uses Menu.ModifyMenu (the modern context-menu API), so it appears on unit
--  frames (any addon's, including EllesmereUI's), party/raid frames, chat
--  name links, the friends/guild/community lists, and nameplates.
-------------------------------------------------------------------------------
local _, ns = ...
local N = ns.N
local issecret = ns.issecret

-------------------------------------------------------------------------------
--  Edit dialog (our own frame, not StaticPopup, to stay clear of its taint)
-------------------------------------------------------------------------------
local dialog

local function CreateDialog()
    local f = CreateFrame("Frame", "NicknamesEditDialog", UIParent, "BackdropTemplate")
    f:SetSize(320, 130)
    f:SetPoint("CENTER", 0, 160)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
    })
    f:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
    f:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
    f:Hide()

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOP", 0, -12)

    f.edit = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    f.edit:SetSize(260, 24)
    f.edit:SetPoint("TOP", 0, -40)
    f.edit:SetAutoFocus(true)
    f.edit:SetMaxLetters(40)

    local function Btn(text, x, onClick)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(90, 24)
        b:SetPoint("BOTTOM", x, 14)
        b:SetText(text)
        b:SetScript("OnClick", onClick)
        return b
    end

    local function Save()
        if f.name then N:Set(f.name, f.realm, f.edit:GetText()) end
        f:Hide()
    end
    f.save   = Btn(SAVE or "Save", -96, Save)
    f.remove = Btn(REMOVE or "Remove", 0, function()
        if f.name then N:Set(f.name, f.realm, nil) end
        f:Hide()
    end)
    f.cancel = Btn(CANCEL or "Cancel", 96, function() f:Hide() end)

    f.edit:SetScript("OnEnterPressed", Save)
    f.edit:SetScript("OnEscapePressed", function() f:Hide() end)
    tinsert(UISpecialFrames, "NicknamesEditDialog")
    return f
end

-- name: any form of the character name; second: surname (Forever) or realm, optional
function ns.ShowEditDialog(name, second)
    if not name then return end
    dialog = dialog or CreateDialog()
    local key, display = ns.Parse(name, second)
    if not key then return end
    dialog.name, dialog.realm = name, second
    dialog.title:SetText(("Nickname for |cffffffff%s|r"):format(display))
    local current = N:Get(name, second)
    dialog.edit:SetText(current or "")
    dialog.remove:SetEnabled(current ~= nil)
    dialog:Show()
    dialog.edit:SetFocus()
    dialog.edit:HighlightText()
end

-------------------------------------------------------------------------------
--  Context menu
-------------------------------------------------------------------------------
-- Work out who the menu is for. Returns name, second (surname on Forever,
-- realm elsewhere; may be nil).
local function Identify(owner, ctx)
    if type(ctx) ~= "table" then return nil end
    local unit = ctx.unit
    if (not unit) and owner and not (owner.IsForbidden and owner:IsForbidden()) then
        unit = owner.unit
    end
    if type(unit) == "string" and not issecret(unit) then
        local name, second = ns.UnitNames(unit)
        if name then return name, second end
        -- A unit that is not a player (NPC/pet): no entry
        local exists = UnitExists(unit)
        if not issecret(exists) and exists then return nil end
    end
    local name = ctx.name
    local second = ns.SURNAMES and ctx.surname or ctx.server
    if issecret(name) or issecret(second) then return nil end
    if type(name) ~= "string" or name == "" then return nil end
    if type(second) ~= "string" or second == "" then second = nil end
    return name, second
end

local function AddEntries(owner, root, ctx)
    if not N:GetSetting("menu") then return end
    -- Forever's gamepad UI player menu is fragile (same guard EnhanceQoL uses)
    if ns.IS_FOREVER and InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled() then return end
    local ok, name, realm = pcall(Identify, owner, ctx)
    if not ok or not name then return end
    if not ns.Parse(name, realm) then return end
    local current = N:Get(name, realm)

    root:CreateDivider()
    root:CreateTitle(ns.ICON_INLINE .. ns.TITLE)
    root:CreateButton(current and ("Edit Nickname (|cffffd100" .. current .. "|r)") or "Set Nickname...", function()
        ns.ShowEditDialog(name, realm)
    end)
    if current then
        root:CreateButton("Remove Nickname", function() N:Set(name, realm, nil) end)
    end
end

local MENU_TAGS = {
    "MENU_UNIT_SELF",
    "MENU_UNIT_PLAYER",
    "MENU_UNIT_ENEMY_PLAYER",
    "MENU_UNIT_PARTY",
    "MENU_UNIT_RAID_PLAYER",
    "MENU_UNIT_RAID",
    "MENU_UNIT_TARGET",
    "MENU_UNIT_FOCUS",
    "MENU_UNIT_FRIEND",
    "MENU_UNIT_FRIEND_OFFLINE",
    "MENU_UNIT_CHAT_ROSTER",
    "MENU_UNIT_GUILD",
    "MENU_UNIT_GUILD_OFFLINE",
    "MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
    "MENU_UNIT_COMMUNITIES_WOW_MEMBER",
    "MENU_UNIT_WORLD_STATE_SCORE",
    "MENU_UNIT_ARENAENEMY",
}

if Menu and Menu.ModifyMenu then
    for _, tag in ipairs(MENU_TAGS) do
        Menu.ModifyMenu(tag, AddEntries)
    end
end
