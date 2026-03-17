-- Author:Nicolas Wrobel,W_R
-- Name:Paint Foliage by Spline Panel_25
-- Description: paintFoliageBySpline ( takes x,z value from spline every selected distance (local folDistance = 0.5	) and paints selected foliage
-- 				on the terrain along and either side of the spline depending on settings.
--
-- Icon:
-- Hide: no
-- AlwaysLoaded: no
-- Version 28-11-2024 updated to FS25,
--[[
 Note ; Script will automatically search map.i3d for file locations using the files fileId number.
       

      Unfortunately I haven't yet been able to add the foliage states to the drop down menu (Set Foliage State)this facility is still being developed.
      In the mean time all the foliage states are printed in the console log  i.e.
      
    MEADOW ;
        Foliage State ;  0 , Remove , 1 . invisible ,  2 . green small ,  3 . green middle ,  4 . harvest ready ,  5 . cut , 

            And in a new foliage_States.txt file in the map.i3d folder for easy reference.


Note for INfo When variable foliage selected random foliage should be selected as well
--]]
 
--end

    

-- gInst --- Main Install directory location if different change to your Farming Simulator 2022 folder location

local gInst ="C:/Program Files (x86)/Farming Simulator 2025/" 


--print(string.format(gInst))
------------------------------------- Beyond here be Dragons -----------------------------------------------------------------

layerIndex ={}
folLayerName ={}
folLayerFT ={}
folXML={}
folState = {}
mlFNA = {}
choice = {"Deselected","Selected"}
densMap = {}
local layerStates = 15 --default layer states allowed by Density map
local fl = 100 -- no of foliages increased for foliage maps
 for i=1,fl do
      folState[i] = {} 
      for j=1,layerStates do
        folState[i][j] = ""	
      end
    end  

local fNd = 0
local index = 0
local i = 0
local count = 0
local fileName = getSceneFilename()
local fNd = fileName:find("/[^/]*$")
local newPath = string.sub(fileName,1,fNd)
local filename2 = newPath.."/foliage_States.txt"
local foliageStates = createFile(filename2,0)
fileWrite(foliageStates,"Foliage States")
local xmlFile = loadXMLFile("map.i3d", fileName)
local countMax = 0
 for x = 0, 10 do
 densMap[x] = getXMLString(xmlFile, "i3D.Scene.TerrainTransformGroup.Layers.FoliageSystem.FoliageMultiLayer("..x..")#densityMapId")
 if densMap[x] == nil then countMax = x break end
 end
 
 --foliage Type/xml/haulm
  while true do
        index = index + 1  
        folLayerName[index] = getXMLString(xmlFile, "i3D.Scene.TerrainTransformGroup.Layers.FoliageSystem.FoliageMultiLayer("..count..").FoliageType("..i..")#name")
        folXML[index] = getXMLString(xmlFile, "i3D.Scene.TerrainTransformGroup.Layers.FoliageSystem.FoliageMultiLayer("..count..").FoliageType("..i..")#foliageXmlId")             
        i= i +1    
        if folLayerName[index] == nil then  count = count + 1 i = 0 index = index - 1 end-- jumps to further FoliageMultiLayer entrys weed, stones etc)
       
    if count == countMax then    
        index = 0 i = 0 count = 0 
    break end   
 end
--parse all fileId's to assign correct xml path for foliage.xml's
 while true do
index = index + 1
 mlFNA[index] = getXMLString(xmlFile,"i3D.Files.File("..index..")#fileId")
if mlFNA[index] == nil then  index = 0 break end

end
--end
--create full xml path
posSlash = {}
 for d = 1, #folLayerName do
