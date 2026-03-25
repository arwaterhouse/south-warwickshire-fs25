-- Author: South Warwickshire FS25 Pipeline
-- Name: SW Foliage Zone Painter
-- Description: Paints ground-level foliage layers (shrubs, grass, meadow,
--              forest floor) along ALL splines in a selected transform group,
--              OR fills the interior of woodland areas with forest floor cover.
--              Designed to complement the existing hedge, road, field and
--              forest spline groups imported via geojson_to_i3d_splines.py.
--
-- Zone presets (pick one per run):
--
--   HEDGE MARGIN   → hazelnut, boxwood & decoBush painted 2-3 m either side
--                    of hedge splines  (use with osm_hedges / inferred_hedges)
--
--   ROAD VERGE     → grass (small/medium) + meadow painted 2-4 m either side
--                    of road splines  (use with residential/track/unclassified
--                    groups — skip primary roads)
--
--   FIELD MARGIN   → meadow + grass painted as a thin 1.5 m band along field
--                    boundary splines  (use with sw_field_splines groups)
--
--   WOODLAND EDGE  → forest floor plants (fern, clover, forest grass) + small
--                    decoBush painted 3-5 m either side of woodland boundary
--                    splines  (use with sw_forest_splines groups)
--
--   WOODLAND FLOOR → fills the entire interior of each woodland spline (closed
--                    loop) with a scattered mix of ferns, clover, forest grass,
--                    dry branches and blueberry undergrowth.
--                    Select sw_forest_splines "woodland_boundaries" group.
--                    Use Grid Step slider to control how fine the scatter is.
--
-- Usage:
--   1. Import sw_hedge_splines.i3d / sw_road_splines.i3d / sw_field_splines.i3d /
--      sw_forest_splines.i3d into GE if not already present
--   2. Select the transform GROUP containing your splines (e.g. "osm_hedges")
--   3. Pick the matching Zone Preset in this panel
--   4. Adjust width/step/density if needed
--   5. Click Paint — all splines in the group are processed in one pass
--
-- Hide: no
-- AlwaysLoaded: no

source("editorUtils.lua")

-- ── State ─────────────────────────────────────────────────────────────────────

local ZONE_NAMES = { "HEDGE MARGIN", "ROAD VERGE", "FIELD MARGIN", "WOODLAND EDGE", "WOODLAND FLOOR" }
local selectedZone = 1   -- index into ZONE_NAMES
local ZONE_FLOOR = 5     -- index of the fill-interior mode

-- Foliage layer names exactly as they appear in map.i3d
-- These are the actual layer names for this South Warwickshire map.
local ZONE_LAYERS = {
    -- [1] HEDGE MARGIN — shrubs that complement existing hedgerows
    { "F_hazelnutSmall", "F_hazelnutMedium", "F_boxwoodSmall",
      "F_boxwoodMedium", "F_decobushSmall",  "F_decobushMedium" },

    -- [2] ROAD VERGE — long grass and meadow plants
    { "F_GrassSmall", "F_GrassMedium", "F_GrassDenseMix", "F_Meadow" },

    -- [3] FIELD MARGIN — meadow mix
    { "F_Meadow", "F_GrassMedium", "F_GrassSmall" },

    -- [4] WOODLAND EDGE — understorey shrubs along the boundary
    { "F_ForestGrass", "F_ForestClover", "F_ForestSwordFern",
      "F_ForestDeerFern", "F_ForestStarFlower", "F_decobushSmall" },

    -- [5] WOODLAND FLOOR — full interior coverage: ferns, ground cover, bushes
    -- Weighted towards the most common UK woodland floor species equivalents.
    { "F_ForestGrass",    "F_ForestGrass",      -- grass - weighted heavier
      "F_ForestClover",   "F_ForestClover",      -- clover/groundcover
      "F_ForestSwordFern","F_ForestDeerFern",    -- ferns
      "F_ForestStarryFalse", "F_ForestBunchBerry",
      "F_ForestDryBranch",                       -- leaf litter / dead wood
      "F_blueberryShort", "F_blueberrySmall",    -- low shrub layer
      "F_decobushSmall" },                        -- occasional small bush
}

