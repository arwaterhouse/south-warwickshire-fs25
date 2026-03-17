-- Author:W_R
-- Name:Spline Paint Panel 25
-- Description: Paint the terrain  using a spline both completely and with random textures depending on settings
-- Icon:
-- Version 2.0.0 19/01/2025
-- Icon No:
-- Hide:no
-- AlwaysLoaded: no

---         Note: Random Width (Max) this is the max distance the texture will be painted either side of the spline (0 to Random Width (Max))
---               Random Distance (Max) this value is used by the RND function for the random distance the texture will be painted along the spline (0 to Random Distance (Max))
---               In both cases texture will be painted randomly at a distance between 0 and Random value entered at each point along the spline
---				  Randon distance bewteen textures can also be adjusted using the Set Texture Distance Value 
---               

textureName ={}
texturePaint ={}
choice ={"Deselected","Selected"}

  local mSceneID = getRootNode()
        local mTerrainID = 0
        for i = 0, getNumOfChildren(mSceneID) - 1 do
            local mID = getChildAt(mSceneID, i)
            if (getName(mID) == "terrain") then
                mTerrainID = mID
                break
            end
        end
		local numLayers = getTerrainNumOfLayers(mTerrainID)
        addedLayer = numLayers +1
		for i = 0,addedLayer do
           texturePaint[i] = getTerrainLayerName(mTerrainID, i-1)
           textureName[i] = getTerrainLayerName(mTerrainID, i)
        end;
            texturePaint[addedLayer]= "-1"

local labelWidth = 140.0
local centreWidth = 0
local edgeWidth = 0
local texLeft = -1
local texCentre = -1
local texRight = -1
local texLeft = -1
local texDistance = 0.1
local rndPaint = false
local rndWidth = 0
local rndTex = -1
local rndDist = 0

local function setCentreWidth(value)
    centreWidth = value
end
local function setEdgeWidth(value)
    edgeWidth = value
end

local function setTexLeft(value)
if texLeft == addedLayer
then texLeft = -1
else
    texLeft = value-1
end
end

local function setTexCentre(value)
    texCentre = value-1
end
local function setTexRight(value)
    texRight = value-1
end

local function setTexDistance(value)
    texDistance = value
end
local function setRndPaint(value)
    if value == 2 then rndPaint = true
    else rndPaint = false
  end 
end
local function setRndWidth(value)
    rndWidth = value
end
local function setRndTex(value)
    rndTex = value-1
end
local function setRndDist(value)
    rndDist = value
end
local function paintTerrain2()
paintTerrainBySpline(centreWidth,edgeWidth,texLeft,texCentre,texRight,texDistance,rndPaint,rndWidth,rndTex, rndDist )
end

-- UI

local frameSizer = UIRowLayoutSizer.new()
local myFrame = UIWindow.new(frameSizer, "Paint Terrain By Spline")

local borderSizer = UIRowLayoutSizer.new()
UIPanel.new(frameSizer, borderSizer)

