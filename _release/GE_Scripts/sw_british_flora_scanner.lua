local SW_VERSION = "1.1"
source("editorUtils.lua")
local gamePath = EditorUtils.getGameBasePath()
if gamePath == nil then
    printError("SW British Flora Scanner: Could not find game install path. Is a map open?")
    return
end
local EXCLUSIONS = {
    { name="Asphalt / Road",          R=0.071, G=0.063, B=0.063, W=0.0,  tol=0.014 },
    { name="Asphalt Dusty",           R=0.137, G=0.129, B=0.116, W=0.0,  tol=0.014 },
    { name="Asphalt Twigs",           R=0.071, G=0.063, B=0.063, W=0.0,  tol=0.014 },
    { name="Asphalt Cracks",          R=0.071, G=0.063, B=0.063, W=0.0,  tol=0.014 },
    { name="Gravel / Hard",           R=0.157, G=0.141, B=0.122, W=0.0,  tol=0.014 },
    { name="Concrete Dirt",           R=0.165, G=0.149, B=0.125, W=0.0,  tol=0.014 },
    { name="Concrete / Rock Hard",    R=0.220, G=0.212, B=0.196, W=0.0,  tol=0.015 },
    { name="Rock Floor Tiles",        R=0.208, G=0.184, B=0.165, W=0.0,  tol=0.014 },
    { name="Rock Floor Pattern",      R=0.212, G=0.204, B=0.188, W=0.0,  tol=0.014 },
    { name="Mud Dark (cultivated)",   R=0.071, G=0.055, B=0.043, W=1.0,  tol=0.014 },
    { name="Mud Tracks (farm)",       R=0.062, G=0.044, B=0.027, W=1.0,  tol=0.014 },
    { name="Mud Tracks 2",            R=0.137, G=0.098, B=0.075, W=1.0,  tol=0.014 },
    { name="Mud Pebbles",             R=0.067, G=0.051, B=0.039, W=1.0,  tol=0.012 },
    { name="Mud Gravel",              R=0.176, G=0.153, B=0.133, W=1.0,  tol=0.014 },
    { name="Mud Light",               R=0.137, G=0.114, B=0.078, W=1.0,  tol=0.014 },
    { name="Mud Dark Grass (field)",  R=0.078, G=0.067, B=0.043, W=1.0,  tol=0.012 },
    { name="Mud Dark Moss (field)",   R=0.071, G=0.075, B=0.043, W=1.0,  tol=0.012 },
    { name="Sand",                    R=0.230, G=0.122, B=0.061, W=1.0,  tol=0.014 },
}
local PRESETS = {
    {
        name = "WOODLAND FLOOR",
        desc = "Bracken, clovers, leaf litter, hazel",
        plants = {
            { plane="forestPlants", state=8,  nc=4, w=5 },  -- swordFern = Bracken
            { plane="forestPlants", state=2,  nc=4, w=4 },  -- dryBranches = Leaf litter
            { plane="forestPlants", state=3,  nc=4, w=3 },  -- clovers
            { plane="forestPlants", state=10, nc=4, w=3 },  -- grass
            { plane="forestPlants", state=11, nc=4, w=2 },  -- stingingNettle
            { plane="decoBush",     state=13, nc=4, w=2 },  -- HazelnutSmall
            { plane="decoBush",     state=10, nc=4, w=1 },  -- BoxwoodSmall
        }
    },
    {
        name = "MEADOW & VERGE",
        desc = "Dried grasses, thistle, tall weeds - British verge",
        plants = {
            { plane="decoFoliage",  state=9,  nc=5, w=5 },  -- grassSmall (dried British grass)
            { plane="decoFoliage",  state=10, nc=5, w=5 },  -- grassMedium
            { plane="decoFoliage",  state=1,  nc=5, w=4 },  -- smallDenseMix (base cover)
            { plane="decoFoliage",  state=6,  nc=5, w=3 },  -- cirsium (thistle)
            { plane="decoFoliage",  state=15, nc=5, w=3 },  -- mixed
            { plane="decoFoliage",  state=4,  nc=5, w=2 },  -- whiteTallWeed
            { plane="decoFoliage",  state=5,  nc=5, w=2 },  -- greenTallWeed
        }
    },
    {
        name = "HEDGEROW SCRUB",
        desc = "Hazel, hawthorn, blackthorn dominant",
        plants = {
            { plane="decoBush",     state=13, nc=4, w=5 },  -- HazelnutSmall
            { plane="decoBush",     state=14, nc=4, w=4 },  -- HazelnutMed
            { plane="decoBush",     state=10, nc=4, w=4 },  -- BoxwoodSmall
            { plane="decoBush",     state=11, nc=4, w=3 },  -- BoxwoodMed
            { plane="decoFoliage",  state=1,  nc=5, w=3 },  -- smallDenseMix (base layer)
            { plane="forestPlants", state=8,  nc=4, w=2 },  -- swordFern (bracken at base)
            { plane="decoBush",     state=15, nc=4, w=1 },  -- HazelnutBig
        }
    },
    {
        name = "FOREST EDGE",
        desc = "Mixed margin - hazel, bracken, nettle, grass",
        plants = {
            { plane="forestPlants", state=8,  nc=4, w=4 },  -- swordFern (bracken)
            { plane="forestPlants", state=10, nc=4, w=3 },  -- grass
            { plane="forestPlants", state=11, nc=4, w=2 },  -- stingingNettle
            { plane="forestPlants", state=3,  nc=4, w=2 },  -- clovers
            { plane="decoBush",     state=13, nc=4, w=3 },  -- HazelnutSmall
            { plane="decoBush",     state=10, nc=4, w=2 },  -- BoxwoodSmall
            { plane="forestPlants", state=2,  nc=4, w=1 },  -- dryBranches
        }
    },
    {
        name = "LIGHT SCATTER",
        desc = "Sparse wildflowers and grasses only",
        plants = {
            { plane="decoFoliage",  state=1,  nc=5, w=5 },  -- smallDenseMix
            { plane="decoFoliage",  state=9,  nc=5, w=3 },  -- grassSmall
            { plane="decoFoliage",  state=7,  nc=5, w=2 },  -- poppy
            { plane="decoFoliage",  state=15, nc=5, w=2 },  -- mixed
        }
    },
    {
        name = "DEEP WOODLAND",
        desc = "Leaf litter, bracken, nettle, branches",
        plants = {
            { plane="forestPlants", state=2,  nc=4, w=6 },  -- dryBranches (leaf litter)
            { plane="forestPlants", state=8,  nc=4, w=4 },  -- swordFern (bracken)
            { plane="forestPlants", state=1,  nc=4, w=2 },  -- bigBranchesPure (fallen)
            { plane="forestPlants", state=11, nc=4, w=2 },  -- stingingNettle
            { plane="decoBush",     state=13, nc=4, w=1 },  -- HazelnutSmall (occasional)
        }
    },
}
local tool = {}
tool.window       = nil
tool.sampR        = 0.155
tool.sampG        = 0.082
tool.sampB        = 0.037
tool.sampW        = 0.7
tool.hasSample    = false
tool.presetIdx    = 1
tool.tolerance    = 0.025
tool.density      = 0.65
tool.spacing      = 1.5
tool.scanRadius   = 50      -- Metres for "Scan Here" targeted paint
tool.partition    = 1
tool.totalPlaced  = 0
tool.lblSample    = nil
tool.lblPreset    = nil
tool.lblDesc      = nil
tool.lblPartition = nil
tool.lblStatus    = nil
tool.lblTolVal    = nil
tool.lblDensVal   = nil
tool.lblSpaceVal  = nil
tool.lblRadVal    = nil
tool.lblCheck     = nil
tool.terrainId    = nil
tool.planeCache   = {}
local function findTerrainNode()
    local tid = nil
    if getTerrainId ~= nil then
        tid = getTerrainId()
    end
    if tid == nil or tid == 0 then
        tid = getRootNode()
        local n = getNumOfChildren(tid)
        for i = 0, n - 1 do
            local child = getChildAt(tid, i)
            if getName(child) == "terrain" then
                tid = child
                break
            end
        end
    end
    return tid
