-- Author: South Warwickshire FS25 Pipeline
-- Name: SW Batch Spline Placer
-- Description: Places objects along ALL splines in a selected group in one
--              pass. Designed for the 2000+ hedge splines imported via
--              geojson_to_i3d_splines.py. Complements splinePlacementPanel
--              which works on one spline at a time.
--
-- Usage:
--   1. Select the transform group containing your imported splines
--      (e.g. "osm_hedges" or "inferred_hedges" from sw_hedge_splines.i3d)
--   2. Set "Object to Place" to any transform group that contains your
--      hedge/fence objects as children (it will clone them)
--   3. Adjust spacing and options
--   4. Click Run — all splines in the group are processed in one pass
--   5. Output lands in a new "sw_placed_<group_name>" group
--   6. After running, select that output group and run
--      FSG-FS25-AlignChildsToTerrain-v1.lua to snap everything to terrain
--
-- Hide: no
-- AlwaysLoaded: no

-- ── State ────────────────────────────────────────────────────────────────────

local objectSpacing   = 2.0     -- metres between placed objects
local randomYRotation = false   -- randomise Y axis rotation
local randomScale     = false   -- randomise object scale
local scaleLow        = 0.8
local scaleHigh       = 1.2
local stayUpright     = true    -- keep objects vertical (no spline X/Z tilt)
local randomPlacement = false   -- random lateral offset
local randomOffset    = 0.5     -- max lateral offset in metres
local templateGroupId = nil     -- the "objectsToPlace" template group
local outputGroupId   = nil     -- created fresh each run

local mSceneID  = getRootNode()
local mTerrainID = 0

for i = 0, getNumOfChildren(mSceneID) - 1 do
    local mID = getChildAt(mSceneID, i)
    if getName(mID) == "terrain" then
        mTerrainID = mID
        break
    end
end

if mTerrainID == 0 then
    printError("Terrain node not found. Node must be named 'terrain'.")
    return
end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function crossProduct(ax, ay, az, bx, by, bz)
    return ay*bz - az*by,  az*bx - ax*bz,  ax*by - ay*bx
end

-- Returns true if node is a spline (works with both <Spline> and <NurbsCurve> i3d types)
local function isSplineNode(nodeId)
    if nodeId == nil or nodeId == 0 then return false end
    -- Primary check: try getSplineLength directly — works for any spline type
    local ok, len = pcall(getSplineLength, nodeId)
    if ok and type(len) == "number" and len > 0 then
        return true
    end
    -- Fallback: ClassIds check (may not be available in all GE versions)
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

-- Collect all spline Shape children (recursively) into a flat table
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

-- Pick a random child from objectsToPlace (round-robin if not random)
local objectIndex = 0
local function nextObject(objectsGroup)
    local n = getNumOfChildren(objectsGroup)
    if n == 0 then return nil end
    local idx = objectIndex % n
    objectIndex = objectIndex + 1
    return getChildAt(objectsGroup, idx)
end

-- ── Core placement function ───────────────────────────────────────────────────

local totalPlaced = 0
local totalSplines = 0
local skippedSplines = 0

