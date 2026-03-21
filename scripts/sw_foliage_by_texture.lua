-- Author: South Warwickshire FS25 Pipeline
-- Name: SW Foliage by Texture
-- Description: Paints ground-level foliage layers across the whole map based
--              on terrain texture type. Up to 4 texture targets can be sampled
--              simultaneously, each mapped to its own foliage preset.
--
-- How it works:
--   GE's getTerrainAttributesAtWorldPos() reads the blended RGBA of the
--   dominant terrain texture at any world position. This script lets you
--   "sample" the colour signature of any texture by placing a transform on
--   it, then scans the whole map and paints foliage wherever that texture
--   is dominant.
--
-- Workflow:
--   1. Place an empty TransformGroup directly on each terrain texture you
--      want to target (e.g. one on forestGrass, one on grassClovers).
--   2. Select the transform for slot 1, click "Sample Slot 1".
--      Repeat for slots 2-4 as needed.
--   3. Choose a Foliage Preset for each sampled slot.
--   4. Adjust Spacing and Density, then click "Paint All Slots".
--
-- Foliage presets available per slot:
--   WOODLAND FLOOR  → ferns, clover, forest grass, blueberry, leaf litter
--   GRASS & MEADOW  → GrassMedium, GrassDenseMix, Meadow
--   HEDGEROW SCRUB  → hazelnutSmall/Med, boxwoodSmall/Med, decobushSmall
--   FIELD MARGIN    → Meadow, GrassSmall, GrassMedium
--
-- Tips for South Warwickshire:
--   • forestGrass01 / forestLeaves01 textures → use WOODLAND FLOOR preset
--   • grass01 / grassClovers01 textures        → use GRASS & MEADOW preset
--   • grassDirtStones01 (roadside)             → use FIELD MARGIN preset
--   • anywhere with hedgerow scrub texture      → use HEDGEROW SCRUB preset
--
-- Scanning is done in 64 partitions to avoid GE freezing.
-- Run one partition at a time if the map is very large.
--
-- Hide: no
-- AlwaysLoaded: no

source("editorUtils.lua")

-- ── Foliage presets ───────────────────────────────────────────────────────────

local PRESET_NAMES = {
    "WOODLAND FLOOR",
    "GRASS & MEADOW",
    "HEDGEROW SCRUB",
    "FIELD MARGIN",
}

-- How channel encoding works in this map:
--
-- decoBush (densityMapId=639, numChannels=4, numTypeIndexChannels=0):
--   Separate 4-channel density map.  ch = raw DetailObject "channels" value.
--   Values 6-15 are the 10 plant types.  nc=4.
--
-- forestPlants / decoFoliage / meadow share a 10-channel multiLayer
--   (densityMapId=640, numChannels=10, numTypeIndexChannels=5):
--   Bits 0-4  = typeIndex (decoFoliage=1, decoBushUS=2, meadow=3, forestPlants=4, waterPlants=5)
--   Bits 5-9  = state (which sub-type / plant variety)
--   getTerrainDataPlaneByName returns a plane at channelOffset=5 (the state bits).
--   → nc = 5  (only the 5 state bits are writable via this plane)
--   → ch = DetailObject_channels >> 5  (extract the state portion)
--   The engine automatically writes the correct typeIndex into bits 0-4.
--
-- Derivation (verify with: full_val = (state<<5)|typeIndex):
--   forestPlants (typeIndex=4):
--     F_decobushSuperBig ch_full=4   → state=0  → ch=0
--     F_ForestDryBranch  ch_full=36  → state=1  → ch=1
--     F_ForestClover     ch_full=68  → state=2  → ch=2
--     F_ForestStarFlower ch_full=100 → state=3  → ch=3
--     F_ForestBunchBerry ch_full=132 → state=4  → ch=4
--     F_ForestSalmonBerry ch_full=164 → state=5 → ch=5
--     F_ForestStarryFalse ch_full=196 → state=6 → ch=6
--     F_ForestSwordFern  ch_full=228 → state=7  → ch=7
--     F_ForestDeerFern   ch_full=260 → state=8  → ch=8
--     F_ForestGrass      ch_full=292 → state=9  → ch=9
--   decoFoliage (typeIndex=1):
--     F_GrassDenseMix   ch_full=33  → state=1  → ch=1
--     F_GrassSmall      ch_full=289 → state=9  → ch=9
--     F_GrassMedium     ch_full=321 → state=10 → ch=10
--   meadow (typeIndex=3):
--     F_Meadow          ch_full=67  → state=2  → ch=2
--   decoBush (separate 4-ch map, typeIndex N/A):
--     F_blueberrySmall  ch=6   F_blueberryMedium ch=7   F_blueberryBig ch=8
--     F_blueberryTall   ch=9   F_boxwoodSmall    ch=10  F_boxwoodMedium ch=11
--     F_boxwoodBig      ch=12  F_hazelnutSmall   ch=13  F_hazelnutMedium ch=14
--     F_hazelnutBig     ch=15