local xmlID = folXML[d]
    for k, value in next, mlFNA do 
        if value == xmlID then
            folXML[d] =getXMLString(xmlFile,"i3D.Files.File("..k..")#filename")
            if string.sub(folXML[d],1, 1) == "$" then  
               local dFoliage =string.sub(folXML[d],2) 
               folXML[d] =gInst..dFoliage
            else            
                local slC = 0
                local pit = 0
                for i in folXML[d]:gmatch("%.%./") do
                    slC = slC + 1
                end
                    for i=1, #newPath do
                        if newPath:sub(i, i) == "/" then
                        count = count + 1
                        posSlash[count] = i
                        end    
                    end
                if slC ~= nil then 
                pit = posSlash[count-slC]
                newPath2 = string.sub(newPath,1,pit)
                local folXML2 = folXML[d]: gsub("%.%./","")
                folXML[d]= newPath2..folXML2
                end                      
            end               
        end
    end
end

   --get Haulm and position it in folLayerName and folXML
local k = 1 -- for second foliage layer name --todo repeat if more than 2 foliage layers (0,1)
local ke = 0
while true do
ke = ke +1
if folLayerName[ke] == nil then break end 
local xmlFileFL = loadXMLFile(folLayerName[ke].."XML", folXML[ke])
    folLayerFT[ke] = getXMLString(xmlFileFL, "foliageType.foliageLayer("..k..")#name")
    if folLayerFT[ke] ~= nil then 
    table.insert(folLayerName, ke+1,folLayerName[ke].."_haulm")
    table.insert(folXML,ke+1,nil) 
        ke=ke+1  

end 

end

for item = 1,#folLayerName do
         local jump = 0 
         index = 1
         local iex = 1
        if folXML[item] ~= nil then               
                local xmlFile2 = loadXMLFile(folLayerName[item], folXML[item])  
       
                while true do               
                    local fState = getXMLString(xmlFile2,"foliageType.foliageLayer.foliageState("..jump..")#name")                       
                        if fState then                  
                            folState[item][index] = tostring(iex)..". "..fState.." , "
                            iex = iex +1
                            jump = jump +1
                            index = index +1 
                     
                        else

layerIndex[item] = index
                            break end                         
                        end                 
       end
                    if string.match(folLayerName[item],"_haulm") then folState[item] = {" State 1"} end
                    if item > 0 then
                    local foName = string.upper(folLayerName[item])
                        local pState ="\n"..foName.."\n"..string.format("\tFoliage State ;  0 , Remove , %s ",table.concat(folState[item],"",1))
                        print(pState)
                        fileWrite(foliageStates,pState)
                    end  
 
end
delete(foliageStates) 
--for u= 1, #folLayerName do
--print(string.format("foliageName %s,layerIndex %s ", folLayerName[u],layerIndex[u]))
--end

--UI----		

local labelWidth = 200.0
local overallWidthPaint = 0
local offsetPaint = 0
local folLayer1 = 0
local folState1 = 0 
local stateV = false
local state1 = 0
local state2 = 0
local stateRnd1= false
local rndDist1 = false
local folDistance = 0.5
local rndDist = 0
local title = "Paint Foliage by Spline Panel"
table.insert(folLayerName, 1,"")

local function setOverallWidthPaint(value)
    overallWidthPaint = value
end
local function setOffsetPaint(value)
    offsetPaint = value
end
local function setFolLayer (value)
    folLayer1  = value
end
   local function setFolState(value)
 folState1 = value 
 end
   local function setStateV(value)
 if value == 2 then stateV = true
    else stateV = false
 end
 end
 local function setState2(value)
 state2 = value 
 end
local function setStateRnd1(value)
    if value == 2 then stateRnd1 = true
    else stateRnd1 = false
  end
end 
local function setRndDist1(value)
    if value == 2 then rndDist1 = true
    else rndDist1 = false
  end
end   
local function setFolDistance(value)
    folDistance = value
end

local function paintFoliage1()
paintFoliage(overallWidthPaint,offsetPaint,folLayer1,folState1,stateRnd1,state2,rndDist1,folDistance )
end

local frameSizer = UIRowLayoutSizer.new()
local myFrame = UIWindow.new(frameSizer, title)

local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer)

