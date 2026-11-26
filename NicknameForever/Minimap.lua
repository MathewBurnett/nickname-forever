-------------------------------------------------------------------------------
--  Nickname Forever - minimap button and AddOns compartment entry
--  Left-click opens the nickname window; drag moves the button around the
--  minimap. Round and square minimaps are both handled (GetMinimapShape).
--  Hidden with the "Minimap button" option or /nick minimap.
-------------------------------------------------------------------------------
local _, ns = ...
local N = ns.N

local btn

-- Which quadrants of each minimap shape are round (same table LibDBIcon uses)
local SHAPES = {
    ["ROUND"] = { true, true, true, true },
    ["SQUARE"] = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, false, false, true },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
    ["TRICORNER-TOPLEFT"] = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local function UpdatePosition()
    if not btn then return end
    local angle = math.rad(N:GetSetting("minimapAngle") or 225)
    local x, y = math.cos(angle), math.sin(angle)
    local q = 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    local shape = (GetMinimapShape and GetMinimapShape()) or "ROUND"
    local quads = SHAPES[shape] or SHAPES.ROUND
    local w = (Minimap:GetWidth() / 2) + 5
    local h = (Minimap:GetHeight() / 2) + 5
    if quads[q] then
        x, y = x * w, y * h
    else
        local dw = math.sqrt(2 * w * w) - 10
        local dh = math.sqrt(2 * h * h) - 10
        x = math.max(-w, math.min(x * dw, w))
        y = math.max(-h, math.min(y * dh, h))
    end
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function OnDragUpdate()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    local atan2 = math.atan2 or atan2
    local db = NicknamesDB and NicknamesDB.settings
    if db then db.minimapAngle = math.deg(atan2(py - my, px - mx)) % 360 end
    UpdatePosition()
end

local function ShowTooltip(owner, fromCompartment)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:AddLine(ns.ICON_INLINE .. ns.TITLE)
    GameTooltip:AddLine("|cffffd100Click|r to open your nickname list.", 1, 1, 1)
    if not fromCompartment then
        GameTooltip:AddLine("|cffffd100Drag|r to move this button.", 1, 1, 1)
        GameTooltip:AddLine("Hide it in /nick > Interface, or with /nick minimap.", 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
end

local function Create()
    btn = CreateFrame("Button", "NicknameForeverMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("AnyUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(24, 24)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("CENTER", 0, 0)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(19, 19)
    icon:SetTexture(ns.ICON)
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- crop the tile edge; the arrows fill the circle
    icon:SetPoint("CENTER", 0, 0)
    btn.icon = icon

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    btn:SetScript("OnClick", function() ns.ToggleManager() end)
    btn:SetScript("OnEnter", function(self) ShowTooltip(self) end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetScript("OnMouseDown", function() icon:SetTexCoord(0.13, 0.87, 0.13, 0.87) end)
    btn:SetScript("OnMouseUp", function() icon:SetTexCoord(0.1, 0.9, 0.1, 0.9) end)
    btn:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", OnDragUpdate)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    end)
end

local function Update()
    if not Minimap then return end
    if N:GetSetting("minimap") then
        if not btn then Create() end
        UpdatePosition()
        btn:Show()
    elseif btn then
        btn:Hide()
    end
end

ns.AfterLoad(Update)
-- Minimap addons (square skins etc.) may resize/reshape the minimap at login
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function() C_Timer.After(1, UpdatePosition) end)

N.RegisterCallback("NicknameForeverMinimap", "SETTINGS_CHANGED", function(_, k)
    if k == "minimap" then Update() end
end)

-------------------------------------------------------------------------------
--  AddOns compartment (the addon menu button next to the minimap)
-------------------------------------------------------------------------------
function NicknameForever_OnAddonCompartmentClick()
    ns.ToggleManager()
end

function NicknameForever_OnAddonCompartmentEnter(_, frame)
    if type(frame) == "table" and frame.IsObjectType then ShowTooltip(frame, true) end
end

function NicknameForever_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end
