source("editorUtils.lua")
local PRESET_NAMES = {
    "WOODLAND FLOOR",
    "GRASS & MEADOW",
    "HEDGEROW SCRUB",
    "FIELD MARGIN",
    "FOREST EDGE",
    "CLEAR",
}
local PRESET_LAYERS = {
    { {ft="forestPlants",ch=9, nc=5,w=4},   -- ForestGrass      dominant
      {ft="forestPlants",ch=7, nc=5,w=3},   -- SwordFern/bracken
      {ft="forestPlants",ch=8, nc=5,w=2},   -- DeerFern
      {ft="forestPlants",ch=2, nc=5,w=3},   -- Clover/bluebell sub
      {ft="forestPlants",ch=1, nc=5,w=2},   -- DryBranch/leaf litter
      {ft="forestPlants",ch=3, nc=5,w=1},   -- StarFlower/wood anemone
      {ft="decoBush",    ch=13,nc=4,w=1},   -- hazelnutSmall seedling
    },
    { {ft="decoFoliage",ch=1, nc=5,w=3},    -- GrassDenseMix/cow parsley
      {ft="decoFoliage",ch=10,nc=5,w=3},    -- GrassMedium
      {ft="meadow",      ch=2, nc=5,w=2},   -- Meadow wildflowers
      {ft="decoFoliage",ch=9, nc=5,w=1},    -- GrassSmall/fescue
    },
    { {ft="decoBush",ch=13,nc=4,w=4},       -- hazelnutSmall (dominant)
      {ft="decoBush",ch=14,nc=4,w=2},       -- hazelnutMedium
      {ft="decoBush",ch=15,nc=4,w=1},       -- hazelnutBig
      {ft="decoBush",ch=10,nc=4,w=2},       -- boxwoodSmall (blackthorn)
      {ft="decoBush",ch=11,nc=4,w=1},       -- boxwoodMedium (elder/hawthorn)
      {ft="decoBush",ch=6, nc=4,w=1},       -- blueberrySmall (dog rose)
    },
    { {ft="decoFoliage",  ch=9, nc=5,w=5},  -- GrassSmall (dominant)
      {ft="decoFoliage",  ch=10,nc=5,w=2},  -- GrassMedium
      {ft="forestPlants", ch=2, nc=5,w=1},  -- Clover
      {ft="meadow",       ch=2, nc=5,w=1},  -- occasional Meadow
    },
    { {ft="forestPlants",ch=7, nc=5,w=3},   -- SwordFern/bracken
      {ft="forestPlants",ch=8, nc=5,w=2},   -- DeerFern
      {ft="forestPlants",ch=9, nc=5,w=2},   -- ForestGrass
      {ft="forestPlants",ch=2, nc=5,w=2},   -- Clover groundcover
      {ft="forestPlants",ch=3, nc=5,w=1},   -- StarFlower
      {ft="decoBush",    ch=10,nc=4,w=1},   -- boxwoodSmall scrub
    },
    {},
}
local function buildPickTable(layers)
    local t = {}
    for _, entry in ipairs(layers) do
        for i=1,(entry.w or 1) do
            table.insert(t, entry)
        end
    end
    return t
end
local PICK_TABLES = {}
for i,p in ipairs(PRESET_LAYERS) do
    PICK_TABLES[i] = buildPickTable(p)
end
local currentPreset = 1
local brushRadius   = 5.0    -- metres
local brushDensity  = 0.70   -- probability per scatter point
local brushSpacing  = 0.8    -- metres between scatter points in the brush area
local presetLabel   = nil    -- UI ref
local function getTerrainId()
    local scene = getRootNode()
    for i=0, getNumOfChildren(scene)-1 do
        local child = getChildAt(scene, i)
        if getName(child) == "terrain" then return child end
    end
    return nil
end
local _planeCache = {}
local function getPlaneId(terrainId, ftName)
    if _planeCache[ftName] == nil then
        local id = getTerrainDataPlaneByName(terrainId, ftName)
        _planeCache[ftName] = (id ~= nil and id ~= 0) and id or 0
        if _planeCache[ftName] == 0 then
            print(string.format("[SW Brush] WARNING: foliage plane '%s' not found", ftName))
        end
    end
    return _planeCache[ftName]
