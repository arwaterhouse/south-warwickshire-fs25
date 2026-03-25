source("editorUtils.lua")
local ZONE_NAMES = {
    "HEDGE MARGIN",      -- hazel-dominant British hedgerow scrub
    "ROAD VERGE",        -- tall grass + meadow (cow parsley, hogweed equiv)
    "FIELD MARGIN",      -- thin clover/short grass strip
    "WOODLAND EDGE",     -- ferns, clover, scrub along woodland boundary
    "WOODLAND FLOOR",    -- interior fill: ferns, clover, leaf litter
    "CLEAR ZONE",        -- erase — removes foliage from zone (set to 0)
}
local ZONE_CLEAR = 6
local ZONE_LAYERS = {
    { {ft="decoBush",     ch=13, nc=4},   -- hazelnutSmall   (weighted ×3)
      {ft="decoBush",     ch=13, nc=4},
      {ft="decoBush",     ch=13, nc=4},
      {ft="decoBush",     ch=14, nc=4},   -- hazelnutMedium  (weighted ×2)
      {ft="decoBush",     ch=14, nc=4},
      {ft="decoBush",     ch=15, nc=4},   -- hazelnutBig
      {ft="decoBush",     ch=10, nc=4},   -- boxwoodSmall    (blackthorn equiv)
      {ft="decoBush",     ch=11, nc=4},   -- boxwoodMedium   (hawthorn equiv)
      {ft="decoBush",     ch=12, nc=4},   -- boxwoodBig      (elder equiv)
      {ft="decoBush",     ch=6,  nc=4},   -- blueberrySmall  (dog-rose low layer)
    },
    { {ft="decoFoliage",  ch=1,  nc=5},   -- GrassDenseMix   (cow parsley ×3)
      {ft="decoFoliage",  ch=1,  nc=5},
      {ft="decoFoliage",  ch=1,  nc=5},
      {ft="decoFoliage",  ch=10, nc=5},   -- GrassMedium     (×2)
      {ft="decoFoliage",  ch=10, nc=5},
      {ft="meadow",       ch=2,  nc=5},   -- Meadow          (buttercup/daisy)
      {ft="decoFoliage",  ch=9,  nc=5},   -- GrassSmall      (fine fescue)
    },
    { {ft="decoFoliage",  ch=9,  nc=5},   -- GrassSmall      (×3)
      {ft="decoFoliage",  ch=9,  nc=5},
      {ft="decoFoliage",  ch=9,  nc=5},
      {ft="decoFoliage",  ch=10, nc=5},   -- GrassMedium
      {ft="forestPlants", ch=2,  nc=5},   -- ForestClover    (white clover strip)
      {ft="meadow",       ch=2,  nc=5},   -- Meadow          (occasional)
    },
    { {ft="forestPlants", ch=7,  nc=5},   -- SwordFern       (bracken ×2)
      {ft="forestPlants", ch=7,  nc=5},
      {ft="forestPlants", ch=8,  nc=5},   -- DeerFern
      {ft="forestPlants", ch=9,  nc=5},   -- ForestGrass
      {ft="forestPlants", ch=2,  nc=5},   -- Clover          (groundcover ×2)
      {ft="forestPlants", ch=2,  nc=5},
      {ft="forestPlants", ch=3,  nc=5},   -- StarFlower      (wood anemone equiv)
      {ft="decoBush",     ch=10, nc=4},   -- boxwoodSmall    (bramble/elder scrub)
    },
    { {ft="forestPlants", ch=9,  nc=5},   -- ForestGrass     (dominant ×4)
      {ft="forestPlants", ch=9,  nc=5},
      {ft="forestPlants", ch=9,  nc=5},
      {ft="forestPlants", ch=9,  nc=5},
      {ft="forestPlants", ch=2,  nc=5},   -- Clover/bluebell ×3
      {ft="forestPlants", ch=2,  nc=5},
      {ft="forestPlants", ch=2,  nc=5},
      {ft="forestPlants", ch=7,  nc=5},   -- SwordFern (bracken) ×2
      {ft="forestPlants", ch=7,  nc=5},
      {ft="forestPlants", ch=8,  nc=5},   -- DeerFern
      {ft="forestPlants", ch=1,  nc=5},   -- DryBranch (leaf litter) ×2
      {ft="forestPlants", ch=1,  nc=5},
      {ft="forestPlants", ch=3,  nc=5},   -- StarFlower (wood anemone)
      {ft="decoBush",     ch=13, nc=4},   -- hazelnutSmall   (seedling layer)
    },
    {},
}
local ZONE_HALF_WIDTH = { 2.5,  3.5,  1.0,  5.0,  0.0,  3.0 }   -- m either side
local ZONE_STEP       = { 0.8,  1.0,  0.5,  1.0,  3.0,  1.5 }   -- m along spline / grid cell
local ZONE_DENSITY    = { 0.80, 0.55, 0.35, 0.70, 0.65, 1.00 }  -- paint probability
local ZONE_BRUSH_M    = { 0.7,  0.9,  0.5,  1.2,  1.8,  2.0 }   -- brush footprint (m)
local selectedZone = 1
local userHalfWidth = ZONE_HALF_WIDTH[1]
local userStep      = ZONE_STEP[1]
local userDensity   = ZONE_DENSITY[1]
local userBrushM    = ZONE_BRUSH_M[1]
local totalPainted  = 0
local totalSplines  = 0
local running       = false
local _planeCache = {}
local function getPlaneId(terrainId, ftName)
    if _planeCache[ftName] == nil then
        local id = getTerrainDataPlaneByName(terrainId, ftName)
        if id ~= nil and id ~= 0 then
            _planeCache[ftName] = id
            print(string.format("[SW Foliage v2] Plane '%s' → id=%s", ftName, tostring(id)))
        else
            _planeCache[ftName] = 0
            print(string.format("[SW Foliage v2] WARNING: plane '%s' not found", ftName))
        end
    end
    return _planeCache[ftName]
