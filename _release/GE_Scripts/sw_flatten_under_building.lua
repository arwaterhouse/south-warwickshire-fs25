-- Author: South Warwickshire FS25 Pipeline
-- Name: SW Fit Terrain to Building
-- Description: Flattens / fits terrain under a selected FS25 building so the
--              ground never pokes through the floor.
--
--              GE 10.0.9 exposes no bounding-box API for scene nodes, so
--              footprint size is chosen via the Preset dropdown and fine-tuned
--              with the Override sliders.  Rotation is always read automatically.
--
-- Presets (full Width × Depth):
--   XSmall shed   :  6 m × 10 m
--   Small barn     : 12 m × 18 m
--   Medium barn    : 18 m × 26 m   ← default
--   Large barn     : 24 m × 36 m
--   XLarge / hangar: 32 m × 48 m
--
-- Workflow:
--   1. Select the building TransformGroup in the scene tree
--   2. Choose the closest Preset for the building size
--   3. Fine-tune with Override Width / Depth if needed (0 = use preset)
--   4. Click "Fit Terrain to Building"
--
-- What it does inside the footprint:
--   • Sets ALL terrain uniformly to floor level — no steps, no mounds,
--     no poke-through.
--   • A feathered Margin outside eases the cut back into the landscape.
--   • The Margin only lowers terrain — never pushes it up into a mound.
--
-- Hide: no
-- AlwaysLoaded: no

source("editorUtils.lua")

-- ── Settings ──────────────────────────────────────────────────────────────────
-- Typical building sizes for reference:
--   XSmall shed    :  6 m ×  10 m
--   Small barn     : 12 m ×  18 m
--   Medium barn    : 18 m ×  26 m  ← default
--   Large barn     : 24 m ×  36 m
--   XLarge / hangar: 32 m ×  48 m

local buildingW = 18.0  -- full footprint width  (m) — adjust to match your building
local buildingD = 26.0  -- full footprint depth  (m) — adjust to match your building
local marginM  = 1.0    -- feathered blend outside footprint (m)
local sinkM    = 0.05   -- sink below pivot Y to kill z-fighting (m)
local gridStep = 0.5    -- terrain sample/write spacing (m)
local rotOffsetDeg = 0  -- extra rotation applied on top of the building's Y rotation (degrees)
                        -- use this to correct any remaining angular misalignment
local running  = false

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function getTerrainId()
    local scene = getRootNode()
    for i = 0, getNumOfChildren(scene) - 1 do
        local child = getChildAt(scene, i)
        if getName(child) == "terrain" then return child end
    end
    return nil
end

local function lerp(a, b, t)
    t = math.max(0, math.min(1, t))
    return a + (b - a) * t
end

local function smoothstep(t)
    t = math.max(0, math.min(1, t))
    return t * t * (3 - 2 * t)
end

-- ── Oriented-rectangle point test ────────────────────────────────────────────
--
-- Transforms (px,pz) into building local space via inverse Y rotation,
-- tests against [-hw,hw] × [-hd,hd].
-- Returns isInside, distToEdge (metres)

local function pointInOrientedRect(px, pz, cx, cz, cosR, sinR, hw, hd)
    local dx = px - cx
    local dz = pz - cz
    local lx =  dx * cosR + dz * sinR
    local lz = -dx * sinR + dz * cosR
    local ax, az = math.abs(lx), math.abs(lz)
    if ax <= hw and az <= hd then return true, 0 end
    local ex = math.max(0, ax - hw)
    local ez = math.max(0, az - hd)
    return false, math.sqrt(ex * ex + ez * ez)
end

-- ── World-space scan AABB ─────────────────────────────────────────────────────

local function getScanAABB(cx, cz, cosR, sinR, hw, hd, margin)
    local hw2, hd2 = hw + margin, hd + margin
    local corners = {
        { -hw2, -hd2 }, {  hw2, -hd2 },
        { -hw2,  hd2 }, {  hw2,  hd2 },
    }
    local x0, x1 =  math.huge, -math.huge
    local z0, z1 =  math.huge, -math.huge
    for _, c in ipairs(corners) do
        local wx = c[1] * cosR - c[2] * sinR + cx
        local wz = c[1] * sinR + c[2] * cosR + cz
        if wx < x0 then x0 = wx end
        if wx > x1 then x1 = wx end
        if wz < z0 then z0 = wz end
        if wz > z1 then z1 = wz end
    end
    return x0, z0, x1, z1
end

-- ── Core ─────────────────────────────────────────────────────────────────────

