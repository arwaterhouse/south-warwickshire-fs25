-- Author: South Warwickshire FS25 Pipeline
-- Name: SW Foliage by Material
-- Description: Paints foliage based on which terrain MATERIAL LAYER is painted
--              at each point — works like GE's "Restrict to Materials" tool.
--
--              Instead of sampling RGBA colours, this script reads the terrain
--              layer names directly from the map's i3d file, lists them in the
--              UI, and lets you assign a foliage preset to each one.
--
--              At each scan point it checks the material layer's density map
--              value — if the material is present (value > 0) it paints the
--              assigned foliage mix. Materials marked EXCLUDE are used to
--              block painting (fields, roads, farmland, etc.).
--
-- Workflow:
--   1. Script loads — it scans the i3d and lists all terrain layer names.
--   2. Use "Prev Layer / Next Layer" buttons on each slot to pick a material.
--   3. Use "Next Preset" to assign a foliage mix per material.
--   4. Mark field/road/farmland materials as EXCLUDE to block foliage there.
--   5. Click "Paint Next Partition" (64 clicks = full 4× map).
--
-- British foliage presets (South Warwickshire):
--   WOODLAND FLOOR  → ForestGrass, bracken fern, clover (bluebell sub), DryBranch
--   GRASS & MEADOW  → GrassDenseMix (cow parsley), GrassMedium, Meadow
--   HEDGEROW SCRUB  → hazelnut (dominant), boxwood (blackthorn/hawthorn sub)
--   FIELD MARGIN    → GrassSmall, Clover (very sparse — thin strip only)
--   NONE            → skip this slot / do not paint
--
-- Hide: no
-- AlwaysLoaded: no

source("editorUtils.lua")

-- ── Foliage presets (British / South Warwickshire) ────────────────────────────

local PRESET_NAMES = {
    "WOODLAND FLOOR",
    "GRASS & MEADOW",
    "HEDGEROW SCRUB",
    "FIELD MARGIN",
    "NONE",
}