end
local function paintPoint(terrainId, wx, wz, pickTable, brushHalf, isClear)
    if isClear then
        local clearPlanes = {
            {ft="decoFoliage",  nc=5},
            {ft="forestPlants", nc=5},
            {ft="meadow",       nc=5},
            {ft="decoBush",     nc=4},
        }
        for _, p in ipairs(clearPlanes) do
            local pid = getPlaneId(terrainId, p.ft)
            if pid ~= 0 then
                local mod = DensityMapModifier.new(pid, 0, p.nc)
                mod:setParallelogramWorldCoords(
                    wx-brushHalf,wz-brushHalf, wx+brushHalf,wz-brushHalf,
                    wx-brushHalf,wz+brushHalf, DensityCoordType.POINT_POINT_POINT)
                mod:executeSet(0)
            end
        end
        return true
    end
    if #pickTable == 0 then return false end
    local entry = pickTable[math.random(1, #pickTable)]
    local pid   = getPlaneId(terrainId, entry.ft)
    if pid == 0 then return false end
    local mod = DensityMapModifier.new(pid, 0, entry.nc)
    mod:setParallelogramWorldCoords(
        wx-brushHalf,wz-brushHalf, wx+brushHalf,wz-brushHalf,
        wx-brushHalf,wz+brushHalf, DensityCoordType.POINT_POINT_POINT)
    mod:executeSet(entry.ch)
    return true
end
local function paintHere()
    local sel = getSelection(0)
    if sel == nil or sel == 0 then
        print("[SW Brush] Nothing selected — select a node at the spot you want to paint.")
        return
    end
    local terrainId = getTerrainId()
    if terrainId == nil then
        print("[SW Brush] ERROR: terrain node not found.")
        return
    end
    local cx, cy, cz = getWorldTranslation(sel)
    local isClear    = (currentPreset == 6)
    local pickTable  = PICK_TABLES[currentPreset]
    local brushHalf  = brushSpacing * 0.5
    local count      = 0
    local x = cx - brushRadius
    while x <= cx + brushRadius do
        local z = cz - brushRadius
        while z <= cz + brushRadius do
            local dx = x - cx
            local dz = z - cz
            if (dx*dx + dz*dz) <= (brushRadius * brushRadius) then
                if math.random() <= brushDensity then
                    local jx = x + (math.random()-0.5)*brushSpacing*0.7
                    local jz = z + (math.random()-0.5)*brushSpacing*0.7
                    if paintPoint(terrainId, jx, jz, pickTable, brushHalf, isClear) then
                        count = count + 1
                    end
                end
            end
            z = z + brushSpacing
        end
        x = x + brushSpacing
    end
    print(string.format("[SW Brush] Painted %d foliage ops  |  preset=%s  radius=%.1fm  @ (%.1f,%.1f)",
        count, PRESET_NAMES[currentPreset], brushRadius, cx, cz))
end
local frameSizer  = UIRowLayoutSizer.new()
local window      = UIWindow.new(frameSizer, "SW Foliage Brush")
local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer, -1,-1,-1,-1, BorderDirection.ALL, 8)
UILabel.new(borderSizer,
    "1. Pick a preset\n"..
    "2. Set radius + density\n"..
    "3. Select any node at the spot you want to paint\n"..
    "4. Click Paint Here",
    TextAlignment.LEFT)
UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 6)
local pHdr = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, pHdr, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
UILabel.new(pHdr, "Preset:", TextAlignment.LEFT)
local pRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, pRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 6)
UIButton.new(pRow, "◀", function()
    currentPreset = ((currentPreset-2+#PRESET_NAMES)%#PRESET_NAMES)+1
    presetLabel:setValue("[ "..PRESET_NAMES[currentPreset].." ]")
    print("[SW Brush] Preset → "..PRESET_NAMES[currentPreset])
end)
presetLabel = UITextArea.new(pRow,
    "[ "..PRESET_NAMES[currentPreset].." ]",
    TextAlignment.LEFT, false,true,220,22,-1,22, BorderDirection.NONE,0,0)
UIButton.new(pRow, "▶", function()
    currentPreset = (currentPreset%#PRESET_NAMES)+1
    presetLabel:setValue("[ "..PRESET_NAMES[currentPreset].." ]")
    print("[SW Brush] Preset → "..PRESET_NAMES[currentPreset])
end)
local rHdr = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, rHdr, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
UILabel.new(rHdr, "Brush radius (m):", TextAlignment.LEFT)
local rSlider = UIFloatSlider.new(rHdr, brushRadius, 1.0, 30.0, 1.0, 30.0)
rSlider:setOnChangeCallback(function(v) brushRadius=v end)
local dHdr = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, dHdr, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
UILabel.new(dHdr, "Density (0.1 – 1.0):", TextAlignment.LEFT)
local dSlider = UIFloatSlider.new(dHdr, brushDensity, 0.1, 1.0, 0.1, 1.0)
dSlider:setOnChangeCallback(function(v) brushDensity=v end)
local sHdr = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, sHdr, -1,-1,-1,-1, BorderDirection.BOTTOM, 6)
UILabel.new(sHdr, "Scatter spacing (m)  — smaller = denser clumps:", TextAlignment.LEFT)
local sSlider = UIFloatSlider.new(sHdr, brushSpacing, 0.3, 3.0, 0.3, 3.0)
sSlider:setOnChangeCallback(function(v) brushSpacing=v end)
UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 4)
local btnRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, btnRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 4)
UIButton.new(btnRow, "Paint Here  (at selected node)", paintHere)
window:showWindow()
print("\n[SW Foliage Brush] Ready.")
print("Presets:")
print("  WOODLAND FLOOR  — ForestGrass, bracken, clover/bluebell, leaf litter")
print("  GRASS & MEADOW  — cow parsley, meadow grass, wildflowers")
print("  HEDGEROW SCRUB  — hazelnut (×4 dominant), blackthorn/hawthorn/elder")
print("  FIELD MARGIN    — GrassSmall + clover (sparse)")
print("  FOREST EDGE     — ferns, clover, occasional scrub")
print("  CLEAR           — erases foliage in the brush area")
print("")
print("Tip: small radius (2-5m) + high density for detailed work")
print("     large radius (10-20m) + low density for broad coverage")