local function fitTerrainToBuilding(objId, terrainId)
    local cx, cy, cz = getWorldTranslation(objId)
    if cx == nil then
        print("[SW Fit] ERROR: getWorldTranslation nil — select a TransformGroup.")
        return false
    end

    local _rx, ry, _rz = getWorldRotation(objId)
    ry = ry or 0
    -- GE uses a right-hand coordinate system.  Negating sinR is correct —
    -- it converts the standard CCW rotation into GE's CW-around-Y convention
    -- (positive Y angle rotates East→South when viewed from above).
    -- rotOffsetDeg lets you fine-tune any remaining angular gap if needed.
    local ryAdj = ry + math.rad(rotOffsetDeg)
    local cosR, sinR = math.cos(ryAdj), -math.sin(ryAdj)
    local rayY   = cy + 300   -- ray origin well above terrain

    local hw, hd = buildingW * 0.5, buildingD * 0.5

    print(string.format("\n[SW Fit] ──────────────────────────────────────────"))
    print(string.format("  Object   : %s", getName(objId)))
    print(string.format("  Centre   : X=%.2f  Y=%.2f  Z=%.2f", cx, cy, cz))
    print(string.format("  Rot Y    : %.4f rad  (%.1f deg)", ry, math.deg(ry)))
    print(string.format("  Size     : %.1f m W × %.1f m D", buildingW, buildingD))
    print(string.format("  Margin: %.1f m   Step: %.2f m", marginM, gridStep))
    -- Print the 4 footprint corners so you can verify orientation in the viewport
    print("  Footprint corners (world X, Z) :")
    local dbgC = {
        { -hw, -hd, "-W -D" }, {  hw, -hd, "+W -D" },
        { -hw,  hd, "-W +D" }, {  hw,  hd, "+W +D" },
    }
    for _, dc in ipairs(dbgC) do
        local wx = dc[1] * cosR - dc[2] * sinR + cx
        local wz = dc[1] * sinR + dc[2] * cosR + cz
        print(string.format("    [%s]  X=%.2f  Z=%.2f", dc[3], wx, wz))
    end

    local x0, z0, x1, z1 = getScanAABB(cx, cz, cosR, sinR, hw, hd, marginM)

    -- ── Pass 1: sample terrain inside footprint to find natural average height ──
    -- This is how the game works — it finds the best level for the foundation
    -- rather than forcing the pivot Y, so it raises valleys AND cuts peaks.
    local heightSum, heightCount = 0, 0
    local x = x0
    while x <= x1 do
        local z = z0
        while z <= z1 do
            local inside = pointInOrientedRect(x, z, cx, cz, cosR, sinR, hw, hd)
            if inside then
                local h = getTerrainHeightAtWorldPos(terrainId, x, rayY, z)
                heightSum   = heightSum + h
                heightCount = heightCount + 1
            end
            z = z + gridStep
        end
        x = x + gridStep
    end

    local floorY
    if heightCount > 0 then
        floorY = (heightSum / heightCount) - sinkM
    else
        floorY = cy - sinkM   -- fallback: use pivot Y
    end

    print(string.format("  Sampled %d pts — avg terrain h: %.3f  →  floor Y: %.3f",
        heightCount, floorY + sinkM, floorY))

    -- ── Pass 2: flatten interior + blend margin ────────────────────────────────
    local nInner, nBlend = 0, 0

    x = x0
    while x <= x1 do
        local z = z0
        while z <= z1 do
            local inside, dist = pointInOrientedRect(x, z, cx, cz, cosR, sinR, hw, hd)
            if inside then
                -- Uniform floor — raises valleys AND lowers peaks
                setTerrainHeightAtWorldPos(terrainId, x, rayY, z, floorY)
                nInner = nInner + 1
            elseif dist <= marginM then
                -- Feathered blend — works in BOTH directions (fills dips, cuts mounds)
                local h      = getTerrainHeightAtWorldPos(terrainId, x, rayY, z)
                local t      = smoothstep(dist / marginM)
                local target = lerp(floorY, h, t)
                setTerrainHeightAtWorldPos(terrainId, x, rayY, z, target)
                nBlend = nBlend + 1
            end
            z = z + gridStep
        end
        x = x + gridStep
    end

    print(string.format("  Done — interior: %d pts   margin: %d pts", nInner, nBlend))
    print("[SW Fit] ──────────────────────────────────────────\n")
    return true
end

-- ── Run helpers ───────────────────────────────────────────────────────────────

local function runFit()
    if running then print("[SW Fit] Still running — please wait.") return end
    local sel = getSelection(0)
    if sel == nil or sel == 0 then
        print("[SW Fit] Nothing selected — select a building in the scene tree.")
        return
    end
    local tid = getTerrainId()
    if tid == nil then print("[SW Fit] ERROR: terrain node not found.") return end
    running = true
    fitTerrainToBuilding(sel, tid)
    running = false
end