-- Default half-widths (metres either side of spline centreline)
-- Not used for WOODLAND FLOOR (uses grid step instead)
local ZONE_HALF_WIDTH = { 2.5, 3.0, 1.0, 4.0, 0.0 }

-- Default step distance along spline (metres).
-- For WOODLAND FLOOR this becomes the grid cell size.
local ZONE_STEP = { 0.8, 1.2, 0.6, 1.0, 3.0 }

-- Per-point paint probability (0-1). Lower = patchier, more natural.
local ZONE_DENSITY = { 0.75, 0.50, 0.40, 0.70, 0.65 }

-- Brush footprint in metres (square half-size around each paint point)
local ZONE_BRUSH_M = { 0.6, 0.8, 0.5, 1.0, 1.5 }

-- User-adjustable overrides (set by UI sliders)
local userHalfWidth = ZONE_HALF_WIDTH[1]
local userStep      = ZONE_STEP[1]
local userDensity   = ZONE_DENSITY[1]
local userBrushM    = ZONE_BRUSH_M[1]

local totalPainted  = 0
local totalSplines  = 0
local running       = false

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function crossProduct(ax, ay, az, bx, by, bz)
    return ay*bz - az*by,  az*bx - ax*bz,  ax*by - ay*bx
end

local function isSplineNode(nodeId)
    if nodeId == nil or nodeId == 0 then return false end
    local ok, len = pcall(getSplineLength, nodeId)
    if ok and type(len) == "number" and len > 0 then return true end
    if ClassIds and ClassIds.SHAPE and ClassIds.SPLINE then
        if getHasClassId(nodeId, ClassIds.SHAPE) then
            local geom = getGeometry(nodeId)
            if geom ~= nil and geom ~= 0 then
                return getHasClassId(geom, ClassIds.SPLINE)
            end
        end
    end
    return false
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

-- ── Core painter ──────────────────────────────────────────────────────────────

local function getTerrainId()
    local scene = getRootNode()
    for i = 0, getNumOfChildren(scene) - 1 do
        local child = getChildAt(scene, i)
        if getName(child) == "terrain" then return child end
    end
    return nil
end