local rowSizer = UIRowLayoutSizer.new()
UIPanel.new(borderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)

    local centreWidthSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, centreWidthSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(centreWidthSliderSizer, "Set Centre Width", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local centreWidthSlider = UIFloatSlider.new(centreWidthSliderSizer, centreWidth, 0, 255 );
    centreWidthSlider:setOnChangeCallback(setCentreWidth)

    local edgeWidthSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, edgeWidthSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(edgeWidthSliderSizer, "Set Edge Width", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local edgeWidthSlider = UIFloatSlider.new(edgeWidthSliderSizer, edgeWidth, 0, 255 );
    edgeWidthSlider:setOnChangeCallback(setEdgeWidth)

    local texLeftPanelSizer = UIColumnLayoutSizer.new()
    local texLeftPanel      =UIPanel.new(rowSizer, texLeftPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local texLeftLabel      =UILabel.new(texLeftPanelSizer, "Set Edge Texture Left:", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local texLeftChoice  = UIChoice.new(texLeftPanelSizer, texturePaint, -1, -1, 100, -1)
    texLeftChoice:setOnChangeCallback(setTexLeft)
    
    local texCentrePanelSizer = UIColumnLayoutSizer.new()
    local texCentrePanel      = UIPanel.new(rowSizer, texCentrePanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local texCentreLabel      = UILabel.new(texCentrePanelSizer, "Set Centre Texture:", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local texCentreChoice      = UIChoice.new(texCentrePanelSizer, texturePaint, -1, -1, 100, -1)
    texCentreChoice:setOnChangeCallback(setTexCentre)

    local texRightPanelSizer = UIColumnLayoutSizer.new()
    local texRightPanel      = UIPanel.new(rowSizer, texRightPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local texRightLabel      = UILabel.new(texRightPanelSizer, "Set Edge Texture Right:", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local texRightChoice      = UIChoice.new(texRightPanelSizer, texturePaint, -1, -1, 100, -1)
    texRightChoice:setOnChangeCallback(setTexRight)

    local texDistanceSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, texDistanceSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(texDistanceSliderSizer, "Set Texture Distance", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local texDistanceSlider = UIFloatSlider.new(texDistanceSliderSizer, texDistance, 0.1, 255)
    texDistanceSlider:setOnChangeCallback(setTexDistance)

    local randomPaintPanelSizer = UIColumnLayoutSizer.new()
    local randomPaintPanel      = UIPanel.new(rowSizer, randomPaintPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local randomPaintChoiceLabel      = UILabel.new(randomPaintPanelSizer, "Select Random Paint", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local randomPaintChoice      = UIChoice.new(randomPaintPanelSizer, choice, 0, -1, 100, -1)
    randomPaintChoice:setOnChangeCallback(setRndPaint)

    local rndWidthSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, rndWidthSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(rndWidthSliderSizer, "Random Width (Max)", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local rndWidthSlider = UIIntSlider.new(rndWidthSliderSizer, rndWidth, 0, 50)
    rndWidthSlider:setOnChangeCallback(setRndWidth)

     local rndTexPanelSizer = UIColumnLayoutSizer.new()
    local rndTexPanel      = UIPanel.new(rowSizer, rndTexPanelSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    local rndTexLabel      = UILabel.new(rndTexPanelSizer, "Random Texture:", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local rndTexChoice      = UIChoice.new(rndTexPanelSizer, texturePaint, -1, 0, 100, -1)
    rndTexChoice:setOnChangeCallback(setRndTex)

    local rndDistSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, rndDistSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(rndDistSliderSizer, "Random Distance (Max)",false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local rndDistSlider = UIIntSlider.new(rndDistSliderSizer, rndDist, 0, 255)
    rndDistSlider:setOnChangeCallback(setRndDist)
 
    UIButton.new(rowSizer, "Paint", paintTerrain2)  
 myFrame:showWindow()


function paintTerrainBySpline(centreWidth,edgeWidth,texLeft,texCentre,texRight,texDistance,rndPaint,rndWidth,rndTex,rndDist )

function crossProduct(ax, ay, az, bx, by, bz)
    return ay*bz - az*by, az*bx - ax*bz, ax*by - ay*bx 
	end

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
        local overallWidth = centreWidth + (edgeWidth * 2)
		local mSideCount = overallWidth/2
        local mSplinePiece = texDistance	
            
	if  not rndPaint then
		local mSplineLength = getSplineLength( mSplineID ) ;
        local mSplinePiecePoint = mSplinePiece / mSplineLength ; -- relative size [0..1]
        local mSplinePos = 0.0;
      while mSplinePos <= 1.0 do
            -- get XYZ at position on spline
            local mPosX, mPosY, mPosZ = getSplinePosition( mSplineID, mSplinePos );
            -- directional vector at the point
            local mDirX, mDirY, mDirZ   = worldDirectionToLocal( mSplineID, getSplineDirection ( mSplineID, mSplinePos) );
            local mVecDx, mVecDy, mVecDz = crossProduct( mDirX, mDirY, mDirZ, 0, 1, 0);
            -- paint textures
			for i = 0, mSideCount,1 do ---mSplinePiecePoint do
                local mNewPosX1 = mPosX + i * mVecDx;
                local mNewPosZ1 = mPosZ + i * mVecDz;
                local mNewPosX2 = mPosX - i * mVecDx;
                local mNewPosZ2 = mPosZ - i * mVecDz;
            setTerrainLayerAtWorldPos(mTerrainID, texCentre, mNewPosX1, mPosY, mNewPosZ1, 128.0 );
            setTerrainLayerAtWorldPos(mTerrainID, texCentre, mNewPosX2, mPosY, mNewPosZ2, 128.0);
            
			local offset = centreWidth/2
			if edgeWidth > 0 and i > offset then
                local mNewEdgeX1 = mPosX + i * mVecDx;
                local mNewEdgeZ1 = mPosZ + i * mVecDz;
                local mNewEdgeX2 = mPosX - i * mVecDx;
                local mNewEdgeZ2 = mPosZ - i * mVecDz;
                if texLeft == -1 then
                    setTerrainLayerAtWorldPos(mTerrainID, texRight, mNewPosX1, mPosY, mNewPosZ1, 128.0 );
                elseif
                texRight == -1 then
                    setTerrainLayerAtWorldPos(mTerrainID, texLeft, mNewPosX2, mPosY, mNewPosZ2, 128.0 );
                else
                    setTerrainLayerAtWorldPos(mTerrainID, texRight, mNewPosX1, mPosY, mNewPosZ1, 128.0 );
                    setTerrainLayerAtWorldPos(mTerrainID, texLeft, mNewPosX2, mPosY, mNewPosZ2, 128.0 );
            end;
			end;
            end;
         
			mSplinePos = mSplinePos + mSplinePiecePoint;  
			end;
		end;	

			--Random Paint
		if rndPaint then
				if rndWidth == 0 or rndDist == 0 then 
				print("\n\t********   WARNING : ERROR IN Width/Distance Settings  *******") 
				return
				end
                local rSplinePiece = 0
				local rSideCount = rndWidth/2 
				local rSplinePiece = rSplinePiece + math.random(0,rndDist) 
				local rSplineLength = getSplineLength( mSplineID ) ;
				local rSplinePiecePoint = rSplinePiece / rSplineLength ; -- relative size [0..1]
				local rSplinePos = 0.01;

			while rSplinePos <= 1.0 do
            -- get XYZ at position on spline
				local rPosX, rPosY, rPosZ = getSplinePosition( mSplineID, rSplinePos );
			--place texture at random x,z distance away from spline distanc evaries between 1 and half the the random width
				local rNewPosX1 = rPosX + math.random(0,rSideCount)
				local rNewPosZ1 = rPosZ + math.random(0,rSideCount)
				local rNewPosX2 = rPosX - math.random(0,rSideCount)
				local rNewPosZ2 = rPosZ - math.random(0,rSideCount)
				if texRight == addedLayer-1 then
				setTerrainLayerAtWorldPos(mTerrainID, rndTex, rNewPosX1, rPosY, rNewPosZ1, 128.0); --left
				elseif
				texLeft == addedLayer-1 then
				setTerrainLayerAtWorldPos(mTerrainID, rndTex, rNewPosX2, rPosY, rNewPosZ2, 128.0 ); --right
				else
				setTerrainLayerAtWorldPos(mTerrainID, rndTex, rNewPosX1, rPosY, rNewPosZ1, 128.0); --left
				setTerrainLayerAtWorldPos(mTerrainID, rndTex, rNewPosX2, rPosY, rNewPosZ2, 128.0 ); --right
			end
            	rSplinePos = rSplinePos + rSplinePiecePoint;  -- goto next point						
			end;			
		end;
	if not rndPaint then
		print(string.format("\nSpline Name :%s", splineName))
		if edgeWidth == 0 then 
		print(textureName[texCentre])
		print(string.format("Centre Width : %.1f m :\n Texture Distance: %.1f", centreWidth, texDistance ))
		return end;

		print(textureName[texLeft])
		print(textureName[texCentre])
		print(textureName[texRight])
		print(string.format("Centre Width : %.1f m : Edge Width : %.1f m : \nTexture Distance: %.1f",centreWidth, edgeWidth, texDistance))
	else
		print(string.format("\nSpline Name :%s", splineName))
		print(textureName[rndTex])
		print(string.format("Random Width : %.1f m :\n Texture Distance: %.1f", rndWidth, rndDist ))
		end;
end