local PRESET_LAYERS = {
    -- [1] WOODLAND FLOOR  – ferns, clover, forest grass + blueberry/decobush
    { {ft="forestPlants", ch=9, nc=5},   -- F_ForestGrass      (full=292)
      {ft="forestPlants", ch=9, nc=5},   -- F_ForestGrass      (weighted x2)
      {ft="forestPlants", ch=2, nc=5},   -- F_ForestClover     (full=68)
      {ft="forestPlants", ch=8, nc=5},   -- F_ForestDeerFern   (full=260)
      {ft="forestPlants", ch=7, nc=5},   -- F_ForestSwordFern  (full=228)
      {ft="forestPlants", ch=4, nc=5},   -- F_ForestBunchBerry (full=132)
      {ft="forestPlants", ch=6, nc=5},   -- F_ForestStarryFalse(full=196)
      {ft="forestPlants", ch=1, nc=5},   -- F_ForestDryBranch  (full=36)
      {ft="forestPlants", ch=5, nc=5},   -- F_ForestSalmonBerry(full=164)
      {ft="decoBush",     ch=6, nc=4},   -- F_blueberrySmall
      {ft="decoBush",     ch=7, nc=4},   -- F_blueberryMedium
    },

    -- [2] GRASS & MEADOW  – decorative grasses and meadow flowers
    { {ft="decoFoliage", ch=10, nc=5},  -- F_GrassMedium      (full=321)
      {ft="decoFoliage", ch=10, nc=5},  -- F_GrassMedium      (weighted x2)
      {ft="decoFoliage", ch=1,  nc=5},  -- F_GrassDenseMix    (full=33)
      {ft="meadow",      ch=2,  nc=5},  -- F_Meadow           (full=67)
      {ft="decoFoliage", ch=9,  nc=5},  -- F_GrassSmall       (full=289)
    },

    -- [3] HEDGEROW SCRUB  – hazelnut, boxwood, berry bushes
    { {ft="decoBush",     ch=13, nc=4},  -- F_hazelnutSmall
      {ft="decoBush",     ch=14, nc=4},  -- F_hazelnutMedium
      {ft="decoBush",     ch=10, nc=4},  -- F_boxwoodSmall
      {ft="decoBush",     ch=11, nc=4},  -- F_boxwoodMedium
      {ft="decoBush",     ch=6,  nc=4},  -- F_blueberrySmall
      {ft="forestPlants", ch=4,  nc=5},  -- F_ForestBunchBerry (full=132)
    },

    -- [4] FIELD MARGIN  – meadow + short grasses
    { {ft="meadow",      ch=2,  nc=5},  -- F_Meadow           (full=67)
      {ft="decoFoliage", ch=9,  nc=5},  -- F_GrassSmall       (full=289)
      {ft="decoFoliage", ch=10, nc=5},  -- F_GrassMedium      (full=321)
    },
}

-- ── Slot state ────────────────────────────────────────────────────────────────
-- Each slot holds a sampled colour signature + chosen preset index

local NUM_SLOTS = 4
local slots = {}
for i = 1, NUM_SLOTS do
    slots[i] = {
        sampled  = false,
        R = nil, G = nil, B = nil, W = nil,   -- colour signature (formatted strings)
        preset   = 1,                          -- index into PRESET_NAMES
        label    = nil,  -- updated after UI is built
    }