local function paintFoliageAlongSpline(terrainId, splineId, layerNames,
                                        halfWidth, stepM, density, brushM)
    local splineLen = getSplineLength(splineId)
    if splineLen < 1.0 then return 0 end

    local stepT    = stepM / splineLen
    local brushHalf = brushM * 0.5
    local count    = 0

    -- Pick a random layer name for this spline pass to add variety
    local function pickLayer()
        return layerNames[math.random(1, #layerNames)]
    end

    local t = 0.0
    while t <= 1.0 do
        if math.random() <= density then
            local px, py, pz = getSplinePosition(splineId, t)
            local dx, dy, dz = getSplineDirection(splineId, t)

            -- Perpendicular vector (horizontal)
            local rx, ry, rz = crossProduct(dx, dy, dz, 0, 1, 0)
            local rLen = math.sqrt(rx*rx + rz*rz)
            if rLen > 0.001 then
                rx = rx / rLen
                rz = rz / rLen
            end

            -- Paint on both sides at a random offset within halfWidth
            for _, side in ipairs({ 1, -1 }) do
                local offset = math.random() * halfWidth + halfWidth * 0.2
                local wx = px + rx * offset * side
                local wz = pz + rz * offset * side

                local layerName = pickLayer()
                local foliageId = getTerrainDataPlaneByName(terrainId, layerName)
                if foliageId and foliageId ~= 0 then
                    local mod = DensityMapModifier.new(foliageId, 0, 5)
                    -- Paint a small parallelogram (square brush) at this world point
                    mod:setParallelogramWorldCoords(
                        wx - brushHalf, wz - brushHalf,
                        wx + brushHalf, wz - brushHalf,
                        wx - brushHalf, wz + brushHalf,
                        DensityCoordType.POINT_POINT_POINT
                    )
                    mod:executeSet(1)
                    count = count + 1
                end
            end
        end
        t = t + stepT
    end
    return count
end

-- ── Woodland floor fill ───────────────────────────────────────────────────────
-- Walks each closed-loop woodland boundary spline to find its bounding box,
-- then scatters foliage paint ops across the interior on a jittered grid.
-- This fills the entire woodland, not just the edge.

local function getSplineBounds(splineId)
    local splineLen = getSplineLength(splineId)
    if splineLen < 1.0 then return nil end

    local minX, minZ =  math.huge,  math.huge
    local maxX, maxZ = -math.huge, -math.huge

    -- Sample at 1 m intervals to map the boundary accurately
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

local function paintFloorFill(terrainId, splineId, layerNames,
                               gridStep, density, brushM)
    local bounds = { getSplineBounds(splineId) }
    if #bounds == 0 then return 0 end
    local minX, minZ, maxX, maxZ = bounds[1], bounds[2], bounds[3], bounds[4]

    local width  = maxX - minX
    local height = maxZ - minZ
    -- Skip splines whose bounding box is tiny (probably open lines, not loops)
    if width < 2.0 or height < 2.0 then return 0 end

    local brushHalf = brushM * 0.5
    local count = 0
    local halfJit = gridStep * 0.5   -- jitter each point up to ±½ grid step

    local x = minX
    while x <= maxX do
        local z = minZ
        while z <= maxZ do
            if math.random() <= density then
                -- Jitter position so the grid doesn't look mechanical
                local wx = x + (math.random() - 0.5) * 2 * halfJit
                local wz = z + (math.random() - 0.5) * 2 * halfJit

                local layerName = layerNames[math.random(1, #layerNames)]
                local foliageId = getTerrainDataPlaneByName(terrainId, layerName)
                if foliageId and foliageId ~= 0 then
                    local mod = DensityMapModifier.new(foliageId, 0, 5)
                    mod:setParallelogramWorldCoords(
                        wx - brushHalf, wz - brushHalf,
                        wx + brushHalf, wz - brushHalf,
                        wx - brushHalf, wz + brushHalf,
                        DensityCoordType.POINT_POINT_POINT
                    )
                    mod:executeSet(1)
                    count = count + 1
                end
            end
            z = z + gridStep
        end
        x = x + gridStep
    end
    return count
end

-- ── Main run ──────────────────────────────────────────────────────────────────

local function runPainter()
    if running then
        print("[SW Foliage Painter] Already running — please wait")
        return
    end

    local selId = getSelection(0)
    if selId == nil or selId == 0 then
        print("[SW Foliage Painter] ERROR: Nothing selected. Select a transform group containing splines.")
        return
    end

    local groupName = getName(selId)
    print(string.format("\n[SW Foliage Painter] ─────────────────────────────"))
    print(string.format("  Zone      : %s", ZONE_NAMES[selectedZone]))
    print(string.format("  Group     : %s", groupName))
    print(string.format("  Half-width: %.1f m", userHalfWidth))
    print(string.format("  Step      : %.2f m", userStep))
    print(string.format("  Density   : %.0f%%", userDensity * 100))

    -- Collect all splines in the group
    local splines = collectSplines(selId)
    if #splines == 0 then
        -- Maybe the selection IS itself a spline
        if isSplineNode(selId) then
            splines = { selId }
        else
            print("[SW Foliage Painter] ERROR: No splines found in selection.")
            return
        end
    end
    print(string.format("  Splines   : %d", #splines))

    local terrainId = getTerrainId()
    if terrainId == nil then
        print("[SW Foliage Painter] ERROR: Terrain node not found.")
        return
    end

    local layerNames = ZONE_LAYERS[selectedZone]
    local isFloor    = (selectedZone == ZONE_FLOOR)
    running = true
    totalPainted = 0
    totalSplines = 0

    if isFloor then
        print("  Mode      : INTERIOR FILL (grid scatter)")
        print(string.format("  Grid step : %.1f m", userStep))
    end

    for i, splineId in ipairs(splines) do
        local painted = 0
        if isFloor then
            painted = paintFloorFill(
                terrainId, splineId, layerNames,
                userStep, userDensity, userBrushM
            )
        else
            painted = paintFoliageAlongSpline(
                terrainId, splineId, layerNames,
                userHalfWidth, userStep, userDensity, userBrushM
            )
        end
        totalPainted = totalPainted + painted
        totalSplines = totalSplines + 1

        if i % 10 == 0 then
            print(string.format("  … processed %d / %d splines (%d paint ops so far)",
                i, #splines, totalPainted))
        end
    end

    running = false
    print(string.format("\n  ✓ Done. %d splines | %d foliage paint operations",
        totalSplines, totalPainted))
    print("[SW Foliage Painter] ─────────────────────────────\n")
end

-- ── UI ────────────────────────────────────────────────────────────────────────

local function updateDefaults()
    userHalfWidth = ZONE_HALF_WIDTH[selectedZone]
    userStep      = ZONE_STEP[selectedZone]
    userDensity   = ZONE_DENSITY[selectedZone]
    userBrushM    = ZONE_BRUSH_M[selectedZone]
end

local frameSizer = UIRowLayoutSizer.new()
local window     = UIWindow.new(frameSizer, "SW Foliage Zone Painter")
local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer)

-- Zone preset dropdown
local zoneLabelSizer = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, zoneLabelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(zoneLabelSizer, "Zone preset:", TextAlignment.LEFT)
local zoneDropdown = UIDropdown.new(zoneLabelSizer, ZONE_NAMES, function(idx)
    selectedZone = idx
    updateDefaults()
    print(string.format("[SW Foliage Painter] Zone → %s  (half-width %.1f m, step %.2f m, density %.0f%%)",
        ZONE_NAMES[idx], userHalfWidth, userStep, userDensity * 100))
end)

-- Half-width slider
local hwSizer = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, hwSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(hwSizer, "Half-width / fill offset (m):", TextAlignment.LEFT)
local hwSlider = UIFloatSlider.new(hwSizer, userHalfWidth, 0.5, 8.0, 0.5, 8.0)
hwSlider:setOnChangeCallback(function(v) userHalfWidth = v end)

-- Step slider
local stepSizer = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, stepSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(stepSizer, "Step / grid size (m):", TextAlignment.LEFT)
local stepSlider = UIFloatSlider.new(stepSizer, userStep, 0.3, 6.0, 0.3, 6.0)
stepSlider:setOnChangeCallback(function(v) userStep = v end)

-- Density slider
local densSizer = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, densSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(densSizer, "Density (0.0 – 1.0):", TextAlignment.LEFT)
local densSlider = UIFloatSlider.new(densSizer, userDensity, 0.1, 1.0, 0.1, 1.0)
densSlider:setOnChangeCallback(function(v) userDensity = v end)

-- Info text
local infoSizer = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, infoSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(infoSizer,
    "Select spline GROUP in scene tree, then click Paint.\n"..
    "WOODLAND FLOOR: select 'woodland_boundaries' group.\n"..
    "Step slider = grid cell size for floor fill.", TextAlignment.LEFT)

-- Run button
local btnSizer = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, btnSizer)
UIButton.new(btnSizer, "Paint Foliage Zone", runPainter)

window:showWindow()

print("\n[SW Foliage Painter] Ready.")
print("Foliage layers per zone:")
print("  HEDGE MARGIN   : hazelnutSmall/Med, boxwoodSmall/Med, decobushSmall/Med")
print("  ROAD VERGE     : GrassSmall, GrassMedium, GrassDenseMix, Meadow")
print("  FIELD MARGIN   : Meadow, GrassMedium, GrassSmall")
print("  WOODLAND EDGE  : ForestGrass, ForestClover, ForestSwordFern,")
print("                   ForestDeerFern, ForestStarFlower, decobushSmall")
print("  WOODLAND FLOOR : ForestGrass, ForestClover, ForestSwordFern,")
print("                   ForestDeerFern, ForestStarryFalse, ForestBunchBerry,")
print("                   ForestDryBranch, blueberryShort/Small, decobushSmall")
