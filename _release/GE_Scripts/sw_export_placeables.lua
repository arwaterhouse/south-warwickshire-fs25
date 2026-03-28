source("editorUtils.lua")
local PLACEHOLDERS_NODE = "placeablePlaceholders"
local ATTR_FILE         = "placeableFile"
local ATTR_UID          = "uniqueId"
local I3D_TO_FILE = {
    ["7Bar"]                = "placeables/FS25_RDM_BritishFieldGates/7Bar.xml",
    ["FS25_GrainMachineShed"] = "placeables/FS25_UK_Grain_MachineryShed/ukGrainMachineryShed.xml",
    ["FS25_MachineShed_3Bay"] = "placeables/FS25_UK_MachineShed_3Bay/UK_MachineShed_3Bay.xml",
    ["FS25_UK_BaleShed"]    = "placeables/FS25_UK_BaleShed/FS25_UK_BaleShed.xml",
    ["FS25_UK_BaleShedAL"]  = "placeables/FS25_UK_BaleShed/UKBaleShedAL.xml",
    ["FS25_UK_CattleShed"]  = "placeables/FS25_UK_CattleShed/FS25_UK_CattleShed.xml",
    ["FS25_UK_LargeBeefShed"] = "placeables/FS25_UK_LargeBeefShed/FS25_UK_LargeBeefShed.xml",
    ["FS25_UK_machineShed"] = "placeables/FS25_UK_Shed/ukShed.xml",
    ["GrainShed"]           = "placeables/FS25_OldEnglishShed/grain_shed.xml",
    ["biggreenshed"]        = "placeables/FS25_britishshedpack/biggreenshed.xml",
    ["britishbaleshed"]     = "placeables/FS22_britishbaleshed/britishbaleshed.xml",
    ["britishhedge"]        = "placeables/FS25_britishshedpack/britishhedge.xml",
    ["grainShed"]           = "placeables/FS25_UkStyleGrainShed/grainShed.xml",
    ["greemopenbarn"]       = "placeables/FS25_britishshedpack/greenopenbarn.xml",
    ["hayshed"]             = "placeables/FS25_britishshedpack/hayshed.xml",
    ["machineShed02"]       = "placeables/FS25_UK_MachineryShed/placeables/machineShed02/machineShed02.xml",
    ["shed01"]              = "placeables/FS25_RDM_BritishGrainSheds/shed01.xml",
    ["shed01UB"]            = "placeables/FS25_RDM_BritishGrainSheds/shed01UB.xml",
    ["shed01UB_B"]          = "placeables/FS25_RDM_BritishGrainSheds/shed01UB_B.xml",
    ["shed01_B"]            = "placeables/FS25_RDM_BritishGrainSheds/shed01_B.xml",
    ["shed02"]              = "placeables/FS25_RDM_BritishGrainSheds/shed02.xml",
    ["shed02UB"]            = "placeables/FS25_RDM_BritishGrainSheds/shed02UB.xml",
    ["shed02UB_B"]          = "placeables/FS25_RDM_BritishGrainSheds/shed02UB_B.xml",
    ["shed02_B"]            = "placeables/FS25_RDM_BritishGrainSheds/shed02_B.xml",
    ["shed03R"]             = "placeables/FS25_RDM_BritishGrainSheds/shed03.xml",
    ["shed03RUB"]           = "placeables/FS25_RDM_BritishGrainSheds/shed03RUB.xml",
    ["shed04"]              = "placeables/FS25_RDM_BritishGrainSheds/shed04.xml",
    ["sheepGoatBarn"]       = "placeables/FS25_englishStyleSheepBarn/sheepGoatBarn.xml",
    ["storageShed1"]        = "placeables/FS22_British_Storage_Shed/storageShed1.xml",
}
local function getMapPath()
    local fullPath = getSceneFilename()
    if not fullPath then return nil end
    return fullPath:match("(.*[/\\])")
end
local function isPlaceableNode(node)
    local uid = getUserAttribute(node, ATTR_UID)
    return uid ~= nil
end
local function getFilenameForNode(node)
    local attr = getUserAttribute(node, ATTR_FILE)
    if attr and attr ~= "" then
        return attr, "attr"
    end
    local nodeName = getName(node)
    local found = I3D_TO_FILE[nodeName]
    if found then
        return found, "lookup"
    end
    return nil, "unknown"
end
local function collectPlaceableNodes(node, results)
    if isPlaceableNode(node) then
        table.insert(results, node)
        return
    end
    for i = 0, getNumOfChildren(node) - 1 do
        collectPlaceableNodes(getChildAt(node, i), results)
    end
