-- Author: South Warwickshire FS25 Pipeline
-- Name: SW Foliage by Texture v2
-- Description: Paints ground-level foliage across the map based on terrain
--              texture type. Foliage is BLOCKED on any point matching the
--              exclusion textures (fields, roads, farmland, residential).
--              Density variation creates a natural, non-uniform look.
--
-- EXCLUSION SYSTEM (6 labelled slots):
--   SLOT 1  CULTIVATED FIELD   — ploughed / tilled bare earth
--   SLOT 2  ROAD / TARMAC      — asphalt, gravel road surfaces
--   SLOT 3  FARMLAND / STUBBLE — harvested crop stubble
--   SLOT 4  RESIDENTIAL        — garden/lawn/paving near buildings
--   SLOT 5  SPARE A            — any other texture to block
--   SLOT 6  SPARE B            — any other texture to block
--
--   Each exclusion slot has its own tolerance. Road tarmac can use a wider
--   tolerance (it's a very distinct colour), cultivated dirt a narrower one.
--
-- NATURAL VARIATION:
--   Each 8×8 section partition uses a seeded random density multiplier
--   (0.4–1.0) so foliage is patchier in some areas and denser in others —
--   avoiding the uniform carpet look.
--
-- PAINT SLOTS (4):
--   Sample any terrain texture and assign a British foliage preset to paint
--   wherever that texture is dominant.
--
-- BRITISH PRESETS (South Warwickshire tuned):
--   WOODLAND FLOOR  → ForestGrass/Fern(bracken)/Clover(bluebell sub)/DryBranch
--   GRASS & MEADOW  → GrassDenseMix(cow parsley)/GrassMedium/Meadow
--   HEDGEROW SCRUB  → hazelnut dominant (×4), boxwood for hawthorn/blackthorn
--   FIELD MARGIN    → GrassSmall/Clover (very sparse — thin edge strip only)
--
-- Workflow:
--   1. Paint slots: place a transform ON a target texture, click "Sample".
--   2. Exclusion: place transforms on field/road/farmland/residential textures,
--      click the matching "Sample EXCLUDE" button.
--   3. Click "Paint Next Partition" up to 64 times for the full map.
--
-- Hide: no
-- AlwaysLoaded: no

source("editorUtils.lua")

-- ── Foliage presets (British / SW tuned) ─────────────────────────────────────

local PRESET_NAMES = {
    "WOODLAND FLOOR",
    "GRASS & MEADOW",
    "HEDGEROW SCRUB",
    "FIELD MARGIN",
}

local PRESET_LAYERS = {
    -- [1] WOODLAND FLOOR  – Warwickshire oak/ash woodland understory
    --   ForestGrass = constant ground cover
    --   SwordFern   = bracken equivalent (dominant in SW Warwickshire)
    --   DeerFern    = damp-shade fern (stream sides, N-facing slopes)
    --   Clover      = bluebell-carpet substitute (closest visual)
    --   DryBranch   = leaf litter / fallen deadwood
    --   StarFlower  = wood anemone / herb robert / wild garlic equiv
    --   hazelnutSmall = hazel seedling layer (very common in Warks woodland)
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
      {ft="decoBush",    ch=13, nc=4},   -- hazelnutSmall seedling
    },

    -- [2] GRASS & MEADOW  – British pasture and road-adjacent grassland
    --   GrassDenseMix = tall rank grass + cow parsley / hogweed visual
    --   GrassMedium   = standard meadow grass
    --   Meadow        = wildflowers (buttercup, daisy, clover)
    --   GrassSmall    = fine fescue (more maintained areas)
    { {ft="decoFoliage", ch=1,  nc=5},  -- GrassDenseMix/cow parsley (×3)
      {ft="decoFoliage", ch=1,  nc=5},
      {ft="decoFoliage", ch=1,  nc=5},
      {ft="decoFoliage", ch=10, nc=5},  -- GrassMedium        (×3)
      {ft="decoFoliage", ch=10, nc=5},
      {ft="decoFoliage", ch=10, nc=5},
      {ft="meadow",      ch=2,  nc=5},  -- Meadow wildflowers (×2)
      {ft="meadow",      ch=2,  nc=5},
      {ft="decoFoliage", ch=9,  nc=5},  -- GrassSmall (fine fescue)
    },

    -- [3] HEDGEROW SCRUB  – Warwickshire hedgerow species
    --   Hazel (Corylus avellana) is the defining hedgerow shrub of SW Warks.
    --   boxwoodSmall/Med = hawthorn / blackthorn / elder / dog rose substitute.
    --   blueberrySmall   = low spiny-stem layer (dog rose, bramble equiv).
    { {ft="decoBush",    ch=13, nc=4},  -- hazelnutSmall    (×4)
      {ft="decoBush",    ch=13, nc=4},
      {ft="decoBush",    ch=13, nc=4},
      {ft="decoBush",    ch=13, nc=4},
      {ft="decoBush",    ch=14, nc=4},  -- hazelnutMedium   (×2)
      {ft="decoBush",    ch=14, nc=4},
      {ft="decoBush",    ch=15, nc=4},  -- hazelnutBig
      {ft="decoBush",    ch=10, nc=4},  -- boxwoodSmall     (blackthorn/hawthorn)
      {ft="decoBush",    ch=11, nc=4},  -- boxwoodMedium    (elder/hawthorn)
      {ft="decoBush",    ch=6,  nc=4},  -- blueberrySmall   (dog rose low layer)
    },

    -- [4] FIELD MARGIN  – very sparse thin strip at field edges
    --   Short fescue grass dominant. Occasional clover and meadow flower.
    --   Intentionally light — field edges in Warwickshire aren't usually thick.
    { {ft="decoFoliage",  ch=9,  nc=5}, -- GrassSmall    (×5 — dominant)
      {ft="decoFoliage",  ch=9,  nc=5},
      {ft="decoFoliage",  ch=9,  nc=5},
      {ft="decoFoliage",  ch=9,  nc=5},
      {ft="decoFoliage",  ch=9,  nc=5},
      {ft="decoFoliage",  ch=10, nc=5}, -- GrassMedium   (×2)
      {ft="decoFoliage",  ch=10, nc=5},
      {ft="forestPlants", ch=2,  nc=5}, -- Clover        (white clover strip)
      {ft="meadow",       ch=2,  nc=5}, -- Meadow        (occasional only)
    },
}

