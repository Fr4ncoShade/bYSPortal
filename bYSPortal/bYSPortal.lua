local locale = GetLocale()
local ZONE_NAME, SUBZONE_NAME

if locale == "ruRU" then
    ZONE_NAME = "Ульдуар"
    SUBZONE_NAME = "Темница Йогг-Сарона"
elseif locale == "enUS" then
    ZONE_NAME = "Ulduar"
    SUBZONE_NAME = "Prison of Yogg-Saron"
end

local MAP_SCALE = 980

local MINIMAP_RADII_YARDS = {
    [0] = 150,
    [1] = 120,
    [2] = 85,
    [3] = 65,
    [4] = 45,
    [5] = 30,
}

local MIN_FONT_SIZE = 10
local MAX_FONT_SIZE = 20
local MINIMAP_MAX_ZOOM = 5

local portals10 = {
	{ x = 0.7029, y = 0.3768 }, -- 1
	{ x = 0.7029, y = 0.4184 }, -- 2
    { x = 0.6610, y = 0.4184 }, -- 3
    { x = 0.6610, y = 0.3768 }, -- 4
}

local portals25 = {
    { x = 0.6816, y = 0.3580 }, -- 1
    { x = 0.7029, y = 0.3660 }, -- 2
    { x = 0.7140, y = 0.3833 }, -- 3
    { x = 0.7140, y = 0.4031 }, -- 4
    { x = 0.7029, y = 0.4184 }, -- 5
    { x = 0.6816, y = 0.4300 }, -- 6
    { x = 0.6610, y = 0.4184 }, -- 7
    { x = 0.6592, y = 0.4031 }, -- 8
    { x = 0.6552, y = 0.3833 }, -- 9
    { x = 0.6663, y = 0.3660 }, -- 10
}

local icons = {}

local MaskFrame = CreateFrame("Frame", "MaskedIconFrame", Minimap)
MaskFrame:SetAllPoints(Minimap)
MaskFrame:SetFrameStrata("HIGH")
MaskFrame:SetFrameLevel(5)

for i = 1, 10 do
    local icon = CreateFrame("Frame", "LocationTrackerIcon"..i, MaskFrame)
    icon:SetSize(16, 16)
    icon:SetFrameStrata("HIGH")
    icon:SetFrameLevel(6)

    icon.text = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    icon.text:SetPoint("CENTER", icon, "CENTER", 0, 0)
    icon.text:SetText(tostring(i))

    icon:Hide()
    table.insert(icons, icon)
end

local function UpdateFontSizes(zoom)
    local scale = zoom / MINIMAP_MAX_ZOOM
    local fontSize = MIN_FONT_SIZE + (MAX_FONT_SIZE - MIN_FONT_SIZE) * scale

    for _, icon in ipairs(icons) do
        local font, _, flags = icon.text:GetFont()
        icon.text:SetFont(font, fontSize, flags)
    end
end

local frame = CreateFrame("Frame")
frame.elapsed = 0

frame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < 0.1 then return end
    self.elapsed = 0

    local zone = GetRealZoneText()
    local subzone = GetSubZoneText()

    if zone ~= ZONE_NAME or subzone ~= SUBZONE_NAME then
        for _, icon in ipairs(icons) do
            icon:Hide()
        end
        return
    end

    local difficulty = select(3, GetInstanceInfo())
	--print("Difficulty:", difficulty)
    local points

    if difficulty == 1 then
        points = portals10
    elseif difficulty == 2 then
        points = portals25
    else
        for _, icon in ipairs(icons) do
            icon:Hide()
        end
        return
    end

    if not WorldMapFrame:IsShown() then
        SetMapToCurrentZone()
    end

    local px, py = GetPlayerMapPosition("player")
    if px == 0 and py == 0 then
        for _, icon in ipairs(icons) do
            icon:Hide()
        end
        return
    end

    local zoom = Minimap:GetZoom() or 3
    if zoom < 0 or zoom > 5 then zoom = 3 end

    UpdateFontSizes(zoom)

    local minimapRadiusYards = MINIMAP_RADII_YARDS[zoom] or 40
    local minimapRadiusCoords = minimapRadiusYards / MAP_SCALE
    local radiusPixels = Minimap:GetWidth() / 2

    local isRotating = GetCVar("rotateMinimap") == "1"
    local rotation = isRotating and GetPlayerFacing() or 0

    local maxVisibleDist = 1.0
    local fadeStart = 0.85

    for i, icon in ipairs(icons) do
        local point = points[i]
        if point then
            local dx = (point.x - px) / minimapRadiusCoords
            local dy = (point.y - py) / minimapRadiusCoords
            local distance = math.sqrt(dx*dx + dy*dy)

            if distance > maxVisibleDist then
                icon:Hide()
            else
                if isRotating then
                    local cos = math.cos(rotation)
                    local sin = math.sin(rotation)
                    local x = dx * cos - dy * sin
                    local y = dx * sin + dy * cos
                    dx, dy = x, y
                end

                local xOffset = dx * radiusPixels
                local yOffset = -dy * radiusPixels

                icon:SetPoint("CENTER", MaskFrame, "CENTER", xOffset, yOffset)

                local alpha = 1
                if distance > fadeStart then
                    alpha = 1 - (distance - fadeStart) / (maxVisibleDist - fadeStart)
                    alpha = math.max(0, math.min(1, alpha))
                end

                icon:SetAlpha(alpha)
                icon:Show()
            end
        else
            icon:Hide()
        end
    end
end)