local function placeAlongSpline(splineId, objectsGroup, parentGroup)
    local splineLength = getSplineLength(splineId)
    if splineLength < 2 then
        skippedSplines = skippedSplines + 1
        return
    end

    totalSplines = totalSplines + 1

    local step = objectSpacing / splineLength
    local pos  = step  -- start one step in so we don't pile up at spline start

    local xLast, yLast, zLast = getSplinePosition(splineId, 0)
    yLast = getTerrainHeightAtWorldPos(mTerrainID, xLast, yLast, zLast) or yLast

    while pos <= 1.0 do
        local x, y, z = getSplinePosition(splineId, pos)
        local placeId = true

        -- Snap to terrain
        local terrainY = getTerrainHeightAtWorldPos(mTerrainID, x, y, z)
        if terrainY == nil or terrainY == 0 then
            placeId = false  -- outside map bounds, skip
        else
            y = terrainY
        end

        if placeId then
            -- Optional random lateral offset
            if randomPlacement then
                local dirX, dirY, dirZ = getSplineDirection(splineId, pos)
                local vx, vy, vz = crossProduct(dirX, dirY, dirZ, 0, 1, 0)
                local offset = (math.random() - 0.5) * 2.0 * randomOffset
                x = x + offset * vx
                z = z + offset * vz
                local offsetY = getTerrainHeightAtWorldPos(mTerrainID, x, y, z)
                if offsetY ~= nil and offsetY ~= 0 then y = offsetY end
            end

            -- Clone next object from template
            local templateObj = nextObject(objectsGroup)
            if templateObj == nil then break end

            local cloneId = clone(templateObj, false, true)
            if cloneId ~= nil then
                link(parentGroup, cloneId)

                -- Position
                setWorldTranslation(cloneId, x, y, z)

                -- Rotation
                if randomYRotation then
                    local ry = math.random() * math.pi * 2
                    setWorldRotation(cloneId, 0, ry, 0)
                elseif not stayUpright then
                    local yyy = y - yLast
                    setDirection(cloneId, x - xLast, yyy, z - zLast, 0, 1, 0)
                end

                -- Scale
                if randomScale and scaleLow < scaleHigh then
                    local s = scaleLow + math.random() * (scaleHigh - scaleLow)
                    setScale(cloneId, s, s, s)
                end

                totalPlaced = totalPlaced + 1
                xLast, yLast, zLast = x, y, z
            end
        end

        pos = pos + step
    end
end

-- ── Main run function ─────────────────────────────────────────────────────────

