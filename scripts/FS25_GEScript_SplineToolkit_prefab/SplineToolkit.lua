-- Author: Aslan
-- Name: SplineToolkit
-- Namespace: local
-- Description: Werkzeug für die Bearbeitung von Splines
-- Icon: iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAJWGlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDggNzkuMTY0MDM2LCAyMDE5LzA4LzEzLTAxOjA2OjU3ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdEV2dD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlRXZlbnQjIiB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjEuMCAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDI2LTAyLTIyVDIyOjM0OjUwKzAxOjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDI2LTAyLTIyVDIyOjM0OjUwKzAxOjAwIiB4bXA6TW9kaWZ5RGF0ZT0iMjAyNi0wMi0yMlQyMjozNDo1MCswMTowMCIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDo4ZGU4NDAxNS00NWQyLTA1NDEtOWEyZi01MDFlZTEyMTQyMDUiIHhtcE1NOkRvY3VtZW50SUQ9ImFkb2JlOmRvY2lkOnBob3Rvc2hvcDozNDk4MmEwZi0wNjBkLTQ5NDktODNmYS01NDExNzkyMTU1MGQiIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDoyYzI0MDc2Zi1jNzJmLTU4NGItOThkNy0zYjkxMWU2MDQ3YjYiIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiIGRjOmZvcm1hdD0iaW1hZ2UvcG5nIj4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDoyYzI0MDc2Zi1jNzJmLTU4NGItOThkNy0zYjkxMWU2MDQ3YjYiIHN0RXZ0OndoZW49IjIwMjYtMDItMjJUMjI6MzQ6NTArMDE6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMS4wIChXaW5kb3dzKSIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6OGRlODQwMTUtNDVkMi0wNTQxLTlhMmYtNTAxZWUxMjE0MjA1IiBzdEV2dDp3aGVuPSIyMDI2LTAyLTIyVDIyOjM0OjUwKzAxOjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjEuMCAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDxwaG90b3Nob3A6RG9jdW1lbnRBbmNlc3RvcnM+IDxyZGY6QmFnPiA8cmRmOmxpPjBGQkIwM0ExNjI0QUVERDg0N0I0QUZDQzg0MzBGRjkwPC9yZGY6bGk+IDxyZGY6bGk+MURDNzRGOURDMTdBODg0MkNEODdGNjM5NDAwMjI0NUE8L3JkZjpsaT4gPHJkZjpsaT4yNzQ0RkFDNUJCN0Y0RjBBRDdEMTZDMUFBRTY4RUQyMzwvcmRmOmxpPiA8cmRmOmxpPjUwMDkxQ0Y2QjBFMjAxQzY4RTMxMDMyMTU4QzRCNTA4PC9yZGY6bGk+IDxyZGY6bGk+QzFBOEM3N0VENTE1MzIxQ0MyQzgyRkFEMkFENDgxRTc8L3JkZjpsaT4gPHJkZjpsaT5DNTZDNUM3NzU3MzI3QjQ0NzA3M0I0Qzc2QzAzRTIxRTwvcmRmOmxpPiA8cmRmOmxpPkRERkEwMjkzMTI1MDAxMDREMjgyMjVDRkY0QzA5MEUzPC9yZGY6bGk+IDxyZGY6bGk+RUFDNzZFOTczQjI3Q0M2MTk5RDc2N0EzREI1Q0Q2RUU8L3JkZjpsaT4gPHJkZjpsaT5GMDlBMDEyQTFBQTdFNDlBMzVCODBGQTYzNDc3MzAzNTwvcmRmOmxpPiA8cmRmOmxpPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDozMThkYmMwNS0yYzg3LTFiNGEtYmY1Mi03MWY3ZjA5YmQzZTM8L3JkZjpsaT4gPHJkZjpsaT5hZG9iZTpkb2NpZDpwaG90b3Nob3A6NDY4MjA4NzQtODRiMS1kMDQxLTlkNGQtMzRiZjk5OTg1NWViPC9yZGY6bGk+IDxyZGY6bGk+YWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjdmYzJlNTU0LTc5MjgtZmY0NC04YTI2LTYwZjg3YzY5OWVmYzwvcmRmOmxpPiA8cmRmOmxpPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDo5ZmIwNzczNi00MjBiLTMzNGUtODU5OS1hMjhhODc5YjExNWU8L3JkZjpsaT4gPHJkZjpsaT5hZG9iZTpkb2NpZDpwaG90b3Nob3A6ZTU3NjBlZWUtYzlmMS1iZjQwLWJhMzYtZGZmYWUyMzAxYTBmPC9yZGY6bGk+IDwvcmRmOkJhZz4gPC9waG90b3Nob3A6RG9jdW1lbnRBbmNlc3RvcnM+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8++nrl+wAAAzVJREFUOBEFwdtrHFUAwOHfmTmz2Uw2e0l2k123NhfRphViekErQVpf1GrBB4v4oFIiKFr1DxDRor6IN/ShLfgmCEKxeCmo7UuKlQTBRpIQkibtmmza3LrZS7I7uzNzzvH75PrP7w3UC1fPp/cw4rWU5TqC0HEJA0AAxoA2oA0oAWgQWtdLzHTuP/WmDDYmL/Q/Vn9qaruPqeRL1GoFTnd/TybZAhEBbYFvwBfggWkqhIGudKx37fYvF6RrLR66VRR8qs6SHX2UH+ehOBFydmgaraoIXUKyg6SGE9HYMoauG6ymh2yWh6WjG2q90sPFuZBIYxO/tMOceZK2Ex+DBhE0wdsg3JzDW7kKW5eJx8sIE0W0PCVbgc1w7h6jS9/w138nsRurHM3+xtRXXxO6eeyuQaK9D5F58BDdT5+A9bepXjtNyp3Fshxk0NCkEw4/PPM7V/4ZJzsQcmw4ABHQ2m3SWDZU/oWl72xWj7zO4++cw+sbw7/1BoY4klBBWbDnPoex1Da6KfBUitDOYyUzdOYyJDoH2BsbIvrAceoBrM5NcMABow3ShBqaLarbNn7mRaIjz+PkDuIk8minHWWD70O9UqZw8wabf35IX/MSzr42TCtEojSN7RbBI+dJPjHGWnGVewsz7KxeJiytEJaLiFoR2VghJTc4mNWk9rqoXYVuGiRK4TWjRA+cJGzscPvcK1AYpysGnR3gutDRDTIPlVKMVqMDr1qhwzGgHKQJwVa7TF/8jP0vf8SxT/4guDuLvz5DuLWAri4TtNYo3lgjdfh94mWP4rUv6Dt6E7REhi1IxCOkl77k7w+u4468QGJolOT9z+E+/CptUYG2wL/yGtmffgWlsWcj3MkJ4kmQKI32DAN5h3Rlkq2JSbbHJVt2GtXeg+nIohK9lBYmsOZrxNpdpvwqhyOABtnwtG0BOoBEZ4RkwmC0QakNwmCdwJ8mqEBhWHC9EiGo1xg4EtKfg8WCsuSOHJxdLswfz+YjaANCAUIgLImMghMVoGE4bsj1KPwAMgkoLisq1uCCzD777pnipc+/vTu1vM+WCIMAQAgAAIMAjAEhQAhYu2OMiu5d7D/11pn/AWm5hR5lZHbjAAAAAElFTkSuQmCC
-- Hide: no
-- AlwaysLoaded: no

source("editorUtils.lua")
source("ui/ProgressDialog.lua")
source("ui/MessageBox.lua")
source("ui/YesNoDialog.lua")
-- source("Hooks.lua")

local gamePath = EditorUtils.getGameBasePath()
if gamePath == nil then
    return
end

source(gamePath .. "dataS/scripts/std.lua")
source(gamePath .. "dataS/scripts/shared/class.lua")
source(gamePath .. "dataS/scripts/misc/Logging.lua")
source(gamePath .. "dataS/scripts/xml/XMLFile.lua")
source(gamePath .. "dataS/scripts/xml/XMLManager.lua")
source("dataS/scripts/i3d/I3DUtil.lua")
source("dataS/scripts/utils/MathUtil.lua")

SplineToolkit = {}
SplineToolkit.DEBUG_MODE = true
SplineToolkit.WINDOW_WIDTH = 450
SplineToolkit.SETTINGS_PATH = getAppDataPath() .. "SplineToolkitSettings.xml"
SplineToolkit.FENCE_RAW_IMG_PATH = "scripts/imgFence/" 
SplineToolkit.ROAD_RAW_IMG_PATH = "scripts/imgRoads/" 

local function getScriptEnvironment(rawPath)
	local editorPath = getEditorDirectory() .. rawPath
	local appDataPath = getAppDataPath() .. rawPath

	if folderExists(editorPath) then
		return getEditorDirectory()
	end

	if folderExists(appDataPath) then
		return getAppDataPath()
	end

	return getEditorDirectory()
end

SplineToolkit.FENCE_IMG_PATH = getScriptEnvironment(SplineToolkit.FENCE_RAW_IMG_PATH) .. SplineToolkit.FENCE_RAW_IMG_PATH
SplineToolkit.ROAD_IMG_PATH = getScriptEnvironment(SplineToolkit.ROAD_RAW_IMG_PATH) .. SplineToolkit.ROAD_RAW_IMG_PATH

local basePath = getSceneFilename():match("(.*/)")
SplineToolkit.EXPORT_PATH = basePath .. "SplineToolkitAslan/" 
SplineToolkit.EXPORT_PATH_OBJ = SplineToolkit.EXPORT_PATH .. "SplineExport/" 
SplineToolkit.EXPORT_PATH_ROAD = SplineToolkit.EXPORT_PATH .. "Roads/" 

function SplineToolkit.new()
    local self = setmetatable({}, { __index = SplineToolkit })

    self.window = nil
	self.currentTab = nil
	self.tabNames = {"Base Tools", "Place Object", "Place Fence", "Export .OBJ", "Gen. Street"}
	self.panels = {}
	
	self.foliageLayers = {
		options = {},
		states = {},
		channels = {},
		offsets = {}
	}

	self.values = {
		base = {
			setOnTerrain = { heightOffset = 0.0 },
			setOffset = { sideOffset = 0.0, heightOffset = 0.0 },
			setTerrainHeight = { terrainHeight = 0.0, terrainWidth = 3.0, smoothDistance = 1.0 },
			paintTerrain = { textureLayers = {}, widthLeft = 3.0, widthRight = 3.0 },
			setFoliage = { widthLeft = 3.0, widthRight = 3.0 },
			resampleSpline = { numPoints = 15 },
		},
		
		objectPlacement = {
			objPlaceType = {"Sequential", "Sequential with Width", "Random", "Random with Width"},
			sideOffset = 0.0,
			widthLeft = 3.0,
			widthRight = 3.0,
			objDistanceType = {"Fixed", "Random"},
			objectFixDistance = 5.0,
			objectMinDistance = 1.0,
			objectMaxDistance = 10.0,
			setHeightType = {"On Spline", "On Spline + Follow Axis", "On Terrain", "On Terrain + Normals", "On Terrain + Follow Axis", "Fix Value"},
			setOnTerrainNormals = {"False", "True"},
			followAxis = {"X", "Z"},
			objectHeight = 0.0,
			objectRotate = 0.0,
			setRandomRotate = {"False", "True"},
		},

		fencePlacement = {
			imgPath = SplineToolkit.FENCE_IMG_PATH,
			defaultImage = "defaultIcon.png",
			fenceTable = {
				{ name = "AS Fence 01", xmlFile = "$data/placeables/brandless/fences/AS/fence01/fence01.xml", imgFile = "AS_fence01.png"},
				{ name = "AS Fence 02", xmlFile = "$data/placeables/brandless/fences/AS/fence02/fence02.xml", imgFile = "AS_fence02.png"},
				{ name = "AS Fence 03", xmlFile = "$data/placeables/brandless/fences/AS/fence03/fence03.xml", imgFile = "AS_fence03.png"},
				{ name = "AS Fence 04", xmlFile = "$data/placeables/brandless/fences/AS/fence04/fence04.xml", imgFile = "AS_fence04.png"},
				{ name = "AS Fence 05", xmlFile = "$data/placeables/brandless/fences/AS/fence05/fence05.xml", imgFile = "AS_fence05.png"},
				{ name = "AS Fence 06", xmlFile = "$data/placeables/brandless/fences/AS/fence06/fence06.xml", imgFile = "AS_fence06.png"},
				{ name = "AS Fence 07", xmlFile = "$data/placeables/brandless/fences/AS/fence07/fence07.xml", imgFile = "AS_fence07.png"},
				{ name = "AS Fence 08", xmlFile = "$data/placeables/brandless/fences/AS/fence08/fence08.xml", imgFile = "AS_fence08.png"},
				{ name = "AS Fence 09", xmlFile = "$data/placeables/brandless/fences/AS/fence09/fence09.xml", imgFile = "AS_fence09.png"},
				{ name = "AS Fence 10", xmlFile = "$data/placeables/brandless/fences/AS/fence10/fence10.xml", imgFile = "AS_fence10.png"},
				{ name = "AS Fence 12", xmlFile = "$data/placeables/brandless/fences/AS/fence12/fence12.xml", imgFile = "AS_fence12.png"},
				{ name = "AS Fence 13", xmlFile = "$data/placeables/brandless/fences/AS/fence13/fence13.xml", imgFile = "AS_fence13.png"},
				{ name = "AS Fence 14", xmlFile = "$data/placeables/brandless/fences/AS/fence14/fence14.xml", imgFile = "AS_fence14.png"},
				{ name = "AS Fence 15", xmlFile = "$data/placeables/brandless/fences/AS/fence15/fence15.xml", imgFile = "AS_fence15.png"},
				{ name = "AS Fence 16", xmlFile = "$data/placeables/brandless/fences/AS/fence16/fence16.xml", imgFile = "AS_fence16.png"},
				{ name = "AS Fence 17", xmlFile = "$data/placeables/brandless/fences/AS/fence17/fence17.xml", imgFile = "AS_fence17.png"},
				
				{ name = "EU Fence 01", xmlFile = "$data/placeables/brandless/fences/EU/fence01/fence01.xml", imgFile = "EU_fence01.png"},
				{ name = "EU Fence 02", xmlFile = "$data/placeables/brandless/fences/EU/fence02/fence02.xml", imgFile = "EU_fence02.png"},
				{ name = "EU Fence 03", xmlFile = "$data/placeables/brandless/fences/EU/fence03/fence03.xml", imgFile = "EU_fence03.png"},
				{ name = "EU Fence 04", xmlFile = "$data/placeables/brandless/fences/EU/fence04/fence04.xml", imgFile = "EU_fence04.png"},
				{ name = "EU Fence 05", xmlFile = "$data/placeables/brandless/fences/EU/fence05/fence05.xml", imgFile = "EU_fence05.png"},
				{ name = "EU Fence 06", xmlFile = "$data/placeables/brandless/fences/EU/fence06/fence06.xml", imgFile = "EU_fence06.png"},
				{ name = "EU Fence 07", xmlFile = "$data/placeables/brandless/fences/EU/fence07/fence07.xml", imgFile = "EU_fence07.png"},
				{ name = "EU Fence 08", xmlFile = "$data/placeables/brandless/fences/EU/fence08/fence08.xml", imgFile = "EU_fence08.png"},
				{ name = "EU Fence 09", xmlFile = "$data/placeables/brandless/fences/EU/fence09/fence09.xml", imgFile = "EU_fence09.png"},
				{ name = "EU Fence 10", xmlFile = "$data/placeables/brandless/fences/EU/fence10/fence10.xml", imgFile = "EU_fence10.png"},
				{ name = "EU Fence 11", xmlFile = "$data/placeables/brandless/fences/EU/fence11/fence11.xml", imgFile = "EU_fence11.png"},
				{ name = "EU Fence 12", xmlFile = "$data/placeables/brandless/fences/EU/fence12/fence12.xml", imgFile = "EU_fence12.png"},
				{ name = "EU Fence 13", xmlFile = "$data/placeables/brandless/fences/EU/fence13/fence13.xml", imgFile = "EU_fence13.png"},
				{ name = "EU Fence 14", xmlFile = "$data/placeables/brandless/fences/EU/fence14/fence14.xml", imgFile = "EU_fence14.png"},
				{ name = "EU Fence 15", xmlFile = "$data/placeables/brandless/fences/EU/fence15/fence15.xml", imgFile = "EU_fence15.png"},
				{ name = "EU Fence 16", xmlFile = "$data/placeables/brandless/fences/EU/fence16/fence16.xml", imgFile = "EU_fence16.png"},
				{ name = "EU Fence 17", xmlFile = "$data/placeables/brandless/fences/EU/fence17/fence17.xml", imgFile = "EU_fence17.png"},
				{ name = "EU Fence 18", xmlFile = "$data/placeables/brandless/fences/EU/fence18/fence18.xml", imgFile = "EU_fence18.png"},
				{ name = "EU Fence 19", xmlFile = "$data/placeables/brandless/fences/EU/fence19/fence19.xml", imgFile = "EU_fence19.png"},
				{ name = "EU Fence 20", xmlFile = "$data/placeables/brandless/fences/EU/fence20/fence20.xml", imgFile = "EU_fence20.png"},
				
				{ name = "US Fence 01", xmlFile = "$data/placeables/brandless/fences/US/fence01/fence01.xml", imgFile = "US_fence01.png"},
				{ name = "US Fence 02", xmlFile = "$data/placeables/brandless/fences/US/fence02/fence02.xml", imgFile = "US_fence02.png"},
				{ name = "US Fence 03", xmlFile = "$data/placeables/brandless/fences/US/fence03/fence03.xml", imgFile = "US_fence03.png"},
				{ name = "US Fence 04", xmlFile = "$data/placeables/brandless/fences/US/fence04/fence04.xml", imgFile = "US_fence04.png"},
				{ name = "US Fence 05", xmlFile = "$data/placeables/brandless/fences/US/fence05/fence05.xml", imgFile = "US_fence05.png"},
				{ name = "US Fence 06", xmlFile = "$data/placeables/brandless/fences/US/fence06/fence06.xml", imgFile = "US_fence06.png"},
				{ name = "US Fence 07", xmlFile = "$data/placeables/brandless/fences/US/fence07/fence07.xml", imgFile = "US_fence07.png"},
				{ name = "US Fence 07 Metal", xmlFile = "$data/placeables/brandless/fences/US/fence07/fenceMetal07.xml", imgFile = "US_fence07Metal.png"},
				{ name = "US Fence 08", xmlFile = "$data/placeables/brandless/fences/US/fence08/fence08.xml", imgFile = "US_fence08.png"},
				{ name = "US Fence 09", xmlFile = "$data/placeables/brandless/fences/US/fence09/fence09.xml", imgFile = "US_fence09.png"},
				{ name = "US Fence 10", xmlFile = "$data/placeables/brandless/fences/US/fence10/fence10.xml", imgFile = "US_fence10.png"},
				{ name = "US Fence 11", xmlFile = "$data/placeables/brandless/fences/US/fence11/fence11.xml", imgFile = "US_fence11.png"},
				{ name = "US Fence 12", xmlFile = "$data/placeables/brandless/fences/US/fence12/fence12.xml", imgFile = "US_fence12.png"},
				{ name = "US Fence 13", xmlFile = "$data/placeables/brandless/fences/US/fence13/fence13.xml", imgFile = "US_fence13.png"},
				{ name = "US Fence 14", xmlFile = "$data/placeables/brandless/fences/US/fence14/fence14.xml", imgFile = "US_fence14.png"},
				{ name = "US Fence 15", xmlFile = "$data/placeables/brandless/fences/US/fence15/fence15.xml", imgFile = "US_fence15.png"},
				{ name = "US Fence 16", xmlFile = "$data/placeables/brandless/fences/US/fence16/fence16.xml", imgFile = "US_fence16.png"},
				{ name = "US Fence 17", xmlFile = "$data/placeables/brandless/fences/US/fence17/fence17.xml", imgFile = "US_fence17.png"},
				
				{ name = "Husbandries 01", xmlFile = "$data/placeables/brandless/fences/husbandries/level01/fencesFarmLevel01.xml", imgFile = "HUS_fencesFarmLevel01.png"},
				{ name = "Husbandries 02", xmlFile = "$data/placeables/brandless/fences/husbandries/level02/fencesFarmLevel02.xml", imgFile = "HUS_fencesFarmLevel02.png"},
				{ name = "Husbandries 03", xmlFile = "$data/placeables/brandless/fences/husbandries/level03/fencesFarmLevel03.xml", imgFile = "HUS_fencesFarmLevel03.png"},
				{ name = "Husbandries 04", xmlFile = "$data/placeables/brandless/fences/husbandries/level04/fencesFarmLevel04.xml", imgFile = "HUS_fencesFarmLevel04.png"},
				{ name = "Husbandries 05", xmlFile = "$data/placeables/brandless/fences/husbandries/level05/fencesFarmLevel05.xml", imgFile = "HUS_fencesFarmLevel05.png"},
				{ name = "Husbandries Chicken", xmlFile = "$data/placeables/brandless/fences/husbandries/chickenNetFence/chickenNetFence.xml", imgFile = "HUS_chickenNetFence.png"},
				{ name = "Husbandries Cow", xmlFile = "$data/placeables/brandless/fences/husbandries/cowFence/cowFence.xml", imgFile = "HUS_cowFence.png"},
				{ name = "Husbandries Sheep", xmlFile = "$data/placeables/brandless/fences/husbandries/sheepNetFence/sheepNetFence.xml", imgFile = "HUS_sheepNetFence.png"},
			},
			placeType = {"Cubic", "Linear"},
			useYOffset = {"True", "False"},
			placeStartPole = {"True", "False"},
			placeEndPole = {"True", "False"},
			mirrorFence = {"False", "True"},
			fenceGateChoice = {},
		},
		
		exportObject = {
			useCustomFilename = false,
			defaultFileName = "SplineExport",
			customFileName = "",
			createMeshType = {"only Vertex", "as Spline"},
			distanceType = {"Fixed", "Variable"},
			vertexDistance = 2,
			vertexMinDistance = 0.5,
			vertexMinAngle = 5,
		},
		
		roadMesh = {
			-- Texture
			imgPath = SplineToolkit.ROAD_IMG_PATH,
			defaultImage = "defaultIcon.png",
			mirrorAtCenter = {"True", "False"},
			textureDistance = 5.0,
			sliceStart = 0.0,
			sliceEnd = 25.0,
			
			textureTable = {
				-- AS ROADS
				{	name = "AS Main Road", imgFile = "AS_mainRoad.png", shaderVar = "alphaNoise_customParallax_alphaMap",
					textures = {
						["diffuse"] = "$data/maps/mapAS/textures/buildings/infrastructure/mainRoad_diffuse.dds",
						["specular"] = "$data/maps/mapAS/textures/buildings/infrastructure/mainRoad_specular.dds",
						["normal"] = "$data/maps/mapAS/textures/buildings/infrastructure/mainRoad_normal.dds",
						["height"] = "$data/maps/mapAS/textures/buildings/infrastructure/mainRoad_height.dds",
						["alpha"] = "$data/maps/mapAS/textures/buildings/infrastructure/mainRoad_alpha.dds",
					},
				},
				{	name = "AS Secondary Road", imgFile = "AS_secondaryRoad.png", shaderVar = "alphaNoise_customParallax_alphaMap",
					textures = {
						["diffuse"] = "$data/maps/mapAS/textures/buildings/infrastructure/mainRoadSecondary_diffuse.dds",
						["specular"] = "$data/maps/mapAS/textures/buildings/infrastructure/mainRoadSecondary_specular.dds",
						["normal"] = "$data/maps/mapAS/textures/buildings/infrastructure/mainRoadSecondary_normal.dds",
						["height"] = "$data/maps/mapAS/textures/buildings/infrastructure/mainRoadSecondary_height.dds",
						["alpha"] = "$data/maps/mapAS/textures/buildings/infrastructure/mainRoadSecondary_alpha.dds",
					},
				},
				{	name = "AS Village Road", imgFile = "AS_villageRoad.png", shaderVar = "alphaNoise_customParallax_alphaMap",
					textures = {
						["diffuse"] = "$data/maps/mapAS/textures/buildings/infrastructure/villageRoad_diffuse.dds",
						["specular"] = "$data/maps/mapAS/textures/buildings/infrastructure/villageRoad_specular.dds",
						["normal"] = "$data/maps/mapAS/textures/buildings/infrastructure/villageRoad_normal.dds",
						["height"] = "$data/maps/mapAS/textures/buildings/infrastructure/villageRoad_height.dds",
						["alpha"] = "",
					},
				},
				{	name = "AS Dirt Road", imgFile = "AS_dirtRoad.png", shaderVar = "alphaNoise_terrainFormat_customParallax",
					textures = {
						["diffuse"] = "$data/maps/mapAS/textures/buildings/infrastructure/dirtRoad_diffuse.dds",
						["specular"] = "$data/maps/mapAS/textures/buildings/infrastructure/dirtRoad_specular.dds",
						["normal"] = "$data/maps/mapAS/textures/buildings/infrastructure/dirtRoad_normal.dds",
						["height"] = "$data/maps/mapAS/textures/buildings/infrastructure/dirtRoad_height.dds",
						["alpha"] = "",
					},
				},
				-- EU ROADS
				{	name = "EU Main Road", imgFile = "EU_mainRoad.png", shaderVar = "alphaNoise_customParallax_alphaMap",
					textures = {
						["diffuse"] = "$data/maps/mapEU/textures/buildings/infrastructure/roads_diffuse.dds",
						["specular"] = "$data/maps/mapEU/textures/buildings/infrastructure/roads_specular.dds",
						["normal"] = "$data/maps/mapEU/textures/buildings/infrastructure/roads_normal.dds",
						["height"] = "",
						["alpha"] = "",
					},
				},
				{	name = "EU Secondary Road", imgFile = "EU_secondaryRoad.png", shaderVar = "alphaNoise_terrainFormat_customParallax",
					textures = {
						["diffuse"] = "$data/maps/mapEU/textures/buildings/infrastructure/sideRoads_diffuse.dds",
						["specular"] = "$data/maps/mapEU/textures/buildings/infrastructure/sideRoads_specular.dds",
						["normal"] = "$data/maps/mapEU/textures/buildings/infrastructure/sideRoads_normal.dds",
						["height"] = "",
						["alpha"] = "",
					},
				},
				{	name = "EU Dirt Road 01", imgFile = "EU_dirtRoad01.png", shaderVar = "alphaNoise_terrainFormat_customParallax",
					textures = {
						["diffuse"] = "$data/maps/mapEU/textures/buildings/infrastructure/dirtRoad01_diffuse.dds",
						["specular"] = "$data/maps/mapEU/textures/buildings/infrastructure/dirtRoad_specular.dds",
						["normal"] = "$data/maps/mapEU/textures/buildings/infrastructure/dirtRoad_normal.dds",
						["height"] = "",
						["alpha"] = "",
					},
				},
                {	name = "EU Dirt Road 02", imgFile = "EU_dirtRoad02.png", shaderVar = "alphaNoise_terrainFormat_customParallax",
					textures = {
						["diffuse"] = "$data/maps/mapEU/textures/buildings/infrastructure/dirtRoad02_diffuse.dds",
						["specular"] = "$data/maps/mapEU/textures/buildings/infrastructure/dirtRoad_specular.dds",
						["normal"] = "$data/maps/mapEU/textures/buildings/infrastructure/dirtRoad_normal.dds",
						["height"] = "",
						["alpha"] = "",
					},
				},
				
				-- US ROADS
				{	name = "US Main Road", imgFile = "US_mainRoad.png", shaderVar = "alphaNoise_customParallax_alphaMap",
					textures = {
						["diffuse"] = "$data/maps/mapUS/textures/buildings/infrastructure/mainRoad_diffuse.dds",
						["specular"] = "$data/maps/mapUS/textures/buildings/infrastructure/mainRoad_specular.dds",
						["normal"] = "$data/maps/mapUS/textures/buildings/infrastructure/mainRoad_normal.dds",
						["height"] = "$data/maps/mapUS/textures/buildings/infrastructure/mainRoad_height.dds",
						["alpha"] = "$data/maps/mapUS/textures/buildings/infrastructure/mainRoad_alpha.dds",
					},
				},
				{	name = "US Secondary Road", imgFile = "US_secondaryRoad.png", shaderVar = "alphaNoise_customParallax_alphaMap",
					textures = {
						["diffuse"] = "$data/maps/mapUS/textures/buildings/infrastructure/mainRoadSecondary_diffuse.dds",
						["specular"] = "$data/maps/mapUS/textures/buildings/infrastructure/mainRoadSecondary_specular.dds",
						["normal"] = "$data/maps/mapUS/textures/buildings/infrastructure/mainRoadSecondary_normal.dds",
						["height"] = "$data/maps/mapUS/textures/buildings/infrastructure/mainRoadSecondary_height.dds",
						["alpha"] = "$data/maps/mapUS/textures/buildings/infrastructure/mainRoadSecondary_alpha.dds",
					},
				},
				{	name = "US Gravel Road", imgFile = "US_gravelRoad.png", shaderVar = "alphaNoise_terrainFormat_customParallax",
					textures = {
						["diffuse"] = "$data/maps/mapUS/textures/buildings/infrastructure/gravelRoad_diffuse.dds",
						["specular"] = "$data/maps/mapUS/textures/buildings/infrastructure/gravelRoad_specular.dds",
						["normal"] = "$data/maps/mapUS/textures/buildings/infrastructure/gravelRoad_normal.dds",
						["height"] = "$data/maps/mapUS/textures/buildings/infrastructure/gravelRoad_height.dds",
						["alpha"] = "",
					},
				},
                {	name = "US Dirt Road", imgFile = "US_dirtRoad.png", shaderVar = "alphaNoise_terrainFormat_customParallax",
					textures = {
						["diffuse"] = "$data/maps/mapUS/textures/buildings/infrastructure/dirtRoad_diffuse.dds",
						["specular"] = "$data/maps/mapUS/textures/buildings/infrastructure/dirtRoad_specular.dds",
						["normal"] = "$data/maps/mapUS/textures/buildings/infrastructure/dirtRoad_normal.dds",
						["height"] = "$data/maps/mapUS/textures/buildings/infrastructure/dirtRoad_height.dds",
						["alpha"] = "",
					},
				},
                {	name = "US Dirt Gravel Road", imgFile = "US_dirtGravelRoad.png", shaderVar = "alphaNoise_terrainFormat_customParallax",
					textures = {
						["diffuse"] = "$data/maps/mapUS/textures/buildings/infrastructure/dirtGravelRoad02_diffuse.dds",
						["specular"] = "$data/maps/mapUS/textures/buildings/infrastructure/dirtGravelRoad_specular.dds",
						["normal"] = "$data/maps/mapUS/textures/buildings/infrastructure/dirtGravelRoad_normal.dds",
						["height"] = "$data/maps/mapUS/textures/buildings/infrastructure/dirtGravelRoad_height.dds",
						["alpha"] = "",
					},
				},
			},
			-- Mesh
			roadName = "",
			width = 7.0,
			minSegmentLength = 3.0,
			maxAngle = 2.5,
			alignEdgesOnTerrain = {"False", "True"},
			terrainDecal = {"True", "False"},
			-- Traffic
			trafficCenter = {"False", "True"},
			trafficLeft = {"False", "True"},
			trafficRight = {"False", "True"},
			leftPercent = 50,
			rightPercent = 50,
			maxSpeedScale = 1,
			speedLimit = 80,
		}
	}

    if not self:isMap() then
        printError("[SplineToolkit] This is not a Map!")
        return
    end

	self:setTerrainTextureLayers()
	self:loadFoliageLayers()
    self:generateUI()
	
    return self