end
local function runExport()
    local root   = getRootNode()
    local phNode = nil
    for i = 0, getNumOfChildren(root) - 1 do
        local c = getChildAt(root, i)
        if getName(c) == PLACEHOLDERS_NODE then
            phNode = c
            break
        end
    end
    if not phNode then
        printError("[SW Export] 'placeablePlaceholders' node not found in scene.")
        print("[SW Export] Import your placeables first using PlaceableImporter.")
        return
    end
    local nodes = {}
    collectPlaceableNodes(phNode, nodes)
    if #nodes == 0 then
        printError("[SW Export] No placeable objects found under placeablePlaceholders.")
        return
    end
    print(string.format("\n[SW Export] ──────────────────────────────────────────"))
    print(string.format("[SW Export] Found %d objects — resolving filenames...", #nodes))
    local lines   = {}
    local skipped = {}
    local modCounts = {}
    local id = 1
    table.insert(lines, '<?xml version="1.0" encoding="utf-8" standalone="no" ?>')
    table.insert(lines, '<placeables version="2"')
    table.insert(lines, '    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"')
    table.insert(lines, '    xsi:noNamespaceSchemaLocation="../../../../shared/xml/schema/savegame_placeables.xsd">')
    for _, node in ipairs(nodes) do
        local filename, src = getFilenameForNode(node)
        if not filename then
            table.insert(skipped, getName(node))
        else
            local px, py, pz = getWorldTranslation(node)
            local rx, ry, rz = getWorldRotation(node)
            rx, ry, rz = math.deg(rx), math.deg(ry), math.deg(rz)
            table.insert(lines, string.format(
                '    <placeable filename="%s" position="%.3f %.3f %.3f" rotation="%.2f %.2f %.2f" id="%d"/>',
                filename, px, py, pz, rx, ry, rz, id
            ))
            local modName = filename:match("placeables/([^/]+)/") or "unknown"
            modCounts[modName] = (modCounts[modName] or 0) + 1
            local tag = src == "attr" and "[A]" or "[L]"
            print(string.format("  %s [%d] %-35s  X=%7.1f  Z=%7.1f  rotY=%6.1f°",
                tag, id, filename:match("[^/]+$") or filename, px, pz, ry))
            id = id + 1
        end
    end
    table.insert(lines, '</placeables>')
    local mapPath = getMapPath()
    if not mapPath then
        printError("[SW Export] Could not determine map path.")
        return
    end
    local xmlPath = mapPath .. "config/placeables.xml"
    local f = io.open(xmlPath, "w")
    if not f then
        printError("[SW Export] Could not write to: " .. xmlPath)
        return
    end
    for _, line in ipairs(lines) do f:write(line .. "\n") end
    f:close()
    print(string.format("[SW Export] ──────────────────────────────────────────"))
    print(string.format("[SW Export] Written %d entries to placeables.xml", id - 1))
    print("[SW Export] Breakdown by mod:")
    local sortedMods = {}
    for mod, count in pairs(modCounts) do
        table.insert(sortedMods, { mod = mod, count = count })
    end
    table.sort(sortedMods, function(a, b) return a.mod < b.mod end)
    for _, e in ipairs(sortedMods) do
        print(string.format("    %-45s  x%d", e.mod, e.count))
    end
    if #skipped > 0 then
        print(string.format("[SW Export] WARNING: %d node(s) skipped — node name not in lookup table:", #skipped))
        for _, n in ipairs(skipped) do
            print("    - " .. n)
        end
        print("[SW Export] Add these to the I3D_TO_FILE table in the script.")
    end
    print("[SW Export] [A]=attribute  [L]=name lookup")
    print("[SW Export] ──────────────────────────────────────────\n")
end
local frame  = UIRowLayoutSizer.new()
local window = UIWindow.new(frame, "SW Export Placeables to XML")
local border = UIRowLayoutSizer.new()
UIPanel.new(frame, border, -1, -1, 380, -1, BorderDirection.ALL, 10, 1)
UILabel.new(border,
    "HOW TO USE\n" ..
    "─────────────────────────────────────────────\n" ..
    "1. Import placeables using PlaceableImporter\n" ..
    "2. Copy and arrange buildings freely in GE\n" ..
    "3. Click Export — placeables.xml is rewritten\n" ..
    "   with every building and its current position\n\n" ..
    "Works with existing imports — no reimport needed.\n" ..
    "[A] = identified via attribute  [L] = name lookup",
    TextAlignment.LEFT)
UIHorizontalLine.new(border, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
local btnRow = UIRowLayoutSizer.new()
UIPanel.new(border, btnRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
local exportBtn = UIButton.new(btnRow, "► Export All Placeables to XML", runExport)
exportBtn:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
window:showWindow()
print("\n[SW Export Placeables] Ready — click Export to write placeables.xml.")
print("  Works with existing imports and any copies made in GE.")
