source("editorUtils.lua")
local PLACEHOLDERS_NODE = "placeablePlaceholders"
local OBJECTS_NODE      = "Objects"
local MOD_ROOT          = "modPlaceholders/"
local ATTR_UID          = "uniqueId"
local ATTR_FILE         = "placeableFile"
local CATALOGUE = {
    {
        mod = "FS22_British_Storage_Shed",
        variants = {
            { label = "Storage Shed",         xml = "storageShed1.xml",                              i3d = "storageShed1.i3d" },
        },
    },
    {
        mod = "FS22_britishbaleshed",
        variants = {
            { label = "British Bale Shed",    xml = "britishbaleshed.xml",                           i3d = "britishbaleshed.i3d" },
        },
    },
    {
        mod = "FS25_OldEnglishShed",
        variants = {
            { label = "Grain Shed",           xml = "grain_shed.xml",                                i3d = "GrainShed.i3d" },
        },
    },
    {
        mod = "FS25_RDM_BritishFieldGates",
        variants = {
            { label = "7 Bar Gate",           xml = "7Bar.xml",                                      i3d = "7Bar.i3d" },
        },
    },
    {
        mod = "FS25_RDM_BritishGrainSheds",
        variants = {
            { label = "Shed 01",              xml = "shed01.xml",                                    i3d = "shed01.i3d" },
            { label = "Shed 01 UB",           xml = "shed01UB.xml",                                  i3d = "shed01UB.i3d" },
            { label = "Shed 01 UB B",         xml = "shed01UB_B.xml",                                i3d = "shed01UB_B.i3d" },
            { label = "Shed 01 B",            xml = "shed01_B.xml",                                  i3d = "shed01_B.i3d" },
            { label = "Shed 02",              xml = "shed02.xml",                                    i3d = "shed02.i3d" },
            { label = "Shed 02 UB",           xml = "shed02UB.xml",                                  i3d = "shed02UB.i3d" },
            { label = "Shed 02 UB B",         xml = "shed02UB_B.xml",                                i3d = "shed02UB_B.i3d" },
            { label = "Shed 02 B",            xml = "shed02_B.xml",                                  i3d = "shed02_B.i3d" },
            { label = "Shed 03R",             xml = "shed03.xml",                                    i3d = "shed03R.i3d" },
            { label = "Shed 03R UB",          xml = "shed03RUB.xml",                                 i3d = "shed03RUB.i3d" },
            { label = "Shed 04",              xml = "shed04.xml",                                    i3d = "shed04.i3d" },
        },
    },
    {
        mod = "FS25_UK_BaleShed",
        variants = {
            { label = "UK Bale Shed",         xml = "FS25_UK_BaleShed.xml",                          i3d = "FS25_UK_BaleShed.i3d" },
            { label = "UK Bale Shed AL",      xml = "UKBaleShedAL.xml",                              i3d = "FS25_UK_BaleShedAL.i3d" },
        },
    },
    {
        mod = "FS25_UK_CattleShed",
        variants = {
            { label = "UK Cattle Shed",       xml = "FS25_UK_CattleShed.xml",                        i3d = "FS25_UK_CattleShed.i3d" },
        },
    },
    {
        mod = "FS25_UK_Grain_MachineryShed",
        variants = {
            { label = "UK Grain Machinery",   xml = "ukGrainMachineryShed.xml",                      i3d = "FS25_GrainMachineShed.i3d" },
        },
    },
    {
        mod = "FS25_UK_LargeBeefShed",
        variants = {
            { label = "UK Large Beef Shed",   xml = "FS25_UK_LargeBeefShed.xml",                     i3d = "FS25_UK_LargeBeefShed.i3d" },
        },
    },
    {
        mod = "FS25_UK_MachineShed_3Bay",
        variants = {
            { label = "Machine Shed 3-Bay",   xml = "UK_MachineShed_3Bay.xml",                       i3d = "FS25_MachineShed_3Bay.i3d" },
        },
    },
    {
        mod = "FS25_UK_MachineryShed",
        variants = {
            { label = "Machine Shed 02",      xml = "placeables/machineShed02/machineShed02.xml",    i3d = "placeables/machineShed02/machineShed02.i3d" },
        },
    },
    {
        mod = "FS25_UK_Shed",
        variants = {
            { label = "UK Machine Shed",      xml = "ukShed.xml",                                    i3d = "FS25_UK_machineShed.i3d" },
        },
    },
    {
        mod = "FS25_UkStyleGrainShed",
        variants = {
            { label = "UK Style Grain Shed",  xml = "grainShed.xml",                                 i3d = "grainShed.i3d" },
        },
    },
    {
        mod = "FS25_britishshedpack",
        variants = {
            { label = "Big Green Shed",       xml = "biggreenshed.xml",                              i3d = "biggreenshed.i3d" },
            { label = "British Hedge",        xml = "britishhedge.xml",                              i3d = "britishhedge.i3d" },
            { label = "Green Open Barn",      xml = "greenopenbarn.xml",                             i3d = "greemopenbarn.i3d" },
            { label = "Hay Shed",             xml = "hayshed.xml",                                   i3d = "hayshed.i3d" },
        },
    },
    {
        mod = "FS25_englishStyleSheepBarn",
        variants = {
            { label = "Sheep / Goat Barn",    xml = "sheepGoatBarn.xml",                             i3d = "sheepGoatBarn.i3d" },
        },
    },
}
local function getMapPath()
    local full = getSceneFilename()
    if not full then return nil end
    return full:match("(.*[/\\])")