end

function SplineToolkit:isMap()
    local rootNode = getRootNode()
    if rootNode == nil or rootNode == 0 then
        return false
    end

    for i = 0, getNumOfChildren(rootNode) - 1 do
        local child = getChildAt(rootNode, i)
        if child ~= nil and child ~= 0 and getName(child) == "terrain" then
            return true
        end
    end

    return false
end

function SplineToolkit:onChangeTab(tabName, isOpenWnd)
	if not isOpenWnd then
		self:saveSettings(self.currentTab)
		
		if self.uiListFence then
			self:clearFenceList()
		end
		if self.uiListRoad then
			self:clearRoadTextureList()
		end
	end
	
	
	if self.panels then
		for _, panel in ipairs(self.panels) do
			if panel ~= nil then
				panel:destroy()
			end
		end
	end
		
    self.panels = {}

	self.currentTab = tabName

	self:loadSettings(self.currentTab)

    if tabName == self.tabNames[1] then
        self:genBaseUI()
    elseif tabName == self.tabNames[2] then
        self:genPlaceObjectUI()
    elseif tabName == self.tabNames[3] then
        self:genPlaceFenceUI()
		self:setFenceList()
    elseif tabName == self.tabNames[4] then
        self:genExportUI()
    elseif tabName == self.tabNames[5] then
		self:genRoadUI()
		self:setRoadTextureList()
    end
	
	self:updateChoicesFromSettings(self.currentTab)
	
    self.window:fit()
end

function SplineToolkit:updateChoicesFromSettings(tabName)
	if not self.loadSettingChoiceList then return end
	for _, entry in ipairs(self.loadSettingChoiceList) do
		local uiElement = self[entry.uiKey]
		if uiElement and entry.options and entry.selected then
			self:setChoiceFromString(uiElement, entry.options, entry.selected)
		end
	end

    if tabName == self.tabNames[2] then
		self:setPlaceObjecType()
		self:setPlaceObjectDistanceType()
		self:setPlaceObjectHeightType()
		self:setPlaceObjectRotateType()
    -- elseif tabName == self.tabNames[3] then
		-- self:setFenceList(true)
    elseif tabName == self.tabNames[4] then
		self:setUseCustomFilename()
		self:setExportChoice()
    elseif tabName == self.tabNames[5] then
		-- self:setRoadTextureList(true)
		self:setRoadTrafficChoice()
    end

	self.loadSettingChoiceList = nil
end

function SplineToolkit:generateUI()
    self.uiFrameRowSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(self.uiFrameRowSizer, "SplineToolkit by Aslan (v1.1.1)", false, false, -1, -1, -1, -1)
	-- self.window:enableAutoMinSize(true)
    
	self.uiBorderSizer = UIRowLayoutSizer.new()
    UIPanel.new(self.uiFrameRowSizer, self.uiBorderSizer, -1, -1, SplineToolkit.WINDOW_WIDTH, -1, BorderDirection.NONE, 0, 1)

    self.uiRowSizer = UIRowLayoutSizer.new()
    self.uiPanelSizer = UIPanel.new(self.uiBorderSizer, self.uiRowSizer, -1, -1, -1, -1, BorderDirection.ALL, 8, 1)

	self.uiNoteBook = UINotebook.new(self.uiRowSizer)	
	self.uiNoteBook:setOnTabChangeCallback(function(tabName) self:onChangeTab(tabName) end)
	
    self.uiBaseRowSizer = UIRowLayoutSizer.new()
	self.uiNoteBook:addTab(self.tabNames[1], self.uiBaseRowSizer)
    self.uiPlaceObjectRowSizer = UIRowLayoutSizer.new()
	self.uiNoteBook:addTab(self.tabNames[2], self.uiPlaceObjectRowSizer)
    self.uiPlaceFenceRowSizer = UIRowLayoutSizer.new()
	self.uiNoteBook:addTab(self.tabNames[3], self.uiPlaceFenceRowSizer)
    self.uiExportRowSizer = UIRowLayoutSizer.new()
	self.uiNoteBook:addTab(self.tabNames[4], self.uiExportRowSizer)
    self.uiRoadRowSizer = UIRowLayoutSizer.new()
	self.uiNoteBook:addTab(self.tabNames[5], self.uiRoadRowSizer)
	
	self:onChangeTab(self.tabNames[1], true)
	-- self:genBaseUI()
	-- self:loadSettings(self.currentTab)

    self.window:showWindow()
	self.window:setOnCloseCallback(function() self:saveSettings(self.currentTab) end)
end

