-- Author:TracMax, W_R, modelleicher
-- Name:Fence_Power_Placement_25
-- Description: places fences (wire and board) or power poles and wires along a spline
-- Icon:
-- Hide: no
-- AlwaysLoaded: no
-- Version 2 28-11-2024 Updated for ES25

choice ={"Deselected","Selected"}

local labelWidth = 240.0
local objectDistance = 0
local randomOrder = false
local randomFence = false
local E_wireNodesCnt = 0
local E_fenceWire = 0
local E_startWireLength = 0
local E_maxPosts = 0
local E_startPost = 0
local remFence = false

local scene = getRootNode()
local node = createTransformGroup("fence_powerObjects")
link(scene,node)
local wire_FenceNode = createTransformGroup("wire_FenceNode");
link(node,wire_FenceNode)
local fence_powerPlacement = createTransformGroup("fencePlacement");
link(node,fence_powerPlacement)
local postObject = createTransformGroup("postObject")
link(fence_powerPlacement,postObject)
local placedObjects = createTransformGroup("placedObjects")
link(fence_powerPlacement,placedObjects)

local function setObjectDistance(value)
    objectDistance = value
end

local function setRandomOrder(value)
    if value == 2 then randomOrder = true
    else randomOrder = false
  end
end   
local function setRandomFence(value)
    if value == 2 then randomFence = true
    else randomFence = false
  end
end   
local function setE_wireNodesCnt(value)
    E_wireNodesCnt = value
end
local function setE_startWireLength(value)
    E_startWireLength = value
end
local function setE_maxPosts(value)
    E_maxPosts = value
end
local function setE_startPost(value)
    E_startPost = value
end
local function setRemFence(value)
    if value == 2 then remFence = true
    else remFence = false  
  end 
end   

local function fencePlacement1()
fencePlacement(wire_FenceNode, postObject, placedObjects, objectDistance,  randomOrder, randomFence, easyFence, E_wireNodesCnt, E_fenceWire, E_startWireLength,  E_maxPosts, E_startPost, remFence)

end

local frameSizer = UIRowLayoutSizer.new()
local myFrame = UIWindow.new(frameSizer, "Fence/Power Line Placement")

local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer)