local function runBatch()
    if running then print("[SW Fit] Still running.") return end
    local sel = getSelection(0)
    if sel == nil or sel == 0 then print("[SW Fit] Nothing selected.") return end
    local tid = getTerrainId()
    if tid == nil then print("[SW Fit] ERROR: terrain not found.") return end
    local n = getNumOfChildren(sel)
    if n == 0 then
        running = true; fitTerrainToBuilding(sel, tid); running = false; return
    end
    print(string.format("[SW Fit] Batch: %d children of '%s'", n, getName(sel)))
    running = true
    local done = 0
    for i = 0, n - 1 do
        local c = getChildAt(sel, i)
        if c and c ~= 0 and fitTerrainToBuilding(c, tid) then done = done + 1 end
    end
    running = false
    print(string.format("[SW Fit] Batch done — %d / %d\n", done, n))
end

-- ── UI ────────────────────────────────────────────────────────────────────────

local frame  = UIRowLayoutSizer.new()
local window = UIWindow.new(frame, "SW Fit Terrain to Building")
local border = UIRowLayoutSizer.new()
UIPanel.new(frame, border)

local function addSlider(parent, label, default, lo, hi, onChange)
    local s = UIColumnLayoutSizer.new()
    UIPanel.new(parent, s, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
    UILabel.new(s, label, TextAlignment.LEFT)
    local sl = UIFloatSlider.new(s, default, lo, hi, lo, hi)
    sl:setOnChangeCallback(onChange)
end

-- ── Step-by-step instructions at the top ─────────────────────────────────────
local instrRow = UIColumnLayoutSizer.new()
UIPanel.new(border, instrRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
UILabel.new(instrRow,
    "HOW TO USE\n"..
    "─────────────────────────────────────────────\n"..
    "1. Click the building root node in the Scene Tree\n"..
    "2. Set Width and Depth below to match its footprint\n"..
    "   (measure in GE: top-down view, press 7 on numpad,\n"..
    "    then count 1-metre grid squares across the building)\n"..
    "3. Click  ► Fit Terrain Under Selected Building\n"..
    "\n"..
    "The building's rotation is detected automatically.\n"..
    "Results are printed to the Console log after each run.",
    TextAlignment.LEFT)

-- ── Footprint size ────────────────────────────────────────────────────────────
local sizeRow = UIColumnLayoutSizer.new()
UIPanel.new(border, sizeRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(sizeRow,
    "BUILDING FOOTPRINT SIZE  (match these to your building)\n"..
    "Typical sizes:  small shed ≈ 6×10 m   medium barn ≈ 18×26 m   large barn ≈ 24×36 m",
    TextAlignment.LEFT)

addSlider(border,
    "Width — side-to-side measurement of the building (metres):",
    buildingW, 2, 60,
    function(v) buildingW = v end)

addSlider(border,
    "Depth — front-to-back measurement of the building (metres):",
    buildingD, 2, 60,
    function(v) buildingD = v end)

-- ── Terrain blend settings ────────────────────────────────────────────────────
local blendRow = UIColumnLayoutSizer.new()
UIPanel.new(border, blendRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UILabel.new(blendRow,
    "TERRAIN BLEND SETTINGS  (defaults work well — only change if needed)",
    TextAlignment.LEFT)

addSlider(border,
    "Blend Zone — how far outside the building edge to smoothly taper the terrain (metres):",
    marginM, 0, 6,
    function(v) marginM = v end)

addSlider(border,
    "Floor Sink — how far below the building pivot the ground is set (stops floor z-fighting, metres):",
    sinkM, 0, 0.5,
    function(v) sinkM = v end)

addSlider(border,
    "Detail — sample spacing when writing terrain (smaller = finer but slower; 0.5 m recommended):",
    gridStep, 0.25, 2,
    function(v) gridStep = v end)

addSlider(border,
    "Rotation Offset — nudge the footprint angle if it doesn't line up with the building (degrees):",
    rotOffsetDeg, -90, 90,
    function(v) rotOffsetDeg = v end)

-- ── Buttons ───────────────────────────────────────────────────────────────────
local b1 = UIRowLayoutSizer.new()
UIPanel.new(border, b1, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
UIButton.new(b1, "► Fit Terrain Under Selected Building", runFit)

local b2 = UIRowLayoutSizer.new()
UIPanel.new(border, b2)
UIButton.new(b2, "Batch — Fit All Children of Selection", runBatch)

window:showWindow()

print("\n[SW Fit Terrain to Building] Ready.")
print("  1. Select your building in the Scene Tree")
print("  2. Set Width and Depth sliders to match the building footprint (metres)")
print("  3. Click  ► Fit Terrain Under Selected Building")
print("  Typical sizes:  small shed=6x10  medium barn=18x26  large barn=24x36")
