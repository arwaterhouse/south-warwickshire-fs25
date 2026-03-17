-- Author: FSG Modding
-- Name: FS25 - Align Childs to Terrain v2
-- Description: Select a transform and this will go through all of the transforms within that transform and set them to the terrain height it not already.
-- Icon:
-- Hide: no
-- Date: 1-11-25

local transformCount = 0
local totalCount = 0

print("Processing, this may take a while...")

local mSceneID = getRootNode()
local mTerrainID = 0
for i = 0, getNumOfChildren(mSceneID) - 1 do
    local mID = getChildAt(mSceneID, i)
    if (getName(mID) == "terrain") then
        mTerrainID = mID
        break
    end
end

if (getNumSelected() == 0) then
    printError("Error: Select one or more splines.")
    return false
end

local selectedTransform = getSelection(0)

local function snapToTerrain(nodeId)
    local x, y, z = getWorldTranslation(nodeId)
    local terrainHeight = getTerrainHeightAtWorldPos(mTerrainID, x, y, z)
    if terrainHeight ~= nil and terrainHeight ~= 0 then
        if math.abs(y - terrainHeight) > 0.001 then
            setWorldTranslation(nodeId, x, terrainHeight, z)
            transformCount = transformCount + 1
        end
        totalCount = totalCount + 1
    end
end

local function floatFix(parentTransformNodeId)
    if parentTransformNodeId == nil then return end
    local numOfChildren = getNumOfChildren(parentTransformNodeId)
    for p = 0, numOfChildren - 1 do
        local childNodeId = getChildAt(parentTransformNodeId, p)
        local childName   = getName(childNodeId)
        local numGrandchildren = getNumOfChildren(childNodeId)

        if numGrandchildren > 0 then
            local grandchildName = getName(getChildAt(childNodeId, 0))
            if grandchildName == "LOD0" then
                -- Original FSG structure: snap the wrapper transform
                snapToTerrain(childNodeId)
            else
                -- Recurse deeper
                floatFix(childNodeId)
            end
        else
            -- Leaf node — this is a directly placed clone (e.g. hedge10m)
            -- Snap it directly
            snapToTerrain(childNodeId)
        end
    end
end

floatFix(selectedTransform)

print("Fixed Transform Count:" .. transformCount)
print("Total Transform Count:" .. totalCount)