function SplineToolkit:genBaseUI()
	self.uiBase = {}
	local values = self.values.base
	
	
    local rowSizer = UIRowLayoutSizer.new()
	self.uiBasePanel = UIPanel.new(self.uiBaseRowSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	table.insert(self.panels, self.uiBasePanel)
    ----------------------------------------------------------------
    -- SET ON TERRAIN
    ----------------------------------------------------------------

	-- UIHorizontalLine.new(rowSizer)
	UILabel.new(rowSizer, "Set Spline on Terrain", false, TextAlignment.CENTER, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1):setBold(true)

    local gridSizer =  UIGridSizer.new(2, 2, 5, 5)
    UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)

    UITextArea.new(gridSizer, "Height Offset (m)", TextAlignment.CENTER, true, false)
    self.uiTerrainHeightOffset = UIFloatSlider.new(gridSizer, values.setOnTerrain.heightOffset, -10.0, 10.0)

    UILabel.new(gridSizer, "")
    UIButton.new(gridSizer, "Apply Height", function() self:setSplineOnTerrain() end) :setBackgroundColor(0.6, 1.0, 0.55, 1.0)

    ----------------------------------------------------------------
    -- SET OFFSET
    ----------------------------------------------------------------
	UIHorizontalLine.new(rowSizer)
	UILabel.new(rowSizer, "Set Offset", false, TextAlignment.CENTER, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1):setBold(true)

    local gridSizer =  UIGridSizer.new(3, 2, 5, 5)
    UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)

    UITextArea.new(gridSizer, "Side Offset (m)", TextAlignment.CENTER, true, false)
    self.uiOffsetSideOffset = UIFloatSlider.new(gridSizer, values.setOffset.sideOffset, -20.0, 20.0)

    UITextArea.new(gridSizer, "Height Offset (m)", TextAlignment.CENTER, true, false)
    self.uiOffsetHeightOffset = UIFloatSlider.new(gridSizer, values.setOffset.heightOffset, -20.0, 20.0)

    UILabel.new(gridSizer, "")
    UIButton.new(gridSizer, "Apply Offset", function() self:setSplineOffset() end) :setBackgroundColor(0.6, 1.0, 0.55, 1.0)

    ----------------------------------------------------------------
    -- SET TERRAIN HEIGHT
    ----------------------------------------------------------------
	UIHorizontalLine.new(rowSizer)
	UILabel.new(rowSizer, "Set Terrain Height", false, TextAlignment.CENTER, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1):setBold(true)

    local gridSizer =  UIGridSizer.new(4, 2, 5, 5)
    UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)

    UITextArea.new(gridSizer, "Height Offset (m)", TextAlignment.CENTER, true, false)
    self.uiTerrainHeightHeightOffset = UIFloatSlider.new(gridSizer, values.setTerrainHeight.terrainHeight, -25.0, 25.0)

    UITextArea.new(gridSizer, "Width (m)", TextAlignment.CENTER, true, false)
    self.uiTerrainHeightWidth = UIFloatSlider.new(gridSizer, values.setTerrainHeight.terrainWidth, 0.1, 25.0)

    UITextArea.new(gridSizer, "Smooth Distance", TextAlignment.CENTER, true, false)
    self.uiTerrainHeightSmoothDist = UIFloatSlider.new(gridSizer, values.setTerrainHeight.smoothDistance, 0.0, 25.0)

    UILabel.new(gridSizer, "")
    UIButton.new(gridSizer, "Generate", function()
        EditorUtils.setTerrainHeight(self.uiTerrainHeightHeightOffset:getValue(), self.uiTerrainHeightWidth:getValue(), self.uiTerrainHeightSmoothDist:getValue())
    end) :setBackgroundColor(0.6, 1.0, 0.55, 1.0)
    ----------------------------------------------------------------
    -- PAINT TERRAIN
    ----------------------------------------------------------------
	UIHorizontalLine.new(rowSizer)
	UILabel.new(rowSizer, "Paint Terrain", false, TextAlignment.CENTER, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1):setBold(true)

    local gridSizer =  UIGridSizer.new(4, 2, 5, 5)
    UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
    
	UITextArea.new(gridSizer, "Terrain Layer", TextAlignment.CENTER, true, false)
	self.uiPaintTerrainLayer = UIChoice.new(gridSizer, values.paintTerrain.textureLayers, 0, -1, -1, 50)
	
	UITextArea.new(gridSizer, "Width Total (m)", TextAlignment.CENTER, true, false)
    self.uiPaintWidth = UIFloatSlider.new(gridSizer, values.paintTerrain.widthLeft + values.paintTerrain.widthRight, 0.1, 50.0)
	
	UITextArea.new(gridSizer, "Width Left/Right (m)", TextAlignment.CENTER, true, false)
    local gridSizer2 =  UIGridSizer.new(1, 2, 5, 5)
    UIPanel.new(gridSizer, gridSizer2, -1, -1, -1, -1, BorderDirection.NONE, 0)
    self.uiPaintWidthLeft = UIFloatSlider.new(gridSizer2, values.paintTerrain.widthLeft, 0.1, 25.0)
    self.uiPaintWidthRight = UIFloatSlider.new(gridSizer2, values.paintTerrain.widthRight, 0.1, 25.0)
	
	self.uiPaintWidth:setOnChangeCallback(function() self:onChangePaintWidth("total") end)
	self.uiPaintWidthLeft:setOnChangeCallback(function() self:onChangePaintWidth("left") end)
	self.uiPaintWidthRight:setOnChangeCallback(function() self:onChangePaintWidth("right") end)
    
	UILabel.new(gridSizer, "")
    UIButton.new(gridSizer, "Paint Terrain", function() self:paintTerrainBySpline() end) :setBackgroundColor(0.6, 1.0, 0.55, 1.0)
    ----------------------------------------------------------------
    -- PAINT TERRAIN
    ----------------------------------------------------------------
	UIHorizontalLine.new(rowSizer)
	UILabel.new(rowSizer, "Set Foliage", false, TextAlignment.CENTER, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1):setBold(true)

    local gridSizer =  UIGridSizer.new(4, 2, 5, 5)
    UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
    
	UITextArea.new(gridSizer, "Foliage Layer", TextAlignment.CENTER, true, false)
	self.uiFoliageLayer = UIChoice.new(gridSizer, self.foliageLayers.options, 0, -1, -1, 50)
	self.uiFoliageLayer:setOnChangeCallback(function(idx)
		local states = self.foliageLayers.states[idx] or {}
		self.uiFoliageLayerState:setChoices(states, 0)
	end)
    
	UITextArea.new(gridSizer, "Layer State", TextAlignment.CENTER, true, false)
	self.uiFoliageLayerState = UIChoice.new(gridSizer, self.foliageLayers.states[1], 0, -1, -1, 50)
	self.uiFoliageLayerState:setChoices(self.foliageLayers.states[1], 0)
	
	UITextArea.new(gridSizer, "Width Total (m)", TextAlignment.CENTER, true, false)
    self.uiFoliageWidth = UIFloatSlider.new(gridSizer, values.setFoliage.widthLeft + values.setFoliage.widthRight, 0.1, 50.0)
	
	UITextArea.new(gridSizer, "Width Left/Right (m)", TextAlignment.CENTER, true, false)
    local gridSizer2 =  UIGridSizer.new(1, 2, 5, 5)
    UIPanel.new(gridSizer, gridSizer2, -1, -1, -1, -1, BorderDirection.NONE, 0)
    self.uiFoliageWidthLeft = UIFloatSlider.new(gridSizer2, values.setFoliage.widthLeft, 0.1, 25.0)
    self.uiFoliageWidthRight = UIFloatSlider.new(gridSizer2, values.setFoliage.widthRight, 0.1, 25.0)
	
	self.uiFoliageWidth:setOnChangeCallback(function() self:onChangeFoliageWidth("total") end)
	self.uiFoliageWidthLeft:setOnChangeCallback(function() self:onChangeFoliageWidth("left") end)
	self.uiFoliageWidthRight:setOnChangeCallback(function() self:onChangeFoliageWidth("right") end)
    
	-- UILabel.new(gridSizer, "")
    UIButton.new(gridSizer, "Clear Foliage", function() self:setFoliageBySpline(true) end) :setBackgroundColor(1.0, 0.9, 0.53, 1.0)
    UIButton.new(gridSizer, "Set Foliage", function() self:setFoliageBySpline(false) end) :setBackgroundColor(0.6, 1.0, 0.55, 1.0)
    ----------------------------------------------------------------
    -- CUT SPLINE BETWEEN POINTS
    ----------------------------------------------------------------
	UIHorizontalLine.new(rowSizer)
	UILabel.new(rowSizer, "Resample Spline", false, TextAlignment.CENTER, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1):setBold(true)
	-- UILabel.new(rowSizer, "    Resample spline to the specified number of points (min. 2).", false, TextAlignment.CENTER, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.NONE, 0)
	-- UILabel.new(rowSizer, "   Select Spline Points to cut between this Points.", false, TextAlignment.CENTER, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
	
    local gridSizer =  UIGridSizer.new(2, 2, 5, 5)
    UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	
	UITextArea.new(gridSizer, "Number of Points", TextAlignment.CENTER, true, false)
    self.uiNumOfPoints = UIIntSlider.new(gridSizer, values.resampleSpline.numPoints, 2, 50)
	
	UILabel.new(gridSizer, "")
    UIButton.new(gridSizer, "Resample Spline", function() self:resampleSpline() end) :setBackgroundColor(0.6, 1.0, 0.55, 1.0)
end

function SplineToolkit:genPlaceObjectUI()
	local values = self.values.objectPlacement
	
    local rowSizer = UIRowLayoutSizer.new()
	self.uiPlaceObjectPanel = UIPanel.new(self.uiPlaceObjectRowSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	table.insert(self.panels, self.uiPlaceObjectPanel)

    local columnSizer = UIColumnLayoutSizer.new()
	UIPanel.new(rowSizer, columnSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1)
	-- UIButton.new(columnSizer, "INFO", function()
		-- MessageBox.show(
			-- "Set Objects on Spline – How To Use",
			
			-- "Platziert ausgewählte Objekte entlang einer Spline.\n\n" ..
			-- "• Object Distance = Abstand der Objekte\n" ..
			-- "• Offset Side = seitlicher Versatz\n" ..
			-- "• Set on Terrain = Höhenanpassung\n" ..
			-- "• Terrain Normal = Gelände-Normalen\n" ..
			-- "• Random Rotate = Zufallsrotation"
		-- )
	-- end, nil, -1, -1, -1, -1, BorderDirection.NONE, 0, 1) :setBackgroundColor(0.5, 0.75, 1.0, 1.0)
	UIButton.new(columnSizer, "Create Transformgroup", function() self:getPlaceObjectTransformgroup() end, nil, -1, -1, -1, -1, BorderDirection.NONE, 0, 1) :setBackgroundColor(1.0, 0.9, 0.53, 1.0)
	
    -- local rowSizer2 = UIRowLayoutSizer.new()
	UIHorizontalLine.new(rowSizer)
	
	-- UIPanel.new(self.uiPlacementRowSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	local gridSizer = UIGridSizer.new(2, 2, 5, 5)
	UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	
	UITextArea.new(gridSizer, "Object Place Type", TextAlignment.LEFT, true, false)
	self.uiObjectPlaceType = UIChoice.new(gridSizer, values.objPlaceType, 0)
	self.uiObjectPlaceType:setOnChangeCallback(function()
		self:setPlaceObjecType()
	end)
	
	UITextArea.new(gridSizer, "Offset Side (m)", TextAlignment.LEFT, true, false)
	self.uiObjectOffsetSide = UIFloatSlider.new(gridSizer, values.sideOffset, -50.0, 50.0)
	
	UIHorizontalLine.new(rowSizer)
	
	local gridSizer = UIGridSizer.new(2, 2, 5, 5)
	UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	
	UITextArea.new(gridSizer, "Width Total (m)", TextAlignment.LEFT, true, false)
    self.uiPlaceWidthTotal = UIFloatSlider.new(gridSizer, values.widthLeft + values.widthRight, 0.1, 50.0)
	
	UITextArea.new(gridSizer, "Width Left/Right (m)", TextAlignment.LEFT, true, false)
    local gridSizer2 =  UIGridSizer.new(1, 2, 5, 5)
    UIPanel.new(gridSizer, gridSizer2, -1, -1, -1, -1, BorderDirection.NONE, 0)
    self.uiPlaceWidthLeft = UIFloatSlider.new(gridSizer2, values.widthLeft, 0.1, 25.0)
    self.uiPlaceWidthRight = UIFloatSlider.new(gridSizer2, values.widthRight, 0.1, 25.0)
	
	self.uiPlaceWidthTotal:setOnChangeCallback(function() self:onChangePlaceObjectWidth("total") end)
	self.uiPlaceWidthLeft:setOnChangeCallback(function() self:onChangePlaceObjectWidth("left") end)
	self.uiPlaceWidthRight:setOnChangeCallback(function() self:onChangePlaceObjectWidth("right") end)
	
	UIHorizontalLine.new(rowSizer)
	
	local gridSizer = UIGridSizer.new(4, 2, 5, 5)
	UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	
	UITextArea.new(gridSizer, "Object Distance Type", TextAlignment.LEFT, true, false)
	self.uiObjectDistanceType = UIChoice.new(gridSizer, values.objDistanceType, 0)
	self.uiObjectDistanceType:setOnChangeCallback(function(state)
		self:setPlaceObjectDistanceType(state)
	end)
	
	UITextArea.new(gridSizer, "Fix Distance", TextAlignment.LEFT, true, false)
	self.uiObjectFixDistance = UIFloatSlider.new(gridSizer, values.objectFixDistance, 0.1, 100.0)
	
	UITextArea.new(gridSizer, "Min Distance", TextAlignment.LEFT, true, false)
	self.uiObjectMinDistance = UIFloatSlider.new(gridSizer, values.objectMinDistance, 0.1, 100.0)
	
	UITextArea.new(gridSizer, "Max Distance", TextAlignment.LEFT, true, false)
	self.uiObjectMaxDistance = UIFloatSlider.new(gridSizer, values.objectMaxDistance, 0.1, 100.0)

	UIHorizontalLine.new(rowSizer)
	
	local gridSizer = UIGridSizer.new(2, 2, 5, 5)
	UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)

	UITextArea.new(gridSizer, "Set Height Type", TextAlignment.LEFT, true, false)
	self.uiSetHeightType = UIChoice.new(gridSizer, values.setHeightType, 0)
	self.uiSetHeightType:setOnChangeCallback(function()
		self:setPlaceObjectHeightType()
	end)

	UITextArea.new(gridSizer, "Follow Axis", TextAlignment.LEFT, true, false)
	self.uiFollowAxis = UIChoice.new(gridSizer, values.followAxis, 0)
	
	UITextArea.new(gridSizer, "Height (Trans. Y)", TextAlignment.LEFT, true, false)
	self.uiObjectHeight = UIFloatSlider.new(gridSizer, values.objectHeight, -100.0, 100.0)
	
	UIHorizontalLine.new(rowSizer)
	
	local gridSizer = UIGridSizer.new(2, 2, 5, 5)
	UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	
	UITextArea.new(gridSizer, "Random Rotate", TextAlignment.LEFT, true, false)
	self.uiRandomRotate = UIChoice.new(gridSizer, values.setRandomRotate, 0)
	self.uiRandomRotate:setOnChangeCallback(function()
		self:setPlaceObjectRotateType()
	end)

	UITextArea.new(gridSizer, "Object Rotate", TextAlignment.LEFT, true, false)
	self.uiObjectRotate = UIFloatSlider.new(gridSizer, values.objectRotate, -180.0, 180.0)

	self.uiBtnPlaceObjects = UIButton.new(self.uiPlaceObjectRowSizer, "Generate", function() self:generateObjectsOnSpline() end)
	self.uiBtnPlaceObjects:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
	table.insert(self.panels, self.uiBtnPlaceObjects)
end

function SplineToolkit:genPlaceFenceUI()
	local values = self.values.fencePlacement
	
    local rowMainSizer = UIRowLayoutSizer.new()
	self.uiPlaceFencePanel = UIPanel.new(self.uiPlaceFenceRowSizer, rowMainSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	table.insert(self.panels, self.uiPlaceFencePanel)
	
    UILabel.new(rowMainSizer, "Fence IMG Path:", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5):setBold(true)
    local columnSizer = UIColumnLayoutSizer.new()
	UIPanel.new(rowMainSizer, columnSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    self.uiImgFencePath = UITextArea.new(columnSizer, values.imgPath, TextAlignment.LEFT, false, false, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
    self.uiImgFencePath:setOnFocusLostCallback(function() self:saveSettings(self.currentTab) end)
    -- self.uiExportI3DPath:setToolTip(self.exportI3dPath)
    UIButton.new(columnSizer, "🗁", function() self:onSelectFenceImgFolder() end, nil, -1, -1, 25, -1)
	
	UIHorizontalLine.new(rowMainSizer)
	
    local columnSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowMainSizer, columnSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	
    local iconPanelSizer = UIRowLayoutSizer.new()
    UIPanel.new(columnSizer, iconPanelSizer, -1, -1, -1, -1, BorderDirection.RIGHT, 5)
	
	self.uiFenceIcon = UIButton.new(iconPanelSizer, "", function() end, nil, -1, -1, 185, 185)
    -- self.uiFenceIcon:setImage(SplineToolkit.FENCE_IMG_PATH .. values.defaultImage)
    -- self.uiFenceIcon:setBackgroundColor(0.1, 0.1, 0.1, 1.0)
    -- self.uiFenceIcon:setEnabled(false)
	
    local rightPanelSizer = UIRowLayoutSizer.new()
    UIPanel.new(columnSizer, rightPanelSizer, -1, -1, -1, -1, BorderDirection.NONE, 5, 1)
	
	self.uiListFence = UIList.new(rightPanelSizer, -1, -1, -1, 158, BorderDirection.BOTTOM, 5)
    self.uiListFence:setOnChangeCallback(function(index) self:setFenceListItemCallback(index+1) end)
	
    local columnSizer2 = UIColumnLayoutSizer.new()
    UIPanel.new(rightPanelSizer, columnSizer2, -1, -1, -1, -1, BorderDirection.NONE, 0, -1)
	
	self.uiFenceAdd = UIButton.new(columnSizer2, "Add", function() self:onFenceAddBtn() end, nil, -1, -1, 20, 20, BorderDirection.NONE, 0, 1)
	self.uiFenceEdit = UIButton.new(columnSizer2, "Edit", function() self:onFenceEditBtn() end, nil, -1, -1, 20, 20, BorderDirection.NONE, 0, 1)
	self.uiiFenceDel = UIButton.new(columnSizer2, "Delete", function() self:onFenceDelBtn() end, nil, -1, -1, 20, 20, BorderDirection.NONE, 0, 1)
	self.uiFenceAdd:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
	self.uiFenceEdit:setBackgroundColor(1.0, 0.9, 0.53, 1.0)
	self.uiiFenceDel:setBackgroundColor(0.9, 0.5, 0.5, 1.0)
	
	UIHorizontalLine.new(rowMainSizer)

	local gridSizer = UIGridSizer.new(3, 2, 5, 5)
	UIPanel.new(rowMainSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	
	UITextArea.new(gridSizer, "Use Y Offset", TextAlignment.LEFT, true, false)
	self.uiFencePlaceYOffset = UIChoice.new(gridSizer, values.useYOffset, 0)
	
	UITextArea.new(gridSizer, "Place Start Pole", TextAlignment.LEFT, true, false)
	self.uiFencePlaceStartPole = UIChoice.new(gridSizer, values.placeStartPole, 0)
	
	UITextArea.new(gridSizer, "Place End Pole", TextAlignment.LEFT, true, false)
	self.uiFencePlaceEndPole = UIChoice.new(gridSizer, values.placeEndPole, 0)
	
    local rowSizer = UIRowLayoutSizer.new()
    UIPanel.new(rowMainSizer, rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1)
	
	self.uiBtnPlaceFence = UIButton.new(rowSizer, "Generate", function() self:generateFenceOnSpline() end, nil, -1, -1, -1, 30)
	self.uiBtnPlaceFence:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
	
	UIHorizontalLine.new(rowMainSizer)

	local gridSizer = UIGridSizer.new(1, 3, 5, 5)
	UIPanel.new(rowMainSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	
	UITextArea.new(gridSizer, "Import Gate", TextAlignment.LEFT, true, false)
	self.uiFenceGateChoice = UIChoice.new(gridSizer, values.fenceGateChoice, 0)
	self.uiBtnPlaceGate = UIButton.new(gridSizer, "Import", function() self:importFenceGate(self.uiFenceGateChoice:getValue()) end)
end

function SplineToolkit:genExportUI()
	local values = self.values.exportObject

    local rowMainSizer = UIRowLayoutSizer.new()
    self.uiExportPanel = UIPanel.new(self.uiExportRowSizer, rowMainSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	table.insert(self.panels, self.uiExportPanel)
	
    local columnSizer = UIColumnLayoutSizer.new()
	UIPanel.new(rowMainSizer, columnSizer, -1, -1, -1, -1, BorderDirection.ALL, 5, 0)
	
    self.uiExportUseCustomFilename = UICheckBox.new(columnSizer, "Custom Filename:", -1, -1, -1, -1, BorderDirection.RIGHT, 5)
	self.uiExportUseCustomFilename:setValue(values.useCustomFilename)
	self.uiExportUseCustomFilename:setOnChangeCallback(function()
		self:setUseCustomFilename()
	end)
    self.uiExportCustomFilename = UITextArea.new(columnSizer, "", TextAlignment.LEFT, false, false, -1, -1, -1, -1, BorderDirection.RIGHT, 2, 1)	
	self.uiExportCustomFilename:setOnFocusLostCallback(function()
		values.customFileName = self.uiExportCustomFilename:getValue()
	end)
	UILabel.new(columnSizer, ".obj", false, TextAlignment.LEFT, VerticalAlignment.CENTER)
	
    local rowSizer = UIRowLayoutSizer.new()
	UIPanel.new(rowMainSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	UIHorizontalLine.new(rowSizer)
	UILabel.new(rowSizer, "Select one or more Splines") :setBold(true)
	
    local gridSizer = UIGridSizer.new(5, 2, 5, 5)
	UIPanel.new(rowMainSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)

    UITextArea.new(gridSizer, "Type", TextAlignment.CENTER, true, false)
    self.uiExportType = UIChoice.new(gridSizer, values.createMeshType, 0)
	self.uiExportType:setOnChangeCallback(function()
		self:setExportChoice()
	end)

    UITextArea.new(gridSizer, "Distance Type", TextAlignment.CENTER, true, false)
    self.uiExportDistanceType = UIChoice.new(gridSizer, values.distanceType, 0)
	self.uiExportDistanceType:setOnChangeCallback(function()
		self:setExportChoice()
	end)
	
    UITextArea.new(gridSizer, "Distance", TextAlignment.CENTER, true, false)
    self.uiExportDistance = UIFloatSlider.new(gridSizer, values.vertexDistance, 0.01, 20.0)
	
    UITextArea.new(gridSizer, "Min Distance", TextAlignment.CENTER, true, false)
    self.uiExportMinDistance = UIFloatSlider.new(gridSizer, values.vertexMinDistance, 0.01, 20.0)

    UITextArea.new(gridSizer, "Min Angle", TextAlignment.CENTER, true, false)
    self.uiExportMinAngle = UIFloatSlider.new(gridSizer, values.vertexMinAngle, 0.1, 90.0)

    -- UILabel.new(gridSizer, "")
    self.uiBtnExportOBJ = UIButton.new(self.uiExportRowSizer, "Create", function() self:exportSplineToObj() end) 
	self.uiBtnExportOBJ:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
	table.insert(self.panels, self.uiBtnExportOBJ)
end

function SplineToolkit:genRoadUI()
	local values = self.values.roadMesh
	
    local rowMainSizer = UIRowLayoutSizer.new()
	self.uiPanelRoadName = UIPanel.new(self.uiRoadRowSizer, rowMainSizer, -1, -1, -1, 650, BorderDirection.ALL, 10)
	table.insert(self.panels, self.uiPanelRoadName)

    local columnSizer = UIColumnLayoutSizer.new()
	UIPanel.new(rowMainSizer, columnSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
	UILabel.new(columnSizer, "Road Name:", false, TextAlignment.CENTER, VerticalAlignment.CENTER, -1, -1, 75, -1, BorderDirection.RIGHT, 5):setBold(true)
    self.uiRoadName = UITextArea.new(columnSizer, values.roadName, TextAlignment.LEFT, false, false, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
	
	UIHorizontalLine.new(rowMainSizer, -1, -1, -1, 5)

    local rowSizer = UIRowLayoutSizer.new()
	UIPanel.new(rowMainSizer, rowSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, -1, true)
	
	-----------------------------------------------------------
	-- TEXTURE SETTINGS

	UILabel.new(rowSizer, "", false, TextAlignment.CENTER, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1)
	UILabel.new(rowSizer, "TEXTURE SETTINGS", false, TextAlignment.CENTER, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1):setBold(true)
	
    local columnSizer = UIColumnLayoutSizer.new()
	UIPanel.new(rowSizer, columnSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    UITextArea.new(columnSizer, "Road IMG Path:", TextAlignment.LEFT, true, false, -1, -1, -1, -1, BorderDirection.LEFT, 5)
    self.uiImgRoadPath = UITextArea.new(columnSizer, values.imgPath, TextAlignment.LEFT, false, false, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
    self.uiImgRoadPath:setToolTip(values.imgPath)
    self.uiImgRoadPath:setOnFocusLostCallback(function() self:saveSettings(self.currentTab) end)
    UIButton.new(columnSizer, "🗁", function() self:onSelectRoadImgFolder() end, nil, -1, -1, 25, -1, BorderDirection.RIGHT, 5)
	
    local columnSizer = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, columnSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	
    local iconPanelSizer = UIRowLayoutSizer.new()
    UIPanel.new(columnSizer, iconPanelSizer, -1, -1, -1, -1, BorderDirection.RIGHT, 5)
	
	self.uiRoadIcon = UIButton.new(iconPanelSizer, "", function() end, nil, -1, -1, 190, 190)
	
    local rightPanelSizer = UIRowLayoutSizer.new()
    UIPanel.new(columnSizer, rightPanelSizer, -1, -1, -1, -1, BorderDirection.NONE, 5, -1)
	
	self.uiListRoad = UIList.new(rightPanelSizer, -1, -1, -1, 158, BorderDirection.BOTTOM, 5)
    self.uiListRoad:setOnChangeCallback(function(index) self:setRoadTextureListItemCallback(index+1) end)
	
    local columnSizer2 = UIColumnLayoutSizer.new()
    UIPanel.new(rightPanelSizer, columnSizer2, -1, -1, -1, -1, BorderDirection.NONE, 0, -1)
	
	self.uiRoadAdd = UIButton.new(columnSizer2, "Add", function() self:onRoadTextureAddBtn() end, nil, -1, -1, 20, 20, BorderDirection.BOTTOM, 5, 1)
	self.uiRoadEdit = UIButton.new(columnSizer2, "Edit", function() self:onRoadTextureEditBtn() end, nil, -1, -1, 20, 20, BorderDirection.BOTTOM, 5, 1)
	self.uiRoadDel = UIButton.new(columnSizer2, "Delete", function() self:onRoadTextureDelBtn() end, nil, -1, -1, 20, 20, BorderDirection.BOTTOM, 5, 1)
	self.uiRoadAdd:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
	self.uiRoadEdit:setBackgroundColor(1.0, 0.9, 0.53, 1.0)
	self.uiRoadDel:setBackgroundColor(0.9, 0.5, 0.5, 1.0)
	UIHorizontalLine.new(rightPanelSizer)
	
    local gridSizer = UIGridSizer.new(1, 5, 2, 2)
    UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
	self.uiRoadTextureHasDiffuse = UIButton.new(gridSizer, "Diffuse", function() end)
	self.uiRoadTextureHasSpecular = UIButton.new(gridSizer, "Specular", function() end)
	self.uiRoadTextureHasNormal = UIButton.new(gridSizer, "Normal", function() end)
	self.uiRoadTextureHasHeight = UIButton.new(gridSizer, "Height", function() end)
	self.uiRoadTextureHasAlpha = UIButton.new(gridSizer, "Alpha", function() end)
	
    local gridSizer = UIGridSizer.new(4, 2, 5, 5)
    UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	
    UITextArea.new(gridSizer, "Mirror Texture at Center", TextAlignment.LEFT, true, false)
    self.uiMirrorAtCenter = UIChoice.new(gridSizer, values.mirrorAtCenter, 0)
	
    UITextArea.new(gridSizer, "Texture Distance (m)", TextAlignment.LEFT, true, false)
    self.uiTextureDistSlider = UIFloatSlider.new(gridSizer, values.textureDistance, 0.5, 25.0)
	
    UITextArea.new(gridSizer, "Slice Height Start (%)", TextAlignment.LEFT, true, false)
    self.uiTextureSliceStartSlider = UIFloatSlider.new(gridSizer, values.sliceStart, 0.0, 100.0)
	
    UITextArea.new(gridSizer, "Slice Height End (%)", TextAlignment.LEFT, true, false)
    self.uiTextureSliceEndSlider = UIFloatSlider.new(gridSizer, values.sliceEnd, 0.0, 100.0)
	
	-----------------------------------------------------------
	-- MESH SETTINGS
	
	UIHorizontalLine.new(rowSizer)
	UILabel.new(rowSizer, "MESH SETTINGS", false, TextAlignment.CENTER, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1):setBold(true)
	
    local gridSizer = UIGridSizer.new(5, 2, 5, 5)
    UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	
    UITextArea.new(gridSizer, "Terrain Decal", TextAlignment.LEFT, true, false)
    self.uiTerrainDecal = UIChoice.new(gridSizer, values.terrainDecal, 0)
	
    UITextArea.new(gridSizer, "Street Width (m)", TextAlignment.LEFT, true, false)
    self.uiGenRoadWidthSlider = UIFloatSlider.new(gridSizer, values.width, 1.0, 20.0)
	
    UITextArea.new(gridSizer, "Min Segment Length (m)", TextAlignment.LEFT, true, false)
    self.uiGenRoadMinSegLenght = UIFloatSlider.new(gridSizer, values.minSegmentLength, 0.1, 10.0)
	
    UITextArea.new(gridSizer, "Min Angle (deg)", TextAlignment.LEFT, true, false)
    self.uiGenRoadMinAngle = UIFloatSlider.new(gridSizer, values.maxAngle, 0.0, 30.0)
	
    UITextArea.new(gridSizer, "Align Edges on Terrain", TextAlignment.LEFT, true, false)
    self.uiGenRoadAlignEdges = UIChoice.new(gridSizer, values.alignEdgesOnTerrain, 0)
	
	-----------------------------------------------------------
	-- TRAFFIC SETTINGS

	UIHorizontalLine.new(rowSizer)
	UILabel.new(rowSizer, "TRAFFIC SETTINGS", false, TextAlignment.CENTER, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1):setBold(true)
	
    local gridSizer = UIGridSizer.new(5, 3, 5, 5)
    UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.LEFT, 5)
	
    UITextArea.new(gridSizer, "Center", TextAlignment.LEFT, true, false)
    self.uiHasTrafficCenter = UIChoice.new(gridSizer, values.trafficCenter, 0)
	self.uiHasTrafficCenter:setOnChangeCallback(function()
		self:setRoadTrafficChoice()
	end)
    UILabel.new(gridSizer, "")
	
    UITextArea.new(gridSizer, "Left (%)", TextAlignment.LEFT, true, false)
    self.uiHasTrafficLeft = UIChoice.new(gridSizer, values.trafficLeft, 0)
	self.uiHasTrafficLeft:setOnChangeCallback(function()
		self:setRoadTrafficChoice()
	end)
    self.uiTrafficLeftPerc = UIFloatSlider.new(gridSizer, values.leftPercent, 0.0, 100.0)
	
    UITextArea.new(gridSizer, "Right (%)", TextAlignment.LEFT, true, false)
    self.uiHasTrafficRight = UIChoice.new(gridSizer, values.trafficRight, 0)
	self.uiHasTrafficRight:setOnChangeCallback(function()
		self:setRoadTrafficChoice()
	end)
    self.uiTrafficRightPerc = UIFloatSlider.new(gridSizer, values.rightPercent, 0.0, 100.0)
	
    UITextArea.new(gridSizer, "maxSpeedScale", TextAlignment.LEFT, true, false)
    self.uiMaxSpeedScale = UIIntSlider.new(gridSizer, values.maxSpeedScale, -20, 20)
    UILabel.new(gridSizer, "")
	
    UITextArea.new(gridSizer, "speedLimit", TextAlignment.LEFT, true, false)
    self.uiSpeedLimit = UIIntSlider.new(gridSizer, values.speedLimit, 0, 120)
    UILabel.new(gridSizer, "")

	UIHorizontalLine.new(rowMainSizer, -1, -1, -1, 5, BorderDirection.BOTTOM, 5)
    self.uiBtnGenRoad = UIButton.new(rowMainSizer, "Generate Street", function() self:generateRoad() end, nil, -1, -1, -1, 30) 
	self.uiBtnGenRoad:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
end


-------------------------------------------------------------------------------------------------------------------------------------------------------
-- 	UI FUNCTIONS		-////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- ---------------------------------------------------------------
-- UI Functions - BASE
-- ---------------------------------------------------------------
function SplineToolkit:onChangePaintWidth(source)
    local left  = self.uiPaintWidthLeft:getValue()
    local right = self.uiPaintWidthRight:getValue()
    local total = self.uiPaintWidth:getValue()

    if source == "left" or source == "right" then
        local newTotal = left + right
        self.uiPaintWidth:setValue(newTotal)
    elseif source == "total" then
        local oldTotal = left + right

        if oldTotal <= 0.0001 then
            left = total * 0.5
            right = total * 0.5
        else
            local scale = total / oldTotal
            left  = left  * scale
            right = right * scale
        end

        self.uiPaintWidthLeft:setValue(left)
        self.uiPaintWidthRight:setValue(right)
    end
end

function SplineToolkit:onChangeFoliageWidth(source)
    local left  = self.uiFoliageWidthLeft:getValue()
    local right = self.uiFoliageWidthRight:getValue()
    local total = self.uiFoliageWidth:getValue()

    if source == "left" or source == "right" then
        local newTotal = left + right
        self.uiFoliageWidth:setValue(newTotal)
    elseif source == "total" then
        local oldTotal = left + right

        if oldTotal <= 0.0001 then
            left = total * 0.5
            right = total * 0.5
        else
            local scale = total / oldTotal
            left  = left  * scale
            right = right * scale
        end

        self.uiFoliageWidthLeft:setValue(left)
        self.uiFoliageWidthRight:setValue(right)
    end
end

function SplineToolkit:loadFoliageLayers()
    local foliage = self.foliageLayers
    foliage.options, foliage.states, foliage.channels, foliage.offsets = {}, {}, {}, {}

    local mapFile = getSceneFilename()
    local xml = loadXMLFile("map.i3d", mapFile)
    if xml == nil then
        printError("[SplineToolkit] Could not load map.i3d")
        return
    end

    local gamePath = getGameBasePath()
    local mapPath  = mapFile:match("(.*/)")
	
	-- foliage.options[1]  = "CLEAR FOLIAGE"
	-- foliage.states[1]   = {}
	-- foliage.channels[1] = nil
	-- foliage.offsets[1]  = nil

	local index = 1

    local foliageLayerPath = "i3D.Scene.TerrainTransformGroup.Layers.FoliageSystem.FoliageMultiLayer"
    local foliageStatePath = "foliageType.foliageLayer.foliageState"

    local function iter(handle, path, fn)
        local i = 0
        while true do
            local key = string.format("%s(%d)", path, i)
            if not hasXMLProperty(handle, key) then break end
            if fn(key, i) == false then break end
            i = i + 1
        end
    end

    iter(xml, foliageLayerPath, function(layerKey)
        iter(xml, layerKey .. ".FoliageType", function(typeKey)
            local name   = getXMLString(xml, typeKey .. "#name")
            local fileId = getXMLInt(xml, typeKey .. "#foliageXmlId")

            if name == nil or fileId == nil then return end

            foliage.options[index] = name
            foliage.states[index]  = {}

            local foliageXMLPath

            iter(xml, "i3D.Files.File", function(fileKey)
                if getXMLInt(xml, fileKey .. "#fileId") == fileId then
                    foliageXMLPath = getXMLString(xml, fileKey .. "#filename")
                    return false
                end
            end)

            if foliageXMLPath == nil then return end

            if foliageXMLPath:sub(1,5) == "$data" then
                foliageXMLPath = foliageXMLPath:gsub("$data", gamePath .. "data")
            else
                foliageXMLPath = mapPath .. foliageXMLPath
            end

            local foliageXML = loadXMLFile("foliage.xml", foliageXMLPath)
            if foliageXML == nil then return end

            foliage.channels[index] = getXMLInt(foliageXML, "foliageType.foliageLayer#numDensityMapChannels")
            foliage.offsets[index] = getXMLInt(foliageXML, "foliageType.foliageLayer#densityMapChannelOffset")

            local s = 1
            iter(foliageXML, foliageStatePath, function(stateKey)
                foliage.states[index][s] = getXMLString(foliageXML, stateKey .. "#name")
                s = s + 1
            end)

            delete(foliageXML)
            index = index + 1
        end)
    end)

    delete(xml)
end

-- ---------------------------------------------------------------
-- UI Functions - Place Objects
-- ---------------------------------------------------------------
function SplineToolkit:setPlaceObjecType()
	if self.uiObjectPlaceType:getValue() == 1 or self.uiObjectPlaceType:getValue() == 3 then
		self.uiPlaceWidthTotal:setEnabled(false)
		self.uiPlaceWidthLeft:setEnabled(false)
		self.uiPlaceWidthRight:setEnabled(false)
	else
		self.uiPlaceWidthTotal:setEnabled(true)
		self.uiPlaceWidthLeft:setEnabled(true)
		self.uiPlaceWidthRight:setEnabled(true)
	end
end

function SplineToolkit:setPlaceObjectDistanceType()
	if self.uiObjectDistanceType:getValue() == 1 then
		self.uiObjectFixDistance:setEnabled(true)
		self.uiObjectMinDistance:setEnabled(false)
		self.uiObjectMaxDistance:setEnabled(false)
	elseif self.uiObjectDistanceType:getValue() == 2 then
		self.uiObjectFixDistance:setEnabled(false)
		self.uiObjectMinDistance:setEnabled(true)
		self.uiObjectMaxDistance:setEnabled(true)
	end
end

function SplineToolkit:setPlaceObjectHeightType()
	if self.uiSetHeightType:getValue() == 2 or self.uiSetHeightType:getValue() == 5 then
		self.uiFollowAxis:setEnabled(true)
	else
		self.uiFollowAxis:setEnabled(false)
	end

	if self.uiSetHeightType:getValue() == 6 then
		self.uiObjectHeight:setEnabled(true)
	else
		self.uiObjectHeight:setEnabled(false)
	end
end

function SplineToolkit:setPlaceObjectRotateType()
	if self.uiRandomRotate:getValue() == 1 then
		self.uiObjectRotate:setEnabled(true)
	else
		self.uiObjectRotate:setEnabled(false)
	end
end

function SplineToolkit:onChangePlaceObjectWidth(source)
    local left  = self.uiPlaceWidthLeft:getValue()
    local right = self.uiPlaceWidthRight:getValue()
    local total = self.uiPlaceWidthTotal:getValue()

    if source == "left" or source == "right" then
        local newTotal = left + right
        self.uiPlaceWidthTotal:setValue(newTotal)
    elseif source == "total" then
        local oldTotal = left + right

        if oldTotal <= 0.0001 then
            left = total * 0.5
            right = total * 0.5
        else
            local scale = total / oldTotal
            left  = left  * scale
            right = right * scale
        end

        self.uiPlaceWidthLeft:setValue(left)
        self.uiPlaceWidthRight:setValue(right)
    end
end

-- ---------------------------------------------------------------
-- UI Functions - Place Fence
-- ---------------------------------------------------------------
function SplineToolkit:onSelectFenceImgFolder()
	local values = self.values.fencePlacement
    local path = openDirDialog(values.imgPath)
    if path ~= nil and path ~= "" then
        path = string.gsub(path, "\\", "/")
        if string.sub(path, -1) ~= "/" then
            path = path .. "/"
        end
        values.imgPath = path
        self.uiImgFencePath:setValue(values.imgPath)
		self.uiImgFencePath:setToolTip(values.imgPath)
        self:saveSettings()
    end
end

function SplineToolkit:setFenceImage(img)
	local values = self.values.fencePlacement
	
	local function validatePath(path)
		if not path or path == "" then
			return nil
		end

		path = string.gsub(path, "^%s*(.-)%s*$", "%1")

		local fileName = string.match(path, "([^/\\]+)$")

		if fileName and string.match(fileName, "%.[^%.]+$") then
			printError("[SplineToolkit] Path must not contain a file extension: " .. fileName)
			return nil
		end

		return path
	end

	local rawPath = self.uiImgFencePath:getValue()
	local path = validatePath(rawPath)

	if not path then
		return
	end

	if not folderExists(path) then
		printError("[SplineToolkit] Fence image folder does not exist: " .. path)
		return
	end

	self.uiFenceIcon:setVisible(true)

	local filePath = path .. img
	local defaultFilePath = path .. values.defaultImage

	if fileExists(filePath) then
		self.uiFenceIcon:setImage(filePath)
		return
	end

	printWarning("[SplineToolkit] Fence icon not found, trying default: " .. filePath)

	if fileExists(defaultFilePath) then
		self.uiFenceIcon:setImage(defaultFilePath)
		return
	end

	printError("[SplineToolkit] Default fence icon not found: " .. defaultFilePath)
	self.uiFenceIcon:setVisible(false)
end

function SplineToolkit:setFenceList()
	local values = self.values.fencePlacement
	local fenceTable = values.fenceTable

    self.uiListFence:clear()

    if not fenceTable or #fenceTable == 0 then
        printWarning("[SplineToolkit] Fence table is empty.")
		self:setFenceImage(values.defaultImage)
        return
    end

    for i, fence in ipairs(fenceTable) do
        self.uiListFence:appendItem(fence.name or ("Fence " .. i))

        if fence.isCustom then
            self.uiListFence:setItemBackgroundColor(i - 1, 1, 1, 0.1, 1)
        end
    end

    if #fenceTable > 0 then
        self.uiListFence:setSelectedItem(0)
        self:setFenceListItemCallback(1)
    end
end

function SplineToolkit:clearFenceList()
    local values = self.values and self.values.fencePlacement
    if values == nil or values.fenceTable == nil then
        return
    end

    local fenceTable = values.fenceTable
    for i = #fenceTable, 1, -1 do
        if fenceTable[i] and fenceTable[i].isCustom then
            table.remove(fenceTable, i)
        end
    end

    if self.uiListFence then
        self.uiListFence:clear()
    end
end

function SplineToolkit:setFenceListItemCallback(index)
    local values = self.values.fencePlacement
    local fenceTable = values.fenceTable
	
	local fence = fenceTable[index]
	if not fence then
		self.uiFenceIcon:setImage(SplineToolkit.FENCE_IMG_PATH .. values.defaultImage)
		self:setFenceImage(values.defaultImage)
		return
	end

	self:setFenceImage(fence.imgFile)

	if fence.isCustom then
		self.uiFenceEdit:setEnabled(true)
		self.uiiFenceDel:setEnabled(true)
	else
		self.uiFenceEdit:setEnabled(false)
		self.uiiFenceDel:setEnabled(false)
	end

	self:loadFenceFromXML(index)
	self:setFenceGateList()
end

function SplineToolkit:setFenceGateList()
    if not self.uiFenceGateChoice then
        return
    end

    local gateNames = {}

    if not self.selFenceInfo or not self.selFenceInfo.gates or #self.selFenceInfo.gates == 0 then
        gateNames = { "No Gates" }
		self.uiFenceGateChoice:setEnabled(false)
		self.uiBtnPlaceGate:setEnabled(false)
    else
        for _, gate in ipairs(self.selFenceInfo.gates) do
            table.insert(gateNames, gate.id or "Gate")
        end
		self.uiFenceGateChoice:setEnabled(true)
		self.uiBtnPlaceGate:setEnabled(true)
    end

    self.uiFenceGateChoice:setChoices(gateNames, 0)
end

function SplineToolkit:onFenceAddBtn()
    self:genUINewFence(nil, function(result, data)

        if not result or not data then return end

        local fenceTable = self.values.fencePlacement.fenceTable

        table.insert(fenceTable, {
            name    = data.name or "",
            xmlFile = data.xmlFile or "",
            imgFile = data.imgFile or "",
            isCustom = true,
        })

		self:saveSettings(self.currentTab)
        self:setFenceList()
    end)
end

function SplineToolkit:onFenceEditBtn()
    local selected = self.uiListFence:getSelectedItem()
    if selected == nil or selected < 0 then
        printWarning("[SplineToolkit] No fence selected.")
        return
    end

    local index = selected + 1
    local fenceTable = self.values.fencePlacement.fenceTable
    local entry = fenceTable[index]
    if not entry then return end

    self:genUINewFence(index, function(result, data)

        if not result or not data then return end

        fenceTable[index] = {
            name    = data.name or "",
            xmlFile = data.xmlFile or "",
            imgFile = data.imgFile or "",
            isCustom = true,
        }

		self:saveSettings(self.currentTab)
        self:setFenceList()
    end, entry)
end

function SplineToolkit:onFenceDelBtn()
    local selected = self.uiListFence:getSelectedItem()
    if selected == nil or selected < 0 then
        printWarning("[SplineToolkit] No fence selected.")
        return
    end

    local index = selected + 1
    local fenceTable = self.values.fencePlacement.fenceTable

    table.remove(fenceTable, index)

	self:saveSettings(self.currentTab)
    self:setFenceList()
end

-- ---------------------------------------------------------------
-- UI Functions - Export Spline
-- ---------------------------------------------------------------
function SplineToolkit:setUseCustomFilename()
	if self.uiExportUseCustomFilename:getValue() == true then
		self.uiExportCustomFilename:setEnabled(true)
		self.uiExportCustomFilename:setValue(self.values.exportObject.customFileName)
	else
		self.uiExportCustomFilename:setEnabled(false)
		if self.uiExportCustomFilename:getValue() ~= "" then
			self.values.exportObject.customFileName = self.uiExportCustomFilename:getValue()
		end
		self.uiExportCustomFilename:setValue(self.values.exportObject.defaultFileName)
	end
end

function SplineToolkit:setExportChoice()
	if self.uiExportType:getValue() == 1 then
		self.uiExportDistanceType:setEnabled(false)
		self.uiExportDistance:setEnabled(false)
		self.uiExportMinDistance:setEnabled(false)
		self.uiExportMinAngle:setEnabled(false)
	else
		self.uiExportDistanceType:setEnabled(true)
		if self.uiExportDistanceType:getValue() == 1 then
			self.uiExportDistance:setEnabled(true)
			self.uiExportMinDistance:setEnabled(false)
			self.uiExportMinAngle:setEnabled(false)
		else
			self.uiExportDistance:setEnabled(false)
			self.uiExportMinDistance:setEnabled(true)
			self.uiExportMinAngle:setEnabled(true)
		end
	end
end

-- ---------------------------------------------------------------
-- UI Functions - Gen Road Mesh
-- ---------------------------------------------------------------

function SplineToolkit:setRoadTrafficChoice()
	if self:getChoiceBoolean(self.uiHasTrafficCenter) or self:getChoiceBoolean(self.uiHasTrafficLeft) or self:getChoiceBoolean(self.uiHasTrafficRight) then
		self.uiMaxSpeedScale:setEnabled(true)
		self.uiSpeedLimit:setEnabled(true)
	else
		self.uiMaxSpeedScale:setEnabled(false)
		self.uiSpeedLimit:setEnabled(false)
	end
	self.uiTrafficLeftPerc:setEnabled(self:getChoiceBoolean(self.uiHasTrafficLeft))
	self.uiTrafficRightPerc:setEnabled(self:getChoiceBoolean(self.uiHasTrafficRight))
end

function SplineToolkit:onSelectRoadImgFolder()
	local values = self.values.roadMesh
    local path = openDirDialog(values.imgPath)
    if path ~= nil and path ~= "" then
        path = string.gsub(path, "\\", "/")
        if string.sub(path, -1) ~= "/" then
            path = path .. "/"
        end
        values.imgPath = path
        self.uiImgRoadPath:setValue(values.imgPath)
		self.uiImgRoadPath:setToolTip(values.imgPath)
        self:saveSettings()
    end
end

function SplineToolkit:setRoadTextureImage(img)
	local values = self.values.fencePlacement
	
	local function validatePath(path)
		if not path or path == "" then
			return nil
		end

		path = string.gsub(path, "^%s*(.-)%s*$", "%1")

		local fileName = string.match(path, "([^/\\]+)$")

		if fileName and string.match(fileName, "%.[^%.]+$") then
			printError("[SplineToolkit] Path must not contain a file extension: " .. fileName)
			return nil
		end

		return path
	end

	local rawPath = self.uiImgRoadPath:getValue()
	local path = validatePath(rawPath)

	if not path then
		return
	end

	if not folderExists(path) then
		printError("[SplineToolkit] Road Texture image folder does not exist: " .. path)
		return
	end

	self.uiRoadIcon:setVisible(true)

	local filePath = path .. img
	local defaultFilePath = path .. values.defaultImage

	if fileExists(filePath) then
		self.uiRoadIcon:setImage(filePath)
		return
	end

	printWarning("[SplineToolkit] Road Texture icon not found, trying default: " .. filePath)

	if fileExists(defaultFilePath) then
		self.uiRoadIcon:setImage(defaultFilePath)
		return
	end

	printError("[SplineToolkit] Default Road Texture icon not found: " .. defaultFilePath)
	self.uiRoadIcon:setVisible(false)
end

function SplineToolkit:setRoadTextureList()
	local values = self.values.roadMesh
	local roadTextureTable = values.textureTable

    self.uiListRoad:clear()

    if not roadTextureTable or #roadTextureTable == 0 then
        printWarning("[SplineToolkit] Fence table is empty.")
        -- self.uiFenceIcon:setImage(SplineToolkit.FENCE_IMG_PATH .. values.defaultImage)
		self:setRoadTextureImage(values.defaultImage)
        return
    end

    for i, roadTexture in ipairs(roadTextureTable) do
        self.uiListRoad:appendItem(roadTexture.name or ("roadTexture " .. i))

        if roadTexture.isCustom then
            self.uiListRoad:setItemBackgroundColor(i - 1, 1, 1, 0.1, 1)
        end
    end

    if #roadTextureTable > 0 then
        self.uiListRoad:setSelectedItem(0)
        self:setRoadTextureListItemCallback(1)
    end
end
function SplineToolkit:clearRoadTextureList()
    local values = self.values and self.values.roadMesh
    if values == nil or values.textureTable == nil then
        return
    end

    local textureTable = values.textureTable

    for i = #textureTable, 1, -1 do
        if textureTable[i] and textureTable[i].isCustom then
            table.remove(textureTable, i)
        end
    end

    if self.uiListRoad then
        self.uiListRoad:clear()
    end
end

function SplineToolkit:setRoadTextureListItemCallback(index)
    local values = self.values.roadMesh
    local roadTextureTable = values.textureTable
	
	local roadTexture = roadTextureTable[index]
	if not roadTexture then
		self.uiRoadIcon:setImage(SplineToolkit.FENCE_IMG_PATH .. values.defaultImage)
		self:setRoadTextureImage(values.defaultImage)
		return
	end

    self.selectedRoadTextureIndex = index
	self:setRoadTextureImage(roadTexture.imgFile)
	
	if roadTextureTable[index].textures["diffuse"] ~= "" then
		self.uiRoadTextureHasDiffuse:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
		self.uiRoadTextureHasDiffuse:setToolTip(roadTextureTable[index].textures["diffuse"])
	else
		self.uiRoadTextureHasDiffuse:setBackgroundColor(0.9, 0.5, 0.5, 1.0)
		self.uiRoadTextureHasDiffuse:setToolTip("")
	end
	if roadTextureTable[index].textures["specular"] ~= "" then
		self.uiRoadTextureHasSpecular:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
		self.uiRoadTextureHasSpecular:setToolTip(roadTextureTable[index].textures["specular"])
	else
		self.uiRoadTextureHasSpecular:setBackgroundColor(0.9, 0.5, 0.5, 1.0)
		self.uiRoadTextureHasSpecular:setToolTip("")
	end
	if roadTextureTable[index].textures["normal"] ~= "" then
		self.uiRoadTextureHasNormal:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
		self.uiRoadTextureHasNormal:setToolTip(roadTextureTable[index].textures["normal"])
	else
		self.uiRoadTextureHasNormal:setBackgroundColor(0.9, 0.5, 0.5, 1.0)
		self.uiRoadTextureHasNormal:setToolTip("")
	end
	if roadTextureTable[index].textures["height"] ~= "" then
		self.uiRoadTextureHasHeight:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
		self.uiRoadTextureHasHeight:setToolTip(roadTextureTable[index].textures["height"])
	else
		self.uiRoadTextureHasHeight:setBackgroundColor(0.9, 0.5, 0.5, 1.0)
		self.uiRoadTextureHasHeight:setToolTip("")
	end
	if roadTextureTable[index].textures["alpha"] ~= "" then
		self.uiRoadTextureHasAlpha:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
		self.uiRoadTextureHasAlpha:setToolTip(roadTextureTable[index].textures["alpha"])
	else
		self.uiRoadTextureHasAlpha:setBackgroundColor(0.9, 0.5, 0.5, 1.0)
		self.uiRoadTextureHasAlpha:setToolTip("")
	end
	
	if roadTexture.isCustom then
		self.uiRoadEdit:setEnabled(true)
		self.uiRoadDel:setEnabled(true)
	else
		self.uiRoadEdit:setEnabled(false)
		self.uiRoadDel:setEnabled(false)
	end
end

function SplineToolkit:onRoadTextureAddBtn()
    self:genUINewRoadTexture(nil, function(result, data)

        if not result or not data then return end

        table.insert(self.values.roadMesh.textureTable, data)

        self:saveSettings(self.currentTab)
        self:setRoadTextureList()
    end)
end

function SplineToolkit:onRoadTextureEditBtn()

    local selected = self.uiListRoad:getSelectedItem()
    if selected == nil or selected < 0 then
        printWarning("[SplineToolkit] No road texture selected.")
        return
    end

    local index = selected + 1
    local textureTable = self.values.roadMesh.textureTable
    local entry = textureTable[index]
    if not entry then return end

    self:genUINewRoadTexture(index, function(result, data)

        if not result or not data then return end

        textureTable[index] = {
            name      = data.name or "",
            imgFile   = data.imgFile or "",
            shaderVar = data.shaderVar or "",

            textures = {
                diffuse  = data.textures.diffuse,
                specular = data.textures.specular,
                normal   = data.textures.normal,
                height   = data.textures.height,
                alpha    = data.textures.alpha,
            },

            isCustom = true
        }

        self:saveSettings(self.currentTab)
        self:setRoadTextureList()

    end, entry)

end

function SplineToolkit:onRoadTextureDelBtn()

    local selected = self.uiListRoad:getSelectedItem()
    if selected == nil or selected < 0 then
        printWarning("[SplineToolkit] No road texture selected.")
        return
    end

    local index = selected + 1
    local textureTable = self.values.roadMesh.textureTable

    if not textureTable[index] then return end

    table.remove(textureTable, index)

    self:saveSettings(self.currentTab)
    self:setRoadTextureList()

end

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- 	BASE TOOLS 		--------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------
function SplineToolkit:paintTerrainBySpline()

    local widthLeft  = self.uiPaintWidthLeft:getValue()
    local widthRight = self.uiPaintWidthRight:getValue()

    local choiceIndex = self.uiPaintTerrainLayer:getValue()
    local layerName = self.values.base.paintTerrain.textureLayers[choiceIndex]

    if layerName == nil or layerName == "" then
        printWarning("[SplineToolkit] No terrain layer selected")
        return
    end

    local terrainId = getChild(getRootNode(), "terrain")
    if terrainId == nil or terrainId == 0 then
        printError("[SplineToolkit] Terrain not found")
        return
    end

    local layerId = nil
    for i = 0, getTerrainNumOfLayers(terrainId) - 1 do
        if getTerrainLayerName(terrainId, i) == layerName then
            layerId = i
            break
        end
    end

    if layerId == nil then
        printError("[SplineToolkit] Layer not found in terrain: " .. tostring(layerName))
        return
    end

    local splineId = getSelection(0)
    if splineId == 0
    or not getHasClassId(splineId, ClassIds.SHAPE)
    or not getHasClassId(getGeometry(splineId), ClassIds.SPLINE) then
        printWarning("[SplineToolkit] Please select a spline")
        return
    end

    local splineLength = getSplineLength(splineId)
    if splineLength <= 0 then
        printWarning("[SplineToolkit] Invalid spline length")
        return
    end

    local step = 0.1 / splineLength
    local widthStep = 0.1
    local pos = 0.0

    while pos <= 1.0 do
        local px, py, pz = getSplinePosition(splineId, pos)
        local dx, dy, dz = getSplineDirection(splineId, pos)

        local crossX = -dz
        local crossZ = dx

        local len = math.sqrt(crossX * crossX + crossZ * crossZ)
        if len > 0 then
            crossX = crossX / len
            crossZ = crossZ / len
        end

        for w = -widthLeft, widthRight, widthStep do
            local nx = px + crossX * w
            local nz = pz + crossZ * w
            local ny = getTerrainHeightAtWorldPos(terrainId, nx, py, nz)

            setTerrainLayerAtWorldPos(terrainId, layerId, nx, ny, nz, 128.0)
        end

        pos = pos + step
    end

    -- letzten Punkt sauber mitnehmen
    do
        local px, py, pz = getSplinePosition(splineId, 1.0)
        local dx, dy, dz = getSplineDirection(splineId, 1.0)

        local crossX = -dz
        local crossZ = dx

        local len = math.sqrt(crossX * crossX + crossZ * crossZ)
        if len > 0 then
            crossX = crossX / len
            crossZ = crossZ / len
        end

        for w = -widthLeft, widthRight, widthStep do
            local nx = px + crossX * w
            local nz = pz + crossZ * w
            local ny = getTerrainHeightAtWorldPos(terrainId, nx, py, nz)

            setTerrainLayerAtWorldPos(terrainId, layerId, nx, ny, nz, 128.0)
        end
    end

    print(string.format("[SplineToolkit] Painted '%s' | Left: %.2f m | Right: %.2f m", layerName, widthLeft, widthRight))
end

function SplineToolkit:setSplineOnTerrain()
    local mSceneID = getRootNode()
    local mTerrainID = 0

    for i = 0, getNumOfChildren(mSceneID) - 1 do
        local mID = getChildAt(mSceneID, i)
        if getName(mID) == "terrain" then
            mTerrainID = mID
            break
        end
    end

    if mTerrainID == 0 then
        print("Error: Terrain node not found. Node must be named 'terrain'.")
        return
    end

    if getNumSelected() == 0 then
        print("Error: Select one or more splines.")
        return
    end

    local mSplineIDs = {}
    for i = 0, getNumSelected() - 1 do
        local mID = getSelection(i)
        if getHasClassId(mID, ClassIds.SHAPE) and getHasClassId(getGeometry(mID), ClassIds.SPLINE) then
            table.insert(mSplineIDs, mID)
        end
    end

    if #mSplineIDs == 0 then
        printError("Error: No valid splines selected.")
        return
    end

	for _, mSplineID in ipairs(mSplineIDs) do

		local numCVs = getSplineNumOfCV(mSplineID)

		if numCVs > 0 then

			local splineType = self:getSplineType(mSplineID)
			local offset = self.uiTerrainHeightOffset:getValue()

			for i = 0, numCVs - 1 do
				local worldX, worldY, worldZ

				if splineType == "CUBIC" then
					worldX, worldY, worldZ = getSplineEP(mSplineID, i)
				else
					worldX, worldY, worldZ = getSplineCV(mSplineID, i)
				end

				local terrainHeight = getTerrainHeightAtWorldPos(mTerrainID, worldX, 0, worldZ)
				local newWorldY = terrainHeight + offset
				local localX, localY, localZ = worldToLocal(mSplineID, worldX, newWorldY, worldZ)

				if splineType == "CUBIC" then
					setSplineEP(mSplineID, i, localX, localY, localZ)
				else
					setSplineCV(mSplineID, i, localX, localY, localZ)
				end
			end

		else
			printWarning("Warning: Spline has no control vertices.")
		end
	end

    print("Splines successfully snapped to terrain height with offset: " .. self.uiTerrainHeightOffset:getValue() .. "m.")
end

function SplineToolkit:getSplineType(splineId)
    local numCVs = getSplineNumOfCV(splineId)
    if numCVs < 2 then
        return "UNKNOWN"
    end

    local epsilon = 0.0001

    for i = 0, numCVs - 1 do
        local epX, epY, epZ = getSplineEP(splineId, i)
        local cvX, cvY, cvZ = getSplineCV(splineId, i)

        if math.abs(epX - cvX) > epsilon
        or math.abs(epY - cvY) > epsilon
        or math.abs(epZ - cvZ) > epsilon then
            return "CUBIC"
        end
    end

    return "LINEAR"
end

function SplineToolkit:setSplineOffset()
    if getNumSelected() == 0 then
        printError("Error: Select one or more splines.")
        return
    end

    local sideOffset = self.uiOffsetSideOffset:getValue()
    local heightOffset = self.uiOffsetHeightOffset:getValue()
    local updatedSplines = 0

    for i = 0, getNumSelected() - 1 do
        local splineID = getSelection(i)

        if getHasClassId(splineID, ClassIds.SHAPE) and getHasClassId(getGeometry(splineID), ClassIds.SPLINE) then
            local numCVs = getSplineNumOfCV(splineID)

            if numCVs > 1 then
                for j = 0, numCVs - 1 do
                    local worldX, worldY, worldZ = getSplineCV(splineID, j)
                    local dirX, dirY, dirZ = getSplineDirection(splineID, j / (numCVs - 1))
                    local offsetX, _, offsetZ = self:crossProduct(dirX, dirY, dirZ, 0, 1, 0)

                    local newWorldX = worldX + (offsetX * sideOffset)
                    local newWorldY = worldY + heightOffset
                    local newWorldZ = worldZ + (offsetZ * sideOffset)
					
                    local localX, localY, localZ = worldToLocal(splineID, newWorldX, newWorldY, newWorldZ)

                    setSplineCV(splineID, j, localX, localY, localZ)
                end
                updatedSplines = updatedSplines + 1
            else
                printWarning("Warning: Spline has less than 2 control points.")
            end
        end
    end

    print(string.format("Updated %d spline(s) with sideOffset = %.2f and heightOffset = %.2f", updatedSplines, sideOffset, heightOffset))
end

function SplineToolkit:crossProduct(ax, ay, az, bx, by, bz)
    return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end

function SplineToolkit:setFoliageBySpline(isClear)
    if getNumSelected() < 1 then
        printWarning("[SplineToolkit] Please select a spline")
        return
    end

    local spline = getSelection(0)
    if not getHasClassId(spline, ClassIds.SHAPE) or not getHasClassId(getGeometry(spline), ClassIds.SPLINE) then
        printWarning("[SplineToolkit] Selected object is not a spline")
        return
    end

    local terrain = getChild(getRootNode(),"terrain")
    if terrain == nil or terrain == 0 then
        printError("[SplineToolkit] Terrain not found")
        return
    end

    local widthLeft  = self.uiFoliageWidthLeft:getValue()
    local widthRight = self.uiFoliageWidthRight:getValue()

    local splineLength = getSplineLength(spline)
    if splineLength <= 0 then
        printWarning("[SplineToolkit] Invalid spline length")
        return
    end

    local step = 0.1 / splineLength
    local pos = 0
    local pointsRight = {}
    local modifiers = {}

    if isClear then
        local grass = getTerrainDataPlaneByName(terrain,"grass")
        if grass == nil or grass == 0 then
            printError("[SplineToolkit] No grass foliage layer found")
            return
        end

        local modifier = DensityMapModifier.new(grass,0,3,terrain)
        modifier:clearPolygonPoints()
        modifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)

        table.insert(modifiers,modifier)
    else
        local layerIndex = self.uiFoliageLayer:getValue()
        local stateIndex = self.uiFoliageLayerState:getValue()

        local layerName = self.foliageLayers.options[layerIndex]
        if layerName == nil then
            printWarning("[SplineToolkit] No foliage layer selected")
            return
        end

        local plane = getTerrainDataPlaneByName(terrain,layerName)
        if plane == nil or plane == 0 then
            printError("[SplineToolkit] Foliage layer not found: "..tostring(layerName))
            return
        end

        local modifier = DensityMapModifier.new(
            plane,
            self.foliageLayers.offsets[layerIndex],
            self.foliageLayers.channels[layerIndex],
            terrain
        )

        modifier:clearPolygonPoints()
        table.insert(modifiers,modifier)
    end

    while pos <= 1.0 do
        local x,_,z = getSplinePosition(spline,pos)
        local dx,_,dz = getSplineDirection(spline,pos)

        local crossX = -dz
        local crossZ = dx

        for _,mod in ipairs(modifiers) do
            mod:addPolygonPointWorldCoords(x + crossX * widthRight, z + crossZ * widthRight)
        end

        table.insert(pointsRight,1,{ x = x - crossX * widthLeft, z = z - crossZ * widthLeft })
        pos = pos + step
    end

    for i=1,#pointsRight do
        for _,mod in ipairs(modifiers) do
            mod:addPolygonPointWorldCoords(pointsRight[i].x,pointsRight[i].z)
        end
    end

    if isClear then
        for _,mod in ipairs(modifiers) do
            mod:executeSet(0)
        end
        print("[SplineToolkit] Foliage cleared by spline")
    else
        local stateIndex = self.uiFoliageLayerState:getValue()
        for _,mod in ipairs(modifiers) do
            mod:executeSet(stateIndex)
        end
        local layerName = self.foliageLayers.options[self.uiFoliageLayer:getValue()]
        print(string.format("[SplineToolkit] Foliage '%s' painted with state %d", layerName, stateIndex))
    end
end

function SplineToolkit:resampleSpline()
    if getNumSelected() < 1 then
        printWarning("[SplineToolkit] Select a spline")
        return
    end

    local spline = getSelection(0)

    if not getHasClassId(spline, ClassIds.SHAPE) or not getHasClassId(getGeometry(spline), ClassIds.SPLINE) then
        printWarning("[SplineToolkit] Selected object is not a spline")
        return
    end

    local targetPoints = math.max(self.uiNumOfPoints:getValue(), 2)

    local length = getSplineLength(spline)
    if length <= 0 then return end

    local parent = getParent(spline)
    if parent == nil or parent == 0 then parent = getRootNode() end

    local name = getName(spline)
    local isClosed = getIsSplineClosed(spline)

    local editPoints = {}

    local function pushWorld(wx, wy, wz)
        local lx, ly, lz = worldToLocal(parent, wx, wy, wz)
        table.insert(editPoints, lx)
        table.insert(editPoints, ly)
        table.insert(editPoints, lz)
    end

    local step = 1.0 / (targetPoints - 1)

    for i = 0, targetPoints - 1 do
        local t = i * step
        local wx, wy, wz = getSplinePosition(spline, t)
        pushWorld(wx, wy, wz)
    end

    if #editPoints < 6 then
        printError("[SplineToolkit] Not enough points")
        return
    end

    local newSpline = createSplineFromEditPoints(parent, editPoints, false, isClosed)
    if newSpline == 0 then
        printError("[SplineToolkit] Failed to create spline")
        return
    end

    setName(newSpline, name)

    clearSelection()
    delete(spline)
    addSelection(newSpline)

    print(string.format("[SplineToolkit] Spline resampled → %d points", targetPoints))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- 	SET SPLINE OBJECTS		------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------

function SplineToolkit:createSetObjectsTransformGroup()
    local root = getRootNode()
    local mainTG, sourceObjTG, sourceSplineTG, placedObjTG
    local createdRoot = false
    local created = {}

    for i = 0, getNumOfChildren(root) - 1 do
        local child = getChildAt(root, i)
        if getName(child) == "SetObjectsBySpline" then
            mainTG = child
            break
        end
    end

    if mainTG == nil then
        mainTG = createTransformGroup("SetObjectsBySpline")
        link(root, mainTG)
        createdRoot = true
    end

    for i = 0, getNumOfChildren(mainTG) - 1 do
        local child = getChildAt(mainTG, i)
        local name = getName(child)
        if name == "SourceObject" then sourceObjTG = child end
        if name == "SourceSplines" then sourceSplineTG = child end
        if name == "PlacedObjects" then placedObjTG = child end
    end

    if sourceObjTG == nil then
        sourceObjTG = createTransformGroup("SourceObject")
        link(mainTG, sourceObjTG)
        table.insert(created, "SourceObject")
    end

    if sourceSplineTG == nil then
        sourceSplineTG = createTransformGroup("SourceSplines")
        link(mainTG, sourceSplineTG)
        table.insert(created, "SourceSplines")
    end

    if placedObjTG == nil then
        placedObjTG = createTransformGroup("PlacedObjects")
        link(mainTG, placedObjTG)
        table.insert(created, "PlacedObjects")
    end

    if not createdRoot and #created == 0 then
        printWarning('Transformgroup "SetObjectsBySpline" already exists.')
        return
    end
	
    printError('--------------------------------------------------------')
    print('Created "SetObjectsBySpline" Transformgroup')
    print(" └─ SetObjectsBySpline")

    local printed = {}
    for _, name in ipairs({"SourceObject","SourceSplines","PlacedObjects"}) do
        printed[name] = true
        local prefix = (name == "PlacedObjects") and "    └─ " or "    ├─ "
        print(prefix .. name)
    end
    printError('--------------------------------------------------------')
end

function SplineToolkit:generateObjectsOnSpline()
    local mainTG, srcObjTG, srcSplineTG, placedTG = self:getPlaceObjectTransformgroup()
    link(mainTG, placedTG)

    for i = getNumOfChildren(placedTG)-1,0,-1 do
        delete(getChildAt(placedTG,i))
    end

    local sourceCount = getNumOfChildren(srcObjTG)
    if sourceCount == 0 then
        printError("[SplineToolkit] No SourceObjects found.")
        return
    end

    local placeType    = self.uiObjectPlaceType:getValue()
    local distType     = self.uiObjectDistanceType:getValue()
    local fixDist      = math.max(self.uiObjectFixDistance:getValue(),0.01)
    local minDist      = self.uiObjectMinDistance:getValue()
    local maxDist      = self.uiObjectMaxDistance:getValue()

    local sideOffset   = self.uiObjectOffsetSide:getValue()

    local widthLeft    = self.uiPlaceWidthLeft:getValue()
    local widthRight   = self.uiPlaceWidthRight:getValue()

    local heightType   = self.uiSetHeightType:getValue()
    local followAxis   = self.uiFollowAxis:getValue()

    local fixHeight    = self.uiObjectHeight:getValue()
    local randomRotate = self:getChoiceBoolean(self.uiRandomRotate)
    local baseRotate   = math.rad(self.uiObjectRotate:getValue() or 0)

    local terrain = self:getTerrain()

    local created = 0
    local seqIndex = 0

    ------------------------------------------------------------
    -- Width Mode
    ------------------------------------------------------------

    local useWidth = (placeType == 2 or placeType == 4)

    if useWidth then

        if heightType == 2 or heightType == 5 then

            if heightType == 2 then
                heightType = 1
                printWarning("Place type with width does not support Follow Axis height types. 'On Spline' was used instead.")
            elseif heightType == 5 then
                heightType = 3
                printWarning("Place type with width does not support Follow Axis height types. 'On Terrain' was used instead.")
            end

        end

    end

    ------------------------------------------------------------
    -- Step function
    ------------------------------------------------------------

    local function getStep()
        if distType == 1 then
            return fixDist
        end
        return math.random()*(maxDist-minDist)+minDist
    end

    ------------------------------------------------------------
    -- Sample spline
    ------------------------------------------------------------

    local function sampleSpline(spline,length,dist)

        dist = math.max(0,math.min(dist,length))

        local t = dist/length
        local px,py,pz = getSplinePosition(spline,t)
        local dx,dy,dz = getSplineDirection(spline,t)

        local rx,rz = -dz,dx
        local rl = math.sqrt(rx*rx+rz*rz)

        if rl>0 then
            rx,rz = rx/rl,rz/rl
        end

        local side

        if useWidth then
            side = math.random()* (widthLeft + widthRight) - widthLeft
        else
            side = sideOffset
        end

        px = px + rx*side
        pz = pz + rz*side

        if heightType == 3 or heightType == 4 or heightType == 5 then
            if terrain then
                py = getTerrainHeightAtWorldPos(terrain,px,py,pz)
            end
        elseif heightType == 6 then
            py = fixHeight
        end

        return px,py,pz
    end

    ------------------------------------------------------------
    -- Iterate splines
    ------------------------------------------------------------

    for i=0,getNumOfChildren(srcSplineTG)-1 do

        local spline = getChildAt(srcSplineTG,i)

        if getHasClassId(spline,ClassIds.SHAPE) and getHasClassId(getGeometry(spline),ClassIds.SPLINE) then

            local length = getSplineLength(spline)
            local dist = 0

            while dist <= length do

                local px,py,pz = sampleSpline(spline,length,dist)

                ------------------------------------------------
                -- Objekt wählen
                ------------------------------------------------

                local sourceObject

                if placeType == 1 or placeType == 2 then
                    sourceObject = getChildAt(srcObjTG,seqIndex)
                    seqIndex = (seqIndex+1)%sourceCount
                else
                    sourceObject = getChildAt(srcObjTG,math.random(0,sourceCount-1))
                end

                local inst = clone(sourceObject,false)
                link(placedTG,inst)

                setWorldTranslation(inst,px,py,pz)

                ------------------------------------------------
                -- Richtung bestimmen
                ------------------------------------------------

                local step = getStep()

                local x1,y1,z1 = sampleSpline(spline,length,dist)
                local x2,y2,z2 = sampleSpline(spline,length,dist+step)

                local tx = x2-x1
                local ty = y2-y1
                local tz = z2-z1

                local tl = math.sqrt(tx*tx + ty*ty + tz*tz)
                if tl < 0.00001 then tl = 0.00001 end

                tx,ty,tz = tx/tl, ty/tl, tz/tl

                local ry = math.atan2(tx,tz) + baseRotate

                if randomRotate then
                    ry = ry + math.random()*math.pi*2
                end

                ------------------------------------------------
                -- HeightType Logic
                ------------------------------------------------

                if heightType == 1 then
                    setWorldRotation(inst,0,ry,0)

                elseif heightType == 2 then

                    local ux,uy,uz = 0,1,0
                    setWorldDirection(inst,tx,ty,tz,ux,uy,uz)

                    local horiz = math.sqrt((x2-x1)^2 + (z2-z1)^2)
                    if horiz < 0.00001 then horiz = 0.00001 end

                    local slope = math.atan2(y2-y1,horiz)

                    if followAxis == 1 then
                        rotateAboutLocalAxis(inst,-slope,0,0,1)
                    else
                        rotateAboutLocalAxis(inst,slope,1,0,0)
                    end

                elseif heightType == 3 then
                    setWorldRotation(inst,0,ry,0)

                elseif heightType == 4 and terrain then

                    local ux,uy,uz = getTerrainNormalAtWorldPos(terrain,px,py,pz)
                    local ul = math.sqrt(ux*ux+uy*uy+uz*uz)

                    if ul>0 then
                        ux,uy,uz = ux/ul,uy/ul,uz/ul
                    end

                    setWorldDirection(inst,tx,ty,tz,ux,uy,uz)

                elseif heightType == 5 then

                    local ux,uy,uz = 0,1,0
                    setWorldDirection(inst,tx,ty,tz,ux,uy,uz)

                    local horiz = math.sqrt((x2-x1)^2 + (z2-z1)^2)
                    if horiz < 0.00001 then horiz = 0.00001 end

                    local slope = math.atan2(y2-y1,horiz)

                    if followAxis == 1 then
                        rotateAboutLocalAxis(inst,-slope,0,0,1)
                    else
                        rotateAboutLocalAxis(inst,slope,1,0,0)
                    end

                elseif heightType == 6 then
                    setWorldRotation(inst,0,ry,0)
                end

                created = created + 1
                dist = dist + step

            end
        end
    end

    print(string.format("[SplineToolkit] Generated %d objects along splines.",created))

end

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- 	PLACE FENCE 		--------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------
function SplineToolkit:loadFenceFromXML(index)
    local values = self.values.fencePlacement
    local fence = values.fenceTable[index]

    if not fence or not fence.xmlFile then
        printWarning("[SplineToolkit] No fence xml defined.")
        return
    end

    local xmlPath = fence.xmlFile:gsub("%$data", gamePath .. "data")

    if not fileExists(xmlPath) then
        printError("[SplineToolkit] Fence XML not found: " .. xmlPath)
        return
    end

    local xmlFile = XMLFile.load("fenceXML", xmlPath)
    if not xmlFile then
        printError("[SplineToolkit] Could not load fence XML.")
        return
    end

    self.selFenceInfo = {
        i3dFile = nil,
        poles = {},
        panels = {},
        gates = {}
    }

	-- I3D Datei-- I3D Datei
	local i3dFile = xmlFile:getString("placeable.base.filename")
	if i3dFile then
		if fence.isCustom then
			-- Nur Dateiname extrahieren (immer!)
			local fileName = i3dFile:match("([^/\\]+%.i3d)$")
			if fileName then
				local xmlDir = fence.xmlFile:match("^(.*[/\\])")
				self.selFenceInfo.i3dFile = xmlDir .. fileName
			else
				printWarning("[SplineToolkit] Could not extract i3d filename.")
			end
		else
			self.selFenceInfo.i3dFile = i3dFile:gsub("%$data", gamePath .. "data")
		end
	end

    -- I3D Mappings lesen
    local i3dMappings = {}
    xmlFile:iterate("placeable.i3dMappings.i3dMapping", function(_, key)
        local id = xmlFile:getString(key .. "#id")
        local node = xmlFile:getString(key .. "#node")
        if id and node then
            i3dMappings[id] = node
        end
    end)

		-- Segmente durchgehen (wir flatten alles)
	local limitFenceSegment = false

	if fence.xmlFile == "$data/placeables/brandless/fences/US/fence08/fence08.xml"
	or fence.xmlFile == "$data/placeables/brandless/fences/US/fence12/fence12.xml" then
		limitFenceSegment = true
	end

	local fenceSegmentHandled = false

	xmlFile:iterate("placeable.fence.segment", function(_, segKey)

		local segmentClass = xmlFile:getString(segKey .. "#class")

		-- Nur für die beiden speziellen XMLs:
		if limitFenceSegment and segmentClass == "FenceSegment" then
			if fenceSegmentHandled then
				return -- weitere FenceSegment überspringen
			end
			fenceSegmentHandled = true
		end

		-- Poles
		xmlFile:iterate(segKey .. ".poles.pole", function(_, poleKey)
			local nodeId = xmlFile:getString(poleKey .. "#node")
			local radius = xmlFile:getFloat(poleKey .. "#radius") or 0
			if nodeId then
				table.insert(self.selFenceInfo.poles, {
					id = nodeId,
					nodePath = i3dMappings[nodeId],
					radius = radius
				})
			end
		end)

		-- Panels
		xmlFile:iterate(segKey .. ".panels.panel", function(_, panelKey)
			local nodeId = xmlFile:getString(panelKey .. "#node")
			local length = xmlFile:getFloat(panelKey .. "#length") or 0
			if nodeId then
				table.insert(self.selFenceInfo.panels, {
					id = nodeId,
					nodePath = i3dMappings[nodeId],
					length = length
				})
			end
		end)

		-- Gates
		xmlFile:iterate(segKey .. ".gate", function(_, gateKey)
			local nodeId = xmlFile:getString(gateKey .. "#node")
			local length = xmlFile:getFloat(gateKey .. "#length") or 0
			if nodeId then
				table.insert(self.selFenceInfo.gates, {
					id = nodeId,
					nodePath = i3dMappings[nodeId],
					length = length
				})
			end
		end)

	end)

    xmlFile:delete()
end

function SplineToolkit:prepareFenceGroupForSpline(splineIDs)
    local fenceRoot = self:getPlaceFenceTransformgroup()

    local selectedIndex = (self.uiListFence:getSelectedItem() or 0) + 1
    local fenceData = self.values.fencePlacement.fenceTable[selectedIndex]
    local cleanName = (fenceData and fenceData.name or "Fence"):gsub("%s+", "")

    if not splineIDs or #splineIDs == 0 then
        return nil
    end

    local firstSpline = splineIDs[1]
    local splineParent = getParent(firstSpline)
    local fenceTG = nil
    local isExistingGroup = false

    if splineParent ~= 0 and getParent(splineParent) == fenceRoot then
        fenceTG = splineParent
        isExistingGroup = true

		local currentName = getName(fenceTG)

		if not currentName:find("^" .. cleanName .. "_") then

			local num = 1
			local function exists(name)
				for i = 0, getNumOfChildren(fenceRoot) - 1 do
					local child = getChildAt(fenceRoot, i)
					if child ~= fenceTG and getName(child) == name then
						return true
					end
				end
				return false
			end

			while exists(cleanName .. "_" .. num) do
				num = num + 1
			end

			setName(fenceTG, cleanName .. "_" .. num)
		end
    else
        local num = 1
        local function exists(name)
            for i = 0, getNumOfChildren(fenceRoot) - 1 do
                if getName(getChildAt(fenceRoot, i)) == name then
                    return true
                end
            end
            return false
        end

        while exists(cleanName .. "_" .. num) do
            num = num + 1
        end

        fenceTG = createTransformGroup(cleanName .. "_" .. num)
        link(fenceRoot, fenceTG)
    end

    for _, splineID in ipairs(splineIDs) do
        if getParent(splineID) ~= fenceTG then
            unlink(splineID)
            link(fenceTG, splineID)
        end
    end

    local fenceSub = nil
    local gatesSub = nil

    for i = 0, getNumOfChildren(fenceTG) - 1 do
        local child = getChildAt(fenceTG, i)
        local name = getName(child)

        if name == "fence" then fenceSub = child end
        if name == "gates" then gatesSub = child end
    end

    if not fenceSub then
        fenceSub = createTransformGroup("fence")
        link(fenceTG, fenceSub)
    end

    if not gatesSub then
        gatesSub = createTransformGroup("gates")
        link(fenceTG, gatesSub)
    end

    if isExistingGroup then
        for i = getNumOfChildren(fenceSub) - 1, 0, -1 do
            delete(getChildAt(fenceSub, i))
        end
    end

    self.currentFenceSubTG = fenceSub
    self.currentGateSubTG  = gatesSub

    return fenceTG
end

function SplineToolkit:resolveI3DMappingNode(rootNode, nodePath)
    if not nodePath or nodePath == "" then return nil end

    local current = rootNode

    for part in string.gmatch(nodePath, "[^|]+") do
        local indices = {}
        for num in string.gmatch(part, "%d+") do
            table.insert(indices, tonumber(num))
        end

        for _, idx in ipairs(indices) do
            if getNumOfChildren(current) > idx then
                current = getChildAt(current, idx)
            else
                return nil
            end
        end
    end

    return current
end

function SplineToolkit:isSpline(entityId)
    return entityId ~= 0
        and getHasClassId(entityId, ClassIds.SHAPE)
        and getHasClassId(getGeometry(entityId), ClassIds.SPLINE)
end

function SplineToolkit:selectedIsFenceGroup()
    if getNumSelected() ~= 1 then
        return false, nil
    end

    local selected = getSelection(0)
    local fenceRoot = self:getPlaceFenceTransformgroup()

    if getParent(selected) ~= fenceRoot then
        return false, nil
    end

    local splineIDs = {}

    for i = 0, getNumOfChildren(selected) - 1 do
        local child = getChildAt(selected, i)

        if self:isSpline(child) then
            table.insert(splineIDs, child)
        end
    end

    if #splineIDs == 0 then
        return false, nil
    end

    return true, splineIDs
end

function SplineToolkit:importFenceGate(index)
    if not self.selFenceInfo or not self.selFenceInfo.i3dFile then
        printError("No fence loaded.")
        return
    end

    local gates = self.selFenceInfo.gates or {}
    if #gates == 0 then
        printWarning("Selected fence has no gates.")
        return
    end

    local gateDef = gates[index]
    if not gateDef then
        printError("Invalid gate index.")
        return
    end

    local cacheNode = loadI3DFile(self.selFenceInfo.i3dFile)
    if cacheNode == 0 then
        printError("Failed to load fence i3d.")
        return
    end

    local gateNode = self:resolveI3DMappingNode(cacheNode, gateDef.nodePath)
    if not gateNode then
        printError("Gate node not found in i3d.")
        delete(cacheNode)
        return
    end

    local cloneGate = clone(gateNode, false)

    local isFenceGroup = self:selectedIsFenceGroup()

    if isFenceGroup then

        local selectedNode = getSelection(0)
        local gatesTG = nil

        for i = 0, getNumOfChildren(selectedNode) - 1 do
            local child = getChildAt(selectedNode, i)
            if getName(child) == "gates" then
                gatesTG = child
                break
            end
        end

        if gatesTG then
            link(gatesTG, cloneGate)
        else
            link(selectedNode, cloneGate)
        end

    else
        link(getRootNode(), cloneGate)
    end

    delete(cacheNode)
end


function SplineToolkit:generateFenceOnSpline()
    if not self.selFenceInfo or not self.selFenceInfo.i3dFile then
        printError("No fence loaded.")
        return
    end

    local splineIDs = {}
    local isFenceGroup, groupSplines = self:selectedIsFenceGroup()

    if isFenceGroup then
        splineIDs = groupSplines
    else
        local numSelected = getNumSelected()
        if numSelected < 1 then
            printError("Select splines or a fence group.")
            return
        end
        for i = 0, numSelected - 1 do
            local id = getSelection(i)
            if self:isSpline(id) then
                table.insert(splineIDs, id)
            end
        end
    end

    if #splineIDs == 0 then
        printError("No valid splines found.")
        return
    end

    local fenceTG  = self:prepareFenceGroupForSpline(splineIDs)
    local cacheNode = loadI3DFile(self.selFenceInfo.i3dFile)
    if cacheNode == 0 then
        printError("Failed to load fence i3d.")
        return
    end
    link(fenceTG, cacheNode)

    local panels = self.selFenceInfo.panels or {}
    local poles  = self.selFenceInfo.poles  or {}
    if #panels == 0 then
        delete(cacheNode)
        return
    end

    local baseLength      = panels[1].length or 3
    local globalStartPole = self:getChoiceBoolean(self.uiFencePlaceStartPole)
    local globalEndPole   = self:getChoiceBoolean(self.uiFencePlaceEndPole)

    for _, splineID in ipairs(splineIDs) do
        if getHasClassId(splineID, ClassIds.SHAPE) and getHasClassId(getGeometry(splineID), ClassIds.SPLINE) then
			local splineType      = self:getSplineType(splineID)

            local splineLength = getSplineLength(splineID)
            local isClosed     = getIsSplineClosed(splineID)

            local placeStartPole = globalStartPole
            local placeEndPole   = globalEndPole
            if isClosed then
                placeStartPole = true
                placeEndPole   = false
            end

            local nodePositions = {}

            ------------------------------------------------
            -- PANEL GENERATION + NODE TRACKING
            ------------------------------------------------
            if splineType == "CUBIC" then
				local ratio  = splineLength / baseLength
				local nFloor = math.max(1, math.floor(ratio))
				local nCeil  = math.max(1, math.ceil(ratio))

				local scaleFloor = splineLength / (nFloor * baseLength)
				local scaleCeil  = splineLength / (nCeil  * baseLength)

				local errFloor = math.abs(scaleFloor - 1)
				local errCeil  = math.abs(scaleCeil  - 1)

				local count = nFloor
				if errCeil < errFloor then
					count = nCeil
				end

				local step = splineLength / count

                for s = 0, count - 1 do
                    local t0 = (s * step) / splineLength
                    local t1 = ((s + 1) * step) / splineLength

                    local x0,y0,z0 = getSplinePosition(splineID,t0)
                    local x1,y1,z1 = getSplinePosition(splineID,t1)

                    local dx = x1-x0
                    local dy = y1-y0
                    local dz = z1-z0
                    local len = math.sqrt(dx*dx+dy*dy+dz*dz)

                    if len > 0 then
                        dx,dy,dz = dx/len,dy/len,dz/len
                        local scale = len/baseLength

                        self:placeFencePanel(self.currentFenceSubTG,cacheNode, panels,{x0,y0,z0},{x1,y1,z1},{dx,dy,dz},scale)

                        if s == 0 then
                            table.insert(nodePositions,{x0,y0,z0,dx,dz})
                        end
                        table.insert(nodePositions,{x1,y1,z1,dx,dz})
                    end
                end

            else
                local numCV    = getSplineNumOfCV(splineID)
                local maxIndex = numCV - 2
                if isClosed then maxIndex = numCV - 1 end

                for s = 0, maxIndex do
                    local nextIndex = s + 1
                    if nextIndex >= numCV then nextIndex = 0 end

                    local x0,y0,z0 = getSplineCV(splineID,s)
                    local x1,y1,z1 = getSplineCV(splineID,nextIndex)

                    local dx = x1-x0
                    local dy = y1-y0
                    local dz = z1-z0
                    local segLength = math.sqrt(dx*dx+dy*dy+dz*dz)

                    if segLength > 0 then
                        dx,dy,dz = dx/segLength,dy/segLength,dz/segLength
						local ratio  = segLength / baseLength
						local nFloor = math.max(1, math.floor(ratio))
						local nCeil  = math.max(1, math.ceil(ratio))

						local scaleFloor = segLength / (nFloor * baseLength)
						local scaleCeil  = segLength / (nCeil  * baseLength)

						local errFloor = math.abs(scaleFloor - 1)
						local errCeil  = math.abs(scaleCeil  - 1)

						local panelCount = nFloor
						if errCeil < errFloor then
							panelCount = nCeil
						end

                        local step  = segLength / panelCount
                        local scale = step / baseLength

                        for p = 0, panelCount - 1 do
                            local px = x0 + dx*(p*step)
                            local py = y0 + dy*(p*step)
                            local pz = z0 + dz*(p*step)

                            local endX = px + dx*step
                            local endY = py + dy*step
                            local endZ = pz + dz*step

                            self:placeFencePanel(self.currentFenceSubTG,cacheNode, panels,{px,py,pz},{endX,endY,endZ},{dx,dy,dz},scale)

                            if s == 0 and p == 0 then
                                table.insert(nodePositions,{px,py,pz,dx,dz})
                            end
                            table.insert(nodePositions,{endX,endY,endZ,dx,dz})
                        end
                    end
                end
            end

            ------------------------------------------------
            -- POLE GENERATION (ISOLATED PER SPLINE)
            ------------------------------------------------
            if #poles > 0 then
                local total = #nodePositions
                for i = 1, total do
                    local x,y,z,dx,dz = unpack(nodePositions[i])
                    local isFirst = (i == 1)
                    local isLast  = (i == total)

                    local place = false
                    if isClosed then
                        place = true
                    else
                        if isFirst and placeStartPole then
                            place = true
                        elseif isLast and placeEndPole then
                            place = true
                        elseif not isFirst and not isLast then
                            place = true
                        end
                    end

                    if place then
                        self:placeFencePole(self.currentFenceSubTG,
                            cacheNode,poles,x,y,z,dx,dz,nil,nil)
                    end
                end
            end
        end
    end

    delete(cacheNode)
end

function SplineToolkit:placeFencePanel(fenceTG, cacheNode, panels, startPos, endPos, dir, scale)
    local panelDef = panels[math.random(1, #panels)]
    local panelNode = self:resolveI3DMappingNode(cacheNode, panelDef.nodePath)
    if not panelNode then return nil end

    local segment = clone(panelNode, false)
    link(fenceTG, segment)

    local terrain = self:getTerrain()

    local startX, startZ = startPos[1], startPos[3]
    local endX, endZ     = endPos[1],   endPos[3]

    local startY = startPos[2]
    local endY   = endPos[2]

    if terrain then
        startY = getTerrainHeightAtWorldPos(terrain, startX, 0, startZ)
        endY   = getTerrainHeightAtWorldPos(terrain, endX,   0, endZ)
    end

    -- 3D Richtungsvektor
    local dx = endX - startX
    local dy = endY - startY
    local dz = endZ - startZ

    local len = math.sqrt(dx*dx + dy*dy + dz*dz)
    if len ~= 0 then
        dx = dx / len
        dy = dy / len
        dz = dz / len
    end

    -- Yaw (Rotation um Y)
    local ry = math.atan2(dx, dz)

    -- Pitch (Rotation um X)
    local rx = -math.atan2(dy, math.sqrt(dx*dx + dz*dz))

    setWorldTranslation(segment, startX, startY, startZ)
    setWorldRotation(segment, rx, ry, 0)

    setScale(segment, 1, 1, scale)
	
	if self.uiFencePlaceYOffset:getValue() == 1 then

		local terrain = self:getTerrain()
		if terrain then

			local startX = startPos[1]
			local startZ = startPos[3]
			local endX   = endPos[1]
			local endZ   = endPos[3]

			local startY = getTerrainHeightAtWorldPos(terrain, startX, 0, startZ)
			local endY   = getTerrainHeightAtWorldPos(terrain, endX,   0, endZ)

			setWorldTranslation(segment, startX, startY, startZ)

			local ry = math.atan2(dir[1], dir[3])
			setWorldRotation(segment, 0, ry, 0)

			local yOffset = endY - startY

			local function applyYOffset(node)
				if node == nil or node == 0 then return end

				if getHasClassId(node, ClassIds.SHAPE) then
					local okMat, numMats = pcall(getNumOfMaterials, node)
					if okMat then
						for m = 0, numMats - 1 do
							local okParam = pcall(getShaderParameter, node, "yOffset", m)
							if okParam then
								setShaderParameter(node, "yOffset", yOffset, 0, 0, 0, false, m)
							end
						end
					end
				end

				for i = 0, getNumOfChildren(node) - 1 do
					applyYOffset(getChildAt(node, i))
				end
			end

			applyYOffset(segment)
		end
	end
    return segment
end

function SplineToolkit:placeFencePole(fenceTG, cacheNode, poles, x,y,z, dx,dz,prevDirX, prevDirZ)
    local poleDef = poles[math.random(1, #poles)]
    local poleNode = self:resolveI3DMappingNode(cacheNode, poleDef.nodePath)
    if not poleNode then return end

    local pole = clone(poleNode, false)
    link(fenceTG, pole)

    local terrain = self:getTerrain()
    local terrainY = y

    if terrain then
        terrainY = getTerrainHeightAtWorldPos(terrain, x, 0, z)
    end

    setWorldTranslation(pole, x, terrainY, z)

    local currX = dx
    local currZ = dz

    local rx, rz

    if prevDirX then
        rx = prevDirX + currX
        rz = prevDirZ + currZ
    else
        rx = currX
        rz = currZ
    end

    local rlen = math.sqrt(rx*rx + rz*rz)
    if rlen ~= 0 then
        rx = rx / rlen
        rz = rz / rlen
    end

    local ry = math.atan2(rx, rz)
    setWorldRotation(pole, 0, ry, 0)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- 	EXPORT SPLINE		-----------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------

function SplineToolkit:exportSplineToObj()
    if getNumSelected() == 0 then
        print("Select at least one spline.")
        return
    end

    local i3dFilePath = getSceneFilename()
    if not i3dFilePath or i3dFilePath == "" then
        print("No i3d loaded.")
        return
    end

    local basePath = i3dFilePath:match("(.*/)")
    local exportPath = SplineToolkit.EXPORT_PATH_OBJ
	
	if not folderExists(SplineToolkit.EXPORT_PATH) then 
		createFolder(SplineToolkit.EXPORT_PATH) 
	end
    if not folderExists(exportPath) then createFolder(exportPath) end

    -- Custom Filename
    local filename
    if self.uiExportUseCustomFilename:getValue() then
        local custom = self.uiExportCustomFilename:getValue()
        if custom and custom ~= "" then
            filename = custom:gsub("%s+", "_") .. ".obj"
        else
            filename = "SplineExport.obj"
        end
    else
        filename = "SplineExport.obj"
    end

    local objFilePath = exportPath .. filename
    local file = createFile(objFilePath, FileAccess.WRITE)
    if file == 0 then
        print("Could not create file:", objFilePath)
        return
    end

    fileWrite(file, "# Exported by SplineToolkit by Aslan\n")

    local meshType  = self.uiExportType:getValue()
    local distType  = self.uiExportDistanceType:getValue()
    local fixedDist = self.uiExportDistance:getValue()
    local minDist   = self.uiExportMinDistance:getValue()
    local minAngle  = math.rad(self.uiExportMinAngle:getValue())

    local globalVertexCount = 0

    for s = 0, getNumSelected() - 1 do
        local splineID = getSelection(s)

        if getHasClassId(splineID, ClassIds.SHAPE) and getHasClassId(getGeometry(splineID), ClassIds.SPLINE) then
            local vertexIndices = {}
            if meshType == 1 then
                -- Only original CVs
                local numCVs = getSplineNumOfCV(splineID)
                for i = 0, numCVs - 1 do
                    local x,y,z = getSplineCV(splineID, i)
                    fileWrite(file, string.format("v %.6f %.6f %.6f\n", x,y,z))
                    globalVertexCount = globalVertexCount + 1
                    table.insert(vertexIndices, globalVertexCount)
                end
            else
                local length = getSplineLength(splineID)
                local t = 0.0
                local internalStep = 0.05

                local lastX,lastY,lastZ = nil,nil,nil
                local lastDirX,lastDirY,lastDirZ = nil,nil,nil

                while t <= length do

                    local px,py,pz = getSplinePosition(splineID, t/length)
                    local dx,dy,dz = getSplineDirection(splineID, t/length)

                    local addVertex = false

                    if not lastX then
                        addVertex = true
                    else
                        local dist = math.sqrt((px-lastX)^2 + (py-lastY)^2 + (pz-lastZ)^2)

                        if distType == 1 then
                            if dist >= fixedDist then
                                addVertex = true
                            end
                        else
                            if dist >= minDist then
                                local dot = dx*lastDirX + dy*lastDirY + dz*lastDirZ
                                dot = math.max(-1, math.min(1, dot))
                                local angle = math.acos(dot)
                                if angle >= minAngle then
                                    addVertex = true
                                end
                            end
                        end
                    end

                    if addVertex then
                        fileWrite(file, string.format("v %.6f %.6f %.6f\n", px,py,pz))
                        globalVertexCount = globalVertexCount + 1
                        table.insert(vertexIndices, globalVertexCount)

                        lastX,lastY,lastZ = px,py,pz
                        lastDirX,lastDirY,lastDirZ = dx,dy,dz
                    end

                    t = t + internalStep
                end
                local px,py,pz = getSplinePosition(splineID, 1.0)
                fileWrite(file, string.format("v %.6f %.6f %.6f\n", px,py,pz))
                globalVertexCount = globalVertexCount + 1
                table.insert(vertexIndices, globalVertexCount)
            end

            if #vertexIndices > 1 then
                fileWrite(file, "l ")
                for _, idx in ipairs(vertexIndices) do
                    fileWrite(file, tostring(idx) .. " ")
                end
                fileWrite(file, "\n")
            end
        else
            print("Selection contains non-spline object.")
        end
    end

    delete(file)
    print("Export completed: " .. objFilePath)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- 	GEN ROAD MESH		-----------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------

function SplineToolkit:generateRoad()
    if getNumSelected() ~= 1 then
        printError("Select exactly one spline.")
        return
    end

    local spline = getSelection(0)

    if not getHasClassId(getGeometry(spline), ClassIds.SPLINE) then
        printError("Selected object is not a spline.")
        return
    end

    local roadName = (self.uiRoadName:getValue() or ""):match("^%s*(.-)%s*$")

    if roadName == "" then
        printError("[SplineToolkit] Enter a Road Name.")
        return
    end

    local mainTG = self:getRoadTransformgroup()
    local parent = getParent(spline)
    local alreadyRoadSpline = false

    if parent ~= nil and parent ~= 0 then
        if getParent(parent) == mainTG then
            alreadyRoadSpline = true
        end
    end

    local existingTG = self:getChildByName(mainTG, roadName)

    if not alreadyRoadSpline and existingTG ~= nil then
        YesNoDialog.show(
            "Road already exists",
            "A road group named '" .. roadName .. "' already exists.\nDo you want to overwrite it?",
            function(result)
                if result == true then
                    self:generateRoadExecute(spline)
                else
                    print("[SplineToolkit] Road generation cancelled.")
                end

            end, "Overwrite", "Cancel")
        return
    end

    self:generateRoadExecute(spline)
end

function SplineToolkit:generateRoadExecute(spline)
    local segments   = self:buildAdaptiveSegments(spline)
    local alignEdges = self:getChoiceBoolean(self.uiGenRoadAlignEdges)

    local vertices, uvs, faces = self:buildMesh(spline, segments, alignEdges)
    local trafficData = self:buildTrafficSplines(spline, segments)

    self:exportRoad(spline, vertices, uvs, faces, trafficData)
end

function SplineToolkit:getChildByName(parent, name)
    if parent == 0 or parent == nil then return nil end
    for i = 0, getNumOfChildren(parent) - 1 do
        local c = getChildAt(parent, i)
        if getName(c) == name then
            return c
        end
    end
    return nil
end

function SplineToolkit:linkI3DRoadChildren(i3dRoot, targetTG)
    for i = getNumOfChildren(i3dRoot) - 1, 0, -1 do
        local c = getChildAt(i3dRoot, i)
        link(targetTG, c)
    end
    delete(i3dRoot)
end

function SplineToolkit:buildAdaptiveSegments(spline)
    local segments = {}
    local minLen   = self.uiGenRoadMinSegLenght:getValue()
    local minAngle = math.rad(self.uiGenRoadMinAngle:getValue())

    local function splitSegment(t1, t2)

        local px1, _, pz1 = getSplinePosition(spline, t1)
        local px2, _, pz2 = getSplinePosition(spline, t2)

        local dx1, _, dz1 = getSplineDirection(spline, t1)
        local dx2, _, dz2 = getSplineDirection(spline, t2)

        local segLen = math.sqrt((px2 - px1)^2 + (pz2 - pz1)^2)

        local dot = dx1 * dx2 + dz1 * dz2
        dot = math.max(-1, math.min(1, dot))
        local angle = math.acos(dot)

        if segLen > minLen and angle > minAngle then
            local tm = (t1 + t2) * 0.5
            splitSegment(t1, tm)
            splitSegment(tm, t2)
        else
            table.insert(segments, { t1 = t1, t2 = t2 })
        end
    end

    splitSegment(0.0, 1.0)
    return segments
end

function SplineToolkit:buildMesh(spline, segments, alignEdgesOnTerrain)
    local verts = {}
    local uvs   = {}
    local faces = {}

    local width     = self.uiGenRoadWidthSlider:getValue()
    local halfWidth = width * 0.5

    -- Texture settings
    local texDist     = math.max(self.uiTextureDistSlider:getValue() or 5.0, 0.01) -- meters per full texture length
    local sliceStartP = (self.uiTextureSliceStartSlider:getValue() or 0.0) / 100.0
    local sliceEndP   = (self.uiTextureSliceEndSlider:getValue() or 25.0) / 100.0
    local mirror      = self:getChoiceBoolean(self.uiMirrorAtCenter)

    -- clamp slice
    sliceStartP = math.max(0.0, math.min(1.0, sliceStartP))
    sliceEndP   = math.max(0.0, math.min(1.0, sliceEndP))
    -- if sliceEndP < sliceStartP then
        -- sliceStartP, sliceEndP = sliceEndP, sliceStartP
    -- end
    local sliceRange = math.max(sliceEndP - sliceStartP, 0.000001)

    local mTerrainID = nil
    if alignEdgesOnTerrain then
        mTerrainID = self:getTerrain()
    end

    local prevPx, prevPz = nil, nil
    local accDist = 0.0
    local sectionCount = 0

    local function fract(x)
        return x - math.floor(x)
    end

    local function addVertex(px, py, pz, u, v)
        verts[#verts + 1] = { px, py, pz }
        uvs[#uvs + 1]     = { u, v }
    end

    local function addCrossSection(t)
        local px, py, pz = getSplinePosition(spline, t)
        local dx, _, dz  = getSplineDirection(spline, t)

        -- accumulate distance (XZ)
        if prevPx ~= nil then
            local ddx = px - prevPx
            local ddz = pz - prevPz
            accDist = accDist + math.sqrt(ddx*ddx + ddz*ddz)
        end
        prevPx, prevPz = px, pz

        -- right vector
        local rx, rz = -dz, dx
        local len = math.sqrt(rx*rx + rz*rz)
        if len < 0.0001 then return end
        rx, rz = rx / len, rz / len

        -- positions: left / center / right (immer center-cut!)
        local lx  = px - rx * halfWidth
        local lz  = pz - rz * halfWidth
        local cx  = px
        local cz  = pz
        local rxp = px + rx * halfWidth
        local rzp = pz + rz * halfWidth

        local ly, cy, ry = py, py, py
		if mTerrainID then
			ly = getTerrainHeightAtWorldPos(mTerrainID, lx, 0, lz) or py
			cy = getTerrainHeightAtWorldPos(mTerrainID, cx, 0, cz) or py
			ry = getTerrainHeightAtWorldPos(mTerrainID, rxp, 0, rzp) or py
		end

		local u = accDist / texDist 

		local vStart = 1.0 - sliceStartP   -- z.B. 0% => 1.0
		local vEnd   = 1.0 - sliceEndP     -- z.B. 25% => 0.75

		local vL, vC, vR

		if mirror then
			-- invertiert: das was vorher außen war, ist jetzt Mitte (und umgekehrt)
			vL, vC, vR = vStart, vEnd, vStart
		else
			vL = vStart
			vC = (vStart + vEnd) * 0.5
			vR = vEnd
		end
		addVertex(lx,  ly, lz,  u, vL)
		addVertex(cx,  cy, cz,  u, vC)
		addVertex(rxp, ry, rzp, u, vR)

        sectionCount = sectionCount + 1

        if sectionCount >= 2 then
            local currBase = (#verts - 2)
            local prevBase = currBase - 3

            local pL = prevBase
            local pC = prevBase + 1
            local pR = prevBase + 2

            local cL = currBase
            local cC = currBase + 1
            local cR = currBase + 2

            table.insert(faces, { pL, pC, cL })
            table.insert(faces, { cL, pC, cC })

            table.insert(faces, { pC, pR, cC })
            table.insert(faces, { cC, pR, cR })
        end
    end

    for _, seg in ipairs(segments) do
        addCrossSection(seg.t1)
    end

    local lastSeg = segments[#segments]
    if lastSeg then
        addCrossSection(lastSeg.t2)
    end

    return verts, uvs, faces
end

function SplineToolkit:buildTrafficSplines(spline, segments)
    local data = {}
    local halfWidth = self.uiGenRoadWidthSlider:getValue() * 0.5
    local roadName  = self.uiRoadName:getValue()

    if #segments == 0 then
        return data
    end

    local function buildOffsetSpline(name, offset)
        local cvs = {}

        local function addPoint(t)

            local px, py, pz = getSplinePosition(spline, t)
            local dx, _, dz = getSplineDirection(spline, t)

            local len = math.sqrt(dx*dx + dz*dz)
            if len < 0.0001 then
                dx, dz, len = 1, 0, 1
            end

            dx, dz = dx / len, dz / len

            local rx = -dz
            local rz = dx

            local cx = px + rx * offset
            local cz = pz + rz * offset

            cvs[#cvs + 1] = { cx, py, cz }
        end

        addPoint(0.0)

        for i = 1, #segments do
            local t1 = segments[i].t1
            local t2 = segments[i].t2
            local tm = (t1 + t2) * 0.5
            addPoint(tm)
        end

        addPoint(1.0)

        if #cvs >= 2 then
            data[name] = cvs
        end
    end

    if self:getChoiceBoolean(self.uiHasTrafficCenter) then
        buildOffsetSpline(roadName .. "_center", 0)
    end

    if self:getChoiceBoolean(self.uiHasTrafficLeft) then
        local offset = -halfWidth * (self.uiTrafficLeftPerc:getValue() / 100)
        buildOffsetSpline(roadName .. "_left", offset)
    end

    if self:getChoiceBoolean(self.uiHasTrafficRight) then
        local offset = halfWidth * (self.uiTrafficRightPerc:getValue() / 100)
        buildOffsetSpline(roadName .. "_right", offset)
    end

    return data
end

function SplineToolkit:exportRoad(spline, vertices, uvs, faces, trafficData)

    local uiRoadName = (self.uiRoadName:getValue() or ""):match("^%s*(.-)%s*$")

    local mainTG = self:getRoadTransformgroup()      -- Roads TG
    local parent = getParent(spline)

    local streetTG = nil
    local roadName = nil

    if parent ~= nil and parent ~= 0 then
        local parentOfParent = getParent(parent)

        if parentOfParent == mainTG then
            streetTG = parent
            roadName = getName(parent)
        end
    end

    if streetTG == nil then

        if uiRoadName == "" then
            printError("[SplineToolkit] Enter a Road Name.")
            return
        end

        streetTG = self:getChildByName(mainTG, uiRoadName)

        if streetTG == nil then
            streetTG = createTransformGroup(uiRoadName)
            link(mainTG, streetTG)
            print("[SplineToolkit] Created road: " .. uiRoadName)
        else
            print("[SplineToolkit] Updating existing road: " .. uiRoadName)
        end

        roadName = uiRoadName
    else
        print("[SplineToolkit] Updating existing road: " .. roadName)
    end

    local sourceName = "source_" .. roadName

    if getName(spline) ~= sourceName then
        setName(spline, sourceName)
    end

    if getParent(spline) ~= streetTG then
        link(streetTG, spline)
    end

    for i = getNumOfChildren(streetTG) - 1, 0, -1 do
        local child = getChildAt(streetTG, i)

        if child ~= spline then
            delete(child)
        end
    end

    if not folderExists(SplineToolkit.EXPORT_PATH) then
        createFolder(SplineToolkit.EXPORT_PATH)
    end

    local exportPath = SplineToolkit.EXPORT_PATH_ROAD
    if not folderExists(exportPath) then
        createFolder(exportPath)
    end

    local meshI3D    = exportPath .. roadName .. ".i3d"
    local objPath    = exportPath .. roadName .. ".obj"
    local trafficI3D = exportPath .. roadName .. "_trafficSplines.i3d"

    self:exportRoadOBJ(objPath, vertices, uvs, faces)
    self:exportRoadI3DMesh(meshI3D, vertices, uvs, faces)

    if next(trafficData) then
        self:exportRoadTrafficSplines(trafficI3D, trafficData)
    end

    local meshRoot = loadI3DFile(meshI3D)
    if meshRoot ~= 0 then
        self:linkI3DRoadChildren(meshRoot, streetTG)
    end

    if next(trafficData) then
        local trafficTG = createTransformGroup("trafficSplines")
        link(streetTG, trafficTG)

        local trafficRoot = loadI3DFile(trafficI3D)
        if trafficRoot ~= 0 then
            self:linkI3DRoadChildren(trafficRoot, trafficTG)
        end
    end

    print("[SplineToolkit] Road generated: " .. roadName)
end

function SplineToolkit:exportRoadOBJ(path, verts, uvs, faces)
    local f = createFile(path, FileAccess.WRITE)
    if f == 0 then
        printError("OBJ export failed")
        return
    end

    fileWrite(f, "# Generated by SplineToolkit Script from Aslan\n")

    -- Vertices
    for i, v in ipairs(verts) do
        local x = tonumber(v[1]) or 0
        local y = tonumber(v[2]) or 0
        local z = tonumber(v[3]) or 0
        fileWrite(f, string.format("v %.6f %.6f %.6f\n", x, y, z))
    end

    fileWrite(f, "\n")

    -- UVs
    for i, uv in ipairs(uvs or {}) do
        local u = tonumber(uv[1]) or 0
        local v = tonumber(uv[2]) or 0
        fileWrite(f, string.format("vt %.6f %.6f\n", u, v))
    end

    fileWrite(f, "\n")

    -- Faces (vertexIndex/uvIndex)
    for _, t in ipairs(faces) do
        local v1 = t[1]
        local v2 = t[2]
        local v3 = t[3]

        -- OBJ indices are 1-based (wie Lua)
        fileWrite(f, string.format(
            "f %d/%d %d/%d %d/%d\n",
            v1, v1,
            v2, v2,
            v3, v3
        ))
    end

    delete(f)
end

function SplineToolkit:exportRoadI3DMesh(path, verts, uvs, faces)
    local f = createFile(path, FileAccess.WRITE)
    if f == 0 then printError("i3D export failed") return end

    local vCount = #verts
    local tCount = #faces

    -- pick selected texture def
    local values = self.values.roadMesh
    local texIndex = self.selectedRoadTextureIndex or 1
    local texDef = values.textureTable and values.textureTable[texIndex] or nil

    -- terrainDecal
    local terrainDecal = self:getChoiceBoolean(self.uiTerrainDecal)

    -- collect texture files (optional)
    local shaderFile = "$data/shaders/vertexPaintShader.xml"

    local diffuse  = texDef and texDef.textures and texDef.textures["diffuse"]  or nil
    local normal   = texDef and texDef.textures and texDef.textures["normal"]   or nil
    local specular = texDef and texDef.textures and texDef.textures["specular"] or nil
    local height   = texDef and texDef.textures and texDef.textures["height"]   or nil
    local alpha    = texDef and texDef.textures and texDef.textures["alpha"]    or nil

    -- decide shader variation
    local variation = "customParallax_alphaMap"
    if height ~= nil and alpha == nil then
        variation = "customParallax"
    elseif height == nil and alpha ~= nil then
        variation = "customAlphaMap"
    elseif height == nil and alpha == nil then
        variation = "custom"
    end

    -- FileIds
    local fileId = 1
    local fileIds = {}

    local function addFile(filename)
        if filename == nil then return nil end
        if fileIds[filename] ~= nil then
            return fileIds[filename]
        end
        local id = fileId
        fileIds[filename] = id
        fileId = fileId + 1
        return id
    end

    local idDiffuse  = addFile(diffuse)
    local idNormal   = addFile(normal)
    local idSpecular = addFile(specular)
    local idAlpha    = addFile(alpha)
    local idHeight   = addFile(height)
    local idShader   = addFile(shaderFile)

    -- header
    fileWrite(f, '<?xml version="1.0" encoding="iso-8859-1"?>\n\n')
    fileWrite(f, '<i3D name="SplineStreet" version="1.6" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://i3d.giants.ch/schema/i3d-1.6.xsd">\n')

    -- Files
    fileWrite(f, '  <Files>\n')
    -- write in deterministic order like sample
    if alpha    then fileWrite(f, string.format('    <File fileId="%d" filename="%s"/>\n', idAlpha, alpha)) end
    if diffuse  then fileWrite(f, string.format('    <File fileId="%d" filename="%s"/>\n', idDiffuse, diffuse)) end
    if height   then fileWrite(f, string.format('    <File fileId="%d" filename="%s"/>\n', idHeight, height)) end
    if normal   then fileWrite(f, string.format('    <File fileId="%d" filename="%s"/>\n', idNormal, normal)) end
    if specular then fileWrite(f, string.format('    <File fileId="%d" filename="%s"/>\n', idSpecular, specular)) end
    fileWrite(f, string.format('    <File fileId="%d" filename="%s"/>\n', idShader, shaderFile))
    fileWrite(f, '  </Files>\n\n')

    -- Materials
    fileWrite(f, '  <Materials>\n')
    fileWrite(f, string.format('    <Material name="roadMaterial" materialId="1" customShaderId="%d" customShaderVariation="%s">\n', idShader, texDef.shaderVar))

    if idDiffuse then
        fileWrite(f, string.format('      <Texture fileId="%d"/>\n', idDiffuse))
    end
    if idNormal then
        fileWrite(f, string.format('      <Normalmap fileId="%d"/>\n', idNormal))
    end
    if idSpecular then
        fileWrite(f, string.format('      <Glossmap fileId="%d"/>\n', idSpecular))
    end
    if idHeight then
        fileWrite(f, string.format('      <Custommap name="mParallaxMap" fileId="%d"/>\n', idHeight))
    end
    if idAlpha and texDef.shaderVar == "alphaNoise_customParallax_alphaMap" then
        fileWrite(f, string.format('      <Custommap name="alphaMap" fileId="%d"/>\n', idAlpha))
    end

    fileWrite(f, '    </Material>\n')
    fileWrite(f, '  </Materials>\n\n')

    -- Shapes
    fileWrite(f, '  <Shapes>\n')
    fileWrite(f, '    <IndexedTriangleSet name="Street" shapeId="1" isOptimized="false">\n')
    fileWrite(f, string.format('      <Vertices count="%d" normal="true" uv0="true" color="true">\n', vCount))

    for i = 1, vCount do
        local p = verts[i]
        local t0 = uvs[i] or {0.0, 0.0}
        -- normal = straight up (wie vorher)
        fileWrite(f, string.format('        <v p="%.4f %.4f %.4f" n="0 1 0" t0="%.6f %.6f" c="0.0 0.0 0.0 1.0"/>\n', p[1], p[2], p[3], t0[1], t0[2]))
    end

    fileWrite(f, '      </Vertices>\n')

    fileWrite(f, string.format('      <Triangles count="%d">\n', tCount))
    for _, tri in ipairs(faces) do
        fileWrite(f, string.format('        <t vi="%d %d %d"/>\n', tri[1]-1, tri[2]-1, tri[3]-1))
    end
    fileWrite(f, '      </Triangles>\n')

    fileWrite(f, '      <Subsets count="1">\n')
    fileWrite(f, string.format('        <Subset firstVertex="0" numVertices="%d" firstIndex="0" numIndices="%d"/>\n', vCount, tCount * 3))
    fileWrite(f, '      </Subsets>\n')

    fileWrite(f, '    </IndexedTriangleSet>\n')
    fileWrite(f, '  </Shapes>\n\n')

    -- Scene
    local shapeName = self.uiRoadName:getValue() or "Road"
    fileWrite(f, '  <Scene>\n')
    fileWrite(f, string.format('    <Shape name="%s" shapeId="1" static="%s" castsShadows="true" receiveShadows="true" nonRenderable="%s" terrainDecal="%s" materialIds="1"/>\n',
        shapeName,
        terrainDecal and "false" or "true",
        terrainDecal and "true" or "false",
        terrainDecal and "true" or "false"
    ))
    fileWrite(f, '  </Scene>\n\n')

    fileWrite(f, '</i3D>\n')
    delete(f)
end

function SplineToolkit:exportRoadTrafficSplines(path, trafficData)
    if next(trafficData) == nil then return end

    local f = createFile(path, FileAccess.WRITE)
    if f == 0 then
        printError("Failed to create traffic spline i3d")
        return
    end

    fileWrite(f, '<?xml version="1.0" encoding="iso-8859-1"?>\n')
    fileWrite(f, '<i3D name="TrafficSplines" version="1.6">\n')

    -- SHAPES
    fileWrite(f, '  <Shapes>\n')
    local shapeId = 1
    for name, cvs in pairs(trafficData) do
        fileWrite(f, string.format('    <NurbsCurve name="%s" shapeId="%d" type="cubic" degree="3" form="open">\n', name, shapeId))
        for _, cv in ipairs(cvs) do
            fileWrite(f, string.format('      <cv c="%.4f %.4f %.4f"/>\n', cv[1], cv[2], cv[3]))
        end
        fileWrite(f, '    </NurbsCurve>\n')
        shapeId = shapeId + 1
    end
    fileWrite(f, '  </Shapes>\n')

    -- SCENE
    fileWrite(f, '  <Scene>\n')
    local nodeIds = {}
    local nodeId = 1
    shapeId = 1
    for name, _ in pairs(trafficData) do
        fileWrite(f, string.format('    <Shape name="%s" shapeId="%d" nodeId="%d"/>\n', name, shapeId, nodeId))
        nodeIds[#nodeIds + 1] = nodeId
        shapeId = shapeId + 1
        nodeId = nodeId + 1
    end
    fileWrite(f, '  </Scene>\n')

    -- USER ATTRIBUTES
    fileWrite(f, '  <UserAttributes>\n')
    for _, nId in ipairs(nodeIds) do
        fileWrite(f, string.format('    <UserAttribute nodeId="%d">\n', nId))
        fileWrite(f, string.format('      <Attribute name="maxSpeedScale" type="float" value="%.3f"/>\n', self.uiMaxSpeedScale:getValue() or 1.0))
        fileWrite(f, string.format('      <Attribute name="speedLimit" type="float" value="%.3f"/>\n', self.uiSpeedLimit:getValue() or 15.0))
        fileWrite(f, '    </UserAttribute>\n')
    end
    fileWrite(f, '  </UserAttributes>\n')

    fileWrite(f, '</i3D>\n')
    delete(f)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- 	UTILS - TRANSFORMGROUP MANAGER 		---------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------

function SplineToolkit:getSplineToolkitTransformgroup()
    local root = getRootNode()
    for i = 0, getNumOfChildren(root) - 1 do
        local child = getChildAt(root, i)
        if getName(child) == "SplineToolkitAslan" then
            return child
        end
    end

    local tg = createTransformGroup("SplineToolkitAslan")
    link(root, tg)

    print("[SplineToolkit] Created TransformGroup 'SplineToolkitAslan'")
    return tg
end

function SplineToolkit:getPlaceObjectTransformgroup()
    local mainContainer = self:getSplineToolkitTransformgroup()

    local placeTG
    local sourceObjTG
    local sourceSplineTG
    local placedObjTG

    -- SetObjectsBySpline suchen
    for i = 0, getNumOfChildren(mainContainer) - 1 do
        local child = getChildAt(mainContainer, i)
        if getName(child) == "SetObjectsBySpline" then
            placeTG = child
            break
        end
    end

    -- Falls nicht vorhanden → erstellen
    if not placeTG then
        placeTG = createTransformGroup("SetObjectsBySpline")
        link(mainContainer, placeTG)
    end

    -- Unterordner prüfen
    for i = 0, getNumOfChildren(placeTG) - 1 do
        local child = getChildAt(placeTG, i)
        local name = getName(child)

        if name == "SourceObject" then sourceObjTG = child end
        if name == "SourceSplines" then sourceSplineTG = child end
        if name == "PlacedObjects" then placedObjTG = child end
    end

    -- Fehlende Unterordner erstellen
    if not sourceObjTG then
        sourceObjTG = createTransformGroup("SourceObject")
        link(placeTG, sourceObjTG)
    end

    if not sourceSplineTG then
        sourceSplineTG = createTransformGroup("SourceSplines")
        link(placeTG, sourceSplineTG)
    end

    if not placedObjTG then
        placedObjTG = createTransformGroup("PlacedObjects")
        link(placeTG, placedObjTG)
    end

    return placeTG, sourceObjTG, sourceSplineTG, placedObjTG
end

function SplineToolkit:getPlaceFenceTransformgroup()
    local mainContainer = self:getSplineToolkitTransformgroup()
    local fenceTG

    for i = 0, getNumOfChildren(mainContainer) - 1 do
        local child = getChildAt(mainContainer, i)
        if getName(child) == "SetFenceBySpline" then
            fenceTG = child
            break
        end
    end

    if not fenceTG then
        fenceTG = createTransformGroup("SetFenceBySpline")
        link(mainContainer, fenceTG)
        print("[SplineToolkit] Created TransformGroup 'SetFenceBySpline'")
    end

    return fenceTG
end

function SplineToolkit:getRoadTransformgroup()
    local mainContainer = self:getSplineToolkitTransformgroup()
    local roadTG

    for i = 0, getNumOfChildren(mainContainer) - 1 do
        local child = getChildAt(mainContainer, i)
        if getName(child) == "GenRoadMesh" then
            roadTG = child
            break
        end
    end

    if not roadTG then
        roadTG = createTransformGroup("GenRoadMesh")
        link(mainContainer, roadTG)
        print("[SplineToolkit] Created TransformGroup 'GenRoadMesh'")
    end

    return roadTG
end
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- 	UTILS - WINDOWS 			-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------

function SplineToolkit:convertFileText(path)
    if type(path) ~= "string" then
        return path
    end

    local marker = "FarmingSimulator2025"

    local startPos = string.find(path, marker, 1, true)
    if startPos ~= nil then
        local shortened = string.sub(path, startPos + #marker)
        shortened = shortened:gsub("^[/\\]+", "")
        return ".../" .. shortened
    end

    return path
end

function SplineToolkit:genUINewFence(fenceId, callback, existingEntry)
    assert(callback == nil or type(callback) == "function")

    local title = (fenceId == nil) and "Add New Fence Entry" or ("Edit Fence Entry - " .. existingEntry.name)

    local state = {
        fenceXMLPath = "",
        ui = {}
    }

    local uiFrameRowSizer = UIRowLayoutSizer.new()
    local window = UIWindow.new(uiFrameRowSizer, title, false, true)

    local uiBorderSizer = UIRowLayoutSizer.new()
    UIPanel.new(uiFrameRowSizer, uiBorderSizer, -1, -1, 400, -1, BorderDirection.NONE, 0, 1)

    local uiRowSizer = UIRowLayoutSizer.new()
    local uiPanelSizer = UIPanel.new(uiBorderSizer, uiRowSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
    uiPanelSizer:setBackgroundColor(0.98, 0.98, 0.98, 1)

    local rowSizerElements = UIRowLayoutSizer.new()
    UIPanel.new(uiRowSizer, rowSizerElements, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)
	
    local rowSizerInfo = UIRowLayoutSizer.new()
    local uiInfoBox = UIPanel.new(rowSizerElements, rowSizerInfo, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1)
    uiInfoBox:setBackgroundColor(1.0, 0.9, 0.53, 1.0)
    local rowSizerInfoElements = UIRowLayoutSizer.new()
    local uiInfoBox = UIPanel.new(rowSizerInfo, rowSizerInfoElements, -1, -1, -1, -1, BorderDirection.ALL, 5, 1)
	UILabel.new(rowSizerInfoElements, "• The Fence I3D file must be in the same folder as the selected XML.")
	UILabel.new(rowSizerInfoElements, "• The icon must be a 512x512 .PNG placed in this folder:")
    UILabel.new(rowSizerInfoElements, getEditorDirectory())
    UILabel.new(rowSizerInfoElements, SplineToolkit.FENCE_RAW_IMG_PATH)
	UILabel.new(rowSizerInfoElements, "• If import Mod-Fence - get permission from the original mod author.")

	UIHorizontalLine.new(rowSizerElements)
    -- ===============================
    -- XML FILE SELECT
    -- ===============================
	local function convertPNGFilename(isAdd, fileName)
		if not fileName or fileName == "" then
			return fileName
		end

		if isAdd then
			-- Wenn nicht bereits .png (case-insensitive)
			if not fileName:lower():match("%.png$") then
				return fileName .. ".png"
			end
			return fileName
		else
			-- Entferne .png am Ende (case-insensitive)
			return fileName:gsub("(%.[pP][nN][gG])$", "")
		end
	end

    
	local function selectFenceXMLFile()

        local filePath = openFileDialog("", "Fence XML File|*.xml")
        if not filePath or filePath == "" then return end

        local xmlFile = XMLFile.loadIfExists("FenceCheck", filePath)
        if not xmlFile then
            printError("[SplineToolkit] Invalid XML file: " .. filePath)
            return
        end

        if not xmlFile:hasProperty("placeable.fence") then
            xmlFile:delete()
            printError("[SplineToolkit] Selected file has no <fence> tag")
            return
        end

        xmlFile:delete()

        state.fenceXMLPath = filePath
        state.ui.fenceXMLPath:setValue(filePath)
    end

    UILabel.new(rowSizerElements, "XML File:")
    local pathRow = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizerElements, pathRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    state.ui.fenceXMLPath = UITextArea.new(pathRow, "", TextAlignment.LEFT, false, false, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
    UIButton.new(pathRow, "🗁", selectFenceXMLFile, nil, -1, -1, 25, -1)

    UILabel.new(rowSizerElements, "Name:")
    state.ui.fenceName = UITextArea.new(rowSizerElements, "", TextAlignment.LEFT, false, false, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    UILabel.new(rowSizerElements, "Icon File Name (without .png):")
    state.ui.fenceIconName = UITextArea.new(rowSizerElements, "", TextAlignment.LEFT, false, false, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local columnSizerButtons = UIColumnLayoutSizer.new()
    UIPanel.new(uiBorderSizer, columnSizerButtons, -1, -1, -1, -1, BorderDirection.ALL, 10)
	
	if existingEntry then
		state.ui.fenceXMLPath:setValue(existingEntry.xmlFile or "")
		state.ui.fenceName:setValue(existingEntry.name or "")
		print(existingEntry.imgFile)
		state.ui.fenceIconName:setValue(convertPNGFilename(false, existingEntry.imgFile) or "")
	end

    local wasButtonPressed = false

	local function onClickSave()
		local xmlPath = state.ui.fenceXMLPath:getValue()
		local name    = state.ui.fenceName:getValue()

		if xmlPath == "" or name == "" then
			printError("[SplineToolkit] XML file and name must be present.")
			return
		end
        
		wasButtonPressed = true

        local result = {
            xmlFile = state.ui.fenceXMLPath:getValue(),
            name    = state.ui.fenceName:getValue(),
            imgFile = convertPNGFilename(true, state.ui.fenceIconName:getValue())
        }
		print(result.imgFile)
        window:close()

        if callback then
            callback(true, result)
        end
    end

    local function onClickReturn()
        wasButtonPressed = true
        window:close()
        if callback then callback(false) end
    end

    UILabel.new(columnSizerButtons, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
    UIButton.new(columnSizerButtons, "Save", onClickSave, nil, -1, -1, 90, 26, BorderDirection.RIGHT, 10):setBackgroundColor(0.6, 1.0, 0.55, 1.0)
    UIButton.new(columnSizerButtons, "Return", onClickReturn, nil, -1, -1, 90, 26):setBackgroundColor(0.9, 0.5, 0.5, 1.0)

    window:setOnCloseCallback(function()
        if not wasButtonPressed and callback then
            callback(nil)
        end
    end)

    window:fit()
    window:refresh()
    window:showWindow()
end

function SplineToolkit:convertFileText(path)
    if type(path) ~= "string" then
        return path
    end

    local marker = "FarmingSimulator2025"

    local startPos = string.find(path, marker, 1, true)
    if startPos ~= nil then
        local shortened = string.sub(path, startPos + #marker)
        shortened = shortened:gsub("^[/\\]+", "")
        return ".../" .. shortened
    end

    return path
end

function SplineToolkit:genUINewRoadTexture(roadId, callback, existingEntry)
    assert(callback == nil or type(callback) == "function")

    local title = (roadId == nil)
        and "Add New Road Texture"
        or ("Edit Road Texture - " .. (existingEntry and existingEntry.name or ""))

    local state = {
        ui = {}
    }

	local function convertPNGFilename(isAdd, fileName)
		if not fileName or fileName == "" then
			return fileName
		end

		if isAdd then
			-- Wenn nicht bereits .png (case-insensitive)
			if not fileName:lower():match("%.png$") then
				return fileName .. ".png"
			end
			return fileName
		else
			-- Entferne .png am Ende (case-insensitive)
			return fileName:gsub("(%.[pP][nN][gG])$", "")
		end
	end

    local uiFrameRowSizer = UIRowLayoutSizer.new()
    local window = UIWindow.new(uiFrameRowSizer, title, false, true)

    local borderSizer = UIRowLayoutSizer.new()
    UIPanel.new(uiFrameRowSizer, borderSizer, -1, -1, 450, -1, BorderDirection.NONE, 0, 1)

    local contentSizer = UIRowLayoutSizer.new()
    local panel = UIPanel.new(borderSizer, contentSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1):setBackgroundColor(0.98, 0.98, 0.98, 1)
    -- panel:setBackgroundColor(0.98, 0.98, 0.98, 1)

    local rowSizerElements = UIRowLayoutSizer.new()
    UIPanel.new(contentSizer, rowSizerElements, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)
	
    -- INFO BOX
    local infoSizer = UIRowLayoutSizer.new()
    local infoPanel = UIPanel.new(rowSizerElements, infoSizer, -1, -1, -1, -1, BorderDirection.ALL, 10, 1)
    infoPanel:setBackgroundColor(1.0, 0.9, 0.53, 1.0)

    UILabel.new(infoSizer, "• Set Icon Filename without '.png'.", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.ALL, 5)
    UILabel.new(infoSizer, "• Icon must be a 512x512 PNG inside Road IMG folder.", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.ALL, 5)

    UIHorizontalLine.new(rowSizerElements, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    ------------------------------------------------
    -- NAME + ICON
    ------------------------------------------------
	local row = UIColumnLayoutSizer.new()
	UIPanel.new(rowSizerElements, row, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    UILabel.new(row, "Texture Name:", false, TextAlignment.LEFT, VerticalAlignment.CENTER, -1, -1, 90, -1, BorderDirection.RIGHT, 5)
    state.ui.name = UITextArea.new(row, "", TextAlignment.LEFT, false, false, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1)

	local row = UIColumnLayoutSizer.new()
	UIPanel.new(rowSizerElements, row, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    UILabel.new(row, "Icon File Name:", false, TextAlignment.LEFT, VerticalAlignment.CENTER, -1, -1, 90, -1, BorderDirection.RIGHT, 5)
    state.ui.icon = UITextArea.new(row, "", TextAlignment.LEFT, false, false, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1)

    UIHorizontalLine.new(rowSizerElements, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    ------------------------------------------------
    -- TEXTURE FILE PICKER
    ------------------------------------------------
    local function createTextureRow(labelText, key)
        local row = UIColumnLayoutSizer.new()
        UIPanel.new(rowSizerElements, row, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

        UILabel.new(row, labelText .. ":", false, TextAlignment.LEFT, VerticalAlignment.CENTER, -1, -1, 60, -1, BorderDirection.RIGHT, 5)

        state.ui[key] = UITextArea.new(row, "", TextAlignment.LEFT, false, false, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)

        UIButton.new(row, "🗁", function()
            local filePath = openFileDialog("", "DDS File|*.dds")
            if filePath and filePath ~= "" then
                state.ui[key]:setValue(filePath)
            end
        end, nil, -1, -1, 25, -1)
		UIButton.new(row, "X", function() 
			state.ui[key]:setValue("")
		end, nil, -1, -1, 25, -1)
    end

    createTextureRow("Diffuse",  "diffuse")
    createTextureRow("Specular", "specular")
    createTextureRow("Normal",   "normal")
    createTextureRow("Height",   "height")
    createTextureRow("Alpha",    "alpha")

	local row = UIColumnLayoutSizer.new()
	UIPanel.new(rowSizerElements, row, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    state.ui.alphaInsideDiffuse = UILabel.new(row, "Is Alpha-Channel inside the Diffuse Map?", false, TextAlignment.LEFT, VerticalAlignment.CENTER, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
    -- UITextArea.new(row, "Is Alpha inside the Diffuse Map?", TextAlignment.LEFT, true, false, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
    state.ui.alphaInsideDiffuse = UIChoice.new(row, {"False", "True"}, 0, -1, -1, -1, -1, BorderDirection.NONE, 5, 1)
    ------------------------------------------------
    -- BUTTONS
    ------------------------------------------------
    local buttonSizer = UIColumnLayoutSizer.new()
    UIPanel.new(borderSizer, buttonSizer, -1, -1, -1, -1, BorderDirection.ALL, 10)

    local wasPressed = false

    local function onClickSave()
        local name = state.ui.name:getValue()
        local icon = convertPNGFilename(true, state.ui.icon:getValue())
		local shaderVariant
		if state.ui.alphaInsideDiffuse:getValue() == 0 then
			shaderVariant = "alphaNoise_customParallax_alphaMap"
		else
			shaderVariant = "alphaNoise_terrainFormat_customParallax"
		end
		print(shaderVariant)

        if name == nil or name == "" then
            printError("[SplineToolkit] Texture name required.")
            return
        end

        -- if icon == nil or icon == "" then
            -- printError("[SplineToolkit] Icon file name required.")
            -- return
        -- end

        local result = {
            name = name,
            imgFile = icon,
			shaderVar = shaderVariant,
            textures = {
                diffuse  = state.ui.diffuse:getValue(),
                specular = state.ui.specular:getValue(),
                normal   = state.ui.normal:getValue(),
                height   = state.ui.height:getValue(),
                alpha    = state.ui.alpha:getValue()
            },
            isCustom = true
        }

        wasPressed = true
        window:close()

        if callback then
            callback(true, result)
        end
    end

    local function onClickReturn()
        wasPressed = true
        window:close()
        if callback then callback(false) end
    end

    UILabel.new(buttonSizer, "", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
    UIButton.new(buttonSizer, "Save", onClickSave, nil, -1, -1, 90, 26, BorderDirection.RIGHT, 10):setBackgroundColor(0.6, 1.0, 0.55, 1.0)
    UIButton.new(buttonSizer, "Return", onClickReturn, nil, -1, -1, 90, 26):setBackgroundColor(0.9, 0.5, 0.5, 1.0)

    window:setOnCloseCallback(function()
        if not wasPressed and callback then
            callback(nil)
        end
    end)

    ------------------------------------------------
    -- EDIT MODE FILL
    ------------------------------------------------
    if existingEntry then
        state.ui.name:setValue(existingEntry.name or "")
		state.ui.icon:setValue(convertPNGFilename(false, existingEntry.imgFile) or "")
        -- state.ui.icon:setValue(existingEntry.imgFile or "")
        -- state.ui.sizeX:setValue(existingEntry.sizeX or 4096)
        -- state.ui.sizeY:setValue(existingEntry.sizeY or 4096)

        if existingEntry.textures then
            state.ui.diffuse:setValue(existingEntry.textures.diffuse or "")
            state.ui.specular:setValue(existingEntry.textures.specular or "")
            state.ui.normal:setValue(existingEntry.textures.normal or "")
            state.ui.height:setValue(existingEntry.textures.height or "")
            state.ui.alpha:setValue(existingEntry.textures.alpha or "")
        end
    end

    window:fit()
    window:refresh()
    window:showWindow()
end
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- 	UTILS - OTHER UTILS 		-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------

function SplineToolkit:getTerrain()
    local root = getRootNode()

    for i = 0, getNumOfChildren(root) - 1 do
        local child = getChildAt(root, i)
        if getName(child) == "terrain" then
            return child
        end
    end

    print("[SplineToolkit] Terrain not found")
    return nil
end

function SplineToolkit:setTerrainTextureLayers()
    local layerTable = self.values.base.paintTerrain.textureLayers
    table.clear(layerTable)

    local mSceneID = getRootNode()
    local mTerrainID = self:getTerrain()

    local numLayers = getTerrainNumOfLayers(mTerrainID)

    local combined = {}
    local normal = {}

    for i = 0, numLayers - 1 do
        local name = getTerrainLayerName(mTerrainID, i)

        if name ~= nil and name ~= "" then
            if name == string.upper(name) then
                table.insert(combined, name)
            else
                table.insert(normal, name)
            end
        end
    end

    for _, v in ipairs(combined) do
        table.insert(layerTable, v)
    end

    for _, v in ipairs(normal) do
        table.insert(layerTable, v)
    end
end

function SplineToolkit:setChoiceFromString(uiChoice, list, valueString)
    if uiChoice == nil or list == nil or valueString == nil then
        return
    end

    local target = tostring(valueString):upper()
    local index = 0

    for i = 1, #list do
        if tostring(list[i]):upper() == target then
            index = i - 1
            break
        end
    end

    uiChoice:setChoices(list, index)
end

function SplineToolkit:getChoiceActiveOptionString(uiChoice)
	return uiChoice:getOptionString(uiChoice:getValue()-1)
end

function SplineToolkit:getChoiceBoolean(uiChoice)

    if uiChoice == nil then
        return false
    end

    local index = uiChoice:getValue()
    if index == nil then
        return false
    end

    local value = uiChoice:getOptionString(index - 1)
    if value == nil then
        return false
    end

    value = string.lower(value)
    return value == "true"
end

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- 	SAVE & LOAD SETTINS 		------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------
function SplineToolkit:saveSettings(tab)
    local xmlFile = XMLFile.loadIfExists("SplineToolkitSettings", SplineToolkit.SETTINGS_PATH)

    if not xmlFile then
        xmlFile = XMLFile.create("SplineToolkitSettings", SplineToolkit.SETTINGS_PATH, "settings")
        if not xmlFile then return end
    end
	
	if tab == self.tabNames[1] then -- Base Tools
		local baseKey = "settings.base"
		xmlFile:setFloat(baseKey .. "#setOnTerrainHeightOffset", self.uiTerrainHeightOffset:getValue())
		xmlFile:setFloat(baseKey .. "#offsetSide", self.uiOffsetSideOffset:getValue())
		xmlFile:setFloat(baseKey .. "#offsetHeight", self.uiOffsetHeightOffset:getValue())
		xmlFile:setFloat(baseKey .. "#terrainHeight", self.uiTerrainHeightHeightOffset:getValue())
		xmlFile:setFloat(baseKey .. "#terrainWidth", self.uiTerrainHeightWidth:getValue())
		xmlFile:setFloat(baseKey .. "#terrainSmoothDistance", self.uiTerrainHeightSmoothDist:getValue())
		xmlFile:setFloat(baseKey .. "#paintWidthLeft", self.uiPaintWidthLeft:getValue())
		xmlFile:setFloat(baseKey .. "#paintWidthRight", self.uiPaintWidthRight:getValue())
		
		xmlFile:setFloat(baseKey .. "#foliageWidthLeft", self.uiFoliageWidthLeft:getValue())
		xmlFile:setFloat(baseKey .. "#foliageWidthRight", self.uiFoliageWidthRight:getValue())
		
		xmlFile:setInt(baseKey .. "#numSplinePoints", self.uiNumOfPoints:getValue())
		
	elseif tab == self.tabNames[2] then -- Place Objects
		local baseKey = "settings.objectPlacement"
		xmlFile:setString(baseKey .. "#objPlaceType", self:getChoiceActiveOptionString(self.uiObjectPlaceType))
		xmlFile:setFloat(baseKey .. "#sideOffset", self.uiObjectOffsetSide:getValue())
		
		xmlFile:setFloat(baseKey .. "#widthLeft", self.uiPlaceWidthLeft:getValue())
		xmlFile:setFloat(baseKey .. "#widthRight", self.uiPlaceWidthRight:getValue())
		
		xmlFile:setString(baseKey .. "#objDistanceType", self:getChoiceActiveOptionString(self.uiObjectDistanceType))
		xmlFile:setFloat(baseKey .. "#objectFixDistance", self.uiObjectFixDistance:getValue())
		xmlFile:setFloat(baseKey .. "#objectMinDistance", self.uiObjectMinDistance:getValue())
		xmlFile:setFloat(baseKey .. "#objectMaxDistance", self.uiObjectMaxDistance:getValue())
		xmlFile:setString(baseKey .. "#setHeightType", self:getChoiceActiveOptionString(self.uiSetHeightType))
		
		xmlFile:setString(baseKey .. "#followAxis", self:getChoiceActiveOptionString(self.uiFollowAxis))
		
		xmlFile:setFloat(baseKey .. "#objectHeight", self.uiObjectHeight:getValue())
		xmlFile:setString(baseKey .. "#setRandomRotate", self:getChoiceActiveOptionString(self.uiRandomRotate))
		xmlFile:setFloat(baseKey .. "#objectRotate", self.uiObjectRotate:getValue())

    elseif tab == self.tabNames[3] then -- Place Fence
        local scene = getSceneFilename()
        local baseKey = "settings.placeFence"

        xmlFile:setString(baseKey .. "#imgPath", self.uiImgFencePath:getValue())
        xmlFile:setString(baseKey .. "#useYOffset",self:getChoiceActiveOptionString(self.uiFencePlaceYOffset))
        xmlFile:setString(baseKey .. "#placeStartPole",self:getChoiceActiveOptionString(self.uiFencePlaceStartPole))
        xmlFile:setString(baseKey .. "#placeEndPole",self:getChoiceActiveOptionString(self.uiFencePlaceEndPole))

        local i = 0
        local sceneIndex = nil

        while xmlFile:hasProperty(string.format("%s.customFences.scene(%d)", baseKey, i)) do
            if xmlFile:getString(string.format("%s.customFences.scene(%d)#path", baseKey, i)) == scene then
                sceneIndex = i
                break
            end
            i = i + 1
        end

        if sceneIndex == nil then
            sceneIndex = i
        else
            xmlFile:removeProperty(string.format("%s.customFences.scene(%d)", baseKey, sceneIndex))
        end

        local sceneKey = string.format("%s.customFences.scene(%d)", baseKey, sceneIndex)
        xmlFile:setString(sceneKey .. "#path", scene)

        local fenceTable = self.values.fencePlacement.fenceTable
        local fenceIndex = 0

        for _, fence in ipairs(fenceTable) do
            if fence.isCustom then
				-- print("fence save for map. Index: " .. fence.name)
                local fenceKey = string.format("%s.fence(%d)", sceneKey, fenceIndex)

                xmlFile:setString(fenceKey .. "#name", fence.name)
                xmlFile:setString(fenceKey .. "#xmlFile", fence.xmlFile)
                xmlFile:setString(fenceKey .. "#imgFile", fence.imgFile)

                fenceIndex = fenceIndex + 1
            end
        end

	elseif tab == self.tabNames[4] then -- Export .OBJ
		local baseKey = "settings.exportObject"
		xmlFile:setBool(baseKey .. "#useCustomFilename", self.uiExportUseCustomFilename:getValue())
		xmlFile:setString(baseKey .. "#customFileName", self.values.exportObject.customFileName)
		xmlFile:setString(baseKey .. "#createMeshType", self:getChoiceActiveOptionString(self.uiExportType))
		xmlFile:setString(baseKey .. "#distanceType", self:getChoiceActiveOptionString(self.uiExportDistanceType))
		xmlFile:setFloat(baseKey .. "#vertexDistance", self.uiExportDistance:getValue())
		xmlFile:setFloat(baseKey .. "#vertexMinDistance", self.uiExportMinDistance:getValue())
		xmlFile:setFloat(baseKey .. "#vertexMinAngle", self.uiExportMinAngle:getValue())

	elseif tab == self.tabNames[5] then -- Gen. Road Mesh
        local scene = getSceneFilename()
		local baseKey = "settings.roadMesh"
		xmlFile:setString(baseKey .. "#roadName", self.uiRoadName:getValue())
		xmlFile:setString(baseKey .. "#imgPath", self.uiImgRoadPath:getValue())
		
		xmlFile:setString(baseKey .. "#mirrorAtCenter", self:getChoiceActiveOptionString(self.uiMirrorAtCenter))
		xmlFile:setFloat(baseKey .. "#textureDistance", self.uiTextureDistSlider:getValue())
		xmlFile:setFloat(baseKey .. "#textureSliceStart", self.uiTextureSliceStartSlider:getValue())
		xmlFile:setFloat(baseKey .. "#textureSliceEnd", self.uiTextureSliceEndSlider:getValue())
		
		xmlFile:setString(baseKey .. "#terrainDecal", self:getChoiceActiveOptionString(self.uiTerrainDecal))
		xmlFile:setFloat(baseKey .. "#width", self.uiGenRoadWidthSlider:getValue())
		xmlFile:setFloat(baseKey .. "#minSegmentLength", self.uiGenRoadMinSegLenght:getValue())
		xmlFile:setFloat(baseKey .. "#maxAngle", self.uiGenRoadMinAngle:getValue())
		xmlFile:setString(baseKey .. "#alignEdgesOnTerrain", self:getChoiceActiveOptionString(self.uiGenRoadAlignEdges))
		xmlFile:setString(baseKey .. "#trafficCenter", self:getChoiceActiveOptionString(self.uiHasTrafficCenter))
		xmlFile:setString(baseKey .. "#trafficLeft", self:getChoiceActiveOptionString(self.uiHasTrafficLeft))
		xmlFile:setString(baseKey .. "#trafficRight", self:getChoiceActiveOptionString(self.uiHasTrafficRight))
		xmlFile:setFloat(baseKey .. "#leftPercent", self.uiTrafficLeftPerc:getValue())
		xmlFile:setFloat(baseKey .. "#rightPercent", self.uiTrafficRightPerc:getValue())
		xmlFile:setInt(baseKey .. "#maxSpeedScale", self.uiMaxSpeedScale:getValue())
		xmlFile:setInt(baseKey .. "#speedLimit", self.uiSpeedLimit:getValue())
		
		local i = 0
		local sceneIndex = nil

		while xmlFile:hasProperty(string.format("%s.customRoadTextures.scene(%d)", baseKey, i)) do
			if xmlFile:getString(string.format("%s.customRoadTextures.scene(%d)#path", baseKey, i)) == scene then
				sceneIndex = i
				break
			end
			i = i + 1
		end

		if sceneIndex == nil then
			sceneIndex = i
		else
			xmlFile:removeProperty(string.format("%s.customRoadTextures.scene(%d)", baseKey, sceneIndex))
		end

		local sceneKey = string.format("%s.customRoadTextures.scene(%d)", baseKey, sceneIndex)
		xmlFile:setString(sceneKey .. "#path", scene)

		local textureTable = self.values.roadMesh.textureTable
		local textureIndex = 0

		for _, texture in ipairs(textureTable) do

			if texture.isCustom then

				print("texture save for map. Index: " .. texture.name)
				local textureKey = string.format("%s.texture(%d)", sceneKey, textureIndex)

				xmlFile:setString(textureKey .. "#name", texture.name)
				xmlFile:setString(textureKey .. "#imgFile", texture.imgFile)
				xmlFile:setString(textureKey .. "#shaderVar", texture.shaderVar)

				if texture.textures then
					xmlFile:setString(textureKey .. "#diffuse",  texture.textures.diffuse)
					xmlFile:setString(textureKey .. "#specular", texture.textures.specular)
					xmlFile:setString(textureKey .. "#normal",   texture.textures.normal)
					xmlFile:setString(textureKey .. "#height",   texture.textures.height)
					xmlFile:setString(textureKey .. "#alpha",    texture.textures.alpha)
				end

				textureIndex = textureIndex + 1
			end
		end
    end

    xmlFile:save()
    xmlFile:delete()
	-- print("[SplineToolkit] Saved Settings")
end

function SplineToolkit:loadSettings(tab)
    local xmlFile = XMLFile.loadIfExists("SplineToolkitSettings", SplineToolkit.SETTINGS_PATH)
    if not xmlFile then return end
	
	self.loadSettingChoiceList = {}

	if tab == self.tabNames[1] then -- Base Tools
		local baseKey = "settings.base"
		if xmlFile:hasProperty(baseKey) then
			local values = self.values.base

			values.setOnTerrain.heightOffset = xmlFile:getFloat(baseKey .. "#setOnTerrainHeightOffset") or values.setOnTerrain.heightOffset
			values.setOffset.sideOffset = xmlFile:getFloat(baseKey .. "#offsetSide") or values.setOffset.sideOffset
			values.setOffset.heightOffset = xmlFile:getFloat(baseKey .. "#offsetHeight") or values.setOffset.heightOffset
			values.setTerrainHeight.terrainHeight = xmlFile:getFloat(baseKey .. "#terrainHeight") or values.setTerrainHeight.terrainHeight
			values.setTerrainHeight.terrainWidth = xmlFile:getFloat(baseKey .. "#terrainWidth") or values.setTerrainHeight.terrainWidth
			values.setTerrainHeight.smoothDistance = xmlFile:getFloat(baseKey .. "#terrainSmoothDistance") or values.setTerrainHeight.smoothDistance
			values.paintTerrain.widthLeft = xmlFile:getFloat(baseKey .. "#paintWidthLeft") or values.paintTerrain.widthLeft
			values.paintTerrain.widthRight = xmlFile:getFloat(baseKey .. "#paintWidthRight") or values.paintTerrain.widthRight
			
			values.setFoliage.widthLeft = xmlFile:getFloat(baseKey .. "#foliageWidthLeft") or values.setFoliage.widthLeft
			values.setFoliage.widthRight = xmlFile:getFloat(baseKey .. "#foliageWidthRight") or values.setFoliage.widthRight
			values.resampleSpline.numPoints = xmlFile:getInt(baseKey .. "#numSplinePoints") or values.resampleSpline.numPoints
		end

	elseif tab == self.tabNames[2] then -- Place Objects
		local baseKey = "settings.objectPlacement"
		if xmlFile:hasProperty(baseKey) then
			local values = self.values.objectPlacement
			table.insert(self.loadSettingChoiceList, {uiKey="uiObjectPlaceType", options=values.objPlaceType, selected=xmlFile:getString(baseKey .. "#objPlaceType")})
			values.sideOffset = xmlFile:getFloat(baseKey .. "#sideOffset") or values.sideOffset
			
			values.widthLeft = xmlFile:getFloat(baseKey .. "#widthLeft") or values.widthLeft
			values.widthRight = xmlFile:getFloat(baseKey .. "#widthRight") or values.widthRight
			
			table.insert(self.loadSettingChoiceList, {uiKey="uiObjectDistanceType", options=values.objDistanceType, selected=xmlFile:getString(baseKey .. "#objDistanceType")})
			values.objectFixDistance = xmlFile:getFloat(baseKey .. "#objectFixDistance") or values.objectFixDistance
			values.objectMinDistance = xmlFile:getFloat(baseKey .. "#objectMinDistance") or values.objectMinDistance
			values.objectMaxDistance = xmlFile:getFloat(baseKey .. "#objectMaxDistance") or values.objectMaxDistance

			table.insert(self.loadSettingChoiceList, {uiKey="uiSetHeightType", options=values.setHeightType, selected=xmlFile:getString(baseKey .. "#setHeightType")})
			table.insert(self.loadSettingChoiceList, {uiKey="uiFollowAxis", options=values.followAxis, selected=xmlFile:getString(baseKey .. "#followAxis")})
			values.objectHeight = xmlFile:getFloat(baseKey .. "#objectHeight") or values.objectHeight
			
			table.insert(self.loadSettingChoiceList, {uiKey="uiRandomRotate", options=values.setRandomRotate, selected=xmlFile:getString(baseKey .. "#setRandomRotate")})
			values.objectRotate = xmlFile:getFloat(baseKey .. "#objectRotate") or values.objectRotate
		end

	elseif tab == self.tabNames[3] then -- Place Fence
		local scene = getSceneFilename()
		local baseKey = "settings.placeFence"
		local values = self.values.fencePlacement

		if xmlFile:hasProperty(baseKey) then
			values.imgPath = xmlFile:getString(baseKey .. "#imgPath") or values.imgPath

			table.insert(self.loadSettingChoiceList, {uiKey="uiFencePlaceYOffset", options=values.useYOffset, selected=xmlFile:getString(baseKey .. "#useYOffset")})
			table.insert(self.loadSettingChoiceList, {uiKey="uiFencePlaceStartPole", options=values.placeStartPole, selected=xmlFile:getString(baseKey .. "#placeStartPole")})
			table.insert(self.loadSettingChoiceList, {uiKey="uiFencePlaceEndPole", options=values.placeEndPole, selected=xmlFile:getString(baseKey .. "#placeEndPole")})

			local i = 0
			while xmlFile:hasProperty(string.format("%s.customFences.scene(%d)", baseKey, i)) do
				local sceneKey = string.format("%s.customFences.scene(%d)", baseKey, i)
				if xmlFile:getString(sceneKey .. "#path") == scene then
					local fenceIndex = 0
					while xmlFile:hasProperty(string.format("%s.fence(%d)", sceneKey, fenceIndex)) do
						-- print("fenceIndex found for map. Index: " .. fenceIndex)
						local fenceKey = string.format("%s.fence(%d)", sceneKey, fenceIndex)
						table.insert(values.fenceTable, {name=xmlFile:getString(fenceKey .. "#name") or "", xmlFile=xmlFile:getString(fenceKey .. "#xmlFile") or "", imgFile=xmlFile:getString(fenceKey .. "#imgFile") or "", isCustom=true})
						fenceIndex = fenceIndex + 1
					end
					break
				end
				i = i + 1
			end
		end

	elseif tab == self.tabNames[4] then -- Export .OBJ
		local baseKey = "settings.exportObject"
		local values = self.values.exportObject
		if xmlFile:hasProperty(baseKey) then
			values.useCustomFilename = xmlFile:getBool(baseKey .. "#useCustomFilename")
			values.customFileName = xmlFile:getString(baseKey .. "#customFileName") or values.customFileName
			values.vertexDistance = xmlFile:getFloat(baseKey .. "#vertexDistance") or values.vertexDistance
			values.vertexMinDistance = xmlFile:getFloat(baseKey .. "#vertexMinDistance") or values.vertexMinDistance
			values.vertexMinAngle = xmlFile:getFloat(baseKey .. "#vertexMinAngle") or values.vertexMinAngle

			table.insert(self.loadSettingChoiceList, {uiKey="uiExportType", options=values.createMeshType, selected=xmlFile:getString(baseKey .. "#createMeshType")})
			table.insert(self.loadSettingChoiceList, {uiKey="uiExportDistanceType", options=values.distanceType, selected=xmlFile:getString(baseKey .. "#distanceType")})
		end

	elseif tab == self.tabNames[5] then -- Gen. Road Mesh
		local scene = getSceneFilename()
		local baseKey = "settings.roadMesh"
		local values = self.values.roadMesh
		if xmlFile:hasProperty(baseKey) then
			values.roadName = xmlFile:getString(baseKey .. "#roadName") or values.roadName
			
			values.imgPath = xmlFile:getString(baseKey .. "#imgPath") or values.imgPath
			values.textureDistance = xmlFile:getFloat(baseKey .. "#textureDistance") or values.textureDistance
			values.sliceStart = xmlFile:getFloat(baseKey .. "#textureSliceStart") or values.sliceStart
			values.sliceEnd = xmlFile:getFloat(baseKey .. "#textureSliceEnd") or values.sliceEnd
			table.insert(self.loadSettingChoiceList, {uiKey="uiMirrorAtCenter", options=values.mirrorAtCenter, selected=xmlFile:getString(baseKey .. "#mirrorAtCenter")})
			table.insert(self.loadSettingChoiceList, {uiKey="uiTerrainDecal", options=values.terrainDecal, selected=xmlFile:getString(baseKey .. "#terrainDecal")})
			
			values.width = xmlFile:getFloat(baseKey .. "#width") or values.width
			values.minSegmentLength = xmlFile:getFloat(baseKey .. "#minSegmentLength") or values.minSegmentLength
			values.maxAngle = xmlFile:getFloat(baseKey .. "#maxAngle") or values.maxAngle
			values.leftPercent = xmlFile:getFloat(baseKey .. "#leftPercent") or values.leftPercent
			values.rightPercent = xmlFile:getFloat(baseKey .. "#rightPercent") or values.rightPercent
			values.maxSpeedScale = xmlFile:getInt(baseKey .. "#maxSpeedScale") or values.maxSpeedScale
			values.speedLimit = xmlFile:getInt(baseKey .. "#speedLimit") or values.speedLimit

			table.insert(self.loadSettingChoiceList, {uiKey="uiAlignEdgesChoice", options=values.alignEdgesOnTerrain, selected=xmlFile:getString(baseKey .. "#alignEdgesOnTerrain")})
			table.insert(self.loadSettingChoiceList, {uiKey="uiHasTrafficCenter", options=values.trafficCenter, selected=xmlFile:getString(baseKey .. "#trafficCenter")})
			table.insert(self.loadSettingChoiceList, {uiKey="uiHasTrafficLeft", options=values.trafficLeft, selected=xmlFile:getString(baseKey .. "#trafficLeft")})
			table.insert(self.loadSettingChoiceList, {uiKey="uiHasTrafficRight", options=values.trafficRight, selected=xmlFile:getString(baseKey .. "#trafficRight")})
			
			
			local i = 0
			while xmlFile:hasProperty(string.format("%s.customRoadTextures.scene(%d)", baseKey, i)) do
				local sceneKey = string.format("%s.customRoadTextures.scene(%d)", baseKey, i)

				if xmlFile:getString(sceneKey .. "#path") == scene then

					local textureIndex = 0
					while xmlFile:hasProperty(string.format("%s.texture(%d)", sceneKey, textureIndex)) do

						local textureKey = string.format("%s.texture(%d)", sceneKey, textureIndex)
						-- print("texture found for map. Index: " .. textureIndex)

						table.insert(values.textureTable, {
							name      = xmlFile:getString(textureKey .. "#name") or "",
							imgFile   = xmlFile:getString(textureKey .. "#imgFile") or "",
							shaderVar = xmlFile:getString(textureKey .. "#shaderVar") or "",

							textures = {
								diffuse  = xmlFile:getString(textureKey .. "#diffuse"),
								specular = xmlFile:getString(textureKey .. "#specular"),
								normal   = xmlFile:getString(textureKey .. "#normal"),
								height   = xmlFile:getString(textureKey .. "#height"),
								alpha    = xmlFile:getString(textureKey .. "#alpha"),
							},

							isCustom = true
						})

						textureIndex = textureIndex + 1
					end

					break
				end

				i = i + 1
			end
			
		end
	end

	xmlFile:delete()
end
			
SplineToolkit.new()