end

-- Scan settings
local scanSpacing = 2.0    -- metres between scan points
local scanDensity = 0.70   -- probability of painting at each matched point
local brushM      = 1.2    -- paint brush footprint (metres)
local colourTol   = 0.02   -- RGBA tolerance for matching (0 = exact)

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

local function fmtR(v) return string.format("%.6f", v) end
local function fmtW(v) return string.format("%.4f",  v) end

local function coloursMatch(aR, aG, aB, aW, bR, bG, bB, bW, tol)
    return math.abs(aR - bR) <= tol
       and math.abs(aG - bG) <= tol
       and math.abs(aB - bB) <= tol
       and math.abs(aW - bW) <= tol
end

-- ── Sample a slot from the current GE selection ───────────────────────────────

local slotLabels = {}   -- updated after UI is built

local function sampleSlot(idx)
    local terrainId = getTerrainId()
    if terrainId == nil then
        print("[SW Foliage by Texture] ERROR: terrain node not found")
        return
    end

    local sel = getSelection(0)
    if sel == nil or sel == 0 then
        print(string.format("[SW Foliage by Texture] Slot %d: nothing selected. "..
            "Place a transform ON the target texture first.", idx))
        return
    end

    local tx, ty, tz = getTranslation(sel)
    local R, G, B, W, U = getTerrainAttributesAtWorldPos(
        terrainId, tx, ty, tz, true, true, true, true, false)

    slots[idx].sampled = true
    slots[idx].R = R
    slots[idx].G = G
    slots[idx].B = B
    slots[idx].W = W

    local msg = string.format(
        "Slot %d sampled at (%.1f, %.1f)  R=%.4f G=%.4f B=%.4f W=%.4f  → %s",
        idx, tx, tz, R, G, B, W, PRESET_NAMES[slots[idx].preset])
    print("[SW Foliage by Texture] " .. msg)
    if slotLabels[idx] then
        slotLabels[idx]:setValue(string.format("✓ R=%.3f G=%.3f B=%.3f W=%.3f", R, G, B, W))
    end
end

-- ── Core scan & paint ─────────────────────────────────────────────────────────

-- Cache foliage plane IDs so we only call getTerrainDataPlaneByName once per plane name
local _planeCache      = {}
local _planeFirstPaint = {}  -- diagnostic: log first paint per plane

local function getPlaneId(terrainId, ftName)
    if _planeCache[ftName] == nil then
        local id = getTerrainDataPlaneByName(terrainId, ftName)
        _planeCache[ftName] = (id ~= nil and id ~= 0) and id or 0
        if _planeCache[ftName] == 0 then
            print(string.format("[SW Foliage] WARNING: plane '%s' not found on terrain %s",
                ftName, tostring(terrainId)))
        else
            print(string.format("[SW Foliage] Plane '%s' → id=%s", ftName, tostring(_planeCache[ftName])))
        end
    end
    return _planeCache[ftName]
end

