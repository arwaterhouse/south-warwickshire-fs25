-- Author:TracMax, W_R
-- Name:splinePlacementPanelCombined_25
-- Description: places objects along a spline - Platziert Objekte entlang eines Splines
-- Icon:
-- Hide: no
-- AlwaysLoaded: no
-- Version 3.1 13/12/2024 -Scale Error 28-11-2024 updated to FS25,

 --[[      Spline can be called any name i.e road1_spline or roadspline01 etc

			If using the Distance Table to set the distance between the individual objects then set the relevant permissions/values in the 'splinePlacement
            User Attributes panel in GE before continuing. 
            The number of distances must be the same as the number of objects in the objectsToPlace transform group and each distance seperated by a comma ','
            
            Stay Upright -- 'Selected' item remains upright --- 'Deselected' reverts to spline 'X'rotation and original object rotation at the placement point
            Random Scale, when selected 'true'allows random object scale between the parameters set by scaleLow,scaleHigh values-- 'Deselected' = retains original size, 
            Random 'Y' rotation -- 'Selected' random rotation of 'Y'axis-- 'Deselected' Y axis rotation as original object
            Random Spline Order -- 'Selected' allows a random order of ojects along the spline if Using Distance table then distances will also vary-- 'Deselected' retains the order set in the objectsToBePlaced transform group
            Random Distance -- 'Selected' allows for random distance between objects along the spline maximun distance allowed set by the Maximum Random Distance -- 'Deselected' distance as set by objectDistance            
            Random Placement, when selected and Max Distance value inserted will randomly place objects away from the spline to Max Distance value in both X and Z axis
            
			
 NOTE: Objects will be placed at terrain height at their point of origin height for example a default cube (Create-Primitive-Cube)will be placed 0.5m below the surface as the cube is 1m square.
 
								The objects will be placed along the spline from the 'S' cv aligned to their "Z" axis so ensure that your object is aligned to the 'Z' axis
								i.e if you have a fence panel that is set so the longest section is not aligned to the 'Z' axis then rotate it in GE and freeze transform rotation
								until is aligned along the 'Z' axis.
								For best results, freeze transform all scale/rotation settings and set all translations to zero on all the objects you want to place.

 --]]
 
distanceTable={}

choice ={"Deselected","Selected"}
local labelWidth = 250.0
local objectDistance = 1 
local useDistanceTable = false 
local fixedDistance = false
local distanceFixed	= 0		
local stayUpright = false  		
local randomScale = false  		
local scaleLow = 0  		 
local scaleHigh = 0  		
local randomYrotation = false  		
local randomOrder = false  		
local rndObjDist = false	
local randomPlacement = false
local rndPLDist_1 = 1		
local rndPLDist_2 = 1	
local placementDel = false
							
local scene = getRootNode()
local node = createTransformGroup("splineObjects")
link(scene,node)
local splinePlacement = createTransformGroup("splinePlacement");
link(node,splinePlacement)
local objectsToPlace = createTransformGroup("objectsToPlace")
link(splinePlacement,objectsToPlace)
local placedObjects = createTransformGroup("placedObjects")
link(splinePlacement,placedObjects)

    for i = 0, getNumOfChildren(node) - 1 do
        local nID = getChildAt(node, i)
        if string.find(getName(nID),"splinePlacement") then
           splPl = nID 
            break
        end
    end


local function createUserAttribute(splPl, attributeName, type, defaultValue) 
if getUserAttribute(splPl, attributeName) == nil then setUserAttribute(splPl, attributeName, type, defaultValue) 
end  
end	
	--createUserAttribute(splPl, "Use Distance Table ", "Boolean", false);
	createUserAttribute(splPl, "Set Distance Table ", "String","1,5");
    
local function setObjectDistance(value)
    objectDistance = value
end
local function setUseDistanceTable(value)
    if value == 2 then useDistanceTable = true
    else useDistanceTable = false
  end 
end 
local function setFixedDistance(value)
    if value == 2 then fixedDistance = true
    else fixedDistance = false
  end 
end 
local function setDistanceFixed(value)
    distanceFixed = value
  end 

local function setStayUpright(value)
    if value == 2 then stayUpright = true
    else stayUpright = false
  end 
 end

local function setRandomScale(value)
    if value == 2 then randomScale = true
    else randomScale = false
  end 
end
 local function setScaleLow(value)
    scaleLow = value
end
local function setScaleHigh(value)
    scaleHigh = value
end
local function setRandomYrotation (value)
    if value == 2 then randomYrotation = true
    else randomYrotation  = false
  end
end   
local function setRandomOrder(value)
    if value == 2 then randomOrder = true
    else randomOrder = false
  end
end 

 local function setRndObjDist (value)
    if value == 2 then rndObjDist = true
    else 
    rndObjDist = false
  end
end  