-- ── Paint slot state ──────────────────────────────────────────────────────────

local NUM_SLOTS = 4
local slots = {}
for i = 1, NUM_SLOTS do
    slots[i] = { sampled=false, R=nil, G=nil, B=nil, W=nil, preset=1 }
end

-- ── Exclusion slot definitions ────────────────────────────────────────────────
-- Label, default tolerance, sampled state.
-- Wider tolerance on road tarmac (very distinct), tighter on cultivated dirt
-- (could bleed into dry-grass pasture if too wide).

local EXCLUDE_DEFS = {
    { label="CULTIVATED FIELD",  tol=0.025 },
    { label="ROAD / TARMAC",     tol=0.035 },
    { label="FARMLAND / STUBBLE",tol=0.025 },
    { label="RESIDENTIAL",       tol=0.030 },
    { label="SPARE A",           tol=0.025 },
    { label="SPARE B",           tol=0.025 },
}
local NUM_EXCLUDE = #EXCLUDE_DEFS

local excludeSlots = {}
for i = 1, NUM_EXCLUDE do
    excludeSlots[i] = {
        sampled = false,
        R=nil, G=nil, B=nil, W=nil,
        tol = EXCLUDE_DEFS[i].tol,
    }
end

-- ── Scan settings ─────────────────────────────────────────────────────────────

local scanSpacing      = 2.0    -- metres between scan points
local scanDensity      = 0.70   -- base paint probability (varied per partition)
local brushM           = 1.2    -- brush footprint (metres)
local colourTol        = 0.020  -- paint slot RGBA tolerance

local TOTAL_PARTITIONS = 64