end
local function getPlaneId(terrainId, planeName)
    if tool.planeCache[planeName] then
        return tool.planeCache[planeName]
    end
    local pid = getTerrainDataPlaneByName(terrainId, planeName)
    tool.planeCache[planeName] = pid
    return pid
end
local function pickPlant(preset)
    local totalW = 0
    for _, p in ipairs(preset.plants) do totalW = totalW + p.w end
    local roll = math.random() * totalW
    local cumW = 0
    for _, p in ipairs(preset.plants) do
        cumW = cumW + p.w
        if roll <= cumW then return p end
    end
    return preset.plants[1]
end
local function rgbaMatch(r, g, b, w, tr, tg, tb, tw, tol)
    return math.abs(r - tr) <= tol
       and math.abs(g - tg) <= tol
       and math.abs(b - tb) <= tol
       and math.abs(w - tw) <= tol
end
local function isExcluded(r, g, b, w)
    for _, ex in ipairs(EXCLUSIONS) do
        if rgbaMatch(r, g, b, w, ex.R, ex.G, ex.B, ex.W, ex.tol) then
            return true, ex.name
        end
    end
    return false, nil
end
local function paintAtPoint(terrainId, wx, wz, plant)
    local pid = getPlaneId(terrainId, plant.plane)
    if pid == nil or pid == 0 then return false end
    local mod = DensityMapModifier.new(pid, 0, plant.nc)
    if mod == nil then return false end
    mod:setParallelogramWorldCoords(
        wx,              wz,
        wx + tool.spacing, wz,
        wx,              wz + tool.spacing,
        DensityCoordType.POINT_POINT_POINT
    )
    mod:executeSet(plant.state)
    return true