local PRESET_LAYERS = {
    -- [1] WOODLAND FLOOR  — Warwickshire oak/ash woodland understory
    --   SwordFern = bracken (dominant in SW Warks), DeerFern = damp shade fern,
    --   Clover = bluebell carpet substitute, DryBranch = leaf litter / deadwood,
    --   StarFlower = wood anemone / herb robert / wild garlic equivalent,
    --   hazelnutSmall = hazel seedling layer (defining tree of Warks woodland)
    { {ft="forestPlants", ch=9,  nc=5},  -- ForestGrass      (×4)
      {ft="forestPlants", ch=9,  nc=5},
      {ft="forestPlants", ch=9,  nc=5},
      {ft="forestPlants", ch=9,  nc=5},
      {ft="forestPlants", ch=7,  nc=5},  -- SwordFern/bracken (×3)
      {ft="forestPlants", ch=7,  nc=5},
      {ft="forestPlants", ch=7,  nc=5},
      {ft="forestPlants", ch=8,  nc=5},  -- DeerFern          (×2)
      {ft="forestPlants", ch=8,  nc=5},
      {ft="forestPlants", ch=2,  nc=5},  -- Clover/bluebell   (×3)
      {ft="forestPlants", ch=2,  nc=5},
      {ft="forestPlants", ch=2,  nc=5},
      {ft="forestPlants", ch=1,  nc=5},  -- DryBranch/leaf litter (×2)
      {ft="forestPlants", ch=1,  nc=5},
      {ft="forestPlants", ch=3,  nc=5},  -- StarFlower/wood anemone
      {ft="decoBush",     ch=13, nc=4},  -- hazelnutSmall seedling
    },

    -- [2] GRASS & MEADOW  — British pasture / road verge
    --   GrassDenseMix = tall rank grass + cow parsley / hogweed visual
    --   GrassMedium   = standard meadow grass
    --   Meadow        = wildflowers (buttercup, daisy, clover heads)
    --   GrassSmall    = fine fescue (slightly maintained feel)
    { {ft="decoFoliage", ch=1,  nc=5},  -- GrassDenseMix/cow parsley (×3)
      {ft="decoFoliage", ch=1,  nc=5},
      {ft="decoFoliage", ch=1,  nc=5},
      {ft="decoFoliage", ch=10, nc=5},  -- GrassMedium        (×3)
      {ft="decoFoliage", ch=10, nc=5},
      {ft="decoFoliage", ch=10, nc=5},
      {ft="meadow",      ch=2,  nc=5},  -- Meadow wildflowers (×2)
      {ft="meadow",      ch=2,  nc=5},
      {ft="decoFoliage", ch=9,  nc=5},  -- GrassSmall/fescue
    },

    -- [3] HEDGEROW SCRUB  — Warwickshire hedgerow species
    --   Hazel (Corylus avellana) dominant — THE defining hedgerow shrub of SW Warks.
    --   boxwoodSmall/Med stand in for hawthorn, blackthorn, elder, dog rose.
    --   blueberrySmall = low thorny layer (dog rose, bramble equivalent).
    { {ft="decoBush",    ch=13, nc=4},  -- hazelnutSmall    (×4 — dominant)
      {ft="decoBush",    ch=13, nc=4},
      {ft="decoBush",    ch=13, nc=4},
      {ft="decoBush",    ch=13, nc=4},
      {ft="decoBush",    ch=14, nc=4},  -- hazelnutMedium   (×2)
      {ft="decoBush",    ch=14, nc=4},
      {ft="decoBush",    ch=15, nc=4},  -- hazelnutBig
      {ft="decoBush",    ch=10, nc=4},  -- boxwoodSmall     (blackthorn/hawthorn)
      {ft="decoBush",    ch=11, nc=4},  -- boxwoodMedium    (elder)
      {ft="decoBush",    ch=6,  nc=4},  -- blueberrySmall   (dog rose/bramble)
    },

    -- [4] FIELD MARGIN  — sparse thin strip at field edge, very light touch
    --   GrassSmall dominant (fine fescue/rye grass), occasional clover.
    --   Intentionally very sparse — Warwickshire field margins are narrow.
    { {ft="decoFoliage",  ch=9,  nc=5}, -- GrassSmall    (×5 — dominant)
      {ft="decoFoliage",  ch=9,  nc=5},
      {ft="decoFoliage",  ch=9,  nc=5},
      {ft="decoFoliage",  ch=9,  nc=5},
      {ft="decoFoliage",  ch=9,  nc=5},
      {ft="decoFoliage",  ch=10, nc=5}, -- GrassMedium   (×2)
      {ft="decoFoliage",  ch=10, nc=5},
      {ft="forestPlants", ch=2,  nc=5}, -- Clover        (white clover)
      {ft="meadow",       ch=2,  nc=5}, -- Meadow        (occasional wildflower)
    },

    -- [5] NONE — slot is unused, no foliage painted
    {},
}

-- ── Terrain layer discovery ───────────────────────────────────────────────────
-- GE terrain paint layers can be named two ways depending on the map:
--   camelCase:   "forestLeaves01"  (shown in i3d XML)
--   UPPER_SNAKE: "FOREST_LEAVES"   (shown in GE paint UI / plane lookup)
--
-- getTerrainDataPlaneByName() uses whichever format the map's terrain actually
-- registered. So we:
--   1. Collect candidate names from the i3d XML (multiple XML paths)
--   2. Generate name variants for each (camelCase, UPPER_SNAKE, stripped suffix)
--   3. Probe each variant against the terrain — keep only the ones that work
--   4. Also probe a broad hardcoded list covering both formats
-- Only verified names appear in the UI.

-- Convert camelCase to UPPER_SNAKE: "forestLeaves01" → "FOREST_LEAVES"
local function camelToUpperSnake(s)
    s = s:gsub("%d+$", "")                 -- strip trailing digits
    s = s:gsub("(%l)(%u)", "%1_%2")        -- insert _ before each uppercase
    return s:upper()
end

-- Generate all plausible name variants for a raw layer name
local function nameVariants(raw)
    local seen = {}
    local out  = {}
    local function add(n)
        if n and #n > 0 and not seen[n] then
            seen[n] = true
            table.insert(out, n)
        end
    end
    add(raw)
    add(raw:lower())
    add(raw:upper())
    add(camelToUpperSnake(raw))
    -- strip trailing digits variant
    local stripped = raw:gsub("%d+$", "")
    add(stripped)
    add(stripped:upper())
    add(camelToUpperSnake(stripped))
    return out