local rowSizer = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)

    local overallWidthPaintSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, overallWidthPaintSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(overallWidthPaintSliderSizer, "Set Width", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local overallWidthPaintSlider = UIFloatSlider.new(overallWidthPaintSliderSizer, overallWidthPaint, 0, 255 );
    overallWidthPaintSlider:setOnChangeCallback(setOverallWidthPaint)
    
    local offsetPaintSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, offsetPaintSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(offsetPaintSliderSizer, "Set Offset Paint Distance", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local offsetPaintSlider = UIFloatSlider.new(offsetPaintSliderSizer, offsetPaint, -255, 255 );
    offsetPaintSlider:setOnChangeCallback(setOffsetPaint)

   local folLayerPanelSizer = UIColumnLayoutSizer.new()
    local folLayerPanel      =UIPanel.new(rowSizer, folLayerPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local folLayerLabel      =UILabel.new(folLayerPanelSizer, "Set Foliage Type", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local folLayerChoice  = UIChoice.new(folLayerPanelSizer, folLayerName, 0, -1, 100, -1)
    folLayerChoice:setOnChangeCallback(setFolLayer)
    
    local folStateSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, folStateSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(folStateSliderSizer, "Set Foliage State ", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local folStateSlider = UIIntSlider.new(folStateSliderSizer, folState1, 0, layerStates );
    folStateSlider:setOnChangeCallback(setFolState)
	
	 local stateRnd1PanelSizer = UIColumnLayoutSizer.new()
    local stateRnd1Panel      = UIPanel.new(rowSizer, stateRnd1PanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local stateRnd1Label      = UILabel.new(stateRnd1PanelSizer, "Random Foliage Paint:", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local stateRnd1Choice      = UIChoice.new(stateRnd1PanelSizer, choice, 0, -1, 100, -1)
    stateRnd1Choice:setOnChangeCallback(setStateRnd1)
    
     local stateVPanelSizer = UIColumnLayoutSizer.new()
    local stateVPanel      = UIPanel.new(rowSizer, stateVPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local stateVChoiceLabel      = UILabel.new(stateVPanelSizer, "Variable Foliage State    ", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local stateVChoice      = UIChoice.new(stateVPanelSizer, choice, 0, -1, 100, -1)
    stateVChoice:setOnChangeCallback(setStateV)
	
	  local state2SliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, state2SliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(state2SliderSizer, "Set Second Foliage State ", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local state2Slider = UIIntSlider.new(state2SliderSizer, state2, 0, layerStates );
    state2Slider:setOnChangeCallback(setState2)
      
    local rndDist1PanelSizer = UIColumnLayoutSizer.new()
    local rndDist1Panel      = UIPanel.new(rowSizer, rndDist1PanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local rndDist1ChoiceLabel      = UILabel.new(rndDist1PanelSizer, "Random Foliage Distance    ", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local rndDist1Choice      = UIChoice.new(rndDist1PanelSizer, choice, 0, -1, 100, -1)
    rndDist1Choice:setOnChangeCallback(setRndDist1)
  
    local folDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, folDistanceSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(folDistanceSliderSizer, "Set Distance between Foliage", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local folDistanceSlider = UIFloatSlider.new(folDistanceSliderSizer, folDistance, 0.5, 255)
    folDistanceSlider:setOnChangeCallback(setFolDistance)
 
    UIButton.new(rowSizer, "Paint Foliage", paintFoliage1)  
 myFrame:showWindow()


function paintFoliage(overallWidthPaint,offsetPaint,folLayer1,folState1,stateRnd1,state2,rndDist1,folDistance)


function crossProduct(ax, ay, az, bx, by, bz)
    return ay*bz - az*by, az*bx - ax*bz, ax*by - ay*bx;
end;

if state1 > state2 then 
	print("***********ERROR in SCALE SETTINGS************")
return end					
		--spline check----
		local mSplineID = getSelection(0)
        if mSplineID == 0 then
            print("\nPLEASE SELECT SPLINE")
            return nil
        end;
        local objName = getName(mSplineID)
        splineCheck = getHasClassId(mSplineID, ClassIds.SHAPE) and getGeometry(mSplineID) ~= 0 
        and getHasClassId(getGeometry(mSplineID), ClassIds.SPLINE)
        if splineCheck then
            splineName = objName  
        else
            print(string.format("\nERROR: OBJECT :-- %s --IS NOT A SPLINE", objName))
            return nil
        end

        --get terrain 1d and set up modifiers---
       local mSceneID = getRootNode()
        local mTerrainID = 0
        local mapMetersPerPixel = 0.25
        local pixelsPerMeter = 1 / mapMetersPerPixel

        for i = 0, getNumOfChildren(mSceneID) - 1 do
            local mID = getChildAt(mSceneID, i)
            if (getName(mID) == "terrain") then
                mTerrainID = mID
                break
            end
end
		local mSideCount = overallWidthPaint/2
		local detail = getTerrainDataPlaneByName(mTerrainID, folLayerName[folLayer1])
		local modifier = DensityMapModifier.new(detail, 0,foliageState)
        local mSplinePieceP = folDistance
		local mSplineLength = getSplineLength( mSplineID ) ;
        local mSplinePiecePoint = mSplinePieceP / mSplineLength ; -- relative size [0..1]
        local mSplinePos = 0.0;
        local state1 = folState1
		
    while mSplinePos <= 1.0 do
            
            local mPosX, mPosY, mPosZ = getSplinePosition( mSplineID, mSplinePos );
            mPosZ = mPosZ + offsetPaint
            local mDirX, mDirY, mDirZ   = worldDirectionToLocal( mSplineID, getSplineDirection ( mSplineID, mSplinePos) );
            local mVecDx, mVecDy, mVecDz = crossProduct( mDirX, mDirY, mDirZ, 0, 1, 0);
				
		for i = 0, mSideCount, mSplinePiecePoint do
             
                if rndDist1 or stateRnd1 then  
           
                        local rNewPosX1 = mPosX + math.random(1,mSideCount)                        
                        local rNewPosZ1 = mPosZ + math.random(1,mSideCount)                       
                        local rNewPosX2 = mPosX - math.random(1,mSideCount)                        
                        local rNewPosZ2 = mPosZ - math.random(1,mSideCount)
                        ---print(state1,state2)
                        if stateV  then folRnd = math.random(state1,state2)
						
                        --stateRnd1 = true
                       else
                       folRnd = math.random(1,layerStates)---#folState[folLayer1])
--if folRnd > #folState[folLayer1-1] then folRnd = 1 end
--print(folRnd)
--print(#folState[folLayer1])
                        end
                        
                        if stateRnd1 then folState1 = folRnd  end
                        
                            modifier:setParallelogramWorldCoords( mPosX,mPosZ, rNewPosX1, rNewPosZ1, rNewPosX2, rNewPosZ2, DensityCoordType.POINT_POINT_POINT)
                            modifier:executeSet(folState1)
                                                     
                else               
                    local mNewPosX1 = mPosX + mSideCount * mVecDx;
                    local mNewPosZ1 = mPosZ + mSideCount * mVecDz;
                    local mNewPosX2 = mPosX - mSideCount * mVecDx;
                    local mNewPosZ2 = mPosZ - mSideCount * mVecDz;
                    
                         modifier:setParallelogramWorldCoords( mPosX,mPosZ, mNewPosX1, mNewPosZ1, mNewPosX2, mNewPosZ2, DensityCoordType.POINT_POINT_POINT)
                        modifier:executeSet(folState1)
                      
                end
          			
        end; --for  		 
                    mSplinePos = mSplinePos + mSplinePiecePoint; 
                     if rndDist1 then mSplinePos = mSplinePos + (math.random()/folDistance) end                            
    end --while         
end; --func
		