end
local function scanArea(x0, x1, z0, z1, preset, seed)
    local tid = tool.terrainId
    math.randomseed(seed)
    local placed = 0
    local wz = z0
    while wz <= z1 do
        local wx = x0
        while wx <= x1 do
            if math.random() <= tool.density then
                local wy = getTerrainHeightAtWorldPos(tid, wx, 0, wz)
                local r, g, b, w = getTerrainAttributesAtWorldPos(
                    tid, wx, wy, wz, true, true, true, true, false)
                local matches
                if tool.hasSample then
                    matches = rgbaMatch(r, g, b, w,
                        tool.sampR, tool.sampG, tool.sampB, tool.sampW,
                        tool.tolerance)
                else
                    matches = true
                end
                local excl = isExcluded(r, g, b, w)
                if matches and not excl then
                    local plant = pickPlant(preset)
                    if paintAtPoint(tid, wx, wz, plant) then
                        placed = placed + 1
                    end
                end
            end
            wx = wx + tool.spacing
        end
        wz = wz + tool.spacing
    end
    return placed
end
local function scanPartition(partIdx)
    local tid = tool.terrainId
    if tid == nil or tid == 0 then
        print("SW Flora: No terrain found.")
        return 0
    end
    local terrainSize = getTerrainSize(tid)
    local half        = terrainSize / 2
    local numSect     = math.sqrt(64)
    local sectSize    = terrainSize / numSect
    local sectHalf    = sectSize / 2
    local col         = (partIdx - 1) % numSect
    local row         = math.floor((partIdx - 1) / numSect)
    local centerX     = (col * sectSize) + sectHalf - half
    local centerZ     = (row * sectSize) + sectHalf - half
    local preset      = PRESETS[tool.presetIdx]
    local seed        = partIdx * 31337 + tool.presetIdx * 7919
    return scanArea(centerX - sectHalf, centerX + sectHalf,
                    centerZ - sectHalf, centerZ + sectHalf,
                    preset, seed)