-- ── Terrain helper ────────────────────────────────────────────────────────────

local function getTerrainId()
    local scene = getRootNode()
    for i = 0, getNumOfChildren(scene) - 1 do
        local child = getChildAt(scene, i)
        if getName(child) == "terrain" then return child end
    end
    return nil
end

local function coloursMatch(aR,aG,aB,aW, bR,bG,bB,bW, tol)
    return math.abs(aR-bR)<=tol and math.abs(aG-bG)<=tol
       and math.abs(aB-bB)<=tol and math.abs(aW-bW)<=tol
end

-- ── UI label references (set after UI is built) ───────────────────────────────

local slotLabels    = {}
local presetLabels  = {}
local excludeLabels = {}

-- ── Slot samplers ─────────────────────────────────────────────────────────────

local function sampleSlot(idx)
    local terrainId = getTerrainId()
    if terrainId == nil then print("[SW Foliage v2] ERROR: terrain not found"); return end
    local sel = getSelection(0)
    if sel == nil or sel == 0 then
        print(string.format("[SW Foliage v2] Slot %d: nothing selected", idx)); return
    end
    local tx,ty,tz = getTranslation(sel)
    local R,G,B,W  = getTerrainAttributesAtWorldPos(
        terrainId, tx,ty,tz, true,true,true,true, false)
    slots[idx].sampled=true; slots[idx].R=R; slots[idx].G=G
    slots[idx].B=B;          slots[idx].W=W
    print(string.format("[SW Foliage v2] Slot %d @ (%.1f,%.1f)  R=%.4f G=%.4f B=%.4f W=%.4f  → %s",
        idx, tx,tz, R,G,B,W, PRESET_NAMES[slots[idx].preset]))
    if slotLabels[idx] then
        slotLabels[idx]:setValue(string.format("✓ R=%.3f G=%.3f B=%.3f W=%.3f",R,G,B,W))
    end
end

local function sampleExclude(idx)
    local terrainId = getTerrainId()
    if terrainId == nil then print("[SW Foliage v2] ERROR: terrain not found"); return end
    local sel = getSelection(0)
    if sel == nil or sel == 0 then
        print(string.format("[SW Foliage v2] EXCLUDE %d: nothing selected", idx)); return
    end
    local tx,ty,tz = getTranslation(sel)
    local R,G,B,W  = getTerrainAttributesAtWorldPos(
        terrainId, tx,ty,tz, true,true,true,true, false)
    excludeSlots[idx].sampled=true; excludeSlots[idx].R=R; excludeSlots[idx].G=G
    excludeSlots[idx].B=B;          excludeSlots[idx].W=W
    print(string.format("[SW Foliage v2] EXCLUDE %d (%s) @ (%.1f,%.1f)  R=%.4f G=%.4f B=%.4f W=%.4f",
        idx, EXCLUDE_DEFS[idx].label, tx,tz, R,G,B,W))
    if excludeLabels[idx] then
        excludeLabels[idx]:setValue(string.format(
            "✓ BLOCKED  R=%.3f G=%.3f B=%.3f W=%.3f  tol=%.3f",
            R,G,B,W, excludeSlots[idx].tol))
    end
end

-- ── Foliage plane cache + paint ───────────────────────────────────────────────

local _planeCache = {}
local _planeDiag  = {}

local function getPlaneId(terrainId, ftName)
    if _planeCache[ftName] == nil then
        local id = getTerrainDataPlaneByName(terrainId, ftName)
        _planeCache[ftName] = (id ~= nil and id ~= 0) and id or 0
        if _planeCache[ftName] == 0 then
            print(string.format("[SW Foliage v2] WARNING: plane '%s' not found", ftName))
        else
            print(string.format("[SW Foliage v2] Plane '%s' → id=%s", ftName, tostring(_planeCache[ftName])))
        end
    end
    return _planeCache[ftName]
end

