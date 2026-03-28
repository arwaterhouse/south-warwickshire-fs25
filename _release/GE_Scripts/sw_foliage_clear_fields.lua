source("editorUtils.lua")
local CLEAR_SIGS = {
    { name="MUD TRACKS (cultivated)",  R=0.062, G=0.044, B=0.027, W=1.0, tol=0.012 },
    { name="MUD DARK (ploughed soil)", R=0.071, G=0.055, B=0.043, W=1.0, tol=0.012 },
    { name="MUD GRAVEL (farm track)",  R=0.176, G=0.153, B=0.133, W=1.0, tol=0.015 },
    { name="MUD LIGHT",                R=0.137, G=0.114, B=0.078, W=1.0, tol=0.015 },
    { name="MUD PEBBLES",              R=0.067, G=0.051, B=0.039, W=1.0, tol=0.012 },
    { name="MUD DARK PATCHY",          R=0.078, G=0.067, B=0.043, W=1.0, tol=0.012 },
    { name="MUD LEAVES",               R=0.082, G=0.075, B=0.027, W=1.0, tol=0.012 },
    { name="MUD TRACKS 2",             R=0.137, G=0.098, B=0.075, W=1.0, tol=0.015 },
    { name="ASPHALT / ROAD",           R=0.071, G=0.063, B=0.063, W=0.0, tol=0.012 },
    { name="GRAVEL / STONE",           R=0.157, G=0.141, B=0.122, W=0.0, tol=0.015 },
    { name="ROCK / CONCRETE",          R=0.220, G=0.212, B=0.196, W=0.0, tol=0.018 },
    { name="CONCRETE DIRT",            R=0.165, G=0.149, B=0.125, W=0.0, tol=0.015 },
    { name="ASPHALT DUSTY",            R=0.137, G=0.129, B=0.116, W=0.0, tol=0.015 },
    { name="ROCK FLOOR TILES",         R=0.208, G=0.184, B=0.165, W=0.0, tol=0.015 },
}
local FOLIAGE_PLANES = {
    { ft="decoFoliage",  nc=5 },
    { ft="forestPlants", nc=5 },
    { ft="meadow",       nc=5 },
    { ft="decoBush",     nc=4 },
}
local scanSpacing      = 1.5    -- metres between texture sample points for the partition scan
local TOTAL_PARTITIONS = 64
local eraseBrushRadius = 10.0   -- radius of the erase brush (metres)
local function getTerrainId()
    local scene = getRootNode()
    for i=0, getNumOfChildren(scene)-1 do
        local child = getChildAt(scene, i)
        if getName(child) == "terrain" then return child end
    end
    return nil
end
local function coloursMatch(R,G,B,W, sig)
    return math.abs(R-sig.R)<=sig.tol and math.abs(G-sig.G)<=sig.tol
       and math.abs(B-sig.B)<=sig.tol and math.abs(W-sig.W)<=sig.tol
end
local function isFieldTexture(R, G, B, W)
    for _, sig in ipairs(CLEAR_SIGS) do
        if coloursMatch(R,G,B,W, sig) then return true, sig.name end
    end
    return false, nil
end
local _planeCache = {}
local function getPlaneId(terrainId, ftName)
    if _planeCache[ftName] == nil then
        local id = getTerrainDataPlaneByName(terrainId, ftName)
        _planeCache[ftName] = (id ~= nil and id ~= 0) and id or 0
        if _planeCache[ftName] == 0 then
            print(string.format("[SW Clear Fields] WARNING: plane '%s' not found", ftName))
        end
    end
    return _planeCache[ftName]
end
local function eraseRect(terrainId, x1, z1, x2, z2)
    for _, p in ipairs(FOLIAGE_PLANES) do
        local pid = getPlaneId(terrainId, p.ft)
        if pid ~= 0 then
            local mod = DensityMapModifier.new(pid, 0, p.nc)
            mod:setParallelogramWorldCoords(
                x1, z1,
                x2, z1,
                x1, z2,
                DensityCoordType.POINT_POINT_POINT)
            mod:executeSet(0)
        end
    end
end
local nextPartition = 1
local sessionErased = 0
local partitionLabel = nil
local function updatePartLabel()
    if partitionLabel then
        if nextPartition > TOTAL_PARTITIONS then
            partitionLabel:setValue(string.format(
                "Done! All %d partitions  |  %d points erased",
                TOTAL_PARTITIONS, sessionErased))
        else
            partitionLabel:setValue(string.format(
                "Next: partition %d/%d  |  erased=%d",
                nextPartition, TOTAL_PARTITIONS, sessionErased))
        end
    end
end
local function resetPartitions()
    nextPartition=1; sessionErased=0; _planeCache={}
    print("[SW Clear Fields] Reset — partition counter back to 1.")
    updatePartLabel()