-- layerEntries is a list of {ft=planeNameString, ch=stateValue, nc=numChannels}
-- ch is the STATE value (channels>>5 for shared multiLayer planes, raw value for decoBush)
local function paintFoliageAtPoint(terrainId, wx, wz, layerEntries, brushHalf)
    local entry    = layerEntries[math.random(1, #layerEntries)]
    local foliageId = getPlaneId(terrainId, entry.ft)
    if foliageId == 0 then
        -- Warning already printed by getPlaneId on first miss; nothing more to do
        return false
    end

    -- One-time diagnostic per plane: confirm nc/ch values are in range
    local diagKey = entry.ft .. ":" .. entry.nc .. ":" .. entry.ch
    if not _planeFirstPaint[diagKey] then
        _planeFirstPaint[diagKey] = true
        local maxVal = (2 ^ entry.nc) - 1
        local rangeOk = (entry.ch >= 0 and entry.ch <= maxVal)
        print(string.format("[SW Foliage] DIAG first paint: plane='%s' id=%s nc=%d ch=%d  maxAllowed=%d  inRange=%s",
            entry.ft, tostring(foliageId), entry.nc, entry.ch, maxVal, tostring(rangeOk)))
    end

    local mod = DensityMapModifier.new(foliageId, 0, entry.nc)
    mod:setParallelogramWorldCoords(
        wx - brushHalf, wz - brushHalf,
        wx + brushHalf, wz - brushHalf,
        wx - brushHalf, wz + brushHalf,
        DensityCoordType.POINT_POINT_POINT
    )
    mod:executeSet(entry.ch)
    return true
end

-- ── Partition-based scan state ────────────────────────────────────────────────
-- Each button press processes exactly ONE partition and returns so GE stays
-- responsive. Click "Paint Next Partition" up to 64 times to cover the whole map.

local nextPartition   = 1    -- which partition to run on the next button press
local sessionMatches  = 0    -- cumulative totals across this session
local sessionPainted  = 0
local partitionLabel  = nil  -- set after UI is built

local function updatePartitionLabel()
    if partitionLabel then
        if nextPartition > TOTAL_PARTITIONS then
            partitionLabel:setValue(string.format(
                "Done! All %d partitions  |  %d matches  |  %d painted",
                TOTAL_PARTITIONS, sessionMatches, sessionPainted))
        else
            partitionLabel:setValue(string.format(
                "Next: partition %d / %d  |  total so far: %d matches  %d painted",
                nextPartition, TOTAL_PARTITIONS, sessionMatches, sessionPainted))
        end
    end
end

local function resetPartitions()
    nextPartition  = 1
    sessionMatches = 0
    sessionPainted = 0
    _planeCache      = {}   -- clear cached plane IDs so fresh run re-resolves them
    _planeFirstPaint = {}   -- reset diagnostics too
    print("[SW Foliage by Texture] Partition counter reset to 1.")
    updatePartitionLabel()
end

-- Runs ONE partition (nextPartition) then returns immediately.
local function runNextPartition()
    if nextPartition > TOTAL_PARTITIONS then
        print("[SW Foliage by Texture] All partitions already complete. "..
              "Click Reset to start over.")
        return
    end

    -- Check at least one slot is sampled
    local activeSlotsCount = 0
    for i = 1, NUM_SLOTS do
        if slots[i].sampled then activeSlotsCount = activeSlotsCount + 1 end
    end
    if activeSlotsCount == 0 then
        print("[SW Foliage by Texture] ERROR: No slots sampled yet. "..
              "Place transforms on target textures and use the Sample buttons first.")
        return
    end

    local terrainId = getTerrainId()
    if terrainId == nil then
        print("[SW Foliage by Texture] ERROR: terrain node not found")
        return
    end

    local p          = nextPartition
    local terrainSize = getTerrainSize(terrainId)
    local halfSize   = terrainSize / 2
    local numSec     = math.sqrt(TOTAL_PARTITIONS)   -- 8
    local sectionSize = terrainSize / numSec
    local brushHalf  = brushM * 0.5

    -- Convert partition index (1-based) → section row/col (0-based)
    local col    = ((p - 1) % numSec)
    local row    = math.floor((p - 1) / numSec)
    local xStart = -halfSize + col * sectionSize
    local zStart = -halfSize + row * sectionSize
    local xEnd   = xStart + sectionSize
    local zEnd   = zStart + sectionSize

    local matches = 0
    local painted = 0

    local x = xStart
    while x <= xEnd do
        local z = zStart
        while z <= zEnd do
            local R, G, B, W, U = getTerrainAttributesAtWorldPos(
                terrainId, x, 300, z, true, true, true, true, false)

            for i = 1, NUM_SLOTS do
                local s = slots[i]
                if s.sampled and math.random() <= scanDensity then
                    if coloursMatch(R, G, B, W, s.R, s.G, s.B, s.W, colourTol) then
                        matches = matches + 1
                        local jx = x + (math.random() - 0.5) * scanSpacing * 0.8
                        local jz = z + (math.random() - 0.5) * scanSpacing * 0.8
                        if paintFoliageAtPoint(terrainId, jx, jz,
                                PRESET_LAYERS[s.preset], brushHalf) then
                            painted = painted + 1
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

    print(string.format("[SW Foliage] Partition %d/%d done — %d matches, %d painted  "..
          "(session total: %d matches, %d painted)",
          p, TOTAL_PARTITIONS, matches, painted, sessionMatches, sessionPainted))

    nextPartition = nextPartition + 1
    updatePartitionLabel()

    if nextPartition > TOTAL_PARTITIONS then
        print(string.format("[SW Foliage] ✓ All %d partitions complete! "..
              "Session total: %d matches | %d painted",
              TOTAL_PARTITIONS, sessionMatches, sessionPainted))
    end
end

-- ── UI (GE 10.0.9 compatible) ─────────────────────────────────────────────────

local presetLabels = {}   -- label per slot showing current preset name

local frameSizer  = UIRowLayoutSizer.new()
local window      = UIWindow.new(frameSizer, "SW Foliage by Texture")
local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer, -1, -1, -1, -1, BorderDirection.ALL, 6)

-- Per-slot controls
for i = 1, NUM_SLOTS do
    UIHorizontalLine.new(borderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)

    local titleRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, titleRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    UILabel.new(titleRow, string.format("── Slot %d ──", i), TextAlignment.LEFT)

    -- Sample button + status label
    local sampleRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, sampleRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    UIButton.new(sampleRow, string.format("Sample Slot %d", i), function()
        sampleSlot(i)
    end)

    local lblRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, lblRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 1)
    local lbl = UITextArea.new(lblRow, "(not sampled)", TextAlignment.LEFT, false, true, -1, 22, -1, 22, BorderDirection.NONE, 0, 0)
    slotLabels[i] = lbl

    -- Preset cycle button
    local presetRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, presetRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    local pLbl = UITextArea.new(presetRow, "Preset: "..PRESET_NAMES[1], TextAlignment.LEFT, false, true, 200, 22, -1, 22, BorderDirection.NONE, 0, 0)
    presetLabels[i] = pLbl
    local idx = i  -- capture loop var
    UIButton.new(presetRow, "Next Preset", function()
        slots[idx].preset = (slots[idx].preset % #PRESET_NAMES) + 1
        presetLabels[idx]:setValue("Preset: "..PRESET_NAMES[slots[idx].preset])
        print(string.format("[SW Foliage] Slot %d → %s", idx, PRESET_NAMES[slots[idx].preset]))
    end)
end

UIHorizontalLine.new(borderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)

-- Info label
local infoRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, infoRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(infoRow,
    "Place Transform on texture, select it, click Sample.\n"..
    "Click Next Preset to cycle foliage type.\n"..
    "Spacing=2m  Density=70%  Tolerance=0.02\n"..
    "Click Paint Next Partition once per section (64 total).", TextAlignment.LEFT)

-- Partition progress label
local progRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, progRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
partitionLabel = UITextArea.new(progRow,
    "Next: partition 1 / 64  |  total so far: 0 matches  0 painted",
    TextAlignment.LEFT, false, true, -1, 22, -1, 22, BorderDirection.NONE, 0, 0)

-- Paint one partition button
local runRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, runRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
UIButton.new(runRow, "Paint Next Partition", runNextPartition)

-- Reset button
local resetRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, resetRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
UIButton.new(resetRow, "Reset Partitions (start over)", resetPartitions)

window:showWindow()

print("\n[SW Foliage by Texture] Ready.")
print("Presets:")
print("  WOODLAND FLOOR  → ForestGrass/Clover/Fern/Blueberry/DryBranch")
print("  GRASS & MEADOW  → GrassMedium/DenseMix/Meadow")
print("  HEDGEROW SCRUB  → hazelnut/boxwood/decobush")
print("  FIELD MARGIN    → Meadow/GrassSmall/Med")
print("")
print("Recommended for South Warwickshire:")
print("  forestGrass01 / forestLeaves01 texture → WOODLAND FLOOR")
print("  grass01 / grassClovers01              → GRASS & MEADOW")
print("  grassDirtStones01 (roadsides)          → FIELD MARGIN")
