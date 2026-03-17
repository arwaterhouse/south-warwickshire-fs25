-- Author:ezaitsev,TracMax,W_R"
-- Name:Spline CSV Creator Panel OBJ_25
-- Description:
-- Icon:
-- Hide: no
-- AlwaysLoaded: no
-- Version : 28-11-2024 updated to FS25, 20-01-24 Added spline obj creation

csvTxt = {}
csvSpline = {}
	
	local labelWidth = 120.0	
	local CSVdistance = 0
	
    local function setCSVDistance(value)
    CSVdistance = value
    end
    local function createCSVdata()
    createCSV(CSVdistance)
    end
    
-- UI

    local frameSizer = UIRowLayoutSizer.new()
    local myFrame = UIWindow.new(frameSizer, "CSV Creator")

    local borderSizer = UIRowLayoutSizer.new()
    UIPanel.new(frameSizer, borderSizer)

    local rowSizer = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)

    local CSVSliderSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, CSVSliderSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UILabel.new(CSVSliderSizer, "Set CSV Distance", false, TextAlignment.LEFT,VerticalAlignment.TOP, -1, -1, labelWidth)
    local CSVSlider = UIFloatSlider.new(CSVSliderSizer, CSVdistance, 0, 255 );
    CSVSlider:setOnChangeCallback(setCSVDistance)

    UIButton.new(rowSizer, "Create CSV", createCSVdata)  
 myFrame:showWindow()
  
    function createCSV(CSVdistance)

    
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
		end;
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
	
	local fileName = getSceneFilename()
    local fNd = fileName:find("/[^/]*$")
	local newStr = string.sub(fileName,1,fNd)	
	local newStr2 = newStr.."/CSVdata/"
		createFolder(newStr2)
	local filename1 = newStr2..splineName.."_CSV.i3d"	
	local splineFile = createFile(filename1,0)
	local filename2 = newStr2..splineName.."_CSV.obj"
    local splineObj = createFile(filename2,0)
        fileWrite(splineObj,"# GE Spline Export".." "..splineName.."\n")
    local filename3 = newStr2..splineName.."_CSVdata.txt"
    local csvFile = createFile(filename3,0)
	local mSplinePiece = CSVdistance
	local mSplineLength = getSplineLength( mSplineID ) ;
	local mSplinePiecePoint = mSplinePiece / mSplineLength ; -- relative size [0..1]
	local mSplinePos = 0.0;
    local bl = 0
    local vPoints = 0
	local xmlTop = string.format("<?xml version=%q encoding=%q?>\n","1.0","iso-8859-1")
	local xmlOne = string.format("<i3D name=%q version=%q xmlns:xsi=%q xsi:noNamespaceSchemaLocation=%q>\n",splineName,"1.6","http://www.w3.org/2001/XMLSchema-instance","http://i3d.giants.ch/schema/i3d-1.6.xsd",">")
	local xmlTwo = string.format("       <Asset>\n         <Export program=%q version=%q/>\n       </Asset>\n","Spline and CSV creator by ezaitsev,TracMax,W_R","1.1 (20-07-2022)")
	local splineName = splineName.."_CSV"
	local xmlThree = string.format("    <Shapes>\n         <NurbsCurve name=%q shapeId=%q degree=%q form=%q>",splineName,"11","3","open")
	local xmlFour = string.format("\n         </NurbsCurve>\n    </Shapes>\n    <Scene>\n         <Shape name=%q translation=%q nodeId=%q shapeId=%q/>\n    </Scene>  \n</i3D>",splineName,"0 0 0","11","11")
	fileWrite(splineFile,xmlTop..xmlOne..xmlTwo..xmlThree)
	while mSplinePos <= 1.0 do
        local xPos, yPos, zPos = getSplinePosition( mSplineID, mSplinePos );
        local ht = getTerrainHeightAtWorldPos(mTerrainID, xPos,yPos,zPos);
		if ht == 0 then ht = yPos 
		end;
        bl =bl + 1
		local csvPos = string.format("%f, %f, %f",xPos,ht,zPos);
        csvTxt[bl] = string.format("%f, %f, %f\n",zPos,xPos,ht);
        csvSpline[bl] = string.format("\n              <cv c=%q />",csvPos);
		fileWrite(splineFile,csvSpline[bl])
        fileWrite(csvFile,csvTxt[bl])
        fileWrite(splineObj, "v "..tostring(xPos).."\t "..tostring(ht).."\t "..tostring(zPos).."\n")
        vPoints = vPoints + 1
        mSplinePos = mSplinePos + mSplinePiecePoint;
    end;
  --join the dots  
    for i = 1, vPoints-1 do
    fileWrite(splineObj, "l "..tostring(i).." "..tostring(i+1).."\n")
    end   
fileWrite(splineFile,xmlFour)
delete(splineFile);
delete(csvFile);
delete(splineObj);

print(string.format("\nNew Spline : %s , %s and %s created in /CSVdata Folder\n",splineName..".i3d",splineName..".obj",splineName.."data.txt"))

  
 end 