local function paintFoliageAtPoint(terrainId, wx,wz, layerEntries, brushHalf)
    local entry    = layerEntries[math.random(1,#layerEntries)]
    local foliageId = getPlaneId(terrainId, entry.ft)
    if foliageId == 0 then return false end

    local diagKey = entry.ft..":"..entry.nc..":"..entry.ch
    if not _planeDiag[diagKey] then
        _planeDiag[diagKey] = true
        local maxVal = (2^entry.nc)-1
        print(string.format("[SW Foliage v2] DIAG plane='%s' nc=%d ch=%d maxAllowed=%d ok=%s",
            entry.ft, entry.nc, entry.ch, maxVal, tostring(entry.ch>=0 and entry.ch<=maxVal)))
    end

    local mod = DensityMapModifier.new(foliageId, 0, entry.nc)
    mod:setParallelogramWorldCoords(
        wx-brushHalf, wz-brushHalf,
        wx+brushHalf, wz-brushHalf,
        wx-brushHalf, wz+brushHalf,
        DensityCoordType.POINT_POINT_POINT)
    mod:executeSet(entry.ch)
    return true
end

-- ── Partition scan ────────────────────────────────────────────────────────────

local nextPartition  = 1
local sessionMatches = 0
local sessionPainted = 0
local sessionSkipped = 0
local partitionLabel = nil

local function updatePartitionLabel()
    if partitionLabel then
        if nextPartition > TOTAL_PARTITIONS then
            partitionLabel:setValue(string.format(
                "Done! All %d done  |  %d matches  |  %d painted  |  %d excluded",
                TOTAL_PARTITIONS, sessionMatches, sessionPainted, sessionSkipped))
        else
            partitionLabel:setValue(string.format(
                "Next: %d/%d  |  matches=%d  painted=%d  excluded=%d",
                nextPartition, TOTAL_PARTITIONS,
                sessionMatches, sessionPainted, sessionSkipped))
        end
    end
end

local function resetPartitions()
    nextPartition=1; sessionMatches=0; sessionPainted=0; sessionSkipped=0
    _planeCache={}; _planeDiag={}
    print("[SW Foliage v2] Reset — partition counter back to 1.")
    updatePartitionLabel()
end

local function runNextPartition()
    if nextPartition > TOTAL_PARTITIONS then
        print("[SW Foliage v2] All partitions done. Click Reset to start over.")
        return
    end

    local activeSlotsCount = 0
    for i=1,NUM_SLOTS do if slots[i].sampled then activeSlotsCount=activeSlotsCount+1 end end
    if activeSlotsCount == 0 then
        print("[SW Foliage v2] ERROR: No paint slots sampled yet.")
        return
    end

    local terrainId = getTerrainId()
    if terrainId == nil then print("[SW Foliage v2] ERROR: terrain not found"); return end

    local p           = nextPartition
    local terrainSize = getTerrainSize(terrainId)
    local halfSize    = terrainSize / 2
    local numSec      = math.sqrt(TOTAL_PARTITIONS)   -- 8
    local secSize     = terrainSize / numSec
    local brushHalf   = brushM * 0.5

    local col    = ((p-1) % numSec)
    local row    = math.floor((p-1) / numSec)
    local xStart = -halfSize + col * secSize
    local zStart = -halfSize + row * secSize
    local xEnd   = xStart + secSize
    local zEnd   = zStart + secSize

    -- ── Natural variation: each partition gets a seeded density multiplier ──
    -- This makes foliage patchier rather than perfectly uniform everywhere.
    -- Range 0.4-1.0 — some partitions are light, some are dense.
    math.randomseed(p * 7919)  -- deterministic per partition so re-runs are consistent
    local densityMult = 0.4 + math.random() * 0.6
    local effectiveDensity = scanDensity * densityMult

    -- Also vary brush size slightly per partition for organic feel
    local brushScale = 0.8 + math.random() * 0.6  -- 0.8×–1.4× base brush
    local effectiveBrushHalf = brushHalf * brushScale

    -- Re-seed with a different prime per partition so jitter varies
    -- (os library not available in GE Lua)
    math.randomseed(p * 31337)

    local matches = 0
    local painted = 0
    local skipped = 0

    local x = xStart
    while x <= xEnd do
        local z = zStart
        while z <= zEnd do
            local R,G,B,W = getTerrainAttributesAtWorldPos(
                terrainId, x,300,z, true,true,true,true, false)

            -- ── Exclusion check (fields, roads, farmland, residential) ──────
            local excluded = false
            for e=1,NUM_EXCLUDE do
                local ex = excludeSlots[e]
                if ex.sampled then
                    if coloursMatch(R,G,B,W, ex.R,ex.G,ex.B,ex.W, ex.tol) then
                        excluded=true; skipped=skipped+1; break
                    end
                end
            end

            if not excluded then
                for i=1,NUM_SLOTS do
                    local s = slots[i]
                    if s.sampled and math.random() <= effectiveDensity then
                        if coloursMatch(R,G,B,W, s.R,s.G,s.B,s.W, colourTol) then
                            matches = matches + 1
                            -- Jitter each painted point slightly so the scan
                            -- grid never shows through as a repeating pattern
                            local jx = x + (math.random()-0.5)*scanSpacing*0.9
                            local jz = z + (math.random()-0.5)*scanSpacing*0.9
                            if paintFoliageAtPoint(terrainId, jx,jz,
                                    PRESET_LAYERS[s.preset], effectiveBrushHalf) then
                                painted = painted + 1
                            end
                        end
                    end
                end
            end

            z = z + scanSpacing
        end
        x = x + scanSpacing
    end

    sessionMatches = sessionMatches + matches
    sessionPainted = sessionPainted + painted
    sessionSkipped = sessionSkipped + skipped

    print(string.format(
        "[SW Foliage v2] Partition %d/%d  density=%.0f%%  brush=%.2f m  "..
        "→ %d matches  %d painted  %d excluded  (session: %d/%d/%d)",
        p, TOTAL_PARTITIONS, effectiveDensity*100, effectiveBrushHalf*2,
        matches, painted, skipped,
        sessionMatches, sessionPainted, sessionSkipped))

    nextPartition = nextPartition + 1
    updatePartitionLabel()

    if nextPartition > TOTAL_PARTITIONS then
        print(string.format(
            "[SW Foliage v2] ✓ Complete! %d matches | %d painted | %d field/road excluded",
            sessionMatches, sessionPainted, sessionSkipped))
    end
end

-- ── UI ────────────────────────────────────────────────────────────────────────

local frameSizer  = UIRowLayoutSizer.new()
local window      = UIWindow.new(frameSizer, "SW Foliage by Texture v2")
local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer, -1,-1,-1,-1, BorderDirection.ALL, 6)

-- ── PAINT SLOTS ───────────────────────────────────────────────────────────────
UILabel.new(borderSizer, "── PAINT SLOTS ──  (sample texture → assign preset)",
    TextAlignment.LEFT)
UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 3)