local rowSizer = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)

    local objDistSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objDistSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(objDistSliderSizer, "Set Post Distance ",false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local objDistSlider = UIFloatSlider.new(objDistSliderSizer, objectDistance, 0, 255, BorderDirection.NONE,0);
    objDistSlider:setOnChangeCallback(setObjectDistance)
    
     local randomOrderPanelSizer = UIColumnLayoutSizer.new()
    local randomOrderPanel      = UIPanel.new(rowSizer, randomOrderPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local randomOrderChoiceLabel      = UILabel.new(randomOrderPanelSizer, "Select Random Spline Order ", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local randomOrderChoice      = UIChoice.new(randomOrderPanelSizer, choice, 0, -1, 100, -1)
    randomOrderChoice:setOnChangeCallback(setRandomOrder)

    local randomFencePanelSizer = UIColumnLayoutSizer.new()
    local randomFencePanel      = UIPanel.new(rowSizer, randomFencePanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local randomFenceChoiceLabel      = UILabel.new(randomFencePanelSizer, "Select Random Wire/Board Placement ", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local randomFenceChoice      = UIChoice.new(randomFencePanelSizer, choice, 0, -1, 100, -1)
    randomFenceChoice:setOnChangeCallback(setRandomFence)

    local E_wireNodesCntSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, E_wireNodesCntSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(E_wireNodesCntSliderSizer, "Number of Wire/Board Nodes ", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local E_wireNodesCntSlider = UIFloatSlider.new(E_wireNodesCntSliderSizer, E_wireNodesCnt, 0, 255 );
    E_wireNodesCntSlider:setOnChangeCallback(setE_wireNodesCnt)

    local E_startWireLengthSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, E_startWireLengthSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(E_startWireLengthSliderSizer, "Wire/Fence Length ", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local E_startWireLengthSlider = UIFloatSlider.new(E_startWireLengthSliderSizer, E_startWireLength, 0, 255)
    E_startWireLengthSlider:setOnChangeCallback(setE_startWireLength)
    
    local E_maxPostsSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, E_maxPostsSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(E_maxPostsSliderSizer, "Maximum Posts ", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local E_maxPostsSlider = UIFloatSlider.new(E_maxPostsSliderSizer, E_maxPosts, 0, 255)
    E_maxPostsSlider:setOnChangeCallback(setE_maxPosts)

    local E_startPostSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, E_startPostSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(E_startPostSliderSizer, "Start Post      ", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local E_startPostSlider = UIFloatSlider.new(E_startPostSliderSizer, E_startPost, 0, 255)
    E_startPostSlider:setOnChangeCallback(setE_startPost)

     local remFencePanelSizer = UIColumnLayoutSizer.new()
    local remFencePanel      = UIPanel.new(rowSizer, remFencePanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local remFenceChoiceLabel      = UILabel.new(remFencePanelSizer, "Remove Fence/Power Line   ",false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local remFenceChoice      = UIChoice.new(remFencePanelSizer, choice, 0, -1, 100, -1)
    remFenceChoice:setOnChangeCallback(setRemFence)
    
    UIButton.new(rowSizer, "Create/Erase Fence/Power Line", fencePlacement1)  
 myFrame:showWindow()
 
function fencePlacement(wire_FenceNode, postObject, placedObjects, objectDistance,  randomOrder, randomFence, easyFence, E_wireNodesCnt, E_fenceWire, E_startWireLength,  E_maxPosts, E_startPost, remFence)

if remFence then fenceRem = false
local node = getSelection(0) --selection required for fence/power line deletion
if node == 0 or getName(node) ~= "fencePlacement" then
    print("ERROR: Please select 'fencePlacement' transform group!")
    return
end
local placedObjects = getChild(node,"placedObjects")
if placedObjects == 0 then
    print("ERROR: 'placedObjects' not present!")
    return
end
local ii = getNumOfChildren(placedObjects)
for i=ii-1,0,-1 do
    local myId = getChildAt(placedObjects,i)
    unlink(myId)
    delete(myId)
end

return end;

local node = getSelection(0)  --selection required for executing script
if node == 0 or getName(node) ~= "fencePlacement" then
    print("\nERROR: Please select 'fencePlacement transform")
    return nil	
end
--check Errors
if  objectDistance == 0 then print("\n ERROR Object Distance = 0 ") return end
if E_startWireLength == 0 then E_startWireLength = objectDistance 
print("\n ERROR Wire/Fence Length = 0 Defaulting to Set Post Distance Value") 
end
local E_fenceWireNode = wire_FenceNode 
          N_fenceWire = getNumOfChildren(E_fenceWireNode)
          if N_fenceWire <= 0 then print("\nERROR No Wire/Panel in the wire_FenceNode") 
          return nil
          end    
local pObjectNum =getNumOfChildren(postObject) 
            if pObjectNum <= 0 then print("ERROR: 'postObject' has no Poles/Posts")
return nil
end 
        for i= 0, pObjectNum -1 do
            pObjectChildNum = getNumOfChildren(getChildAt(postObject,i))
            pObjectName = getName(getChildAt(postObject,i))
            if pObjectChildNum < E_wireNodesCnt then print(string.format("\nERROR : Insufficient Wire/Board nodes object: %s", pObjectName))
return nil
end
end
local nID = 0
local mySpline = 0
local numChild = getNumOfChildren(node)
        for i = 0, numChild - 1 do
            local nID = getChildAt(node, i)
            local splineCheck = getHasClassId(nID, ClassIds.SHAPE) and getGeometry(nID) ~= 0 
            and getHasClassId(getGeometry(nID), ClassIds.SPLINE)
       if splineCheck then mySpline = nID 
            splineName = getName(nID)	  
            elseif not splineCheck and i == numChild-1 then
                print(string.format("\nERROR: Spline not found"))
return nil         
end
end

local myParent = getParent(node)
if myParent == 0 then
    print("ERROR: 'splinePlacement' has no parent (why ever?)!")
    return nil
end

local root = getRootNode();
for i = 0, getNumOfChildren(root) - 1 do
            local mID = getChildAt(root, i)
            if (getName(mID) == "terrain") then
                terrain = mID
                break
            end
        end

local xParent, yParent, zParent = getWorldTranslation(myParent)


local iObject = 0   
local splineLength = getSplineLength(mySpline)
local splinePos = 0 
if splinePos < 0 then 
	splinePos = 0 
end
if splinePos > 1 then 
	print("ERROR: splinePos > 1 at beginning! Check parameters")
	return 
end

local xlast, ylast, zlast = getSplinePosition(mySpline, 0);    -- Position des letzten objekts
local plObjects = -1
local plNode = getChild(node, "placedObjects")
while splinePos <= 1 do
    local placeId = true
	local x, y, z = getSplinePosition(mySpline, splinePos);

        y = getTerrainHeightAtWorldPos(terrain, x, y, z);
        if y == 0 then -- remove object, probably outside the map - Objekt loeschen, ist vermutlich ausserhalb der Map -
            placeId = false
        end;
    

	local rx, ry, rz = getSplineOrientation(mySpline, splinePos,0,-1,0);  
 
    if randomOrder then
        iObject = math.floor(math.random()*pObjectNum)
    else
        iObject = iObject + 1 -- naechstes Objekt nehmen
        if iObject >= pObjectNum then 
            iObject = 0
        end
    end -- if randomOrder

    if placeId then -- place object 
        local myId = clone(getChildAt(postObject,iObject), false, true)
        link(placedObjects,myId)
         plObjects =plObjects + 1
        setTranslation(myId, x, y, z);
        setRotation(myId, rx, ry, rz);
        yyy = 0
       
    end -- if placeId

    xlast = x -- update last position
    ylast = y
    zlast = z

	yyy = objectDistance/splineLength
   
    splinePos = splinePos + yyy 
    if splinePos < 0 then 
        splinePos = 0 
    end

end -- while


function vector3Length(x,y,z)
return math.sqrt(x*x + y*y + z*z);
end;

    local wireObject = 0 
    local E_fenceTransform = placedObjects
        if E_maxPosts == 0 then E_maxPosts = plObjects end
    for i = E_startPost, E_maxPosts do

        local post = getChildAt(E_fenceTransform, i);
        local nextPost = getChildAt(E_fenceTransform, math.min(i+1, E_maxPosts));
        if i == E_maxPosts then print(string.format("Finished! Enjoy the fence :) \nSpline Name :%s  ",splineName)) return end;
        local numWire = getNumOfChildren(wire_FenceNode)
    -- do all the wire things for each wire.. As we start with 0 its nodesCnt -1 = max
             
    for x = 0, E_wireNodesCnt-1 do
    
        if randomFence then
        wireObject = math.floor(math.random()*numWire)
        end 
       
        local wireNode = getChildAt(post, x);
        local newWireNode = getChildAt(nextPost, x);
        local rWire = getChildAt(wire_FenceNode,wireObject)
        local newWireObject = clone(rWire, false, false, false)  ----(Nn_fenceWire, false, false, false);
        link(wireNode, newWireObject);
        setTranslation(newWireObject, 0, 0, 0);
        setRotation(newWireObject, 0, 0, 0);

        local ax, ay, az = getWorldTranslation(newWireObject);
        local bx, by, bz = getWorldTranslation(newWireNode);
        x, y, z = worldDirectionToLocal(getParent(newWireObject), bx-ax, by-ay, bz-az);
        local upx, upy, upz = 0,1,0;

        setDirection(newWireObject, x, y, z, upx, upy, upz);

        local distance = vector3Length(ax-bx, ay-by, az-bz);
        local setScaleWert = 1 * (distance / E_startWireLength);
        setScale(newWireObject, 1, 1, setScaleWert);
    end;
    wireObject = wireObject + 1 -- naechstes Objekt nehmen
        if wireObject >= numWire then 
           wireObject = 0
           end
end;

end