end
local function runNextPartition()
    if nextPartition > TOTAL_PARTITIONS then
        print("[SW Clear Fields] All partitions done. Click Reset to start over.")
        return
    end
    local terrainId = getTerrainId()
    if terrainId == nil then print("[SW Clear Fields] ERROR: terrain not found"); return end
    local p           = nextPartition
    local terrainSize = getTerrainSize(terrainId)
    local halfSize    = terrainSize / 2
    local numSec      = math.sqrt(TOTAL_PARTITIONS)
    local secSize     = terrainSize / numSec
    local col    = ((p-1) % numSec)
    local row    = math.floor((p-1) / numSec)
    local xStart = -halfSize + col*secSize
    local zStart = -halfSize + row*secSize
    local xEnd   = xStart+secSize
    local zEnd   = zStart+secSize
    local erased = 0
    local texMatches = 0
    local z = zStart
    while z <= zEnd do
        local spanX1 = nil   -- start of current matching run on this Z row
        local x = xStart
        while x <= xEnd + scanSpacing * 0.1 do   -- small epsilon avoids float drift
            local inSpan = false
            if x <= xEnd then
                local R,G,B,W = getTerrainAttributesAtWorldPos(
                    terrainId, x, 300, z, true,true,true,true,false)
                if isFieldTexture(R,G,B,W) then
                    texMatches = texMatches + 1
                    inSpan = true
                end
            end
            if inSpan then
                if not spanX1 then spanX1 = x end   -- open a new span
            else
                if spanX1 then
                    local spanX2 = x - scanSpacing
                    eraseRect(terrainId,
                        spanX1 - scanSpacing * 0.5, z - scanSpacing * 0.5,
                        spanX2 + scanSpacing * 0.5, z + scanSpacing * 0.5)
                    erased = erased + 1
                    spanX1 = nil
                end
            end
            x = x + scanSpacing
        end
        z = z + scanSpacing
    end
    if texMatches == 0 then
        print(string.format(
            "[SW Clear Fields] Partition %d/%d — WARNING: 0 texture matches found. " ..
            "Check that CLEAR_SIGS values match your terrain textures.",
            p, TOTAL_PARTITIONS))
    end
    sessionErased = sessionErased + erased
    print(string.format(
        "[SW Clear Fields] Partition %d/%d — %d texture matches → %d span(s) erased  (session total: %d)",
        p, TOTAL_PARTITIONS, texMatches, erased, sessionErased))
    nextPartition = nextPartition + 1
    updatePartLabel()
    if nextPartition > TOTAL_PARTITIONS then
        print(string.format("[SW Clear Fields] ✓ Complete! %d foliage points erased from field/road surfaces.",
            sessionErased))
    end
end
local function eraseHere()
    local sel = getSelection(0)
    if sel == nil or sel == 0 then
        print("[SW Clear Fields] Nothing selected — select a node at the spot to erase.")
        return
    end
    local terrainId = getTerrainId()
    if terrainId == nil then print("[SW Clear Fields] ERROR: terrain not found"); return end
    local cx, cy, cz = getWorldTranslation(sel)
    local r = eraseBrushRadius
    eraseRect(terrainId, cx - r, cz - r, cx + r, cz + r)
    print(string.format("[SW Clear Fields] Erased foliage in %.1fm radius @ (%.1f, %.1f)",
        r, cx, cz))
end
local frameSizer  = UIRowLayoutSizer.new()
local window      = UIWindow.new(frameSizer, "SW Foliage Clear Fields")
local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer, -1,-1,-1,-1, BorderDirection.ALL, 8)
UILabel.new(borderSizer,
    "MODE 1 — ERASE BY TEXTURE\n"..
    "Scans map partition by partition and removes ALL\n"..
    "foliage from field/cultivated/road terrain textures.",
    TextAlignment.LEFT)
UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 4)
local progRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, progRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
partitionLabel = UITextArea.new(progRow,
    "Next: partition 1/64  |  erased=0",
    TextAlignment.LEFT, false,true,-1,22,-1,22, BorderDirection.NONE,0,0)
local runRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, runRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
UIButton.new(runRow, "Erase Next Partition", runNextPartition)
local rstRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, rstRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 6)
UIButton.new(rstRow, "Reset (start over)", resetPartitions)
UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 4)
UILabel.new(borderSizer,
    "MODE 2 — MANUAL ERASE BRUSH\n"..
    "Select a node at the problem spot,\n"..
    "set radius, click Erase Here.",
    TextAlignment.LEFT)
UIHorizontalLine.new(borderSizer, -1,-1,-1,-1, BorderDirection.BOTTOM, 4)
local rCol = UIColumnLayoutSizer.new()
UIPanel.new(borderSizer, rCol, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
UILabel.new(rCol, "Erase brush radius (m):", TextAlignment.LEFT)
local rSlider = UIFloatSlider.new(rCol, eraseBrushRadius, 1.0, 50.0, 1.0, 50.0)
rSlider:setOnChangeCallback(function(v) eraseBrushRadius=v end)
local ebRow = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, ebRow, -1,-1,-1,-1, BorderDirection.BOTTOM, 2)
UIButton.new(ebRow, "Erase Here  (at selected node)", eraseHere)
window:showWindow()
print("\n[SW Foliage Clear Fields] Ready.")
print("Textures that will be cleared:")
for _, sig in ipairs(CLEAR_SIGS) do
    print(string.format("  %-30s R=%.3f G=%.3f B=%.3f W=%.1f  tol=%.3f",
        sig.name, sig.R, sig.G, sig.B, sig.W, sig.tol))
end
print("")
print("MODE 1: Click 'Erase Next Partition' 64 times to clean the whole map.")
print("MODE 2: Select a node over any problem area, set radius, click Erase Here.")