local function setRandomPlacement (value)
    if value == 2 then randomPlacement = true
    else randomPlacement  = false
  end
end 

local function setRndPLDist_1(value)
   rndPLDist_1 = value
end 

local function setRndPLDist_2(value)
   rndPLDist_2 = value
end 

local function setPlacementDel(value)
    if value == 2 then placementDel = true
    else placementDel = false  
    end
    end
local function  delObjects()
    if placementDel == true then
    local node = getSelection(0)
    if node == 0 or getName(node) ~= "splinePlacement" then
    print("\n\tERROR: Please select 'splinePlacement' transform group!")
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
    placementDel = 1
    print("\n\tObjects Deleted")  
    end   
end   

local function splinePlacement1()
splineObjects(objectDistance , useDistanceTable,stayUpright, randomScale, scaleLow,scaleHigh,randomYrotation,randomOrder,rndObjDist,rndObjDistV,randomPlacement,rndPLDist_1,rndPLDist_2,placementDel)

end

local frameSizer = UIRowLayoutSizer.new()
local myFrame = UIWindow.new(frameSizer, "Spline Placement Panel")

local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer)

local rowSizer = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 10)

    local objDistSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, objDistSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(objDistSliderSizer, "Object Distance", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local objDistSlider = UIFloatSlider.new(objDistSliderSizer, objectDistance, 0, 255 );
    objDistSlider:setOnChangeCallback(setObjectDistance)
    
      local useDistanceTablePanelSizer = UIColumnLayoutSizer.new()
    local useDistanceTablePanel      = UIPanel.new(rowSizer, useDistanceTablePanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local useDistanceTableChoiceLabel      = UILabel.new(useDistanceTablePanelSizer, "Use Distance Table", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local useDistanceTableChoice      = UIChoice.new(useDistanceTablePanelSizer, choice, 0, -1, 100, -1)
    useDistanceTableChoice:setOnChangeCallback(setUseDistanceTable)
   
     local infoPanelSizer = UIColumnLayoutSizer.new()
    local infoPanel = UIPanel.new(rowSizer, infoPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local labelInfo = UILabel.new(infoPanelSizer, "If Use Distance Table Selected - Set values in \nUser Attributes Setting 'splinePlacement' before continuing.", TextAlignment.CENTER, -1, -1, -1, -1)
	
	   local fixedDistancePanelSizer = UIColumnLayoutSizer.new()
    local fixedDistancePanel      = UIPanel.new(rowSizer, fixedDistancePanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local fixedDistanceChoiceLabel      = UILabel.new(fixedDistancePanelSizer, "Fixed Distance", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local fixedDistanceChoice      = UIChoice.new(fixedDistancePanelSizer, choice, 0, -1, 100, -1)
    fixedDistanceChoice:setOnChangeCallback(setFixedDistance)
	
	 local distanceFixedSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, distanceFixedSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(distanceFixedSliderSizer, "Distance to Fix", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local distanceFixedSlider = UIFloatSlider.new(distanceFixedSliderSizer, distanceFixed, -255, 255 );
    distanceFixedSlider:setOnChangeCallback(setDistanceFixed)
  
    local stayUprightPanelSizer = UIColumnLayoutSizer.new()
    local stayUprightPanel      = UIPanel.new(rowSizer, stayUprightPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local stayUprightChoiceLabel      = UILabel.new(stayUprightPanelSizer, "Stay Upright", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local stayUprightChoice      = UIChoice.new(stayUprightPanelSizer, choice, 0, -1, 100, -1)
    stayUprightChoice:setOnChangeCallback(setStayUpright)
    
    local randomScalePanelSizer = UIColumnLayoutSizer.new()
    local randomScalePanel      = UIPanel.new(rowSizer, randomScalePanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local randomScaleChoiceLabel      = UILabel.new(randomScalePanelSizer, "Random Scale", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local randomScaleChoice      = UIChoice.new(randomScalePanelSizer, choice, 0, -1, 100, -1)
    randomScaleChoice:setOnChangeCallback(setRandomScale)
    
    local scaleLowSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, scaleLowSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(scaleLowSliderSizer, "Scale Low (Min)", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local scaleLowSlider = UIFloatSlider.new(scaleLowSliderSizer, scaleLow, 0, 255 );
    scaleLowSlider:setOnChangeCallback(setScaleLow)
    
    local scaleHighSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, scaleHighSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(scaleHighSliderSizer, "Scale High (Max)", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local scaleHighSlider = UIFloatSlider.new(scaleHighSliderSizer, scaleHigh, 0, 255 );
    scaleHighSlider:setOnChangeCallback(setScaleHigh)
    
     local randomYrotationPanelSizer = UIColumnLayoutSizer.new()
    local randomYrotationPanel      = UIPanel.new(rowSizer, randomYrotationPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local randomYrotationChoiceLabel      = UILabel.new(randomYrotationPanelSizer, "Select Random 'Y' Rotation", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local randomYrotationChoice      = UIChoice.new(randomYrotationPanelSizer, choice, 0, -1, 100, -1)
    randomYrotationChoice:setOnChangeCallback(setRandomYrotation)
    
     local randomOrderPanelSizer = UIColumnLayoutSizer.new()
    local randomOrderPanel      = UIPanel.new(rowSizer, randomOrderPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local randomOrderChoiceLabel      = UILabel.new(randomOrderPanelSizer, "Select Random Spline Order", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local randomOrderChoice      = UIChoice.new(randomOrderPanelSizer, choice, 0, -1, 100, -1)
    randomOrderChoice:setOnChangeCallback(setRandomOrder)

    local rndObjDistPanelSizer = UIColumnLayoutSizer.new()
    local rndObjDistPanel      = UIPanel.new(rowSizer, rndObjDistPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local rndObjDistChoiceLabel      = UILabel.new(rndObjDistPanelSizer, "Select Random Distance", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local rndObjDistChoice      = UIChoice.new(rndObjDistPanelSizer, choice, 0, -1, 100, -1)
    rndObjDistChoice:setOnChangeCallback(setRndObjDist)
   
    local randomPlacementPanelSizer = UIColumnLayoutSizer.new()
    local randomPlacementPanel      = UIPanel.new(rowSizer, randomPlacementPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local randomPlacementChoiceLabel      = UILabel.new(randomPlacementPanelSizer, "Select Random Placement", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local randomPlacementChoice      = UIChoice.new(randomPlacementPanelSizer, choice, 0, -1, 100, -1)
    randomPlacementChoice:setOnChangeCallback(setRandomPlacement)

    local rndPLDist_2SliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer,rndPLDist_2SliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(rndPLDist_2SliderSizer, "Random Placement \nDistance (Max)", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local rndPLDist_2Slider = UIFloatSlider.new(rndPLDist_2SliderSizer,rndPLDist_2, 1, 255)
   rndPLDist_2Slider:setOnChangeCallback(setRndPLDist_2)
    
    UIButton.new(rowSizer, "Place Objects", splinePlacement1,nil, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    
    local placementDelPanelSizer = UIColumnLayoutSizer.new()
    local placementDelPanel      = UIPanel.new(rowSizer, placementDelPanelSizer, -1, -1,-1, -1, BorderDirection.BOTTOM,1)
    local placementDelChoiceLabel      = UILabel.new(placementDelPanelSizer, "Delete Placed Objects", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local placementDelChoice      = UIChoice.new(placementDelPanelSizer, choice, 0, -1, 100, -1)
    placementDelChoice:setOnChangeCallback(setPlacementDel)
    
   UIButton.new(rowSizer, "Delete Placed Objects", delObjects,nil, -1, -1, -1, -1, BorderDirection.BOTTOM, 10) 
   
 myFrame:showWindow()

function 
splineObjects(objectDistance , useDistanceTable,stayUpright, randomScale, scaleLow,scaleHigh,randomYrotation,randomOrder,rndObjDist,rndObjDistV,randomPlacement,rndPLDist_1,rndPLDist_2,placementDel)

if scaleLow > scaleHigh then 
		 print("***********ERROR in SCALE SETTINGS************")
return end
    
local node = getSelection(0)
if node == 0 or getName(node) ~= "splinePlacement" then
    print("\n\tERROR: Please select 'splinePlacement' transform group!")
    return nil
    end	
---print(splinePlacement)
local splPl = node
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
--clear distance table before running any new settings
for k in pairs (distanceTable) do
    distanceTable [k] = nil
end

	local distTable = getUserAttribute(splPl, "Set Distance Table ")

if objectDistance <= 0 then
    print("ERROR: Please use positive value for 'objectDistance' !")
    return nil
end
local objectsToPlace = getChild(node,"objectsToPlace")
if objectsToPlace == 0 then
    print("ERROR: 'objectsToPlace' not present!")
    return nil
end
local numObjectsToPlace = getNumOfChildren(objectsToPlace)
if numObjectsToPlace <= 0 then
    print("ERROR: 'objectsToPlace' has no objects!")
    return nil
end
if useDistanceTable then
for dist in string.gmatch(distTable, "%d+") do
    table.insert(distanceTable,dist)
     end    
     if #distanceTable ~= numObjectsToPlace then
  print("\nDISTANCE TABLE ERROR")
 return nil
end 
end
 
local placedObjects = getChild(node,"placedObjects")
if placedObjects == 0 then
    print("ERROR: 'placedObjects' not present!")
    return nil
end
local myParent = getParent(node)
if myParent == 0 then
    print("\nERROR: 'splineObjects Transform not found")
    return nil
end
function crossProduct(ax, ay, az, bx, by, bz)	
    return ay*bz - az*by, az*bx - ax*bz, ax*by - ay*bx;
end


local splineLength = getSplineLength(mySpline)
-- wird fuer alignWithTerrain gebraucht
 local mSceneID = getRootNode()
        local mTerrainID = 0
      
        for i = 0, getNumOfChildren(mSceneID) - 1 do
            local mID = getChildAt(mSceneID, i)
            if (getName(mID) == "terrain") then
                terrain = mID
                break
            end
        end
local xParent, yParent, zParent = getWorldTranslation(myParent)
local RxParent, RyParent, RzParent = getWorldRotation(myParent)

local iObject = 0   
local splinePos = objectDistance/splineLength --0 

if splinePos < 0 then 
	splinePos = 0 
end
if splinePos > 1 then 
	print("ERROR: splinePos > 1 at beginning! Check parameters")
	return 
end
  
local xlast, ylast, zlast = getSplinePosition(mySpline, 0);    

local plObjects = -1
local plNode = getChild(node, "placedObjects")

while splinePos <= 1 do
    local placeId = true
	local x, y, z = getSplinePosition(mySpline, splinePos);	
    if randomPlacement then --- x und z variieren           
		x = x + (math.random()-0.5)*rndPLDist_2
        z = z + (math.random()-0.5)*rndPLDist_2		
    end

		y = getTerrainHeightAtWorldPos(terrain, x, y, z);     
        if y == 0 then -- remove object, probably outside the map - Objekt loeschen, ist vermutlich ausserhalb der Map -
            placeId = false
       end;
  
	local rx, ry, rz = getSplineOrientation(mySpline, splinePos, 0, 1, 0);

    if placeId then -- place object 
        local myId = clone(getChildAt(objectsToPlace,iObject), false, true)
        link(placedObjects,myId)
        plObjects =plObjects + 1
		 local mDirX, mDirY,   mDirZ = worldDirectionToLocal( mySpline, getSplineDirection (mySpline, splinePos) );
         local mVecDx, mVecDy, mVecDz = crossProduct( mDirX, mDirY, mDirZ, 0, 1, 0);
          if fixedDistance then					
					local fixPosX = x +distanceFixed * mVecDx;
					local fixPosY = y +distanceFixed * mVecDy;
					local fixPosZ = z +distanceFixed * mVecDz;
					
				 fixPosY = getTerrainHeightAtWorldPos(terrain, fixPosX, fixPosY, fixPosZ );
				 if fixPosY ~= 0 then 
				 setTranslation(myId, fixPosX-xParent, fixPosY-yParent, fixPosZ-zParent);
				else end
					 
			else
				setTranslation(myId, x, y, z);			
             	
		end	--fixDst
        if randomYrotation then
            if stayUpright then
                rx = 0
                rz = 0
            end
            ry = math.random()*math.pi*2
            setRotation(myId, rx, ry, rz);
        else
            local yyy = y-ylast
            if stayUpright then
                yyy = 0
            end
           setDirection(myId,x-xlast,yyy,z-zlast,0,1,0)
			
        end 

         if randomScale then -- set random scale, use sx,sy,sz 
		  local scale = scaleHigh - scaleLow
            sx = math.random()*scale+scaleLow
            --sx = scaleLow + math.random() * scaleHigh 
            sy = sx
            sz = sx
            setScale(myId,sx,sy,sz)
            end		
          
    end -- if placeId

    xlast = x -- update last position
    ylast = y
    zlast = z
    yyy = objectDistance/splineLength
   
    if useDistanceTable then 
    rndObjDist = false 
    randomOrder = false
		--iObject = iObject + 1 -- naechstes Objekt nehmen
        yyy = distanceTable[iObject+1]/splineLength -- splinePos um 1 Einheit erhoehen
		
		 if iObject >= numObjectsToPlace then 
            iObject = 0
			end
           
    end
    if randomOrder then 
        iObject = math.floor(math.random()*numObjectsToPlace)
    end -- if randomOrder
    if rndObjDist then 
         yyy = yyy*(math.random(objectDistance/2,objectDistance+1))
    end    
    splinePos = splinePos + yyy -- splinePos um 1 Einheit erhoehen
    if splinePos < 0 then -- kann durch rndObjDist negativ werden
        splinePos = 0 
    end
	
	iObject = iObject + 1 -- naechstes Objekt nehmen
        if iObject >= numObjectsToPlace then 
           iObject = 0

   end
end -- while

print(string.format("\n\tSpline Name :%s",splineName))
print("\tObject Placement Complete  ---  So weit so gut")
print(string.format("\tNumber of Objects Placed : %d",plObjects))
if useDistanceTable then dTable =table.concat(distanceTable,",")
print("\tDistance Table :  "..dTable)

end
end
--]]