end

-- Probe whether a name resolves to a real terrain data plane
local function probeLayerName(terrainId, name)
    if not name or #name == 0 then return false end
    local ok, id = pcall(getTerrainDataPlaneByName, terrainId, name)
    return ok and id ~= nil and id ~= 0
end

local function discoverTerrainLayers(terrainId)
    -- Step 1: collect raw names from i3d XML (multiple paths)
    local rawNames = {}
    local seen     = {}
    local function addRaw(n)
        if n and #n > 0 and not seen[n] then seen[n]=true; table.insert(rawNames, n) end
    end

    local fileName = getSceneFilename()
    if fileName and #fileName > 0 then
        local xmlFile = loadXMLFile("map.i3d.mat", fileName)
        if xmlFile then
            local paths = {
                "i3D.Scene.TerrainTransformGroup.Layers.Layer(%d)#name",
                "i3D.Scene.TerrainTransformGroup.Layers.DetailLayer(%d)#name",
                "i3D.Scene.TerrainTransformGroup.Layers.PaintedLayer(%d)#name",
                "i3D.Scene.TerrainTransformGroup.Layers.TerrainLayer(%d)#name",
            }
            for _, path in ipairs(paths) do
                local idx = 0
                while true do
                    local n = getXMLString(xmlFile, string.format(path, idx))
                    if n == nil then break end
                    addRaw(n)
                    idx = idx + 1
                end
            end
            delete(xmlFile)
        end
    end

    -- Step 2: broad hardcoded candidate list covering both naming conventions
    local hardcoded = {
        -- camelCase format
        "grass01","grassClovers01","grassDry01","grassLong01",
        "forestFloor01","forestGrass01","forestLeaves01","forestBrush01",
        "dirt01","dirtGravel01","gravelCoarse01","gravelFine01",
        "cultivatedDirt01","fieldGround01","stubble01","cropResidue01",
        "asphalt01","concrete01","gravelRoad01","cobblestone01",
        "sand01","mud01","rock01","rockMoss01",
        "hedgerow01","scrub01","bramble01","bush01",
        "water01","riverBed01",
        -- UPPER_SNAKE format (GE paint UI names)
        "GRASS","GRASS_CLOVERS","GRASS_DRY","GRASS_LONG",
        "FOREST_FLOOR","FOREST_GRASS","FOREST_LEAVES","FOREST_BRUSH",
        "DIRT","DIRT_GRAVEL","GRAVEL_COARSE","GRAVEL_FINE",
        "CULTIVATED_DIRT","FIELD_GROUND","STUBBLE","CROP_RESIDUE",
        "ASPHALT","CONCRETE","GRAVEL_ROAD","COBBLESTONE",
        "SAND","MUD","ROCK","ROCK_MOSS",
        "HEDGEROW","SCRUB","BRAMBLE","BUSH",
    }
    for _, n in ipairs(hardcoded) do addRaw(n) end

    -- Step 3: probe every raw name + its variants, keep working ones
    local verified = {}
    local vSeen    = {}

    if terrainId == nil then
        -- Can't probe without terrain — return raw names as best guess
        print("[SW Foliage Mat] WARNING: terrain not found at startup — cannot verify layer names.")
        for _, n in ipairs(rawNames) do
            if not vSeen[n] then vSeen[n]=true; table.insert(verified, n) end
        end
    else
        print("[SW Foliage Mat] Probing terrain layers...")
        for _, raw in ipairs(rawNames) do
            for _, variant in ipairs(nameVariants(raw)) do
                if not vSeen[variant] then
                    if probeLayerName(terrainId, variant) then
                        vSeen[variant] = true
                        table.insert(verified, variant)
                        print(string.format("  ✓ '%s'", variant))
                    end
                end
            end
        end
    end

    if #verified == 0 then
        print("[SW Foliage Mat] WARNING: no terrain paint layers resolved.")
        print("  Try clicking 'Probe Layers' after the map is fully loaded.")
        verified = rawNames  -- show raw names as fallback
    end

    table.insert(verified, 1, "— select a layer —")
    return verified
end