local function runBatchPlacement()
    if templateGroupId == nil or templateGroupId == 0 then
        printError("No template group set. Enter the name of your objectsToPlace group in the Object Group Name field.")
        return
    end

    -- Resolve template group by name if needed
    local objectsGroup = templateGroupId

    local numTemplates = getNumOfChildren(objectsGroup)
    if numTemplates == 0 then
        printError("Template group is empty. Add objects to place inside it first.")
        return
    end

    local selectedGroup = getSelection(0)
    if selectedGroup == nil or selectedGroup == 0 then
        printError("No group selected. Select the spline group (e.g. osm_hedges) before running.")
        return
    end

    local groupName = getName(selectedGroup)
    print(string.format("Processing spline group: %s", groupName))

    -- Collect all splines in the selected group
    local splines = collectSplines(selectedGroup)
    if #splines == 0 then
        printError(string.format("No spline shapes found in '%s'. Make sure you imported sw_hedge_splines.i3d and selected the correct group.", groupName))
        return
    end

    print(string.format("  Found %d splines, %d template objects, spacing=%.1fm",
        #splines, numTemplates, objectSpacing))

    -- Create output group
    local outputName = "sw_placed_" .. groupName
    outputGroupId = createTransformGroup(outputName)
    link(mSceneID, outputGroupId)
    print(string.format("  Output group: %s", outputName))

    -- Reset counters
    totalPlaced   = 0
    totalSplines  = 0
    skippedSplines = 0
    objectIndex   = 0

    -- Process each spline
    for i, splineId in ipairs(splines) do
        placeAlongSpline(splineId, objectsGroup, outputGroupId)
        if i % 100 == 0 then
            print(string.format("  Progress: %d/%d splines | %d objects placed",
                i, #splines, totalPlaced))
        end
    end

    print("")
    print("=== Batch Placement Complete ===")
    print(string.format("  Splines processed: %d", totalSplines))
    print(string.format("  Splines skipped:   %d (too short)", skippedSplines))
    print(string.format("  Objects placed:    %d", totalPlaced))
    print(string.format("  Output group:      %s", "sw_placed_" .. groupName))
    print("")
    print("NEXT: Select 'sw_placed_" .. groupName .. "' and run")
    print("      FSG-FS25-AlignChildsToTerrain-v1.lua")
    print("      to snap all objects to exact terrain height.")
end

-- ── UI ────────────────────────────────────────────────────────────────────────

local labelWidth = 250.0

local frameSizer = UIRowLayoutSizer.new()
local myFrame = UIWindow.new(frameSizer, "SW Batch Spline Placer")

local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer)

local rowSizer = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, rowSizer, -1, -1, 320, -1, BorderDirection.ALL, 10, 1)

-- Info
local infoLabel = UILabel.new(rowSizer,
    "Select a spline group (e.g. osm_hedges)\nthen Run to place objects along all splines.",
    TextAlignment.LEFT, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

-- Object template group selector
local templateSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, templateSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
UILabel.new(templateSizer, "Object Template Group ID", TextAlignment.LEFT, -1, -1, labelWidth)
UILabel.new(templateSizer, "(enter node ID from Scene Tree — the group containing\nyour hedge/fence objects as children)",
    TextAlignment.LEFT, -1, -1, labelWidth)
local templateInput = UIIntSlider.new(templateSizer, 0, 0, 9999999)
templateInput:setOnChangeCallback(function(value)
    if value ~= nil and value > 0 then
        templateGroupId = value
    end
end)

-- Spacing
local spacingSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, spacingSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
UILabel.new(spacingSizer, "Object Spacing (metres)", TextAlignment.LEFT, -1, -1, labelWidth)
local spacingSlider = UIFloatSlider.new(spacingSizer, objectSpacing, 0.5, 20.0, 0.5, 20.0)
spacingSlider:setOnChangeCallback(function(value) objectSpacing = value end)

-- Stay upright
local choice = {"Deselected", "Selected"}

local uprightSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, uprightSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
UILabel.new(uprightSizer, "Stay Upright (no spline tilt)", TextAlignment.LEFT, -1, -1, labelWidth)
local uprightChoice = UIChoice.new(uprightSizer, choice, 1, -1, 120, -1)
uprightChoice:setOnChangeCallback(function(v) stayUpright = (v == 2) end)

-- Random Y rotation
local ryRotSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, ryRotSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
UILabel.new(ryRotSizer, "Random Y Rotation", TextAlignment.LEFT, -1, -1, labelWidth)
local ryRotChoice = UIChoice.new(ryRotSizer, choice, 0, -1, 120, -1)
ryRotChoice:setOnChangeCallback(function(v) randomYRotation = (v == 2) end)

-- Random scale
local rScaleSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, rScaleSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
UILabel.new(rScaleSizer, "Random Scale", TextAlignment.LEFT, -1, -1, labelWidth)
local rScaleChoice = UIChoice.new(rScaleSizer, choice, 0, -1, 120, -1)
rScaleChoice:setOnChangeCallback(function(v) randomScale = (v == 2) end)

local scaleLowSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, scaleLowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(scaleLowSizer, "Scale Low", TextAlignment.LEFT, -1, -1, labelWidth)
local scaleLowSlider = UIFloatSlider.new(scaleLowSizer, scaleLow, 0.1, 3.0, 0.1, 3.0)
scaleLowSlider:setOnChangeCallback(function(v) scaleLow = v end)

local scaleHighSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, scaleHighSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
UILabel.new(scaleHighSizer, "Scale High", TextAlignment.LEFT, -1, -1, labelWidth)
local scaleHighSlider = UIFloatSlider.new(scaleHighSizer, scaleHigh, 0.1, 3.0, 0.1, 3.0)
scaleHighSlider:setOnChangeCallback(function(v) scaleHigh = v end)

-- Random lateral offset
local rPlaceSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, rPlaceSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
UILabel.new(rPlaceSizer, "Random Lateral Offset", TextAlignment.LEFT, -1, -1, labelWidth)
local rPlaceChoice = UIChoice.new(rPlaceSizer, choice, 0, -1, 120, -1)
rPlaceChoice:setOnChangeCallback(function(v) randomPlacement = (v == 2) end)

local rOffsetSizer = UIColumnLayoutSizer.new()
UIPanel.new(rowSizer, rOffsetSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
UILabel.new(rOffsetSizer, "Max Lateral Offset (m)", TextAlignment.LEFT, -1, -1, labelWidth)
local rOffsetSlider = UIFloatSlider.new(rOffsetSizer, randomOffset, 0.0, 5.0, 0.0, 5.0)
rOffsetSlider:setOnChangeCallback(function(v) randomOffset = v end)

UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

UIButton.new(rowSizer, "Run Batch Placement", runBatchPlacement, nil,
    -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1)

myFrame:showWindow()