end
local function getTerrainId()
    local root = getRootNode()
    for i = 0, getNumOfChildren(root) - 1 do
        local c = getChildAt(root, i)
        if getName(c) == "terrain" then return c end
    end
    return nil
end
local function findOrCreateChild(parentNode, name)
    for i = 0, getNumOfChildren(parentNode) - 1 do
        local c = getChildAt(parentNode, i)
        if getName(c) == name then return c end
    end
    local newNode = createTransformGroup(name)
    link(parentNode, newNode)
    return newNode
end
local function importVariant(modName, xmlFilename, i3dFilename)
    local mapPath = getMapPath()
    if not mapPath then
        printError("[SW Import] Could not determine map path — is a scene open?")
        return
    end
    local i3dPath = mapPath .. MOD_ROOT .. modName .. "/" .. i3dFilename
    local xmlPath = mapPath .. MOD_ROOT .. modName .. "/" .. xmlFilename   -- for reference only
    local relXmlPath = "placeables/" .. modName .. "/" .. xmlFilename
    print(string.format("\n[SW Import] ──────────────────────────────────────────"))
    print(string.format("[SW Import] Importing: %s", i3dFilename))
    print(string.format("  Mod       : %s", modName))
    print(string.format("  I3D path  : %s", i3dPath))
    if not fileExists(i3dPath) then
        printError("[SW Import] I3D file not found: " .. i3dPath)
        printError("[SW Import] Check that modPlaceholders folder is in the right place.")
        return
    end
    local rootNode = getRootNode()
    local phNode   = findOrCreateChild(rootNode, PLACEHOLDERS_NODE)
    local objNode  = findOrCreateChild(phNode,   OBJECTS_NODE)
    local modNode  = findOrCreateChild(objNode,  modName)
    local objectId = createI3DReference(i3dPath, false)
    if not objectId or objectId == 0 then
        printError("[SW Import] createI3DReference failed for: " .. i3dPath)
        return
    end
    link(modNode, objectId)
    local groundY = 0
    local tid = getTerrainId()
    if tid then
        groundY = getTerrainHeightAtWorldPos(tid, 0, 500, 0)
    end
    setTranslation(objectId, 0, groundY, 0)
    setRotation(objectId, 0, 0, 0)
    setUserAttribute(objectId, ATTR_UID,  3, "")
    setUserAttribute(objectId, ATTR_FILE, 3, relXmlPath)
    print(string.format("[SW Import] ✓ Imported: %s", getName(objectId)))
    print(string.format("  Placed at : X=0  Y=%.2f  Z=0  (world origin — move it now)", groundY))
    print(string.format("  Attribute : placeableFile = %s", relXmlPath))
    print("[SW Import] Move the object to its final position, then run:")
    print("            SW Export Placeables to XML  to update placeables.xml")
    print("[SW Import] ──────────────────────────────────────────\n")
end
local frame  = UIRowLayoutSizer.new()
local window = UIWindow.new(frame, "SW Import Mod")
local border = UIRowLayoutSizer.new()
UIPanel.new(frame, border, -1, -1, 420, -1, BorderDirection.ALL, 10, 1)
UILabel.new(border,
    "HOW TO USE\n" ..
    "─────────────────────────────────────────────\n" ..
    "1. Find the mod / variant below\n" ..
    "2. Click its  ► Import  button\n" ..
    "3. Move the new object to its position in GE\n" ..
    "4. Run  SW Export Placeables to XML\n\n" ..
    "Objects appear at world origin (0, ground, 0).\n" ..
    "Attributes are stamped so the exporter recognises them.",
    TextAlignment.LEFT)
UIHorizontalLine.new(border, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
local function addModSection(parent, entry)
    local hdrRow = UIRowLayoutSizer.new()
    UIPanel.new(parent, hdrRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 2)
    UILabel.new(hdrRow, "── " .. entry.mod .. " ──", TextAlignment.LEFT)
    local ROW_MAX = 3
    local btnRow  = nil
    for idx, v in ipairs(entry.variants) do
        if (idx - 1) % ROW_MAX == 0 then
            btnRow = UIRowLayoutSizer.new()
            UIPanel.new(parent, btnRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 4)
        end
        local modName    = entry.mod
        local xmlFile    = v.xml
        local i3dFile    = v.i3d
        local btnLabel   = "► " .. v.label
        UIButton.new(btnRow, btnLabel, function()
            importVariant(modName, xmlFile, i3dFile)
        end)
    end
end
for _, entry in ipairs(CATALOGUE) do
    addModSection(border, entry)
end
UIHorizontalLine.new(border, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
UILabel.new(border,
    "After importing, run  SW Export Placeables to XML\n" ..
    "to write all positions back to placeables.xml.",
    TextAlignment.LEFT)
window:showWindow()
print("\n[SW Import Mod] Ready — click any variant button to import it into the scene.")
print("  Objects are placed at world origin.  Move them, then run SW Export to save.")
