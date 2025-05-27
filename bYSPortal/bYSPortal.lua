local ZONE_NAME = "Ульдуар"
local SUBZONE_NAME = "Темница Йогг-Сарона"

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

local points = {
--[[
    { x = 0.682, y = 0.428 },
    { x = 0.662, y = 0.419 },
    { x = 0.656, y = 0.398 },
    { x = 0.658, y = 0.375 },
    { x = 0.667, y = 0.361 },
    { x = 0.681, y = 0.358 },
    { x = 0.696, y = 0.361 },
    { x = 0.705, y = 0.382 },
    { x = 0.708, y = 0.400 },
    { x = 0.700, y = 0.419 },
	]]
	---------------------------
		
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


        
	---------------------------
}

local icons = {}

for i, point in ipairs(points) do
    local icon = CreateFrame("Frame", "LocationTrackerIcon"..i, Minimap)
    icon:SetSize(16, 16)
    icon:SetFrameStrata("HIGH")

    icon.text = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    icon.text:SetPoint("CENTER", icon, "CENTER", 0, 0)
    icon.text:SetText(tostring(i))

    icon:Hide()
    table.insert(icons, icon)
end

local function GetDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
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

    for i, point in ipairs(points) do
        local icon = icons[i]
        local distance = GetDistance(px, py, point.x, point.y)

        if distance > minimapRadiusCoords then
            icon:Hide()
        else
            local dx = (point.x - px) / minimapRadiusCoords
            local dy = (point.y - py) / minimapRadiusCoords
            local xOffset = dx * radiusPixels
            local yOffset = dy * radiusPixels

            icon:SetPoint("CENTER", Minimap, "CENTER", xOffset, -yOffset)
            icon:Show()
        end
    end
end)