end
local function onSampleTexture()
    local node = getSelection(0)
    if node == nil or node == 0 then
        printWarning("SW Flora: Select a transform node placed on the texture you want to target first.")
        return
    end
    local tid = tool.terrainId
    if tid == nil or tid == 0 then
        printWarning("SW Flora: No terrain node found.")
        return
    end
    local tx, ty, tz = getWorldTranslation(node)
    local r, g, b, w = getTerrainAttributesAtWorldPos(
        tid, tx, ty, tz, true, true, true, true, false)
    tool.sampR, tool.sampG, tool.sampB, tool.sampW = r, g, b, w
    tool.hasSample = true
    local txt = string.format("Sampled: R=%.3f G=%.3f B=%.3f W=%.3f", r, g, b, w)
    tool.lblSample:setText(txt)
    local excl, exclName = isExcluded(r, g, b, w)
    if excl then
        printWarning("SW Flora: WARNING - sampled texture is excluded (" .. exclName .. "). Foliage will NOT be painted there.")
    else
        print("SW Flora: " .. txt)
    end
end
local function updatePresetUI()
    local p = PRESETS[tool.presetIdx]
    tool.lblPreset:setText(string.format("[%d/%d] %s", tool.presetIdx, #PRESETS, p.name))
    tool.lblDesc:setText(p.desc)
end
local function onPresetPrev()
    tool.presetIdx = tool.presetIdx - 1
    if tool.presetIdx < 1 then tool.presetIdx = #PRESETS end
    updatePresetUI()
end
local function onPresetNext()
    tool.presetIdx = tool.presetIdx + 1
    if tool.presetIdx > #PRESETS then tool.presetIdx = 1 end
    updatePresetUI()
end
local function onScanNext()
    if tool.partition > 64 then
        tool.lblStatus:setText("All 64 partitions complete! Total: " .. tool.totalPlaced .. " plants.")
        return
    end
    tool.lblStatus:setText("Scanning partition " .. tool.partition .. " / 64...")
    print(string.format("SW Flora: Scanning partition %d / 64  (preset: %s)", tool.partition, PRESETS[tool.presetIdx].name))
    local placed = scanPartition(tool.partition)
    tool.totalPlaced = tool.totalPlaced + placed
    tool.partition = tool.partition + 1
    local done = math.min(tool.partition - 1, 64)
    tool.lblPartition:setText(string.format("Partition: %d / 64  (done: %d)", tool.partition, done))
    tool.lblStatus:setText(string.format("Done p%d: +%d plants.  Total: %d", done, placed, tool.totalPlaced))
    print(string.format("SW Flora: Partition %d complete. Placed: %d  |  Total: %d", done, placed, tool.totalPlaced))
end
local function onScanAll()
    tool.lblStatus:setText("Running all 64 partitions - please wait...")
    print("SW Flora: Scanning all 64 partitions. Preset: " .. PRESETS[tool.presetIdx].name)
    while tool.partition <= 64 do
        local placed = scanPartition(tool.partition)
        tool.totalPlaced = tool.totalPlaced + placed
        print(string.format("  Partition %d done: +%d", tool.partition, placed))
        tool.partition = tool.partition + 1
    end
    tool.lblPartition:setText("Partition: 64 / 64  (complete)")
    tool.lblStatus:setText("ALL DONE! Total plants placed: " .. tool.totalPlaced)
    print("SW Flora: All done. Total plants placed: " .. tool.totalPlaced)
end
local function onScanHere()
    local node = getSelection(0)
    if node == nil or node == 0 then
        tool.lblStatus:setText("ERROR: Select a node on the area to paint, then click Scan Here.")
        return
    end
    local tid = tool.terrainId
    if tid == nil or tid == 0 then return end
    local tx, _, tz = getWorldTranslation(node)
    local rad    = tool.scanRadius
    local preset = PRESETS[tool.presetIdx]
    local seed   = math.floor(math.abs(tx) * 17 + math.abs(tz) * 31337 + tool.presetIdx * 7919)
    print(string.format("SW Flora: Scan Here  pos=(%.1f, %.1f)  radius=%.0fm  preset=%s",
        tx, tz, rad, preset.name))
    local placed = scanArea(tx - rad, tx + rad, tz - rad, tz + rad, preset, seed)
    tool.totalPlaced = tool.totalPlaced + placed
    tool.lblStatus:setText(string.format("Scan Here: +%d plants in %.0fm radius.  Total: %d",
        placed, rad, tool.totalPlaced))
    print(string.format("SW Flora: Scan Here complete. Placed: %d  |  Total: %d", placed, tool.totalPlaced))
end
local function onResetScan()
    tool.partition   = 1
    tool.totalPlaced = 0
    tool.planeCache  = {}
    tool.lblPartition:setText("Partition: 1 / 64")
    tool.lblStatus:setText("Scan reset. Ready.")
    print("SW Flora: Scan reset.")
end
local function onClearHere()
    local node = getSelection(0)
    if node == nil or node == 0 then
        printWarning("SW Flora: Select a node placed over the area to clear.")
        return
    end
    local tid = tool.terrainId
    if tid == nil or tid == 0 then return end
    local tx, _, tz = getWorldTranslation(node)
    local brushR = 10
    local planes = {
        { name="decoFoliage",  nc=5 },
        { name="forestPlants", nc=4 },
        { name="meadow",       nc=4 },
        { name="decoBush",     nc=4 },
    }
    for _, p in ipairs(planes) do
        local pid = getPlaneId(tid, p.name)
        if pid and pid ~= 0 then
            local mod = DensityMapModifier.new(pid, 0, p.nc)
            if mod then
                mod:setParallelogramWorldCoords(
                    tx - brushR, tz - brushR,
                    tx + brushR, tz - brushR,
                    tx - brushR, tz + brushR,
                    DensityCoordType.POINT_POINT_POINT
                )
                mod:executeSet(0)
            end
        end
    end
    tool.lblStatus:setText("Cleared foliage near selected node (~10m radius).")
    print(string.format("SW Flora: Cleared foliage at (%.1f, %.1f)", tx, tz))
end
local function onCheckLocation()
    local node = getSelection(0)
    if node == nil or node == 0 then
        tool.lblCheck:setText("ERROR: Select a node on the terrain first.")
        return
    end
    local tid = tool.terrainId
    if tid == nil or tid == 0 then return end
    local tx, ty, tz = getWorldTranslation(node)
    local r, g, b, w = getTerrainAttributesAtWorldPos(tid, tx, ty, tz, true, true, true, true, false)
    local rgbaTxt = string.format("R=%.3f G=%.3f B=%.3f W=%.3f", r, g, b, w)
    local excl, exclName = isExcluded(r, g, b, w)
    if excl then
        local msg = "EXCLUDED - " .. exclName .. "  [" .. rgbaTxt .. "]"
        tool.lblCheck:setText(msg)
        print("SW Flora CHECK: " .. msg)
        return
    end
    local isUniversalGrass = rgbaMatch(r, g, b, w, 0.155, 0.082, 0.037, 0.700, 0.015)
    if tool.hasSample then
        if rgbaMatch(r, g, b, w, tool.sampR, tool.sampG, tool.sampB, tool.sampW, tool.tolerance) then
            local msg
            if isUniversalGrass then
                msg = string.format("WILL PAINT [%s]  Preset: %s  -- NOTE: all grass surfaces share this RGBA. Use 'Scan Here' to target only this zone.",
                    rgbaTxt, PRESETS[tool.presetIdx].name)
            else
                msg = string.format("WILL PAINT [%s]  Preset: %s", rgbaTxt, PRESETS[tool.presetIdx].name)
            end
            tool.lblCheck:setText(msg)
            print("SW Flora CHECK: " .. msg)
        else
            local sampTxt = string.format("R=%.3f G=%.3f B=%.3f W=%.3f",
                tool.sampR, tool.sampG, tool.sampB, tool.sampW)
            local msg = string.format("NO MATCH  Here: [%s]  Sample: [%s]", rgbaTxt, sampTxt)
            tool.lblCheck:setText(msg)
            print("SW Flora CHECK: " .. msg)
        end
    else
        local msg
        if isUniversalGrass then
            msg = string.format("WILL PAINT [%s]  Preset: %s  -- NOTE: all grass surfaces share this RGBA. Use 'Scan Here' to target only this zone.",
                rgbaTxt, PRESETS[tool.presetIdx].name)
        else
            msg = string.format("WILL PAINT [%s]  Preset: %s  (no sample set)", rgbaTxt, PRESETS[tool.presetIdx].name)
        end
        tool.lblCheck:setText(msg)
        print("SW Flora CHECK: " .. msg)
    end
end
local function onDiagnostic()
    local tid = tool.terrainId
    if tid == nil or tid == 0 then
        print("SW Flora DIAG: ERROR - no terrain ID")
        return
    end
    print("SW Flora DIAG: --- Foliage plane IDs ---")
    local planeNames = { "decoFoliage", "forestPlants", "meadow", "decoBush" }
    for _, pname in ipairs(planeNames) do
        local pid = getTerrainDataPlaneByName(tid, pname)
        print(string.format("  %-14s -> id=%s", pname, tostring(pid)))
    end
    local node = getSelection(0)
    if node == nil or node == 0 then
        print("SW Flora DIAG: No node selected - select a node on the terrain first.")
        return
    end
    local tx, ty, tz = getWorldTranslation(node)
    local r, g, b, w = getTerrainAttributesAtWorldPos(tid, tx, ty, tz, true, true, true, true, false)
    print(string.format("SW Flora DIAG: RGBA at node  R=%.4f G=%.4f B=%.4f W=%.4f", r, g, b, w))
    local excl, exclName = isExcluded(r, g, b, w)
    print("SW Flora DIAG: isExcluded = " .. tostring(excl) .. (excl and (" (" .. exclName .. ")") or ""))
    local pid1 = getTerrainDataPlaneByName(tid, "forestPlants")
    if pid1 and pid1 ~= 0 then
        local mod1 = DensityMapModifier.new(pid1, 0, 4)
        if mod1 then
            mod1:setParallelogramWorldCoords(tx, tz, tx+1, tz, tx, tz+1, DensityCoordType.POINT_POINT_POINT)
            local res = mod1:executeSet(8)
            print("SW Flora DIAG: forestPlants nc=4 state=8(bracken)  result=" .. tostring(res))
        end
    else
        print("SW Flora DIAG: ERROR - forestPlants plane not found")
    end
    local pid2 = getTerrainDataPlaneByName(tid, "decoBush")
    if pid2 and pid2 ~= 0 then
        local mod2 = DensityMapModifier.new(pid2, 0, 4)
        if mod2 then
            mod2:setParallelogramWorldCoords(tx+2, tz, tx+3, tz, tx+2, tz+1, DensityCoordType.POINT_POINT_POINT)
            local res = mod2:executeSet(13)
            print("SW Flora DIAG: decoBush     nc=4 state=13(hazel)   result=" .. tostring(res))
        end
    else
        print("SW Flora DIAG: ERROR - decoBush plane not found")
    end
    local pid3 = getTerrainDataPlaneByName(tid, "decoFoliage")
    if pid3 and pid3 ~= 0 then
        local mod3 = DensityMapModifier.new(pid3, 0, 5)
        if mod3 then
            mod3:setParallelogramWorldCoords(tx+4, tz, tx+5, tz, tx+4, tz+1, DensityCoordType.POINT_POINT_POINT)
            local res = mod3:executeSet(1)
            print("SW Flora DIAG: decoFoliage  nc=5 state=1(wildflowers) result=" .. tostring(res))
        end
    else
        print("SW Flora DIAG: ERROR - decoFoliage plane not found")
    end
    print("SW Flora DIAG: --- Done. 3 test plants placed at selected node (if results != nil) ---")
    tool.lblStatus:setText("Diagnostic done - check GE console.")
end
local function buildUI()
    local frameRow = UIRowLayoutSizer.new()
    tool.window = UIWindow.new(frameRow, "SW British Flora Scanner v" .. SW_VERSION)
    local outerPanel = UIRowLayoutSizer.new()
    UIPanel.new(frameRow, outerPanel)
    local col = UIRowLayoutSizer.new()
    UIPanel.new(outerPanel, col, -1, -1, 400, -1, BorderDirection.ALL, 10, 1)
    local hdr1 = UILabel.new(col, "STEP 1 - Sample Target Texture", false,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    hdr1:setBold(true)
    UIHorizontalLine.new(col, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    UILabel.new(col, "Place a node on the texture to target. All grass surfaces share the same",
        false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.NONE, 0)
    UILabel.new(col, "RGBA - use 'Scan Here' with the right preset to paint specific zones.",
        false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    local sampleRow = UIGridSizer.new(1, 2, 6, 0)
    UIPanel.new(col, sampleRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    UIButton.new(sampleRow, "Sample Texture Here",  function() onSampleTexture()  end, -1, -1, -1, -1)
    UIButton.new(sampleRow, "Check This Location",  function() onCheckLocation()  end, -1, -1, -1, -1)
    tool.lblSample = UILabel.new(col, "Sampled: not yet sampled",
        false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    tool.lblCheck = UILabel.new(col, "Check result will appear here.",
        false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    local tolRow = UIGridSizer.new(1, 4, 4, 0)
    UIPanel.new(col, tolRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    UILabel.new(tolRow, "Match Tolerance:", false, TextAlignment.LEFT, VerticalAlignment.TOP, 170, -1)
    UIButton.new(tolRow, " - ", function()
        tool.tolerance = math.max(0.005, tool.tolerance - 0.005)
        tool.lblTolVal:setText(string.format("%.3f", tool.tolerance))
    end, -1, -1, 40, -1)
    tool.lblTolVal = UILabel.new(tolRow, string.format("%.3f", tool.tolerance),
        false, TextAlignment.CENTER, VerticalAlignment.TOP, 55, -1)
    UIButton.new(tolRow, " + ", function()
        tool.tolerance = math.min(0.08, tool.tolerance + 0.005)
        tool.lblTolVal:setText(string.format("%.3f", tool.tolerance))
    end, -1, -1, 40, -1)
    UIHorizontalLine.new(col, -1, -1, -1, -1, BorderDirection.BOTTOM, 6)
    local hdr2 = UILabel.new(col, "STEP 2 - Choose British Flora Preset", false,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    hdr2:setBold(true)
    UIHorizontalLine.new(col, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    local presetRow = UIGridSizer.new(1, 3, 4, 0)
    UIPanel.new(col, presetRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    UIButton.new(presetRow, "  <  ", function() onPresetPrev() end, -1, -1, 40, -1)
    tool.lblPreset = UILabel.new(presetRow,
        string.format("[1/%d] %s", #PRESETS, PRESETS[1].name),
        false, TextAlignment.CENTER, VerticalAlignment.TOP, 280, -1)
    UIButton.new(presetRow, "  >  ", function() onPresetNext() end, -1, -1, 40, -1)
    tool.lblDesc = UILabel.new(col, PRESETS[1].desc,
        false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 6)
    UIHorizontalLine.new(col, -1, -1, -1, -1, BorderDirection.BOTTOM, 6)
    local hdr3 = UILabel.new(col, "STEP 3 - Configure & Scan", false,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    hdr3:setBold(true)
    UIHorizontalLine.new(col, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    local densRow = UIGridSizer.new(1, 4, 4, 0)
    UIPanel.new(col, densRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    UILabel.new(densRow, "Density (plant chance):", false, TextAlignment.LEFT, VerticalAlignment.TOP, 170, -1)
    UIButton.new(densRow, " - ", function()
        tool.density = math.max(0.05, tool.density - 0.05)
        tool.lblDensVal:setText(string.format("%.2f", tool.density))
    end, -1, -1, 40, -1)
    tool.lblDensVal = UILabel.new(densRow, string.format("%.2f", tool.density),
        false, TextAlignment.CENTER, VerticalAlignment.TOP, 55, -1)
    UIButton.new(densRow, " + ", function()
        tool.density = math.min(1.0, tool.density + 0.05)
        tool.lblDensVal:setText(string.format("%.2f", tool.density))
    end, -1, -1, 40, -1)
    local spaceRow = UIGridSizer.new(1, 4, 4, 0)
    UIPanel.new(col, spaceRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    UILabel.new(spaceRow, "Spacing (metres):", false, TextAlignment.LEFT, VerticalAlignment.TOP, 170, -1)
    UIButton.new(spaceRow, " - ", function()
        tool.spacing = math.max(0.5, tool.spacing - 0.25)
        tool.lblSpaceVal:setText(string.format("%.2f", tool.spacing))
    end, -1, -1, 40, -1)
    tool.lblSpaceVal = UILabel.new(spaceRow, string.format("%.2f", tool.spacing),
        false, TextAlignment.CENTER, VerticalAlignment.TOP, 55, -1)
    UIButton.new(spaceRow, " + ", function()
        tool.spacing = math.min(4.0, tool.spacing + 0.25)
        tool.lblSpaceVal:setText(string.format("%.2f", tool.spacing))
    end, -1, -1, 40, -1)
    local radRow = UIGridSizer.new(1, 4, 4, 0)
    UIPanel.new(col, radRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 6)
    UILabel.new(radRow, "Scan Here radius (m):", false, TextAlignment.LEFT, VerticalAlignment.TOP, 170, -1)
    UIButton.new(radRow, " - ", function()
        tool.scanRadius = math.max(10, tool.scanRadius - 10)
        tool.lblRadVal:setText(string.format("%d", tool.scanRadius))
    end, -1, -1, 40, -1)
    tool.lblRadVal = UILabel.new(radRow, string.format("%d", tool.scanRadius),
        false, TextAlignment.CENTER, VerticalAlignment.TOP, 55, -1)
    UIButton.new(radRow, " + ", function()
        tool.scanRadius = math.min(500, tool.scanRadius + 10)
        tool.lblRadVal:setText(string.format("%d", tool.scanRadius))
    end, -1, -1, 40, -1)
    UIHorizontalLine.new(col, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    tool.lblPartition = UILabel.new(col, "Partition: 1 / 64",
        false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    local scanRow = UIGridSizer.new(1, 2, 6, 0)
    UIPanel.new(col, scanRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    UIButton.new(scanRow, "Scan Next Partition", function() onScanNext() end, -1, -1, -1, -1)
    UIButton.new(scanRow, "Scan ALL 64",         function() onScanAll()  end, -1, -1, -1, -1)
    UIButton.new(col, "Scan Here  (paint selected zone with current preset + radius)",
        function() onScanHere() end, -1, -1, -1, 28)
    UIHorizontalLine.new(col, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    local utilRow = UIGridSizer.new(1, 3, 6, 0)
    UIPanel.new(col, utilRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 6)
    UIButton.new(utilRow, "Reset Counter", function() onResetScan()  end, -1, -1, -1, -1)
    UIButton.new(utilRow, "Clear Here",    function() onClearHere()  end, -1, -1, -1, -1)
    UIButton.new(utilRow, "Diagnostic",    function() onDiagnostic() end, -1, -1, -1, -1)
    UIHorizontalLine.new(col, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    local hdrStatus = UILabel.new(col, "Status:", false,
        TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    hdrStatus:setBold(true)
    tool.lblStatus = UILabel.new(col, "Ready.",
        false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    tool.window:showWindow()
end
if g_sw_flora_scanner ~= nil then
    g_sw_flora_scanner = nil
end
tool.terrainId = findTerrainNode()
if tool.terrainId == nil or tool.terrainId == 0 then
    printError("SW British Flora Scanner: Could not find terrain node. Open a map first.")
    return
end
print(string.format("SW British Flora Scanner v%s loaded. Terrain ID: %s", SW_VERSION, tostring(tool.terrainId)))
print(string.format("  %d presets available. %d hard exclusions active.", #PRESETS, #EXCLUSIONS))
print("  TIP: All grass surfaces share the same RGBA. Use 'Scan Here' to paint specific zones.")
buildUI()
g_sw_flora_scanner = tool