for i=1,NUM_SLOTS do
    local idx = i
    local hdr = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, hdr, -1,-1,-1,-1, BorderDirection.BOTTOM, 1)
    UILabel.new(hdr, string.format("Slot %d", i), TextAlignment.LEFT)

    local sRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, sRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 1)
    UIButton.new(sRow, string.format("Sample Slot %d", i), function() sampleSlot(idx) end)

    local lRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, lRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 1)
    local lbl = UITextArea.new(lRow, "(not sampled)", TextAlignment.LEFT,
        false,true,-1,22,-1,22, BorderDirection.NONE,0,0)
    slotLabels[i] = lbl

    local pRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, pRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 3)
    local pLbl = UITextArea.new(pRow, "Preset: "..PRESET_NAMES[1],
        TextAlignment.LEFT, false,true,200,22,-1,22, BorderDirection.NONE,0,0)
    presetLabels[i] = pLbl
    UIButton.new(pRow, "Next Preset", function()
        slots[idx].preset = (slots[idx].preset % #PRESET_NAMES) + 1
        presetLabels[idx]:setValue("Preset: "..PRESET_NAMES[slots[idx].preset])
        print(string.format("[SW Foliage v2] Slot %d → %s", idx, PRESET_NAMES[slots[idx].preset]))
    end)

    UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
end

-- ── EXCLUSION SLOTS ───────────────────────────────────────────────────────────
UILabel.new(borderSizer,
    "── EXCLUSION  ──  (sample textures to BLOCK foliage here)",
    TextAlignment.LEFT)
UILabel.new(borderSizer,
    "Fields, roads, farmland, residential — any matching point is skipped.",
    TextAlignment.LEFT)
UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 3)