-- Terrain ref needed for probing — get it once now
local function getTerrainId()
    local scene = getRootNode()
    for i = 0, getNumOfChildren(scene) - 1 do
        local child = getChildAt(scene, i)
        if getName(child) == "terrain" then return child end
    end
    return nil
end

local TERRAIN_LAYERS = discoverTerrainLayers(getTerrainId())

print(string.format("[SW Foliage Mat] %d verified terrain layers available:",
    #TERRAIN_LAYERS - 1))
for i = 2, #TERRAIN_LAYERS do
    print(string.format("  [%d] %s", i-1, TERRAIN_LAYERS[i]))
end

-- ── Slot state ────────────────────────────────────────────────────────────────
-- Each slot targets one terrain material layer and paints one foliage preset.
-- Slots marked 'exclude' suppress painting (field/road/farmland/residential).

local NUM_SLOTS = 8   -- 6 paint + 2 dedicated exclude (shown differently in UI)
local slots = {}
for i = 1, NUM_SLOTS do
    slots[i] = {
        layerIdx = 1,          -- index into TERRAIN_LAYERS (1 = "— select —")
        preset   = 5,          -- index into PRESET_NAMES (5 = NONE)
        exclude  = false,      -- if true, BLOCK foliage where this material is
        layerLabel  = nil,     -- UI label refs (set after UI built)
        presetLabel = nil,
        exLabel     = nil,
    }
end

-- Convenience: default last 2 slots as exclude
slots[7].exclude = true
slots[8].exclude = true

-- ── Scan settings ─────────────────────────────────────────────────────────────

local scanSpacing = 2.0    -- metres between scan points
local scanDensity = 0.70   -- base paint probability per matched point
local brushM      = 1.2    -- brush footprint (metres)
local matThreshold = 0     -- material weight threshold (> this = present)
                           -- 0 = any non-zero coverage counts

local TOTAL_PARTITIONS = 64

-- ── Plane helpers ─────────────────────────────────────────────────────────────

local _planeCache = {}
local _planeDiag  = {}

local function getPlaneId(terrainId, name)
    if _planeCache[name] == nil then
        local id = getTerrainDataPlaneByName(terrainId, name)
        _planeCache[name] = (id ~= nil and id ~= 0) and id or 0
        if _planeCache[name] == 0 then
            print(string.format("[SW Foliage Mat] WARNING: plane '%s' not found on this terrain", name))
        else
            print(string.format("[SW Foliage Mat] Plane '%s' → id=%s", name, tostring(_planeCache[name])))
        end
    end
    return _planeCache[name]
end

-- ── Material presence check ───────────────────────────────────────────────────
-- Uses DensityMapModifier + DensityMapFilter to check whether a terrain material
-- layer has any coverage at the given world position.
-- Returns true if the material is painted there (value > matThreshold).

local MAT_NC = 8   -- terrain paint layers are typically 8-bit weight maps

local function isMaterialPresent(terrainId, matLayerName, wx, wz, halfEps)
    local planeId = getPlaneId(terrainId, matLayerName)
    if planeId == 0 then return false end

    local diagKey = "mat:"..matLayerName
    if not _planeDiag[diagKey] then
        _planeDiag[diagKey] = true
        print(string.format("[SW Foliage Mat] DIAG mat='%s' planeId=%s nc=%d threshold>%d",
            matLayerName, tostring(planeId), MAT_NC, matThreshold))
    end

    local mod = DensityMapModifier.new(planeId, 0, MAT_NC)
    mod:setParallelogramWorldCoords(
        wx - halfEps, wz - halfEps,
        wx + halfEps, wz - halfEps,
        wx - halfEps, wz + halfEps,
        DensityCoordType.POINT_POINT_POINT)

    local filter = DensityMapFilter.new(planeId, 0, MAT_NC)
    filter:setValueCompareParams(DensityValueCompareType.GREATER, matThreshold)

    local numCells, totalCount, coverCount = mod:executeGet(filter)
    return (coverCount ~= nil and coverCount > 0)
end

-- ── Foliage paint ─────────────────────────────────────────────────────────────

local function paintFoliageAt(terrainId, wx, wz, layerEntries, brushHalf)
    local entry = layerEntries[math.random(1, #layerEntries)]
    local pid   = getPlaneId(terrainId, entry.ft)
    if pid == 0 then return false end

    local fDiag = entry.ft..":"..entry.nc..":"..entry.ch
    if not _planeDiag[fDiag] then
        _planeDiag[fDiag] = true
        local maxV = (2^entry.nc)-1
        print(string.format("[SW Foliage Mat] DIAG fol='%s' nc=%d ch=%d maxAllowed=%d ok=%s",
            entry.ft, entry.nc, entry.ch, maxV, tostring(entry.ch>=0 and entry.ch<=maxV)))
    end

    local mod = DensityMapModifier.new(pid, 0, entry.nc)
    mod:setParallelogramWorldCoords(
        wx - brushHalf, wz - brushHalf,
        wx + brushHalf, wz - brushHalf,
        wx - brushHalf, wz + brushHalf,
        DensityCoordType.POINT_POINT_POINT)
    mod:executeSet(entry.ch)
    return true
end

-- ── Partition scan ────────────────────────────────────────────────────────────

local nextPartition  = 1
local sessionPainted = 0
local sessionSkipped = 0
local partitionLabel = nil

local function updatePartLabel()
    if partitionLabel then
        if nextPartition > TOTAL_PARTITIONS then
            partitionLabel:setValue(string.format(
                "Done! All %d partitions  |  %d painted  |  %d excluded",
                TOTAL_PARTITIONS, sessionPainted, sessionSkipped))
        else
            partitionLabel:setValue(string.format(
                "Next: partition %d / %d  |  painted=%d  excluded=%d",
                nextPartition, TOTAL_PARTITIONS, sessionPainted, sessionSkipped))
        end
    end
end

local function resetPartitions()
    nextPartition=1; sessionPainted=0; sessionSkipped=0
    _planeCache={}; _planeDiag={}
    print("[SW Foliage Mat] Reset — partition counter back to 1.")
    updatePartLabel()
end

local function runNextPartition()
    if nextPartition > TOTAL_PARTITIONS then
        print("[SW Foliage Mat] All partitions done. Click Reset to start over.")
        return
    end

    -- Check at least one active paint slot
    local hasActive = false
    for i=1,NUM_SLOTS do
        local s = slots[i]
        if s.layerIdx > 1 and not s.exclude and s.preset < 5 then
            hasActive = true; break
        end
    end
    if not hasActive then
        print("[SW Foliage Mat] ERROR: No paint slots configured.")
        print("  Assign a layer AND a foliage preset (not NONE) to at least one slot.")
        return
    end

    local terrainId = getTerrainId()
    if terrainId == nil then print("[SW Foliage Mat] ERROR: terrain not found"); return end

    local p           = nextPartition
    local terrainSize = getTerrainSize(terrainId)
    local halfSize    = terrainSize / 2
    local numSec      = math.sqrt(TOTAL_PARTITIONS)   -- 8
    local secSize     = terrainSize / numSec
    local brushHalf   = brushM * 0.5
    local matEps      = scanSpacing * 0.5  -- half-size of material query box

    local col    = ((p-1) % numSec)
    local row    = math.floor((p-1) / numSec)
    local xStart = -halfSize + col * secSize
    local zStart = -halfSize + row * secSize
    local xEnd   = xStart + secSize
    local zEnd   = zStart + secSize

    -- Natural density variation per partition (40-100% of base)
    math.randomseed(p * 7919)
    local densityMult  = 0.4 + math.random() * 0.6
    local effectiveDen = scanDensity * densityMult
    local brushScale   = 0.8 + math.random() * 0.6
    local effectiveBH  = brushHalf * brushScale
    math.randomseed(p * 31337)

    local painted = 0
    local skipped = 0

    local x = xStart
    while x <= xEnd do
        local z = zStart
        while z <= zEnd do

            if math.random() <= effectiveDen then
                -- 1. Check EXCLUDE slots first — if any exclude material is here, skip
                local excluded = false
                for i=1,NUM_SLOTS do
                    local s = slots[i]
                    if s.exclude and s.layerIdx > 1 then
                        local matName = TERRAIN_LAYERS[s.layerIdx]
                        if isMaterialPresent(terrainId, matName, x, z, matEps) then
                            excluded = true
                            skipped  = skipped + 1
                            break
                        end
                    end
                end

                if not excluded then
                    -- 2. Check each PAINT slot — first matching slot wins
                    for i=1,NUM_SLOTS do
                        local s = slots[i]
                        if not s.exclude and s.layerIdx > 1 and s.preset < 5 then
                            local matName = TERRAIN_LAYERS[s.layerIdx]
                            if isMaterialPresent(terrainId, matName, x, z, matEps) then
                                -- Add position jitter so scan grid doesn't show through
                                local jx = x + (math.random()-0.5)*scanSpacing*0.8
                                local jz = z + (math.random()-0.5)*scanSpacing*0.8
                                if paintFoliageAt(terrainId, jx, jz,
                                        PRESET_LAYERS[s.preset], effectiveBH) then
                                    painted = painted + 1
                                end
                                break  -- only paint once per scan point
                            end
                        end
                    end
                end
            end

            z = z + scanSpacing
        end
        x = x + scanSpacing
    end

    sessionPainted = sessionPainted + painted
    sessionSkipped = sessionSkipped + skipped

    print(string.format(
        "[SW Foliage Mat] Partition %d/%d  density=%.0f%%  brush=%.2fm  → %d painted  %d excluded",
        p, TOTAL_PARTITIONS, effectiveDen*100, effectiveBH*2, painted, skipped))

    nextPartition = nextPartition + 1
    updatePartLabel()

    if nextPartition > TOTAL_PARTITIONS then
        print(string.format("[SW Foliage Mat] ✓ Complete! %d painted | %d excluded",
            sessionPainted, sessionSkipped))
    end
end

-- ── UI ────────────────────────────────────────────────────────────────────────

local frameSizer  = UIRowLayoutSizer.new()
local window      = UIWindow.new(frameSizer, "SW Foliage by Material")
local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer, -1,-1,-1,-1, BorderDirection.ALL, 6)

UILabel.new(borderSizer,
    "Assign terrain MATERIAL LAYERS → foliage presets.\n"..
    "Works like GE Restrict to Materials — paints only where that\n"..
    "layer is painted on the terrain. Mark field/road layers EXCLUDE.",
    TextAlignment.LEFT)
UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 4)

-- Slot label for PAINT vs EXCLUDE header
UILabel.new(borderSizer, "SLOTS 1-6  →  PAINT foliage", TextAlignment.LEFT)
UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)

for slotIdx=1,NUM_SLOTS do
    local si = slotIdx
    local isPaintSlot = (si <= 6)

    -- Slot header
    local hRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, hRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 1)
    if isPaintSlot then
        UILabel.new(hRow, string.format("PAINT %d", si), TextAlignment.LEFT)
    else
        UILabel.new(hRow, string.format("EXCLUDE %d", si-6), TextAlignment.LEFT)
    end

    -- Layer cycling row
    local lRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, lRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 1)

    UIButton.new(lRow, "◀", function()
        slots[si].layerIdx = ((slots[si].layerIdx - 2 + #TERRAIN_LAYERS) % #TERRAIN_LAYERS) + 1
        slots[si].layerLabel:setValue(TERRAIN_LAYERS[slots[si].layerIdx])
        print(string.format("[SW Foliage Mat] Slot %d layer → '%s'",
            si, TERRAIN_LAYERS[slots[si].layerIdx]))
    end)

    local layLbl = UITextArea.new(lRow,
        TERRAIN_LAYERS[slots[si].layerIdx],
        TextAlignment.LEFT, false, true, 180, 22, -1, 22, BorderDirection.NONE, 0, 0)
    slots[si].layerLabel = layLbl

    UIButton.new(lRow, "▶", function()
        slots[si].layerIdx = (slots[si].layerIdx % #TERRAIN_LAYERS) + 1
        slots[si].layerLabel:setValue(TERRAIN_LAYERS[slots[si].layerIdx])
        print(string.format("[SW Foliage Mat] Slot %d layer → '%s'",
            si, TERRAIN_LAYERS[slots[si].layerIdx]))
    end)

    -- Preset row (only for PAINT slots — exclude slots don't need a preset)
    if isPaintSlot then
        local pRow = UIRowLayoutSizer.new()
        UIPanel.new(borderSizer, pRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 3)

        local pLbl = UITextArea.new(pRow,
            "Preset: "..PRESET_NAMES[slots[si].preset],
            TextAlignment.LEFT, false, true, 200, 22, -1, 22, BorderDirection.NONE, 0, 0)
        slots[si].presetLabel = pLbl

        UIButton.new(pRow, "Next Preset", function()
            slots[si].preset = (slots[si].preset % #PRESET_NAMES) + 1
            slots[si].presetLabel:setValue("Preset: "..PRESET_NAMES[slots[si].preset])
            print(string.format("[SW Foliage Mat] Slot %d preset → %s",
                si, PRESET_NAMES[slots[si].preset]))
        end)
    else
        -- Exclude slot: just a note label
        local eRow = UIRowLayoutSizer.new()
        UIPanel.new(borderSizer, eRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 3)
        UILabel.new(eRow, "  → foliage BLOCKED where this material is painted", TextAlignment.LEFT)
    end

    UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)

    -- Header between paint and exclude slots
    if si == 6 then
        UILabel.new(borderSizer, "SLOTS 7-8  →  EXCLUDE (no foliage painted here)", TextAlignment.LEFT)
        UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
    end
end

-- Re-probe button — rescans the terrain for valid layer names after map load
local probeRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, probeRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)

-- Layer list label (updates after re-probe)
local layerListLabel = UITextArea.new(probeRow,
    string.format("%d layers verified — see log", #TERRAIN_LAYERS - 1),
    TextAlignment.LEFT, false, true, 220, 22, -1, 22, BorderDirection.NONE, 0, 0)

UIButton.new(probeRow, "Re-probe Layers", function()
    local tid = getTerrainId()
    local newLayers = discoverTerrainLayers(tid)
    -- Rebuild TERRAIN_LAYERS in-place
    while #TERRAIN_LAYERS > 0 do table.remove(TERRAIN_LAYERS) end
    for _, v in ipairs(newLayers) do table.insert(TERRAIN_LAYERS, v) end
    -- Reset all slot indices to sentinel
    for i=1,NUM_SLOTS do
        slots[i].layerIdx = 1
        if slots[i].layerLabel then
            slots[i].layerLabel:setValue(TERRAIN_LAYERS[1])
        end
    end
    layerListLabel:setValue(string.format("%d layers verified — see log", #TERRAIN_LAYERS - 1))
    print(string.format("[SW Foliage Mat] Re-probed: %d valid layers", #TERRAIN_LAYERS - 1))
end)

UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 3)

-- Progress + controls
local progRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, progRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
partitionLabel = UITextArea.new(progRow,
    "Next: partition 1/64  |  painted=0  excluded=0",
    TextAlignment.LEFT, false,true,-1,22,-1,22, BorderDirection.NONE,0,0)

local runRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, runRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
UIButton.new(runRow, "Paint Next Partition", runNextPartition)

local rstRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, rstRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
UIButton.new(rstRow, "Reset (start over)", resetPartitions)

window:showWindow()

print("\n[SW Foliage by Material] Ready.")
print("How to use:")
print("  PAINT slots 1-6: pick a terrain layer with ◀ ▶, assign a foliage preset.")
print("  EXCLUDE slots 7-8: pick field/road/farmland layers — foliage is blocked there.")
print("  Then click 'Paint Next Partition' up to 64 times for the whole map.")
print("")
print("Suggested SW Warwickshire slot setup:")
print("  Slot 1 → forestFloor01 / forestGrass01   → WOODLAND FLOOR")
print("  Slot 2 → grass01 / grassClovers01         → GRASS & MEADOW")
print("  Slot 3 → hedgerow01 / scrub01             → HEDGEROW SCRUB")
print("  Slot 4 → grassDirt01 (roadside verge)     → GRASS & MEADOW")
print("  Slot 5 → grassDry01 (field margin)        → FIELD MARGIN")
print("  Slot 6 → (optional extra)")
print("  Slot 7 (EXCLUDE) → cultivatedDirt01       → blocks fields")
print("  Slot 8 (EXCLUDE) → asphalt01 / concrete01 → blocks roads")
print("")
print("Detected terrain layers:")
for i=2, #TERRAIN_LAYERS do
    print(string.format("  %s", TERRAIN_LAYERS[i]))
end
