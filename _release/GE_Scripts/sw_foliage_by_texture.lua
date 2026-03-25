source("editorUtils.lua")
local PRESET_NAMES = {
    "WOODLAND FLOOR",
    "GRASS & MEADOW",
    "HEDGEROW SCRUB",
    "FIELD MARGIN",
}
local PRESET_LAYERS = {
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
    { {ft="decoFoliage", ch=10, nc=5},  -- F_GrassMedium      (full=321)
      {ft="decoFoliage", ch=10, nc=5},  -- F_GrassMedium      (weighted x2)
      {ft="decoFoliage", ch=1,  nc=5},  -- F_GrassDenseMix    (full=33)
      {ft="meadow",      ch=2,  nc=5},  -- F_Meadow           (full=67)
      {ft="decoFoliage", ch=9,  nc=5},  -- F_GrassSmall       (full=289)
    },
    { {ft="decoBush",     ch=13, nc=4},  -- F_hazelnutSmall
      {ft="decoBush",     ch=14, nc=4},  -- F_hazelnutMedium
      {ft="decoBush",     ch=10, nc=4},  -- F_boxwoodSmall
      {ft="decoBush",     ch=11, nc=4},  -- F_boxwoodMedium
      {ft="decoBush",     ch=6,  nc=4},  -- F_blueberrySmall
      {ft="forestPlants", ch=4,  nc=5},  -- F_ForestBunchBerry (full=132)
    },
    { {ft="meadow",      ch=2,  nc=5},  -- F_Meadow           (full=67)
      {ft="decoFoliage", ch=9,  nc=5},  -- F_GrassSmall       (full=289)
      {ft="decoFoliage", ch=10, nc=5},  -- F_GrassMedium      (full=321)
    },
}
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
local scanSpacing = 2.0    -- metres between scan points
local scanDensity = 0.70   -- probability of painting at each matched point
local brushM      = 1.2    -- paint brush footprint (metres)
local colourTol   = 0.02   -- RGBA tolerance for matching (0 = exact)
local TOTAL_PARTITIONS = 64
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
local function paintFoliageAtPoint(terrainId, wx, wz, layerEntries, brushHalf)
    local entry    = layerEntries[math.random(1, #layerEntries)]
    local foliageId = getPlaneId(terrainId, entry.ft)
    if foliageId == 0 then
        return false
    end
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
local function runNextPartition()
    if nextPartition > TOTAL_PARTITIONS then
        print("[SW Foliage by Texture] All partitions already complete. "..
              "Click Reset to start over.")
        return
    end
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
local presetLabels = {}   -- label per slot showing current preset name
local frameSizer  = UIRowLayoutSizer.new()
local window      = UIWindow.new(frameSizer, "SW Foliage by Texture")
local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer, -1, -1, -1, -1, BorderDirection.ALL, 6)
for i = 1, NUM_SLOTS do
    UIHorizontalLine.new(borderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    local titleRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, titleRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    UILabel.new(titleRow, string.format("── Slot %d ──", i), TextAlignment.LEFT)
    local sampleRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, sampleRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    UIButton.new(sampleRow, string.format("Sample Slot %d", i), function()
        sampleSlot(i)
    end)
    local lblRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, lblRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 1)
    local lbl = UITextArea.new(lblRow, "(not sampled)", TextAlignment.LEFT, false, true, -1, 22, -1, 22, BorderDirection.NONE, 0, 0)
    slotLabels[i] = lbl
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
local infoRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, infoRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(infoRow,
    "Place Transform on texture, select it, click Sample.\n"..
    "Click Next Preset to cycle foliage type.\n"..
    "Spacing=2m  Density=70%  Tolerance=0.02\n"..
    "Click Paint Next Partition once per section (64 total).", TextAlignment.LEFT)
local progRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, progRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
partitionLabel = UITextArea.new(progRow,
    "Next: partition 1 / 64  |  total so far: 0 matches  0 painted",
    TextAlignment.LEFT, false, true, -1, 22, -1, 22, BorderDirection.NONE, 0, 0)
local runRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, runRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
UIButton.new(runRow, "Paint Next Partition", runNextPartition)
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
