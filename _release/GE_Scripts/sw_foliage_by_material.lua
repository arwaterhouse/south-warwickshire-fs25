source("editorUtils.lua")
local GROUPS = {
    { name="GRASS & FOREST",
      R=0.155, G=0.082, B=0.037, W=0.7, tol=0.018,
      members="grass01/02, grassClovers, grassDirtStones, grassDirtPatchy, grassMoss, "..
              "grassFresh, grassCut, forestGrass, forestLeaves, forestNeedels, pebblesForestGround" },
    { name="GRAVEL MOSS",
      R=0.155, G=0.082, B=0.037, W=0.3, tol=0.018,
      members="gravelDirtMoss, gravelPebblesMoss, gravelPebblesMossPatchy" },
    { name="ASPHALT / ROAD",
      R=0.071, G=0.063, B=0.063, W=0.0, tol=0.015,
      members="asphalt01/02, asphaltCracks, asphaltTwigs" },
    { name="GRAVEL / STONE",
      R=0.157, G=0.141, B=0.122, W=0.0, tol=0.015,
      members="gravel01/02, gravelSmall01/02" },
    { name="ROCK / CONCRETE",
      R=0.220, G=0.212, B=0.196, W=0.0, tol=0.018,
      members="rock, rockForest, rockyForestGround, forestRockRoots, "..
              "concrete, concreteShattered, concreteGravelSand, concretePebbles" },
    { name="CONCRETE DIRT",
      R=0.165, G=0.149, B=0.125, W=0.0, tol=0.015,
      members="concreteDirt01/02" },
    { name="MUD GRAVEL",
      R=0.176, G=0.153, B=0.133, W=1.0, tol=0.015,
      members="mudGravel01/02" },
    { name="MUD DARK  (cultivated soil)",
      R=0.071, G=0.055, B=0.043, W=1.0, tol=0.015,
      members="mudDark01/02  — use as field/ploughed-soil EXCLUDE" },
    { name="MUD TRACKS  (freshly cultivated)",
      R=0.062, G=0.044, B=0.027, W=1.0, tol=0.012,
      members="mudTracks01  — very distinct, good for field EXCLUDE" },
    { name="MUD TRACKS 2",
      R=0.137, G=0.098, B=0.075, W=1.0, tol=0.015,
      members="mudTracks02" },
    { name="MUD LIGHT",
      R=0.137, G=0.114, B=0.078, W=1.0, tol=0.015,
      members="mudLight01/02, mudPebblesLight01/02" },
    { name="MUD LEAVES",
      R=0.082, G=0.075, B=0.027, W=1.0, tol=0.015,
      members="mudLeaves01/02" },
    { name="MUD PEBBLES",
      R=0.067, G=0.051, B=0.039, W=1.0, tol=0.012,
      members="mudPebbles01/02" },
    { name="MUD DARK PATCHY",
      R=0.078, G=0.067, B=0.043, W=1.0, tol=0.012,
      members="mudDarkGrassPatchy01/02, mudDarkMossPatchy01/02" },
    { name="ASPHALT DUSTY",
      R=0.137, G=0.129, B=0.116, W=0.0, tol=0.015,
      members="asphaltDusty01/02" },
    { name="ROCK FLOOR TILES",
      R=0.208, G=0.184, B=0.165, W=0.0, tol=0.015,
      members="rockFloorTiles01/02, rockFloorTilesPattern01/02" },
    { name="SAND",
      R=0.230, G=0.122, B=0.061, W=1.0, tol=0.015,
      members="sand01/02" },
    { name="— no group selected —",
      R=nil, G=nil, B=nil, W=nil, tol=0,
      members="" },
}
local NUM_GROUPS = #GROUPS
local PRESET_NAMES = { "WOODLAND FLOOR", "GRASS & MEADOW", "HEDGEROW SCRUB", "FIELD MARGIN", "NONE" }
local PRESET_LAYERS = {
    { {ft="forestPlants",ch=9,nc=5},{ft="forestPlants",ch=9,nc=5},
      {ft="forestPlants",ch=9,nc=5},{ft="forestPlants",ch=9,nc=5},
      {ft="forestPlants",ch=7,nc=5},{ft="forestPlants",ch=7,nc=5},
      {ft="forestPlants",ch=7,nc=5},{ft="forestPlants",ch=8,nc=5},
      {ft="forestPlants",ch=8,nc=5},{ft="forestPlants",ch=2,nc=5},
      {ft="forestPlants",ch=2,nc=5},{ft="forestPlants",ch=2,nc=5},
      {ft="forestPlants",ch=1,nc=5},{ft="forestPlants",ch=1,nc=5},
      {ft="forestPlants",ch=3,nc=5},{ft="decoBush",ch=13,nc=4} },
    { {ft="decoFoliage",ch=1,nc=5},{ft="decoFoliage",ch=1,nc=5},
      {ft="decoFoliage",ch=1,nc=5},{ft="decoFoliage",ch=10,nc=5},
      {ft="decoFoliage",ch=10,nc=5},{ft="decoFoliage",ch=10,nc=5},
      {ft="meadow",ch=2,nc=5},{ft="meadow",ch=2,nc=5},
      {ft="decoFoliage",ch=9,nc=5} },
    { {ft="decoBush",ch=13,nc=4},{ft="decoBush",ch=13,nc=4},
      {ft="decoBush",ch=13,nc=4},{ft="decoBush",ch=13,nc=4},
      {ft="decoBush",ch=14,nc=4},{ft="decoBush",ch=14,nc=4},
      {ft="decoBush",ch=15,nc=4},{ft="decoBush",ch=10,nc=4},
      {ft="decoBush",ch=11,nc=4},{ft="decoBush",ch=6,nc=4} },
    { {ft="decoFoliage",ch=9,nc=5},{ft="decoFoliage",ch=9,nc=5},
      {ft="decoFoliage",ch=9,nc=5},{ft="decoFoliage",ch=9,nc=5},
      {ft="decoFoliage",ch=9,nc=5},{ft="decoFoliage",ch=10,nc=5},
      {ft="decoFoliage",ch=10,nc=5},{ft="forestPlants",ch=2,nc=5},
      {ft="meadow",ch=2,nc=5} },
    {},
}
local NUM_PAINT   = 6
local NUM_EXCLUDE = 6
local paintSlots = {}
for i=1,NUM_PAINT do
    paintSlots[i] = { groupIdx=NUM_GROUPS, preset=5,  -- default: no group, NONE preset
                      groupLabel=nil, presetLabel=nil }