for e=1,NUM_EXCLUDE do
    local exIdx = e
    local eRow  = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, eRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 1)
    UIButton.new(eRow,
        string.format("Sample EXCLUDE %d  (%s)", e, EXCLUDE_DEFS[e].label),
        function() sampleExclude(exIdx) end)

    local eLblRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, eLblRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 3)
    local exLbl = UITextArea.new(eLblRow,
        string.format("(not set — %s)", EXCLUDE_DEFS[e].label),
        TextAlignment.LEFT, false,true,-1,22,-1,22, BorderDirection.NONE,0,0)
    excludeLabels[e] = exLbl
    UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
end

-- ── INFO + CONTROLS ───────────────────────────────────────────────────────────
local infoSizer = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, infoSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 4)
UILabel.new(infoSizer,
    "Workflow:\n"..
    "1. Place transforms on countryside textures → Sample Slots 1-4.\n"..
    "2. Place transforms on field/road/farmland/residential → Sample Excludes.\n"..
    "3. Click Paint Next Partition (64 clicks = whole map).\n"..
    "Density varies per partition (40-100%) for a natural uneven look.\n"..
    "Spacing=2m  Base density=70%  Tolerance=0.02  Road tol=0.035",
    TextAlignment.LEFT)

local progRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, progRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
partitionLabel = UITextArea.new(progRow,
    "Next: partition 1/64  |  matches=0  painted=0  excluded=0",
    TextAlignment.LEFT, false,true,-1,22,-1,22, BorderDirection.NONE,0,0)

local runRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, runRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
UIButton.new(runRow, "Paint Next Partition", runNextPartition)

local resetRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, resetRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
UIButton.new(resetRow, "Reset Partitions (start over)", resetPartitions)

window:showWindow()

print("\n[SW Foliage by Texture v2] Ready.")
print("Exclusion slots:")
for e=1,NUM_EXCLUDE do
    print(string.format("  EXCLUDE %d → %-22s (tol=%.3f)", e, EXCLUDE_DEFS[e].label, EXCLUDE_DEFS[e].tol))
end
print("")
print("British presets:")
print("  WOODLAND FLOOR  → ForestGrass/SwordFern(bracken)/DeerFern/Clover/DryBranch")
print("  GRASS & MEADOW  → GrassDenseMix(cow parsley)/GrassMedium/Meadow")
print("  HEDGEROW SCRUB  → hazelnut(×4 dominant)/boxwood(blackthorn/hawthorn)")
print("  FIELD MARGIN    → GrassSmall(×5)/Clover (very sparse)")
print("")
print("Natural variation: each partition uses 40-100% of base density.")
print("Brush size also varies per partition for organic patchiness.")
print("")
print("Recommended SW sampling targets:")
print("  forestGrass01 / forestLeaves01 → Slot 1 → WOODLAND FLOOR")
print("  grass01 / grassClovers01       → Slot 2 → GRASS & MEADOW")
print("  hedgerow / scrub textures       → Slot 3 → HEDGEROW SCRUB")
print("  grassDirtStones01 (roadside)    → Slot 4 → FIELD MARGIN")
print("  cultivatedDirt01 / fieldGround  → EXCLUDE 1 (CULTIVATED FIELD)")
print("  asphalt01 / road textures       → EXCLUDE 2 (ROAD / TARMAC)")
print("  cropStubble / fieldDry          → EXCLUDE 3 (FARMLAND / STUBBLE)")
print("  villageLawn / residential       → EXCLUDE 4 (RESIDENTIAL)")
