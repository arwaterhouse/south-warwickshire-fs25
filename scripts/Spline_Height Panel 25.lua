-- Author: W_R
-- Name:Spline Height Panel 25
-- Description:
-- Version No 2.0.0 
-- Icon:
-- Hide: no
-- AlwaysLoaded: no
-- Version 28-11-2024 updated to FS25,


function crossProduct(ax, ay, az, bx, by, bz)	
    return ay*bz - az*by, az*bx - ax*bz, ax*by - ay*bx;
end
		

local labelWidth = 200.0
local centreWidth = 0
local mHeightOffset = 0
setEdge = {"Deselected","Selected"}
local edgeWidth = 0
local heightL = 0
local heightR = 0
local smoothL = 1
local smoothR = 1
local mSplinePieceH =0.5
        
        
local function setCentreWidth(value)
    centreWidth = value
end
local function setmHeightOffset(value)
    mHeightOffset = value
end       
local function setSetEdge(value)
    if value == 2 then setEdge = true
    else
    setEdge = false
    end
end       
local function setEdgeWidth(value)
    edgeWidth = value
end
local function setHeightL(value)
    heightL = value
end        
local function setHeightR(value)
    heightR = value
end        
local function setSmoothL(value)
    smoothL = value
end        
local function setSmoothR(value)
    smoothR = value
end        
local function setmSplinePieceH(value)
    mSplinePieceH = value
end        
local function setTerrainHeight()
setTerrainHeight1(centreWidth,mHeightOffset,setEdge,edgeWidth,heightL,heightR,smoothL,smoothR,mSplinePieceH)
end;       

-- UI

local frameSizer = UIRowLayoutSizer.new()
local myFrame = UIWindow.new(frameSizer, "Set Terrain Height By Spline")

local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer)