end
local excludeSlots = {}
for i=1,NUM_EXCLUDE do
    excludeSlots[i] = { groupIdx=NUM_GROUPS, groupLabel=nil }
end
local scanSpacing = 2.0
local scanDensity = 0.70
local brushM      = 1.2
local TOTAL_PARTITIONS = 64
local function getTerrainId()
    local scene = getRootNode()
    for i=0,getNumOfChildren(scene)-1 do
        local child = getChildAt(scene,i)
        if getName(child)=="terrain" then return child end
    end
    return nil
end
local function coloursMatch(R,G,B,W, gR,gG,gB,gW, tol)
    return math.abs(R-gR)<=tol and math.abs(G-gG)<=tol
       and math.abs(B-gB)<=tol and math.abs(W-gW)<=tol
end
local _planeCache = {}
local _planeDiag  = {}
local function getPlaneId(terrainId, ftName)
    if _planeCache[ftName]==nil then
        local id = getTerrainDataPlaneByName(terrainId, ftName)
        _planeCache[ftName] = (id~=nil and id~=0) and id or 0
        if _planeCache[ftName]==0 then
            print(string.format("[SW Foliage Mat] WARNING: foliage plane '%s' not found", ftName))
        end
    end
    return _planeCache[ftName]
end
local function paintFoliageAt(terrainId, wx,wz, entries, brushHalf)
    local e = entries[math.random(1,#entries)]
    local pid = getPlaneId(terrainId, e.ft)
    if pid==0 then return false end
    local dKey = e.ft..":"..e.ch
    if not _planeDiag[dKey] then
        _planeDiag[dKey]=true
        print(string.format("[SW Foliage Mat] First paint: plane='%s' ch=%d nc=%d",e.ft,e.ch,e.nc))
    end
    local mod = DensityMapModifier.new(pid, 0, e.nc)
    mod:setParallelogramWorldCoords(
        wx-brushHalf,wz-brushHalf, wx+brushHalf,wz-brushHalf,
        wx-brushHalf,wz+brushHalf, DensityCoordType.POINT_POINT_POINT)
    mod:executeSet(e.ch)
    return true
end
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
                "Next: partition %d/%d  |  painted=%d  excluded=%d",
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
        print("[SW Foliage Mat] All partitions done. Click Reset to start over."); return
    end
    local hasActive = false
    for i=1,NUM_PAINT do
        local s = paintSlots[i]
        if GROUPS[s.groupIdx].R ~= nil and s.preset < 5 then hasActive=true; break end
    end
    if not hasActive then
        print("[SW Foliage Mat] ERROR: No paint slots configured.")
        print("  Assign a group AND a foliage preset (not NONE) to at least one PAINT slot.")
        return
    end
    local terrainId = getTerrainId()
    if terrainId==nil then print("[SW Foliage Mat] ERROR: terrain not found"); return end
    local p           = nextPartition
    local terrainSize = getTerrainSize(terrainId)
    local halfSize    = terrainSize / 2
    local numSec      = math.sqrt(TOTAL_PARTITIONS)
    local secSize     = terrainSize / numSec
    local brushHalf   = brushM * 0.5
    local col = ((p-1) % numSec)
    local row = math.floor((p-1) / numSec)
    local xStart = -halfSize + col*secSize
    local zStart = -halfSize + row*secSize
    local xEnd = xStart+secSize
    local zEnd = zStart+secSize
    math.randomseed(p*7919)
    local eff_den = scanDensity * (0.4 + math.random()*0.6)
    local eff_bh  = brushHalf  * (0.8 + math.random()*0.6)
    math.randomseed(p*31337)
    local painted=0; local skipped=0
    local x = xStart
    while x <= xEnd do
        local z = zStart
        while z <= zEnd do
            if math.random() <= eff_den then
                local R,G,B,W = getTerrainAttributesAtWorldPos(
                    terrainId, x,300,z, true,true,true,true,false)
                local excluded = false
                for i=1,NUM_EXCLUDE do
                    local ex = excludeSlots[i]
                    local g  = GROUPS[ex.groupIdx]
                    if g.R ~= nil then
                        if coloursMatch(R,G,B,W, g.R,g.G,g.B,g.W, g.tol) then
                            excluded=true; skipped=skipped+1; break
                        end
                    end
                end
                if not excluded then
                    for i=1,NUM_PAINT do
                        local s = paintSlots[i]
                        local g = GROUPS[s.groupIdx]
                        if g.R ~= nil and s.preset < 5 then
                            if coloursMatch(R,G,B,W, g.R,g.G,g.B,g.W, g.tol) then
                                local jx = x+(math.random()-0.5)*scanSpacing*0.8
                                local jz = z+(math.random()-0.5)*scanSpacing*0.8
                                if paintFoliageAt(terrainId, jx,jz,
                                        PRESET_LAYERS[s.preset], eff_bh) then
                                    painted=painted+1
                                end
                                break
                            end
                        end
                    end
                end
            end
            z = z + scanSpacing
        end
        x = x + scanSpacing
    end
    sessionPainted=sessionPainted+painted; sessionSkipped=sessionSkipped+skipped
    print(string.format("[SW Foliage Mat] Partition %d/%d  eff_den=%.0f%%  → %d painted  %d excluded",
        p,TOTAL_PARTITIONS, eff_den*100, painted, skipped))
    nextPartition=nextPartition+1
    updatePartLabel()
    if nextPartition>TOTAL_PARTITIONS then
        print(string.format("[SW Foliage Mat] ✓ Complete! %d painted | %d excluded",
            sessionPainted, sessionSkipped))
    end
end
local frameSizer  = UIRowLayoutSizer.new()
local window      = UIWindow.new(frameSizer, "SW Foliage by Material")
local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer, -1,-1,-1,-1, BorderDirection.ALL, 6)
UILabel.new(borderSizer,
    "Select MATERIAL GROUPS — no sampling needed, RGBA values\n"..
    "are read automatically from your map.i3d.",
    TextAlignment.LEFT)
UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 4)
UILabel.new(borderSizer, "PAINT SLOTS (foliage is painted where this group is)", TextAlignment.LEFT)
UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
for i=1,NUM_PAINT do
    local si = i
    local hRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, hRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 1)
    UILabel.new(hRow, string.format("Paint %d:", si), TextAlignment.LEFT)
    local gRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, gRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 1)
    UIButton.new(gRow, "◀", function()
        paintSlots[si].groupIdx = ((paintSlots[si].groupIdx-2+NUM_GROUPS)%NUM_GROUPS)+1
        local g = GROUPS[paintSlots[si].groupIdx]
        paintSlots[si].groupLabel:setValue(g.name)
        print(string.format("[SW Foliage Mat] Paint %d → %s  (%s)", si, g.name, g.members))
    end)
    local gLbl = UITextArea.new(gRow,
        GROUPS[paintSlots[si].groupIdx].name,
        TextAlignment.LEFT, false,true,200,22,-1,22, BorderDirection.NONE,0,0)
    paintSlots[si].groupLabel = gLbl
    UIButton.new(gRow, "▶", function()
        paintSlots[si].groupIdx = (paintSlots[si].groupIdx%NUM_GROUPS)+1
        local g = GROUPS[paintSlots[si].groupIdx]
        paintSlots[si].groupLabel:setValue(g.name)
        print(string.format("[SW Foliage Mat] Paint %d → %s  (%s)", si, g.name, g.members))
    end)
    local pRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, pRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 3)
    local pLbl = UITextArea.new(pRow,
        "Preset: "..PRESET_NAMES[paintSlots[si].preset],
        TextAlignment.LEFT, false,true,200,22,-1,22, BorderDirection.NONE,0,0)
    paintSlots[si].presetLabel = pLbl
    UIButton.new(pRow, "Next Preset", function()
        paintSlots[si].preset = (paintSlots[si].preset%#PRESET_NAMES)+1
        paintSlots[si].presetLabel:setValue("Preset: "..PRESET_NAMES[paintSlots[si].preset])
    end)
    UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
end
UILabel.new(borderSizer, "EXCLUDE SLOTS (no foliage where this group is)", TextAlignment.LEFT)
UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
for i=1,NUM_EXCLUDE do
    local ei = i
    local eRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, eRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 1)
    UILabel.new(eRow, string.format("Excl %d:", ei), TextAlignment.LEFT)
    local gRow = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, gRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 3)
    UIButton.new(gRow, "◀", function()
        excludeSlots[ei].groupIdx = ((excludeSlots[ei].groupIdx-2+NUM_GROUPS)%NUM_GROUPS)+1
        local g = GROUPS[excludeSlots[ei].groupIdx]
        excludeSlots[ei].groupLabel:setValue(g.name)
        print(string.format("[SW Foliage Mat] Excl %d → %s  (%s)", ei, g.name, g.members))
    end)
    local gLbl = UITextArea.new(gRow,
        GROUPS[excludeSlots[ei].groupIdx].name,
        TextAlignment.LEFT, false,true,200,22,-1,22, BorderDirection.NONE,0,0)
    excludeSlots[ei].groupLabel = gLbl
    UIButton.new(gRow, "▶", function()
        excludeSlots[ei].groupIdx = (excludeSlots[ei].groupIdx%NUM_GROUPS)+1
        local g = GROUPS[excludeSlots[ei].groupIdx]
        excludeSlots[ei].groupLabel:setValue(g.name)
        print(string.format("[SW Foliage Mat] Excl %d → %s  (%s)", ei, g.name, g.members))
    end)
    UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
end
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
print("\n[SW Foliage by Material] Ready — groups pre-loaded from map.i3d.")
print("Recommended setup for South Warwickshire:")
print("  Paint 1 → GRASS & FOREST  → GRASS & MEADOW")
print("  Paint 2 → GRAVEL MOSS     → FIELD MARGIN")
print("  Excl  1 → ASPHALT / ROAD")
print("  Excl  2 → GRAVEL / STONE")
print("  Excl  3 → ROCK / CONCRETE")
print("  Excl  4 → MUD DARK (cultivated soil)")
print("  Excl  5 → MUD TRACKS (freshly cultivated)")
print("  Excl  6 → MUD GRAVEL (farm track entrances)")
print("")
print("NOTE: grass01, forestLeaves01, grassClovers01 etc all share identical")
print("RGBA — they are indistinguishable at runtime. For WOODLAND FLOOR")
print("specifically, use sw_foliage_zone_painter_v2.lua with sw_forest_splines.i3d.")
print(string.format("\n%d material groups available.", NUM_GROUPS-1))