end
local function paintPoint(terrainId, wx, wz, layers, brushHalf, isClear)
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
                    wx - brushHalf, wz - brushHalf,
                    wx + brushHalf, wz - brushHalf,
                    wx - brushHalf, wz + brushHalf,
                    DensityCoordType.POINT_POINT_POINT)
                mod:executeSet(0)
            end
        end
        return true
    end
    local entry    = layers[math.random(1, #layers)]
    local planeId  = getPlaneId(terrainId, entry.ft)
    if planeId == 0 then return false end
    local mod = DensityMapModifier.new(planeId, 0, entry.nc)
    mod:setParallelogramWorldCoords(
        wx - brushHalf, wz - brushHalf,
        wx + brushHalf, wz - brushHalf,
        wx - brushHalf, wz + brushHalf,
        DensityCoordType.POINT_POINT_POINT)
    mod:executeSet(entry.ch)
    return true
end
local function isSplineNode(nodeId)
    if nodeId == nil or nodeId == 0 then return false end
    local ok, len = pcall(getSplineLength, nodeId)
    return ok and type(len) == "number" and len > 0
end
local function collectSplines(parentId, result)
    result = result or {}
    for i = 0, getNumOfChildren(parentId) - 1 do
        local child = getChildAt(parentId, i)
        if isSplineNode(child) then
            table.insert(result, child)
        else
            collectSplines(child, result)
        end
    end
    return result
end
local function getTerrainId()
    local scene = getRootNode()
    for i = 0, getNumOfChildren(scene) - 1 do
        local child = getChildAt(scene, i)
        if getName(child) == "terrain" then return child end
    end
    return nil
end
local function perpOffset(dx, dy, dz, side, mag)
    local rx = -(dz)
    local rz =  (dx)
    local rLen = math.sqrt(rx*rx + rz*rz)
    if rLen < 0.001 then return 0, 0 end
    rx = rx / rLen * mag * side
    rz = rz / rLen * mag * side
    return rx, rz
end
local function paintAlongSpline(terrainId, splineId, layers,
                                halfWidth, stepM, density, brushM, isClear)
    local splineLen = getSplineLength(splineId)
    if splineLen < 1.0 then return 0 end
    local stepT     = stepM / splineLen
    local brushHalf = brushM * 0.5
    local count     = 0
    local t         = 0.0
    while t <= 1.0 do
        if math.random() <= density then
            local px, py, pz = getSplinePosition(splineId, t)
            local dx, dy, dz = getSplineDirection(splineId, t)
            for _, side in ipairs({ 1, -1 }) do
                local offset = halfWidth * (0.2 + math.random() * 0.8)
                local ox, oz = perpOffset(dx, dy, dz, side, offset)
                local wx = px + ox
                local wz = pz + oz
                wx = wx + (math.random() - 0.5) * stepM * 0.4
                wz = wz + (math.random() - 0.5) * stepM * 0.4
                if paintPoint(terrainId, wx, wz, layers, brushHalf, isClear) then
                    count = count + 1
                end
            end
        end
        t = t + stepT
    end
    return count
end
local function getSplineBounds(splineId)
    local splineLen = getSplineLength(splineId)
    if splineLen < 1.0 then return nil end
    local minX, minZ =  math.huge,  math.huge
    local maxX, maxZ = -math.huge, -math.huge
    local steps = math.max(20, math.floor(splineLen))
    for i = 0, steps do
        local t = i / steps
        local px, py, pz = getSplinePosition(splineId, t)
        if px < minX then minX = px end
        if px > maxX then maxX = px end
        if pz < minZ then minZ = pz end
        if pz > maxZ then maxZ = pz end
    end
    return minX, minZ, maxX, maxZ
end
local function paintFloorFill(terrainId, splineId, layers,
                               gridStep, density, brushM, isClear)
    local minX, minZ, maxX, maxZ = getSplineBounds(splineId)
    if minX == nil then return 0 end
    if (maxX - minX) < 2.0 or (maxZ - minZ) < 2.0 then return 0 end
    local brushHalf = brushM * 0.5
    local halfJit   = gridStep * 0.5
    local count     = 0
    local x = minX
    while x <= maxX do
        local z = minZ
        while z <= maxZ do
            if math.random() <= density then
                local wx = x + (math.random() - 0.5) * 2 * halfJit
                local wz = z + (math.random() - 0.5) * 2 * halfJit
                if paintPoint(terrainId, wx, wz, layers, brushHalf, isClear) then
                    count = count + 1
                end
            end
            z = z + gridStep
        end
        x = x + gridStep
    end
    return count
end
local function runPainter()
    if running then
        print("[SW Foliage v2] Already running — please wait")
        return
    end
    local selId = getSelection(0)
    if selId == nil or selId == 0 then
        print("[SW Foliage v2] ERROR: Nothing selected. "..
              "Select a transform group containing splines.")
        return
    end
    local terrainId = getTerrainId()
    if terrainId == nil then
        print("[SW Foliage v2] ERROR: Terrain node not found.")
        return
    end
    local splines = collectSplines(selId)
    if #splines == 0 then
        if isSplineNode(selId) then
            splines = { selId }
        else
            print("[SW Foliage v2] ERROR: No splines found in the selected group.")
            print("  Make sure you have selected a TransformGroup that CONTAINS splines,")
            print("  not an empty group or a non-spline object.")
            return
        end
    end
    local isClear   = (selectedZone == ZONE_CLEAR)
    local isFloor   = (selectedZone == 5)  -- WOODLAND FLOOR = fill mode
    local layers    = ZONE_LAYERS[selectedZone]
    local brushHalf = userBrushM * 0.5
    _planeCache = {}
    running      = true
    totalPainted = 0
    totalSplines = 0
    print(string.format("\n[SW Foliage v2] ─────────────────────────────────"))
    print(string.format("  Zone      : %s", ZONE_NAMES[selectedZone]))
    print(string.format("  Group     : %s", getName(selId)))
    print(string.format("  Splines   : %d", #splines))
    if isFloor then
        print(string.format("  Mode      : INTERIOR FILL  grid=%.1f m", userStep))
    else
        print(string.format("  Half-width: %.1f m   Step: %.2f m   Density: %.0f%%",
            userHalfWidth, userStep, userDensity * 100))
    end
    for idx, splineId in ipairs(splines) do
        local painted = 0
        if isFloor or isClear then
            painted = paintFloorFill(terrainId, splineId, layers,
                                     userStep, userDensity, userBrushM, isClear)
        else
            painted = paintAlongSpline(terrainId, splineId, layers,
                                       userHalfWidth, userStep, userDensity,
                                       userBrushM, false)
        end
        totalPainted = totalPainted + painted
        totalSplines = totalSplines + 1
        if idx % 10 == 0 then
            print(string.format("  … %d / %d splines  (%d paint ops)",
                idx, #splines, totalPainted))
        end
    end
    running = false
    print(string.format("\n  ✓ Done. %d splines | %d foliage operations",
        totalSplines, totalPainted))
    print("[SW Foliage v2] ─────────────────────────────────\n")
end
local function updateDefaults()
    userHalfWidth = ZONE_HALF_WIDTH[selectedZone]
    userStep      = ZONE_STEP[selectedZone]
    userDensity   = ZONE_DENSITY[selectedZone]
    userBrushM    = ZONE_BRUSH_M[selectedZone]
end
local frameSizer  = UIRowLayoutSizer.new()
local window      = UIWindow.new(frameSizer, "SW Foliage Zone Painter v2")
local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer, -1, -1, -1, -1, BorderDirection.ALL, 6)
local zoneColSizer = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, zoneColSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(zoneColSizer, "Zone preset  (click button to cycle):", TextAlignment.LEFT)
local zoneLblRow = UIRowLayoutSizer.new()
UIPanel.new(zoneColSizer, zoneLblRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
local zoneCurrentLabel = UITextArea.new(zoneLblRow,
    "[ " .. ZONE_NAMES[1] .. " ]",
    TextAlignment.LEFT, false, true, -1, 22, -1, 22, BorderDirection.NONE, 0, 0)
local zoneBtnRow = UIRowLayoutSizer.new()
UIPanel.new(zoneColSizer, zoneBtnRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UIButton.new(zoneBtnRow, "Next Zone", function()
    selectedZone = (selectedZone % #ZONE_NAMES) + 1
    updateDefaults()
    zoneCurrentLabel:setValue("[ " .. ZONE_NAMES[selectedZone] .. " ]")
    print(string.format("[SW Foliage v2] Zone → %s  (half=%.1f m  step=%.2f m  density=%.0f%%)",
        ZONE_NAMES[selectedZone], userHalfWidth, userStep, userDensity * 100))
end)
local hwSizer = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, hwSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(hwSizer, "Half-width / grid step (m):", TextAlignment.LEFT)
local hwSlider = UIFloatSlider.new(hwSizer, userHalfWidth, 0.5, 10.0, 0.5, 10.0)
hwSlider:setOnChangeCallback(function(v) userHalfWidth = v end)
local stepSizer = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, stepSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(stepSizer, "Step along spline (m):", TextAlignment.LEFT)
local stepSlider = UIFloatSlider.new(stepSizer, userStep, 0.3, 6.0, 0.3, 6.0)
stepSlider:setOnChangeCallback(function(v) userStep = v end)
local densSizer = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, densSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(densSizer, "Density (0.1 – 1.0):", TextAlignment.LEFT)
local densSlider = UIFloatSlider.new(densSizer, userDensity, 0.1, 1.0, 0.1, 1.0)
densSlider:setOnChangeCallback(function(v) userDensity = v end)
local infoSizer = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, infoSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(infoSizer,
    "1. Select a TransformGroup containing splines in scene tree.\n"..
    "2. Pick zone preset.\n"..
    "3. Adjust sliders if needed, then click Paint.\n"..
    "   WOODLAND FLOOR: 'half-width' slider = grid cell size.\n"..
    "   CLEAR ZONE: erases decoFoliage/forestPlants/meadow/decoBush.",
    TextAlignment.LEFT)
local btnSizer = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, btnSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UIButton.new(btnSizer, "Paint Foliage Zone", runPainter)
window:showWindow()
print("\n[SW Foliage Zone Painter v2] Ready.")
print("v2 fixes:")
print("  • Plane name bug fixed — paint operations now actually execute")
print("  • British presets: hazel-dominant hedgerows, bracken/fern woodland,")
print("    cow-parsley road verges, thin clover field margins")
print("")
print("Zone summary:")
print("  HEDGE MARGIN   → hazelnutSmall/Med/Big + boxwood (blackthorn/hawthorn)")
print("  ROAD VERGE     → GrassDenseMix (cow parsley) + GrassMedium + Meadow")
print("  FIELD MARGIN   → GrassSmall + Clover + occasional Meadow (sparse)")
print("  WOODLAND EDGE  → SwordFern (bracken) + DeerFern + Clover + StarFlower")
print("  WOODLAND FLOOR → ForestGrass + Clover/bluebell + Ferns + DryBranch")
print("  CLEAR ZONE     → erases all decoration foliage layers")