local rowSizer = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 10, 1) 

    local centreWidthSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, centreWidthSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(centreWidthSliderSizer, "Set Centre Width", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local centreWidthSlider = UIFloatSlider.new(centreWidthSliderSizer, centreWidth, 0, 255 );
    centreWidthSlider:setOnChangeCallback(setCentreWidth)
    
    local splineHeightSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, splineHeightSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(splineHeightSliderSizer, "Set Spline Height", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local splineHeightSlider = UIFloatSlider.new(splineHeightSliderSizer, mHeightOffset, -50, 255 );
    splineHeightSlider:setOnChangeCallback(setmHeightOffset)   
    
    local edgeTPanelSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, edgeTPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(edgeTPanelSizer, "Select Edge Transformation", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local edgeTChoice      = UIChoice.new(edgeTPanelSizer, setEdge, 0, -1, 100, -1)
    edgeTChoice:setOnChangeCallback(setSetEdge)
    
    local edgeWidthSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, edgeWidthSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(edgeWidthSliderSizer, "Set Edge Width", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local edgeWidthSlider = UIFloatSlider.new(edgeWidthSliderSizer, edgeWidth, 0, 50 );
    edgeWidthSlider:setOnChangeCallback(setEdgeWidth)
    
    local heightLSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, heightLSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(heightLSliderSizer, "Set Edge Height Left", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local heightLSlider = UIFloatSlider.new(heightLSliderSizer, heightL, -20, 20 );
    heightLSlider:setOnChangeCallback(setHeightL) 

    local heightRSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, heightRSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(heightRSliderSizer, "Set Edge Height Right", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local heightRSlider = UIFloatSlider.new(heightRSliderSizer, heightR, -20, 20 );
    heightRSlider:setOnChangeCallback(setHeightR)
    
    local smoothLSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, smoothLSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(smoothLSliderSizer, "Set Edge Smooth Left", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local smoothLSlider = UIFloatSlider.new(smoothLSliderSizer, smoothL, 1, 20 );
    smoothLSlider:setOnChangeCallback(setSmoothL)

    local smoothRSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, smoothRSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(smoothRSliderSizer, "Set Edge Smooth Right", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local smoothRSlider = UIFloatSlider.new(smoothRSliderSizer, smoothR, 1, 20 );
    smoothRSlider:setOnChangeCallback(setSmoothR)
    
    local mSplinePieceHSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, mSplinePieceHSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(mSplinePieceHSliderSizer, "Set DistanceBeween Points", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local mSplinePieceHSlider = UIFloatSlider.new(mSplinePieceHSliderSizer, mSplinePieceH, 0.0, 100 );
    mSplinePieceHSlider:setOnChangeCallback(setmSplinePieceH)
    
    UIButton.new(rowSizer, "Set Height", setTerrainHeight)  
 myFrame:showWindow()

 function setTerrainHeight1(centreWidth,mHeightOffset,setEdge,edgeWidth,heightL,heightR,smoothL,smoothR,mSplinePieceH)

        local mSplineID = getSelection(0)
        if mSplineID == 0 then
        print("\nPLEASE SELECT SPLINE")
        return nil
        end
		
        local objName = getName(mSplineID)
        splineCheck = getHasClassId(mSplineID, ClassIds.SHAPE) and getGeometry(mSplineID) ~= 0 
        and getHasClassId(getGeometry(mSplineID), ClassIds.SPLINE)
        if splineCheck then
         splineName = objName  
        else
		 print(string.format("\nERROR: OBJECT :-- %s --IS NOT A SPLINE", objName))
		return nil
		end;

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

        local mSplineLength = getSplineLength( mSplineID ) ;
        
        local mSplinePiecePoint = mSplinePieceH / mSplineLength ; -- relative size [0..1]
		if not setEdge then mSideCount = centreWidth/2
		else
		local overallWidth = centreWidth + (edgeWidth * 2)
		mSideCount = overallWidth/2
		end
--print(mTerrainID,splineName)
--print(centreWidth,mHeightOffset,setEdge,edgeWidth,heightL,heightR,smoothL,smoothR,mSplinePieceH)
local mSplinePos = 0.0;
        while mSplinePos <= 1.0 do
            -- get XYZ at position on spline
            local mPosX, mPosY, mPosZ = getSplinePosition( mSplineID, mSplinePos );
            -- define height value
            local mHeight = mPosY + mHeightOffset;
            -- directional vector at the point
            local mDirX, mDirY,   mDirZ   = worldDirectionToLocal( mSplineID, getSplineDirection ( mSplineID, mSplinePos) );
            local mVecDx, mVecDy, mVecDz = crossProduct( mDirX, mDirY, mDirZ, 0, 1, 0);
			
						--set HEIGHT at the center
                    for i = 0, mSideCount, mSplinePieceH do
							local mNewPosX1 = mPosX + i * mVecDx;
							local mNewPosY1 = mPosY + i * mVecDy;
							local mNewPosZ1 = mPosZ + i * mVecDz;
							local mNewPosX2 = mPosX  - i * mVecDx;
							local mNewPosY2 = mPosY  - i * mVecDy;
							local mNewPosZ2 = mPosZ  - i * mVecDz;
			
						if setEdge  and i > centreWidth/2 + 1  then     --set offset width and direction
							local mHeightL = mHeight + (heightL/smoothL)		--set left edge height and smoothness
							local mHeightR = mHeight + (heightR/smoothR)  		--set right edge height and smoothness
							setTerrainHeightAtWorldPos( mTerrainID, mNewPosX1, mNewPosY1, mNewPosZ1, mHeightR ); --set terrainHeight with offset
							setTerrainHeightAtWorldPos( mTerrainID, mNewPosX2, mNewPosY2, mNewPosZ2, mHeightL );
							else	
							setTerrainHeightAtWorldPos( mTerrainID, mNewPosX1, mNewPosY1, mNewPosZ1, mHeight );	--set terrainHeight no offset
							setTerrainHeightAtWorldPos( mTerrainID, mNewPosX2, mNewPosY2, mNewPosZ2, mHeight );
                        end          
                    end
            -- goto next point
            mSplinePos = mSplinePos + mSplinePiecePoint;  
        end;
	print(string.format("\nSpline Name :%s", splineName))
    if setEdge then 
	print("Offset:'True'")
    print(string.format("Spline Height: %.1f", mHeightOffset))
	----print(string.format("Overall Width: %.1f", overallWidth))
	print(string.format("Centre Width: %.1f m :Edge Width: %.1f m :\nHeight Left: %1.f :Height Right: %1.f :\nSmoothing Left: %1.f Smoothing Right:%1.f  ",centreWidth,edgeWidth, heightL, heightR, smoothL, smoothR))
    else
    print("Offset: 'False':")
    print(string.format("Spline Height: %.1f m", mHeightOffset))
    print(string.format("Centre Width: %.1f m",mSideCount *2))
	end
print("\nFinished Transform OK") 

end