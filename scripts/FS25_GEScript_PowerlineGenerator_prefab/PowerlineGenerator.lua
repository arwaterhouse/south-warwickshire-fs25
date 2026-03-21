-- Author: Aslan
-- Name: PowerlineGenerator
-- Namespace: local
-- Description: Werkzeug für die Bearbeitung von Splines
-- Icon: iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAMcWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDggNzkuMTY0MDM2LCAyMDE5LzA4LzEzLTAxOjA2OjU3ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIxLjAgKFdpbmRvd3MpIiB4bXA6Q3JlYXRlRGF0ZT0iMjAyNi0wMi0yMlQyMjo0Mjo1NSswMTowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyNi0wMi0yNlQwMDo1NDozMiswMTowMCIgeG1wOk1vZGlmeURhdGU9IjIwMjYtMDItMjZUMDA6NTQ6MzIrMDE6MDAiIHBob3Rvc2hvcDpDb2xvck1vZGU9IjMiIGRjOmZvcm1hdD0iaW1hZ2UvcG5nIiB4bXBNTTpJbnN0YW5jZUlEPSJ4bXAuaWlkOjEwYzAzZWMwLTVmMzMtZjQ0Ni04NmUyLWZiYjVjNzNkYmMxZCIgeG1wTU06RG9jdW1lbnRJRD0iYWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOmIwZGU2NWMzLTkzMDAtZDY0MC1iYjVmLWU1MzVlMDg5M2E4NiIgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOmM3NGNkMmQ2LTFlMjMtZjU0NC1iYjJiLTllNTQyZTdhNWViYSI+IDxwaG90b3Nob3A6RG9jdW1lbnRBbmNlc3RvcnM+IDxyZGY6QmFnPiA8cmRmOmxpPjBGQkIwM0ExNjI0QUVERDg0N0I0QUZDQzg0MzBGRjkwPC9yZGY6bGk+IDxyZGY6bGk+MURDNzRGOURDMTdBODg0MkNEODdGNjM5NDAwMjI0NUE8L3JkZjpsaT4gPHJkZjpsaT4yNzQ0RkFDNUJCN0Y0RjBBRDdEMTZDMUFBRTY4RUQyMzwvcmRmOmxpPiA8cmRmOmxpPjUwMDkxQ0Y2QjBFMjAxQzY4RTMxMDMyMTU4QzRCNTA4PC9yZGY6bGk+IDxyZGY6bGk+QzFBOEM3N0VENTE1MzIxQ0MyQzgyRkFEMkFENDgxRTc8L3JkZjpsaT4gPHJkZjpsaT5DNTZDNUM3NzU3MzI3QjQ0NzA3M0I0Qzc2QzAzRTIxRTwvcmRmOmxpPiA8cmRmOmxpPkRERkEwMjkzMTI1MDAxMDREMjgyMjVDRkY0QzA5MEUzPC9yZGY6bGk+IDxyZGY6bGk+RUFDNzZFOTczQjI3Q0M2MTk5RDc2N0EzREI1Q0Q2RUU8L3JkZjpsaT4gPHJkZjpsaT5GMDlBMDEyQTFBQTdFNDlBMzVCODBGQTYzNDc3MzAzNTwvcmRmOmxpPiA8cmRmOmxpPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDozMThkYmMwNS0yYzg3LTFiNGEtYmY1Mi03MWY3ZjA5YmQzZTM8L3JkZjpsaT4gPHJkZjpsaT5hZG9iZTpkb2NpZDpwaG90b3Nob3A6NDY4MjA4NzQtODRiMS1kMDQxLTlkNGQtMzRiZjk5OTg1NWViPC9yZGY6bGk+IDxyZGY6bGk+YWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjY4NzQxNzRkLTFkYjQtNDQ0ZS1iYmE3LWYxYjdmMjY3MjUxNzwvcmRmOmxpPiA8cmRmOmxpPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDo3ZmMyZTU1NC03OTI4LWZmNDQtOGEyNi02MGY4N2M2OTllZmM8L3JkZjpsaT4gPHJkZjpsaT5hZG9iZTpkb2NpZDpwaG90b3Nob3A6OWZiMDc3MzYtNDIwYi0zMzRlLTg1OTktYTI4YTg3OWIxMTVlPC9yZGY6bGk+IDxyZGY6bGk+YWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOmU1NzYwZWVlLWM5ZjEtYmY0MC1iYTM2LWRmZmFlMjMwMWEwZjwvcmRmOmxpPiA8L3JkZjpCYWc+IDwvcGhvdG9zaG9wOkRvY3VtZW50QW5jZXN0b3JzPiA8eG1wTU06SGlzdG9yeT4gPHJkZjpTZXE+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjcmVhdGVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmM3NGNkMmQ2LTFlMjMtZjU0NC1iYjJiLTllNTQyZTdhNWViYSIgc3RFdnQ6d2hlbj0iMjAyNi0wMi0yMlQyMjo0Mjo1NSswMTowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIxLjAgKFdpbmRvd3MpIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJzYXZlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDo5NjZiNWRiMy0xMTc0LTY2NDAtYjE4Ni1kMjA1ZjNlZDU4MDYiIHN0RXZ0OndoZW49IjIwMjYtMDItMjZUMDA6NTQ6MzIrMDE6MDAiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMS4wIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY29udmVydGVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJmcm9tIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AgdG8gaW1hZ2UvcG5nIi8+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJkZXJpdmVkIiBzdEV2dDpwYXJhbWV0ZXJzPSJjb252ZXJ0ZWQgZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZyIvPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0ic2F2ZWQiIHN0RXZ0Omluc3RhbmNlSUQ9InhtcC5paWQ6MTBjMDNlYzAtNWYzMy1mNDQ2LTg2ZTItZmJiNWM3M2RiYzFkIiBzdEV2dDp3aGVuPSIyMDI2LTAyLTI2VDAwOjU0OjMyKzAxOjAwIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjEuMCAoV2luZG93cykiIHN0RXZ0OmNoYW5nZWQ9Ii8iLz4gPC9yZGY6U2VxPiA8L3htcE1NOkhpc3Rvcnk+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOjk2NmI1ZGIzLTExNzQtNjY0MC1iMTg2LWQyMDVmM2VkNTgwNiIgc3RSZWY6ZG9jdW1lbnRJRD0iYWRvYmU6ZG9jaWQ6cGhvdG9zaG9wOjM0OTgyYTBmLTA2MGQtNDk0OS04M2ZhLTU0MTE3OTIxNTUwZCIgc3RSZWY6b3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOmM3NGNkMmQ2LTFlMjMtZjU0NC1iYjJiLTllNTQyZTdhNWViYSIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pns+hTYAAALtSURBVDgRBcHLa1xlGMDh33tykozNDO3JNLcm0YlOmwoJ2FJqpJQqLosiXUkjVcG9IrgRXIjgJa1diP4DZiGkou4EcaELFYIuFDFeaJJecutkMpO5f+d87/f6PPLZ2688ufrn+jc77WhEAyICiGAGAhgAhgACGCCCTebD/lNPzF2Rl194ZldG5sZOTE7y3+118keGiAb6yZoPuDgfKE5ME7IqyDaVtR2+/S0hN/4Y3VaDRLcq8cZBGB0ebLFb+Z2hoSG6rkfa7DA/UeG1N98D/gBfgyzH8hu3eVA7TTLUAAvcqYViLJg556Q/jgFDTQjNTRbfugzZD1jjR2QgYu3Wvyz/nCd5fJYYT6+XIQYRQAhKCIrPPLXKAU+fP8LJeYfVv0cspblW5cand9kemCVzGeoVzTwIxBioBkRAQx/H4l1eWjwDjZ/A1SFS2vU6l57L82xyh9rmP3y9OgZJCTAiMMwMVaNZq7J4JUdxpg6hgfhDrL3H+PQe164dcPXcAZ2NXeo9AwwMYgxUFeeNxG/ycDfw1+dbgFE+mzKgO2BGbyth6eM2X2zMMjw1QeYcfUAMkKUOJKKaFXj9kz16LuXifIvrc20Qpbtf5PqNFiv3yoyWyljmyDJPn0EM4DMFPP2FUaJkmv5eyvOXf6Vv0NG9X2TpZpuVe2WK04+CpjiXIgIAMYAIeK9EPiPNhNPH73JpoUPnfsIHS02+2i4zPDUDmuFciqoCBjHEGHgNqCraM9Jum6uvpvhGgfc/qvLldpnjUyVC5sgyj/eKWcAMiCE2IE1TQlB86GO+1GLhkYh339nn1tZJhk9Mo87hVVH1eK+EYEQiAMRmSC43SKPRwLmUM8d2uPlhjeX1GZLxEXrtFkEDGgIAIRghKIV8gRAc8cRD4eDveq84NjZGCIHv1lI6Umbm1AhCIAQDwMwQAUwwgcN6ndLRcBhfWDj3Ir+srux1qkcFJPTnyQHWrmAAAICAAQASgZ0qaOPC+bOL/wMhrqDaf/wXkAAAAABJRU5ErkJggg==
-- Hide: no
-- AlwaysLoaded: no

source("editorUtils.lua")
-- source("Hooks.lua")
source("ui/ProgressDialog.lua")
source("ui/MessageBox.lua")

local gamePath = EditorUtils.getGameBasePath()
if gamePath == nil then
    return
end

source(gamePath .. "dataS/scripts/std.lua")
source(gamePath .. "dataS/scripts/shared/class.lua")
source(gamePath .. "dataS/scripts/misc/Logging.lua")
source(gamePath .. "dataS/scripts/xml/XMLFile.lua")
source(gamePath .. "dataS/scripts/xml/XMLManager.lua")
source(gamePath .. "dataS/scripts/Files.lua")
source(gamePath .. "dataS/scripts/io.lua")
source(gamePath .. "dataS/scripts/i3d/I3DManager.lua")
source(gamePath .. "dataS/scripts/CollisionFlag.lua")
source(gamePath .. "dataS/scripts/utils/Utils.lua")

-- Fallback: Utils.lua sometimes fails to load after a game update, leaving MathUtil nil.
-- Define the functions we need manually so the script still works.
if MathUtil == nil then
    MathUtil = {}
    function MathUtil.vector3Length(x, y, z)
        return math.sqrt(x * x + y * y + z * z)
    end
end

PowerlineGenerator = {}

PowerlineGenerator.VERSION = "v1.0"

PowerlineGenerator.WINDOW_WIDTH = 350
PowerlineGenerator.SETTINGS_PATH = getAppDataPath() .. "PowerlineGeneratorSettings.xml"
PowerlineGenerator.SETTINGS_PATH_EDITOR = getAppDataPath() .. "editor.xml"

PowerlineGenerator.TEXTURE_SIZE = 1024
PowerlineGenerator.TEXTURE_HEIGHT_START = 996
PowerlineGenerator.TEXTURE_HEIGHT_END = 1024
PowerlineGenerator.TEXTURE_DIFFUSE = "$data/maps/mapAS/textures/props/antenna_diffuse.png"

-- local basePath = getSceneFilename():match("(.*/)")
-- PowerlineGenerator.EXPORT_PATH = basePath .. "PowerLines/" 

function PowerlineGenerator:isMap()
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

function PowerlineGenerator.getEditorLanguage()
    if not fileExists(PowerlineGenerator.SETTINGS_PATH_EDITOR) then
        return
    end

    local xmlFile = XMLFile.loadIfExists("editorSettings", PowerlineGenerator.SETTINGS_PATH_EDITOR)
    if xmlFile == nil then
        return 0
    end

    local lang = xmlFile:getInt("editor.language#language")
    xmlFile:delete()

    return lang
end

function PowerlineGenerator.new()
    local self = setmetatable({}, { __index = PowerlineGenerator })
	
    if not self:isMap() then
        printError("[PowerlineGenerator] This is not a Map!")
        return
    end
    self.window = nil
    self.windowGuide = nil

	self.debugLineColors = {
		segment = {
			segmentLine  = {1.0, 0.9, 0.0, 1.0},   -- kräftiges Blau
			segmentPoint = {1.0, 0.0, 1.00, 1.0},  -- dunkles Violett
		},

		crossing = {
			[1] = { line  = {1.00, 0.15, 0.15, 1.0}, point = {0.00, 0.80, 0.90, 1.0}}, -- 1 Rot + Cyan
			[2] = { line  = {0.10, 0.85, 0.25, 1.0}, point = {0.90, 0.10, 0.75, 1.0}}, -- 2 Grün + Magenta
			[3] = { line  = {0.20, 0.45, 1.00, 1.0}, point = {1.00, 0.55, 0.10, 1.0}}, -- 3 Blau + Orange
			[4] = { line  = {0.00, 0.75, 0.65, 1.0}, point = {1.00, 0.30, 0.15, 1.0}}, -- 4 Türkis + Rot-Orange
			[5] = { line  = {0.65, 0.25, 1.00, 1.0}, point = {0.65, 1.00, 0.10, 1.0}}, -- 5 Violett + Limettengrün
			[6] = { line  = {1.00, 0.90, 0.00, 1.0}, point = {0.05, 0.20, 0.60, 1.0}}, -- 6 Gelb + Tiefblau
			[7] = { line  = {1.00, 0.25, 0.75, 1.0}, point = {0.10, 0.80, 0.30, 1.0}}, -- 7 Pink + Grün
			[8] = { line  = {0.30, 0.75, 1.00, 1.0}, point = {0.90, 0.25, 0.20, 1.0}}, -- 8 Himmelblau + Warmrot
			[9] = { line  = {1.00, 0.55, 0.00, 1.0}, point = {0.00, 0.40, 0.45, 1.0}}, -- 9 Orange + Petrol
			[10] = { line  = {0.60, 1.00, 0.00, 1.0}, point = {0.55, 0.10, 0.75, 1.0}} -- 10 Lime + Violett
		}
	}
	
	self.sceneFilePath = getSceneFilename():match("(.*/)")
	self.exportI3dPath = self.sceneFilePath
	
	self.settings = {
		numCutsOfCuts = 10,
		powerLineRadius = 3,
		saggingVariationMin = 5,
		saggingVariationMax = 10,
	}
	
	self.progressDialog = {
		window = nil,
		totalCount = 0,
		genCount = 0
	}
	
	self.debugConnections = {}
	self.isDebugRenderingActive = false
	
	self:loadSettings()
	
	if self:getElectricityRootNode() then
		self:generateMainUI()
	else
		self:generateStartUI()
	end

    self.saveListener = addEventListener(HookType.ON_SELECTION_CHANGED, self.onSave, self)
    return self
end

function PowerlineGenerator:generateStartUI()
    self.uiFrameRowSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(self.uiFrameRowSizer, "Powerline Generator by Aslan (" .. PowerlineGenerator.VERSION .. ")", false, false, -1, -1, -1, -1)
    
	self.uiBorderSizer = UIRowLayoutSizer.new()
    UIPanel.new(self.uiFrameRowSizer, self.uiBorderSizer, -1, -1, PowerlineGenerator.WINDOW_WIDTH, -1, BorderDirection.NONE, 0, 1)

    local rowSizer = UIRowLayoutSizer.new()
    self.uiPanelSizer = UIPanel.new(self.uiBorderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 8, 1)
	
    UILabel.new(rowSizer, "TransformGroup Name:", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5):setBold(true)
    local columnSizer = UIColumnLayoutSizer.new()
	UIPanel.new(rowSizer, columnSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    self.uiCreateWorkGroupName = UITextArea.new(columnSizer, "electricity", TextAlignment.LEFT, false, false, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
	
    UILabel.new(rowSizer, "After creating the TransformGroup, you can place it")
    UILabel.new(rowSizer, "anywhere in your scene.", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 8)
	UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
	
    local function onCreateWorkGroup()
        local success = self:onCreateWorkingGroup(self.uiCreateWorkGroupName:getValue())
        if success then
            self:generateMainUI()
        end
    end
	
    self.uiBtnCreateWorkGroup = UIButton.new(rowSizer, "Create Working Group", onCreateWorkGroup , nil, -1, -1, -1, 30) 
	self.uiBtnCreateWorkGroup:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
	
    self.window:showWindow()
end

function PowerlineGenerator:generateMainUI()
    self.uiFrameRowSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(self.uiFrameRowSizer, "Powerline Generator by Aslan (" .. PowerlineGenerator.VERSION .. ")", false, false, -1, -1, -1, -1)
    
	self.uiBorderSizer = UIRowLayoutSizer.new()
    UIPanel.new(self.uiFrameRowSizer, self.uiBorderSizer, -1, -1, PowerlineGenerator.WINDOW_WIDTH, -1, BorderDirection.NONE, 0, 1)

    local rowSizer = UIRowLayoutSizer.new()
    self.uiPanelSizer = UIPanel.new(self.uiBorderSizer, rowSizer, -1, -1, -1, -1, BorderDirection.ALL, 8, 1)

	local gridSizer = UIGridSizer.new(2, 2, 5, 5)
	UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.ALL, 5)
	
    self.uiBtnHowTo = UIButton.new(gridSizer, "Guide", function() self:onOpenGuideWindow() end):setBackgroundColor(1.0, 0.9, 0.53, 1.0)
    self.uiBtnDebug = UIButton.new(gridSizer, "Render Debug", function() self:toggleDebugRendering() end)
    self.uiBtnDebug:setBackgroundColor(0.95, 0.4, 0.4, 1.0)
	
    UILabel.new(gridSizer, "")
	local debugColorTable = self.debugLineColors.segment
	local gridSubSizer = UIGridSizer.new(1, 2, 5, 5)
	UIPanel.new(gridSizer, gridSubSizer)
	
	self.uiBtnColorLine = UIButton.new(gridSubSizer, "Line",
		function()
			local c = debugColorTable.segmentLine
			showColorDialog(self.selectDebugLineColor, self, c[1], c[2], c[3])
		end
	)
	self.uiBtnColorLine:setEnabled(false)
	
	self.uiBtnColorPoint = UIButton.new(gridSubSizer, "Point",
		function()
			local c = debugColorTable.segmentLine
			showColorDialog(self.selectDebugPointColor, self, c[1], c[2], c[3])
		end
	)
	self.uiBtnColorPoint:setEnabled(false)

	UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
	
    UILabel.new(rowSizer, "Export I3D Folder:", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5):setBold(true)
    local columnSizer = UIColumnLayoutSizer.new()
	UIPanel.new(rowSizer, columnSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    self.uiExportI3DPath = UITextArea.new(columnSizer, self.exportI3dPath, TextAlignment.LEFT, false, false, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
    self.uiExportI3DPath:setToolTip(self.exportI3dPath)
    UIButton.new(columnSizer, "🗁", function() self:onSelectExportFolder() end, nil, -1, -1, 25, -1)
    UIButton.new(columnSizer, "X", function() end, nil, -1, -1, 25, -1)
	
	UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
	
    UILabel.new(rowSizer, "Generating Powerlines:", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5):setBold(true)
	local gridSizer = UIGridSizer.new(2, 2, 5, 5)
	UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    self.uiBtnGenSelectedSegment = UIButton.new(gridSizer, "Selected Segment ", function() self:genPowerlinesSegments(getSelection(0)) end)
    self.uiBtnGenSelectedCrossing = UIButton.new(gridSizer, "Selected Crossing ", function() self:genPowerlinesCrossings(getSelection(0)) end)
    self.uiBtnGenAllSegments = UIButton.new(gridSizer, "All Segments", function() self:genPowerlinesSegments() end)
    self.uiBtnGenAllCrossings = UIButton.new(gridSizer, "All Crossings", function() self:genPowerlinesCrossings() end)
	
    self.uiBtnGenAllPowerlines = UIButton.new(rowSizer, "Generate All", function() self:genPowerlinesAll() end, nil, -1, -1, -1, 30, BorderDirection.BOTTOM, 5):setBackgroundColor(0.6, 1.0, 0.55, 1.0)

	UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
	
    UILabel.new(rowSizer, "Create Groups:", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5):setBold(true)
	local gridSizer = UIGridSizer.new(1, 2, 5, 5)
	UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    self.uiBtnGenStraightPowerlines = UIButton.new(gridSizer, "Create Segment Group", function() self:createNewGroup("segment") end)
    self.uiBtnGenStraightPowerlines = UIButton.new(gridSizer, "Create Crossing Group", function() self:createNewGroup("crossing") end)
	
	UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
	
    UILabel.new(rowSizer, "Global Settings:", false, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.BOTTOM, 5):setBold(true)
	local gridSizer = UIGridSizer.new(4, 2, 5, 5)
	UIPanel.new(rowSizer, gridSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

	UITextArea.new(gridSizer, "Num Cuts per Line", TextAlignment.LEFT, true, false)
	self.uiNumOfCuts = UIIntSlider.new(gridSizer, self.settings.numCutsOfCuts, 1, 50)
	
	UITextArea.new(gridSizer, "Power Line Radius (cm)", TextAlignment.LEFT, true, false)
	self.uiPowerLineRadius = UIFloatSlider.new(gridSizer, self.settings.powerLineRadius, 0.1, 10.0)
	
	UITextArea.new(gridSizer, "Sagging (min.)", TextAlignment.LEFT, true, false)
	self.uiSaggingMin = UIIntSlider.new(gridSizer, self.settings.saggingVariationMin, 3, 30)
	
	UITextArea.new(gridSizer, "Sagging (max.)", TextAlignment.LEFT, true, false)
	self.uiSaggingMax = UIIntSlider.new(gridSizer, self.settings.saggingVariationMax, 3, 30)
	
    self.window:showWindow()
	self.window:setOnCloseCallback(function() self:onClose() end)
end

function PowerlineGenerator:onOpenGuideWindow()
	if self.windowGuide == nil then
		self.windowGuide = self:openWindowGuide()
	else
		self.windowGuide:close()
		self.windowGuide = nil
	end
end

function PowerlineGenerator:onClose()
	self:saveSettings()
    self:deactivateDebugRendering()
	if self.windowGuide ~= nil then
		self.windowGuide:close()
	end
end

function PowerlineGenerator:onSelectExportFolder()
    local path = openDirDialog(self.exportI3dPath)
    if path ~= nil and path ~= "" then
        path = string.gsub(path, "\\", "/")
        if string.sub(path, -1) ~= "/" then
            path = path .. "/"
        end
        self.exportI3dPath = path
        self.uiExportI3DPath:setValue(self.exportI3dPath)
		self.uiExportI3DPath:setToolTip(self.exportI3dPath)
        self:saveSettings()
    end
end

function PowerlineGenerator:selectDebugLineColor(r, g, b)
	self.debugLineColors.segment.segmentLine = {r, g, b, 1.0}
    self:updateDebugColorButtons()
end

function PowerlineGenerator:selectDebugPointColor(r, g, b)
	self.debugLineColors.segment.segmentPoint = {r, g, b, 1.0}
    self:updateDebugColorButtons()
end

function PowerlineGenerator:updateDebugColorButtons()
	if self.isDebugRenderingActive == true then
		self.uiBtnColorLine:setEnabled(true)
		self.uiBtnColorPoint:setEnabled(true)

		local debugColorTable = self.debugLineColors.segment

		local lr, lg, lb = unpack(debugColorTable.segmentLine)

		self.uiBtnColorLine:setBackgroundColor(lr, lg, lb, 1.0)

		local brightnessLine = 0.299 * lr + 0.587 * lg + 0.114 * lb
		if brightnessLine > 0.55 then
			self.uiBtnColorLine:setTextColor(0, 0, 0, 1.0)
		else
			self.uiBtnColorLine:setTextColor(1, 1, 1, 1.0)
		end

		local pr, pg, pb = unpack(debugColorTable.segmentPoint)

		self.uiBtnColorPoint:setBackgroundColor(pr, pg, pb, 1.0)

		local brightnessPoint = 0.299 * pr + 0.587 * pg + 0.114 * pb
		if brightnessPoint > 0.55 then
			self.uiBtnColorPoint:setTextColor(0, 0, 0, 1.0)
		else
			self.uiBtnColorPoint:setTextColor(1, 1, 1, 1.0)
		end
	else
		self.uiBtnColorLine:setTextColor(0, 0, 0, 1.0)
		self.uiBtnColorPoint:setTextColor(0, 0, 0, 1.0)
		self.uiBtnColorLine:setBackgroundColor(1.0, 1.0, 1.0, 1.0)
		self.uiBtnColorPoint:setBackgroundColor(1.0, 1.0, 1.0, 1.0)
		self.uiBtnColorLine:setEnabled(false)
		self.uiBtnColorPoint:setEnabled(false)
	end
end

function PowerlineGenerator:getElectricityRootNode()
    local electricityNode = nil
    EditorUtils.interateRecursively(getRootNode(), function(node)
        if node ~= nil and node ~= 0 then
            if getUserAttribute(node, "isElectricityMainGroup") ~= nil then
                electricityNode = node
                return false
            end
        end

        return true
    end)

    return electricityNode
end

function PowerlineGenerator:createNewGroup(segmentType)
    if segmentType ~= "segment" and segmentType ~= "crossing" then
        print("PowerlineGenerator: Invalid segmentType:", segmentType)
        return nil
    end

    local electricityNode = self:getElectricityRootNode()
    if electricityNode == nil then
        print("PowerlineGenerator: electricity main group not found")
        return nil
    end

    local parentGroup = getChild(electricityNode, segmentType .. "s")
    if parentGroup == nil or parentGroup == 0 then
        print("PowerlineGenerator: parent group not found:", segmentType .. "s")
        return nil
    end

    local highest = 0
    local childCount = getNumOfChildren(parentGroup)

    for i = 0, childCount - 1 do
        local child = getChildAt(parentGroup, i)
        local name = getName(child)

        local number = string.match(name, segmentType .. "(%d+)")
        if number then
            number = tonumber(number)
            if number > highest then
                highest = number
            end
        end
    end

    local newIndex = highest + 1
    local newName = string.format("%s%02d", segmentType, newIndex)

    local node = createTransformGroup(newName)
    link(parentGroup, node)

    setUserAttribute(node, "useCustomValues", UserAttributeType.BOOLEAN, false)
    setUserAttribute(node, "numOfCuts", UserAttributeType.INTEGER, self.settings.numCutsOfCuts)
    setUserAttribute(node, "powerLineRadius", UserAttributeType.FLOAT, self.settings.powerLineRadius)
    setUserAttribute(node, "saggingMin", UserAttributeType.INTEGER, self.settings.saggingVariationMin)
    setUserAttribute(node, "saggingMax", UserAttributeType.INTEGER, self.settings.saggingVariationMax)
	
    -- if segmentType == "crossing" then
        -- local node01 = createTransformGroup("node01")
        -- link(node, node01)
        -- setTranslation(node01, 0, 0, 0)
        -- local node01_01 = createTransformGroup("node01_01")
        -- link(node01, node01_01)
        -- setTranslation(node01_01, 2, 0, 0)
    -- end

    print("[PowerlineGenerator] Created new " .. segmentType .. ": " .. newName)

    return node
end

function PowerlineGenerator:onCreateWorkingGroup(groupName)
    if groupName == nil or groupName == "" then
        print("PowerlineGenerator: Invalid group name")
        return false
    end
	
    local existing = self:getElectricityRootNode()
    if existing ~= nil then
        print("PowerlineGenerator: Electricity group already exists")
        return false
    end
	
    local rootNode = getRootNode()
    local electricityNode = createTransformGroup(groupName)
    link(rootNode, electricityNode)

    setUserAttribute(electricityNode, "isElectricityMainGroup", UserAttributeType.BOOLEAN, true)

    local segmentsNode = createTransformGroup("segments")
    link(electricityNode, segmentsNode)

    local crossingsNode = createTransformGroup("crossings")
    link(electricityNode, crossingsNode)

    local meshesNode = createTransformGroup("powerlineMeshes")
    link(electricityNode, meshesNode)

    link(meshesNode, createTransformGroup("segments"))
    link(meshesNode, createTransformGroup("crossings"))
    link(electricityNode, meshesNode)
    self:createNewGroup("segment")
    self:createNewGroup("crossing")

    local objectsNode = createTransformGroup("objects")
    link(electricityNode, objectsNode)

    if self.window ~= nil then
        self.window:close()
        self.window = nil
    end

    print("[PowerlineGenerator] Working group created: " .. groupName)

    return true
end


function PowerlineGenerator:syncGroupSettingsWithUI(groupNode)
    if groupNode == nil or groupNode == 0 then
        return
    end

    local useCustom = getUserAttribute(groupNode, "useCustomValues")

    if useCustom == true then
        return
    end

    setUserAttribute(groupNode, "numOfCuts", UserAttributeType.INTEGER, self.uiNumOfCuts:getValue())
    setUserAttribute(groupNode, "powerLineRadius", UserAttributeType.FLOAT, self.uiPowerLineRadius:getValue())
    setUserAttribute(groupNode, "saggingMin", UserAttributeType.INTEGER, self.uiSaggingMin:getValue())
    setUserAttribute(groupNode, "saggingMax", UserAttributeType.INTEGER, self.uiSaggingMax:getValue())
end

function PowerlineGenerator:getGroupSettings(groupNode)
    return {
        numCuts = getUserAttribute(groupNode, "numOfCuts") or self.uiNumOfCuts:getValue(),
        radius  = (getUserAttribute(groupNode, "powerLineRadius") or self.uiPowerLineRadius:getValue()) * 0.01,
        sagMin  = getUserAttribute(groupNode, "saggingMin") or self.uiSaggingMin:getValue(),
        sagMax  = getUserAttribute(groupNode, "saggingMax") or self.uiSaggingMax:getValue()
    }
end

function PowerlineGenerator:genPowerlinesAll()
    local electricityRoot = self:getElectricityRootNode()
    if electricityRoot == nil then
        print("No electricity root found")
        return
    end

    local segmentsRoot  = getChild(electricityRoot, "segments")
    local crossingsRoot = getChild(electricityRoot, "crossings")

    local totalCount = 0
    if segmentsRoot ~= 0 then
        totalCount = totalCount + getNumOfChildren(segmentsRoot)
    end
    if crossingsRoot ~= 0 then
        totalCount = totalCount + getNumOfChildren(crossingsRoot)
    end
    if totalCount == 0 then return end

    local window = ProgressDialog.show("[PowerlineGenerator] Generate All Powerlines...")
    local current = 0

    if segmentsRoot ~= 0 then
        current = self:generateBatch(segmentsRoot, "segments", nil, current, totalCount, window)
    end

    if crossingsRoot ~= 0 then
        current = self:generateBatch(crossingsRoot, "crossings", nil, current, totalCount, window)
    end

    window:close()
	self:printList()
end

function PowerlineGenerator:genPowerlinesSegments(selectedNode)

    local electricityRoot = self:getElectricityRootNode()
    if electricityRoot == nil then return end

    local segmentsRoot = getChild(electricityRoot, "segments")
    if segmentsRoot == 0 then return end

    local singleNode = nil

    if selectedNode ~= nil then
        singleNode = self:getSegmentRootByNode(selectedNode)
        if singleNode == nil then
            printError("[PowerlineGenerator] No segment selected")
            return
        end
    end

    local total = singleNode and 1 or getNumOfChildren(segmentsRoot)

    local window = ProgressDialog.show("[PowerlineGenerator] Generate Segments...")

    self:generateBatch(segmentsRoot, "segments", singleNode, 0, total, window)

    window:close()
	self:printList()
end

function PowerlineGenerator:genPowerlinesCrossings(selectedNode)

    local electricityRoot = self:getElectricityRootNode()
    if electricityRoot == nil then return end

    local crossingsRoot = getChild(electricityRoot, "crossings")
    if crossingsRoot == 0 then return end

    local singleNode = nil

    if selectedNode ~= nil then
        singleNode = self:getCrossingRootByNode(selectedNode)
        if singleNode == nil then
            printError("[PowerlineGenerator] No crossing selected")
            return
        end
    end

    local total = singleNode and 1 or getNumOfChildren(crossingsRoot)

    local window = ProgressDialog.show("[PowerlineGenerator] Generate Crossings...")

    self:generateBatch(crossingsRoot, "crossings", singleNode, 0, total, window)

    window:close()
	self:printList()
end

function PowerlineGenerator:generateBatch(rootNode, type, singleNode, current, total, window)
    local count = getNumOfChildren(rootNode)

    for i = 0, count - 1 do
        local node = getChildAt(rootNode, i)

        if singleNode == nil or node == singleNode then
            current = current + 1
            if type == "segments" then
                self:generateSegment(node)
            else
                self:generateCrossing(node)
            end

            window:setProgress(current / total, string.format("Generate %d / %d", current, total))
        end
    end

    return current
end

function PowerlineGenerator:generateSegment(segmentNode)
	self:syncGroupSettingsWithUI(segmentNode)
	local settings = self:getGroupSettings(segmentNode)

    local segmentName = getName(segmentNode)
    local objects = self:collectObjectsWithPowerLineNodes(segmentNode)

    if #objects < 2 then
		self:addPrint("error", "[PowerlineGenerator] Segment has less than 2 valid objects: %s", segmentName)
        return
    end

    local verts  = {}
    local faces  = {}
    local vertexOffset = 0

    for j = 1, #objects - 1 do
        vertexOffset = self:connectObjects(objects[j], objects[j+1], segmentName, verts, faces, vertexOffset, settings, j)
    end

    self:exportAndImportMesh(segmentName, "segments", verts, faces)
end

function PowerlineGenerator:generateCrossing(crossingNode)
	self:syncGroupSettingsWithUI(crossingNode)
	local settings = self:getGroupSettings(crossingNode)
	
    local crossingName = getName(crossingNode)
    local verts  = {}
    local faces  = {}
    local vertexOffset = 0

    for i = 0, getNumOfChildren(crossingNode)-1 do
        local child = getChildAt(crossingNode, i)

        vertexOffset = self:processCrossingBranch(child, crossingName, verts, faces, vertexOffset, settings)
    end

    if #verts > 0 then
        self:exportAndImportMesh(crossingName, "crossings", verts, faces)
    else
        self:addPrint("warning", "Crossing has no valid connections: %s", crossingName)
    end
end

function PowerlineGenerator:processCrossingBranch(node, path, verts, faces, vertexOffset, settings)
    if node == nil or node == 0 then
        return vertexOffset
    end

    local childCount = getNumOfChildren(node)

    for i = 0, childCount - 1 do
        local child = getChildAt(node, i)
        local childPath = path .. "|" .. getName(child)

        vertexOffset = self:createPowerLineBetween(node, child, verts, faces, vertexOffset, settings)
        vertexOffset = self:processCrossingBranch(child, childPath, verts, faces,vertexOffset, settings)
    end

    return vertexOffset
end

function PowerlineGenerator:collectObjectsWithPowerLineNodes(root)
    local result = {}
    local count = getNumOfChildren(root)

    for i = 0, count - 1 do
        local child = getChildAt(root, i)

        if getChild(child, "powerLineNodes") ~= nil then
            table.insert(result, child)
        end
    end

    return result
end

function PowerlineGenerator:connectObjects(objA, objB, debugPath, verts, faces, vertexOffset, settings, objectIndex)

    local startA, endA = self:getPowerLineNodes(objA)
    local startB, endB = self:getPowerLineNodes(objB)

    local countA = #startA
    local countB = #endB
    local maxCount = math.max(countA, countB)

    for i = 1, maxCount do
        local nodeA = startA[i]
        local nodeB = endB[i]

        if nodeA and nodeB then
            vertexOffset = self:createPowerLineBetween(nodeA, nodeB, verts, faces, vertexOffset, settings)
        else
            self:addPrint(
                "warning",
                "Mismatch in '%s' between object #%d and #%d at node index %d (StartNodes A: %d | EndNodes B: %d)",
                debugPath, objectIndex, objectIndex + 1, i, countA, countB
            )
        end
    end

    return vertexOffset
end

function PowerlineGenerator:getPowerLineNodes(pole)

    local startNodes = {}
    local endNodes   = {}

    if pole == nil or pole == 0 then
        return startNodes, endNodes
    end

    local group = getChild(pole, "powerLineNodes")
    if group == nil or group == 0 then
        return startNodes, endNodes
    end

    local count = getNumOfChildren(group)

    for i = 0, count - 1 do
        local node = getChildAt(group, i)

        if node ~= nil and node ~= 0 then
            local name = getName(node)

            if string.sub(name, 1, 6) == "start_" then
                table.insert(startNodes, node)

            elseif string.sub(name, 1, 4) == "end_" then
                table.insert(endNodes, node)

            else
                -- kein Präfix → bidirektional
                table.insert(startNodes, node)
                table.insert(endNodes, node)
            end
        end
    end

    return startNodes, endNodes
end

function PowerlineGenerator:generateCatenaryPoints(startPos, endPos, segments, sag)
    local points = {}

    local dx = endPos.x - startPos.x
    local dy = endPos.y - startPos.y
    local dz = endPos.z - startPos.z

    local length = MathUtil.vector3Length(dx, dy, dz)

    for i = 0, segments do

        local t = i / segments

        local x = startPos.x + dx * t
        local y = startPos.y + dy * t
        local z = startPos.z + dz * t

        -- Durchhang (parabolisch angenähert, später echte Catenary möglich)
        local sagFactor = sag * math.sin(math.pi * t)
        y = y - sagFactor

        table.insert(points, {x=x, y=y, z=z})
    end

    return points
end

function PowerlineGenerator:createPowerLineBetween(nodeA, nodeB, verts, faces, vertexOffset, settings)
    local sx, sy, sz = getWorldTranslation(nodeA)
    local ex, ey, ez = getWorldTranslation(nodeB)

    local segments = settings.numCuts
    local radius   = settings.radius

    local sag = math.random(settings.sagMin, settings.sagMax) * 0.1

    local points = self:generateCatenaryPoints(
        {x=sx,y=sy,z=sz},
        {x=ex,y=ey,z=ez},
        segments,
        sag
    )

    return self:createPowerlineMesh(points, radius, verts, faces, vertexOffset)
end

function PowerlineGenerator:createPowerlineMesh(points, radius, verts, faces, vertexOffset)

    local baseOffset = vertexOffset
    local ringSize = 3
    local lineVariation = math.random()

    ----------------------------------------------------------
    -- Gesamtlänge berechnen
    ----------------------------------------------------------
    local totalLength = 0
    local distances = {0}

    for i = 2, #points do
        local dx = points[i].x - points[i-1].x
        local dy = points[i].y - points[i-1].y
        local dz = points[i].z - points[i-1].z
        local d = MathUtil.vector3Length(dx,dy,dz)
        totalLength = totalLength + d
        distances[i] = totalLength
    end

    ----------------------------------------------------------
    -- TEXTURSTREIFEN (Pixel → UV, invertiert!)
    ----------------------------------------------------------
    local texSize = PowerlineGenerator.TEXTURE_SIZE

    local texStartPx = PowerlineGenerator.TEXTURE_HEIGHT_START
    local texEndPx   = PowerlineGenerator.TEXTURE_HEIGHT_END

    -- Y-Achse invertieren
    local texStart = 1.0 - (texStartPx / texSize)
    local texEnd   = 1.0 - (texEndPx   / texSize)

    -- Reihenfolge korrigieren falls nötig
    if texStart > texEnd then
        texStart, texEnd = texEnd, texStart
    end

    local texRange = texEnd - texStart

    ----------------------------------------------------------
    -- Geometrie
    ----------------------------------------------------------
    for i = 1, #points do

        local p = points[i]
        local dist = distances[i]

        ------------------------------------------------------
        -- Tangente
        ------------------------------------------------------
        local dir
        if i < #points then
            local nextP = points[i+1]
            dir = {
                x = nextP.x - p.x,
                y = nextP.y - p.y,
                z = nextP.z - p.z
            }
        else
            local prevP = points[i-1]
            dir = {
                x = p.x - prevP.x,
                y = p.y - prevP.y,
                z = p.z - prevP.z
            }
        end

        local len = MathUtil.vector3Length(dir.x,dir.y,dir.z)
        dir.x,dir.y,dir.z = dir.x/len, dir.y/len, dir.z/len

        local worldUp = {x=0,y=1,z=0}

        local right = {
            x = dir.y * worldUp.z - dir.z * worldUp.y,
            y = dir.z * worldUp.x - dir.x * worldUp.z,
            z = dir.x * worldUp.y - dir.y * worldUp.x
        }

        local rLen = MathUtil.vector3Length(right.x,right.y,right.z)
        if rLen < 0.0001 then
            right = {x=1,y=0,z=0}
        else
            right.x, right.y, right.z = right.x/rLen, right.y/rLen, right.z/rLen
        end

        local up = {
            x = right.y * dir.z - right.z * dir.y,
            y = right.z * dir.x - right.x * dir.z,
            z = right.x * dir.y - right.y * dir.x
        }

        ------------------------------------------------------
        -- U = horizontal entlang Leitung
        -- 5m = 1.0 UV
        ------------------------------------------------------
        local u = dist / 5.0

        ------------------------------------------------------
        -- Dreieck
        ------------------------------------------------------
        local h = radius
        local halfWidth = radius * math.sqrt(3) / 2

        local triangleOffsets = {
            {  0,        -h },
            { -halfWidth,  h/2 },
            {  halfWidth,  h/2 }
        }

		for r = 1, 3 do
			local ox = triangleOffsets[r][1]
			local oy = triangleOffsets[r][2]

			local px = p.x + right.x * ox + up.x * oy
			local py = p.y + right.y * ox + up.y * oy
			local pz = p.z + right.z * ox + up.z * oy

			local nx = right.x * ox + up.x * oy
			local ny = right.y * ox + up.y * oy
			local nz = right.z * ox + up.z * oy

			local nLen = MathUtil.vector3Length(nx, ny, nz)
			if nLen > 0.000001 then
				nx = nx / nLen
				ny = ny / nLen
				nz = nz / nLen
			end

			local v = texStart + texRange * ((r-1) / 2)
			
			local intensity = 0.5
			table.insert(verts, {
				p   = {px, py, pz},
				n   = {nx, ny, nz},
				uv0 = {u, v},
				uv1 = {dist / totalLength, (r-1)/2},
				c   = {dist / totalLength, lineVariation, intensity, 1.0}
			})
		end
    end

    ----------------------------------------------------------
    -- Indices
    ----------------------------------------------------------
    local ringCount = #points

    for i = 0, ringCount - 2 do
        for r = 0, 2 do

            local current   = baseOffset + i * ringSize + r
            local next      = baseOffset + i * ringSize + ((r + 1) % ringSize)
            local currentUp = baseOffset + (i + 1) * ringSize + r
            local nextUp    = baseOffset + (i + 1) * ringSize + ((r + 1) % ringSize)

            table.insert(faces, {current+1, next+1, currentUp+1})
            table.insert(faces, {next+1, nextUp+1, currentUp+1})
        end
    end

    return baseOffset + (#points * ringSize)
end

function PowerlineGenerator:exportPowerlineI3D(path, name, verts, faces)
    local f = createFile(path, FileAccess.WRITE)
    if f == 0 then
		self:addPrint("error", "[PowerlineGenerator] Powerline i3D export failed")
        return
    end

    local vCount = #verts
    local tCount = #faces

    fileWrite(f, '<?xml version="1.0" encoding="iso-8859-1"?>\n')
	fileWrite(f, string.format('<i3D name="%s" version="1.6">\n', name))

	------------------------------------------------------------
	-- FILES
	------------------------------------------------------------
	fileWrite(f, '  <Files>\n')
	fileWrite(f, '    <File filename="$data/shaders/clothesWindShader.xml" fileId="1"/>\n')
	fileWrite(f, string.format('    <File filename="%s" fileId="2"/>\n', PowerlineGenerator.TEXTURE_DIFFUSE))
	fileWrite(f, '    <File filename="$data/shared/default_normal.png" fileId="3"/>\n')
	fileWrite(f, '    <File filename="$data/shared/default_specular.png" fileId="4"/>\n')
	fileWrite(f, '  </Files>\n')

	------------------------------------------------------------
	-- MATERIAL
	------------------------------------------------------------
	fileWrite(f, '  <Materials>\n')
	fileWrite(f, '    <Material name="powerLineMat" materialId="1" customShaderId="1" customShaderVariation="powerLines">\n')
	fileWrite(f, '      <Texture fileId="2"/>\n')
	fileWrite(f, '      <Normalmap fileId="3"/>\n')
	fileWrite(f, '      <Glossmap fileId="4"/>\n')
	fileWrite(f, '    </Material>\n')
	fileWrite(f, '  </Materials>\n')

    ------------------------------------------------------------
    -- SHAPES
    ------------------------------------------------------------
    fileWrite(f, '  <Shapes>\n')
    fileWrite(f, '    <IndexedTriangleSet name="Powerlines" shapeId="1" isOptimized="false">\n')

    fileWrite(f, string.format('      <Vertices count="%d" normal="true" tangent="true" uv0="true" uv1="true" color="true">\n', vCount))

    for _, v in ipairs(verts) do
        fileWrite(f, string.format(
            '        <v p="%.6f %.6f %.6f" n="%.6f %.6f %.6f" t0="%.6f %.6f" t1="%.6f %.6f" c="%.6f %.6f %.6f %.6f"/>\n',
            v.p[1], v.p[2], v.p[3], v.n[1], v.n[2], v.n[3], v.uv0[1], v.uv0[2], v.uv1[1], v.uv1[2], v.c[1], v.c[2], v.c[3], v.c[4]
        ))
    end

    fileWrite(f, '      </Vertices>\n')

    ------------------------------------------------------------
    -- TRIANGLES (0-based!)
    ------------------------------------------------------------
    fileWrite(f, string.format('      <Triangles count="%d">\n', tCount))

    for _, tri in ipairs(faces) do
        fileWrite(f, string.format('        <t vi="%d %d %d"/>\n', tri[1]-1, tri[2]-1, tri[3]-1))
    end

    fileWrite(f, '      </Triangles>\n')

    ------------------------------------------------------------
    -- SUBSET
    ------------------------------------------------------------
    fileWrite(f, '      <Subsets count="1">\n')
    fileWrite(f, string.format('        <Subset firstVertex="0" numVertices="%d" firstIndex="0" numIndices="%d"/>\n', vCount, tCount * 3))
    fileWrite(f, '      </Subsets>\n')

    fileWrite(f, '    </IndexedTriangleSet>\n')
    fileWrite(f, '  </Shapes>\n')

    ------------------------------------------------------------
    -- SCENE
    ------------------------------------------------------------
    fileWrite(f, '  <Scene>\n')
	fileWrite(f, string.format('    <Shape name="%s" shapeId="1" clipDistance="500" castsShadows="true" receiveShadows="true" tangents="true" materialIds="1"/>\n', name))
    fileWrite(f, '  </Scene>\n')

    fileWrite(f, '</i3D>\n')

    delete(f)

	self:addPrint("normal", "[PowerlineGenerator] Powerline I3D exported: %s", path)
end

function PowerlineGenerator:exportAndImportMesh(name, type, verts, faces)

    if #verts == 0 then return end

    local folder = self.exportI3dPath
    if not fileExists(folder) then
        createFolder(folder)
    end

    local path = folder .. "powerlines_" .. name .. ".i3d"

    self:exportPowerlineI3D(path, name, verts, faces)

    local importRoot = loadI3DFile(path)
    if importRoot == 0 then
		self:addPrint("error", "[PowerlineGenerator] Import failed: %s", name)
        return
    end

    ------------------------------------------------------------
    -- Shape aus importierter i3d holen
    ------------------------------------------------------------
    local shapeNode = getChildAt(importRoot, 0)
    if shapeNode == nil or shapeNode == 0 then
        delete(importRoot)
		self:addPrint("error", "[PowerlineGenerator] No shape found in i3d: %s", name)
        return
    end

    setName(shapeNode, name)

    local electricityRoot = self:getElectricityRootNode()
    if electricityRoot == nil then
        delete(importRoot)
        return
    end

    local meshesRoot = getChild(electricityRoot, "powerlineMeshes")
    if meshesRoot == nil or meshesRoot == 0 then
        delete(importRoot)
        return
    end

    local targetRoot = getChild(meshesRoot, type)
    if targetRoot == nil or targetRoot == 0 then
        delete(importRoot)
        return
    end

    ------------------------------------------------------------
    -- Existierendes Mesh mit gleichem Namen löschen
    ------------------------------------------------------------
    local existing = getChild(targetRoot, name)
    if existing ~= nil and existing ~= 0 then
        delete(existing)
    end

    ------------------------------------------------------------
    -- Shape direkt linken
    ------------------------------------------------------------
    link(targetRoot, shapeNode)

    ------------------------------------------------------------
    -- Import-Wrapper löschen
    ------------------------------------------------------------
    delete(importRoot)

	self:addPrint("normal", "[PowerlineGenerator] Mesh loaded: %s", name)
end

function PowerlineGenerator:toggleDebugRendering()

    if self.isDebugRenderingActive then
        if self.drawCallback ~= nil then
            removeDrawListener(self.drawCallback)
            self.drawCallback = nil
        end

        self.isDebugRenderingActive = false
		self.uiBtnDebug:setBackgroundColor(0.95, 0.4, 0.4, 1.0)
		self:updateDebugColorButtons()

        print("[PowerlineGenerator] Debug Rendering Disabled")
        return
    end

    self.debugElectricityRoot = self:getElectricityRootNode()
    if self.debugElectricityRoot == nil then
        printError("[PowerlineGenerator] No electricity root defined")
        return
    end

    self.crossingColors = {}
    self.isDebugRenderingActive = true
    self.drawCallback = addDrawListener("powerlineGenerator_debugDrawCallback", self, self.draw)

	self.uiBtnDebug:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
	self:updateDebugColorButtons()
	
    print("[PowerlineGenerator] Debug Rendering Enabled")
end

function PowerlineGenerator:deactivateDebugRendering()
    if self.isDebugRenderingActive then
        self:toggleDebugRendering()
    end
end

function PowerlineGenerator:draw()

    if not self.isDebugRenderingActive then
        return
    end

    local electricityRoot = self.debugElectricityRoot
    if electricityRoot == nil or electricityRoot == 0 then
        return
    end

    ------------------------------------------------------------
    -- SEGMENTS

	local segmentsRoot = getChild(electricityRoot, "segments")

	if segmentsRoot ~= nil and segmentsRoot ~= 0 then
		local segmentCount = getNumOfChildren(segmentsRoot)

		for i = 0, segmentCount - 1 do
			local segmentNode = getChildAt(segmentsRoot, i)
			local objectCount = getNumOfChildren(segmentNode)

			for j = 0, objectCount - 2 do
				local objA = getChildAt(segmentNode, j)
				local objB = getChildAt(segmentNode, j + 1)

				if objA ~= 0 and objB ~= 0 then

					local startA, _ = self:getPowerLineNodes(objA)
					local _, endB   = self:getPowerLineNodes(objB)

					local countA = #startA
					local countB = #endB
					local maxCount = math.max(countA, countB)

					for k = 1, maxCount do
						local nodeA = startA[k]
						local nodeB = endB[k]

						if nodeA and nodeB then
							local ax, ay, az = getWorldTranslation(nodeA)
							local bx, by, bz = getWorldTranslation(nodeB)

							local segmentPoint = self.debugLineColors.segment.segmentPoint
							local segmentLine  = self.debugLineColors.segment.segmentLine

							drawDebugPoint(ax, ay, az,
								segmentPoint[1], segmentPoint[2], segmentPoint[3], segmentPoint[4], false)

							drawDebugPoint(bx, by, bz,
								segmentPoint[1], segmentPoint[2], segmentPoint[3], segmentPoint[4], false)

							drawDebugLine(ax, ay, az,
								segmentLine[1], segmentLine[2], segmentLine[3],
								bx, by, bz,
								segmentLine[1], segmentLine[2], segmentLine[3],
								false)
						end
					end
				end
			end
		end
	end

		------------------------------------------------------------
		-- CROSSINGS

	local crossingsRoot = getChild(electricityRoot, "crossings")

	if crossingsRoot ~= nil and crossingsRoot ~= 0 then

		local crossingCount = getNumOfChildren(crossingsRoot)
		local colorCount = #self.debugLineColors.crossing

		for i = 0, crossingCount - 1 do

			local crossingNode = getChildAt(crossingsRoot, i)

			if crossingNode ~= 0 then

				local colorIndex = (i % colorCount) + 1
				local colorSet = self.debugLineColors.crossing[colorIndex]

				local lineColor  = colorSet.line
				local pointColor = colorSet.point

				local lr, lg, lb, la = unpack(lineColor)
				local pr, pg, pb, pa = unpack(pointColor)

				local function processBranch(node)

					local childCount = getNumOfChildren(node)

					for j = 0, childCount - 1 do
						local child = getChildAt(node, j)

						if child ~= 0 then

							local ax, ay, az = getWorldTranslation(node)
							local bx, by, bz = getWorldTranslation(child)

							drawDebugPoint(ax, ay, az, pr, pg, pb, pa, false)
							drawDebugPoint(bx, by, bz, pr, pg, pb, pa, false)

							drawDebugLine(ax, ay, az, lr, lg, lb,
										  bx, by, bz, lr, lg, lb,
										  false)

							processBranch(child)
						end
					end
				end

				local firstLevelCount = getNumOfChildren(crossingNode)

				for c = 0, firstLevelCount - 1 do
					local rootChild = getChildAt(crossingNode, c)

					if rootChild ~= 0 then
						processBranch(rootChild)
					end
				end
			end
		end
	end
end

function PowerlineGenerator:getSegmentRootByNode(node)
    if node == nil or node == 0 then
        return nil
    end

    while node ~= getRootNode() do
        local parent = getParent(node)
        if parent == nil or parent == 0 then
            return nil
        end

        if getName(parent) == "segments" then
            return node
        end
        node = parent
    end

    return nil
end

function PowerlineGenerator:getCrossingRootByNode(node)
    if node == nil or node == 0 then
        return nil
    end

    while node ~= getRootNode() do
        local parent = getParent(node)
        if parent == nil or parent == 0 then
            return nil
        end
        if getName(parent) == "crossings" then
            return node
        end

        node = parent
    end

    return nil
end

function PowerlineGenerator:addPrint(logType, text, ...)
    if self.printBuffer == nil then
        self.printBuffer = {}
    end

    if type(text) ~= "string" then
        text = tostring(text)
    end

    local formatted

    if select("#", ...) > 0 then
        formatted = string.format(text, ...)
    else
        formatted = text
    end

    table.insert(self.printBuffer, {type = logType or "normal", message = formatted})
end

function PowerlineGenerator:printList()
    if self.printBuffer == nil or #self.printBuffer == 0 then
        return
    end

    print("--------------------------------------------------")
    print("[PowerlineGenerator] Summary")
    print("--------------------------------------------------")

    for _, entry in ipairs(self.printBuffer) do
        if entry.type == "warning" then
            printWarning("⚠ WARNING: " .. entry.message)
        elseif entry.type == "error" then
            printError("✖ ERROR: " .. entry.message)
        else
            print("• " .. entry.message)
        end
    end

    print("--------------------------------------------------")

    self.printBuffer = {}
end

function PowerlineGenerator:saveSettings()
    local scenePath = getSceneFilename()
    if scenePath == nil then return end

    local xmlFile = XMLFile.loadIfExists("PowerlineGeneratorSettings", PowerlineGenerator.SETTINGS_PATH)

    if not xmlFile then
        xmlFile = XMLFile.create("PowerlineGeneratorSettings", PowerlineGenerator.SETTINGS_PATH, "settings")
        if not xmlFile then return end
    end

    local mapIndex = nil
    local i = 0

    while true do
        local key = string.format("settings.map(%d)", i)
        if not xmlFile:hasProperty(key) then
            break
        end

        local path = xmlFile:getString(key .. "#path")
        if path == scenePath then
            mapIndex = i
            break
        end

        i = i + 1
    end

    if mapIndex == nil then
        mapIndex = i
    end

    local mapKey = string.format("settings.map(%d)", mapIndex)

    xmlFile:setString(mapKey .. "#path", scenePath)
    xmlFile:setString(mapKey .. ".exportI3DPath#path", self.exportI3dPath or "")

	local colorKey = mapKey .. ".debugDrawColor"

	local line = self.debugLineColors.segment.segmentLine
	local point = self.debugLineColors.segment.segmentPoint
	xmlFile:setString(colorKey .. "#segmentLine", string.format("%.4f %.4f %.4f %.4f", line[1], line[2], line[3], line[4]))
	xmlFile:setString(colorKey .. "#segmentPoint", string.format("%.4f %.4f %.4f %.4f", point[1], point[2], point[3], point[4]))
	
    local key = mapKey .. ".values"
    xmlFile:setInt(key .. "#numOfCuts", self.uiNumOfCuts:getValue())
    xmlFile:setFloat(key .. "#powerLineRadius", self.uiPowerLineRadius:getValue())
    xmlFile:setInt(key .. "#saggingVariationMin", self.uiSaggingMin:getValue())
    xmlFile:setInt(key .. "#saggingVariationMax", self.uiSaggingMax:getValue())
	
    xmlFile:save()
    xmlFile:delete()
end

function PowerlineGenerator:loadSettings()
    local scenePath = getSceneFilename()
    if scenePath == nil then return end

    local xmlFile = XMLFile.loadIfExists("PowerlineGeneratorSettings", PowerlineGenerator.SETTINGS_PATH)
    if not xmlFile then return end

    local mapIndex = nil
    local i = 0

    while true do
        local key = string.format("settings.map(%d)", i)

        if not xmlFile:hasProperty(key) then
            break
        end

        local path = xmlFile:getString(key .. "#path")
        if path == scenePath then
            mapIndex = i
            break
        end

        i = i + 1
    end

    if mapIndex == nil then
        xmlFile:delete()
        return
    end

    local mapKey = string.format("settings.map(%d)", mapIndex)

    self.exportI3dPath = xmlFile:getString(mapKey .. ".exportI3DPath#path") or self.exportI3dPath
	
	local colorKey = mapKey .. ".debugDrawColor"
	local lineStr = xmlFile:getString(colorKey .. "#segmentLine")
	local pointStr = xmlFile:getString(colorKey .. "#segmentPoint")

	if lineStr ~= nil then
		local r,g,b,a = lineStr:match("([%d%.]+) ([%d%.]+) ([%d%.]+) ([%d%.]+)")
		self.debugLineColors.segment.segmentLine = {tonumber(r), tonumber(g), tonumber(b), tonumber(a)}
	end

	if pointStr ~= nil then
		local r,g,b,a = pointStr:match("([%d%.]+) ([%d%.]+) ([%d%.]+) ([%d%.]+)")
		self.debugLineColors.segment.segmentPoint = {tonumber(r), tonumber(g), tonumber(b), tonumber(a)}
	end

    local valuesKey = mapKey .. ".values"
    self.settings.numCutsOfCuts = xmlFile:getInt(valuesKey .. "#numOfCuts") or self.settings.numCutsOfCuts
    self.settings.powerLineRadius = xmlFile:getFloat(valuesKey .. "#powerLineRadius") or self.settings.powerLineRadius
    self.settings.saggingVariationMin = xmlFile:getInt(valuesKey .. "#saggingVariationMin") or self.settings.saggingVariationMin
    self.settings.saggingVariationMax = xmlFile:getInt(valuesKey .. "#saggingVariationMax") or self.settings.saggingVariationMax

    xmlFile:delete()
end

function PowerlineGenerator:openWindowGuide()
	local language = self:getEditorLanguage()
    
	local windowRowSizer = UIRowLayoutSizer.new()
    local window = UIWindow.new(windowRowSizer, "GUIDE - Powerline Generator by Aslan", false, false)

    local bgSizer = UIRowLayoutSizer.new()
    UIPanel.new(windowRowSizer, bgSizer, -1, -1, 430, 500, BorderDirection.NONE, 0, 1, true)

    local uiBorderSizer = UIRowLayoutSizer.new()
    local panel = UIPanel.new(bgSizer, uiBorderSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
    -- panel:setBackgroundColor(1, 1, 1, 1)

    local rowSizerElements = UIRowLayoutSizer.new()
    UIPanel.new(uiBorderSizer, rowSizerElements, -1, -1, -1, -1, BorderDirection.ALL, 15, 1)

	if language == 0 then -- EN
		UILabel.new(rowSizerElements, "This tool automatically generates power lines between defined")
		UILabel.new(rowSizerElements, "connection points (TransformGroups) in the scene graph.")
		UILabel.new(rowSizerElements, "The lines are generated as a separate mesh and stored under")
		UILabel.new(rowSizerElements, "'powerlineMeshes'.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Basic Scene Graph Structure:"):setBold(true)
		UILabel.new(rowSizerElements, "   [MainGroup]")
		UILabel.new(rowSizerElements, "    ├─ segments")
		UILabel.new(rowSizerElements, "    │   ├─ segment01")
		UILabel.new(rowSizerElements, "    │   └─ segment02")
		UILabel.new(rowSizerElements, "    ├─ crossings")
		UILabel.new(rowSizerElements, "    │   ├─ crossing01")
		UILabel.new(rowSizerElements, "    │   └─ crossing02")
		UILabel.new(rowSizerElements, "    ├─ powerlineMeshes")
		UILabel.new(rowSizerElements, "    │    ├─ segments")
		UILabel.new(rowSizerElements, "    │    └─ crossings")
		UILabel.new(rowSizerElements, "    └─ objects")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "The groups 'segments' and 'crossings' are essential")
		UILabel.new(rowSizerElements, "for generating powerlines.")
		UILabel.new(rowSizerElements, "The generated powerline meshes are automatically")
		UILabel.new(rowSizerElements, "imported and stored inside 'powerlineMeshes'")
		UILabel.new(rowSizerElements, "after creation.")
		UILabel.new(rowSizerElements, "The 'objects' group can contain additional objects")
		UILabel.new(rowSizerElements, "that serve as decorative elements related to the")
		UILabel.new(rowSizerElements, "powerline infrastructure.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Segments (linear connections):"):setBold(true)
		UILabel.new(rowSizerElements, "A segment consists of multiple objects")
		UILabel.new(rowSizerElements, "arranged sequentially in the scene graph.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Important:")
		UILabel.new(rowSizerElements, "Each object must contain a TransformGroup named")
		UILabel.new(rowSizerElements, "'powerLineNodes'.")
		UILabel.new(rowSizerElements, "Inside this group are the connection points.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Example:")
		UILabel.new(rowSizerElements, "   segments")
		UILabel.new(rowSizerElements, "   └─ segment01")
		UILabel.new(rowSizerElements, "        ├─ [Object01]")
		UILabel.new(rowSizerElements, "        │  ├─ vis")
		UILabel.new(rowSizerElements, "        │  ├─ col")
		UILabel.new(rowSizerElements, "        │  └─ powerLineNodes")
		UILabel.new(rowSizerElements, "        │      └─ 01")
		UILabel.new(rowSizerElements, "        │      └─ 02")
		UILabel.new(rowSizerElements, "        └─ [Object02]")
		UILabel.new(rowSizerElements, "            ├─ vis")
		UILabel.new(rowSizerElements, "            ├─ col")
		UILabel.new(rowSizerElements, "            └─ powerLineNodes")
		UILabel.new(rowSizerElements, "                └─ 01")
		UILabel.new(rowSizerElements, "                └─ 02")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Connections are always created as follows:")
		UILabel.new(rowSizerElements, "Object 1 → Object 2")
		UILabel.new(rowSizerElements, "Object 2 → Object 3")
		UILabel.new(rowSizerElements, "etc.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Connection points are matched by index (1→1, 2→2, 3→3).")
		UILabel.new(rowSizerElements, "Two optional prefixes are available: 'start_'")
		UILabel.new(rowSizerElements, "and 'end_'.")
		UILabel.new(rowSizerElements, "They can be used when an object has cable entry")
		UILabel.new(rowSizerElements, "and exit points at different positions.")
		UILabel.new(rowSizerElements, "Without a prefix, a node acts as both")
		UILabel.new(rowSizerElements, "entry and exit point.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Crossings (hierarchical connections):"):setBold(true)
		UILabel.new(rowSizerElements, "Crossings work in a tree-like hierarchy.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Example:")
		UILabel.new(rowSizerElements, "   crossing01")
		UILabel.new(rowSizerElements, "    ├─ point01")
		UILabel.new(rowSizerElements, "    │   ├─ point01_01")
		UILabel.new(rowSizerElements, "    │   └─ point01_02")
		UILabel.new(rowSizerElements, "    └─ point02")
		UILabel.new(rowSizerElements, "        └─ point02_01")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Connections are always Parent → Child.")
		UILabel.new(rowSizerElements, "Siblings (e.g. point01 and point02)")
		UILabel.new(rowSizerElements, "are NOT connected.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "The hierarchy fully defines the connection structure.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Settings and UserAttributes:"):setBold(true)
		UILabel.new(rowSizerElements, "Each segment or crossing group has its own")
		UILabel.new(rowSizerElements, "UserAttributes:")
		UILabel.new(rowSizerElements, "• useCustomValues")
		UILabel.new(rowSizerElements, "• numOfCuts")
		UILabel.new(rowSizerElements, "• powerLineRadius")
		UILabel.new(rowSizerElements, "• saggingMin")
		UILabel.new(rowSizerElements, "• saggingMax")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Before generation, the current global UI values")
		UILabel.new(rowSizerElements, "are automatically applied to the groups")
		UILabel.new(rowSizerElements, "if 'useCustomValues' is disabled.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "If 'useCustomValues' is enabled,")
		UILabel.new(rowSizerElements, "the group's stored parameters remain unchanged.")
		UILabel.new(rowSizerElements, "This allows individual settings per group.")
	elseif language == 1 then -- DE
		UILabel.new(rowSizerElements, "Dieses Tool erzeugt automatisch Stromleitungen zwischen definierten")
		UILabel.new(rowSizerElements, "Verbindungspunkten (TransformGroups) im Scenegraph.")
		UILabel.new(rowSizerElements, "Die Leitungen werden als eigenes Mesh generiert und unter")
		UILabel.new(rowSizerElements, "'powerlineMeshes' gespeichert.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Grundstruktur im Szenegraph:"):setBold(true)
		UILabel.new(rowSizerElements, "   [MainGroup]")
		UILabel.new(rowSizerElements, "    ├─ segments")
		UILabel.new(rowSizerElements, "    │   ├─ segment01")
		UILabel.new(rowSizerElements, "    │   └─ segment02")
		UILabel.new(rowSizerElements, "    ├─ crossings")
		UILabel.new(rowSizerElements, "    │   ├─ crossing01")
		UILabel.new(rowSizerElements, "    │   └─ crossing02")
		UILabel.new(rowSizerElements, "    ├─ powerlineMeshes")
		UILabel.new(rowSizerElements, "    │    ├─ segments")
		UILabel.new(rowSizerElements, "    │    └─ crossings")
		UILabel.new(rowSizerElements, "    └─ objects")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Die Gruppen 'segments' und 'crossings' sind essenziell")
		UILabel.new(rowSizerElements, "für die Generierung der Powerlines.")
		UILabel.new(rowSizerElements, "In 'powerlineMeshes' werden die erzeugten Powerline-")
		UILabel.new(rowSizerElements, "Meshes nach der Generierung automatisch importiert.")
		UILabel.new(rowSizerElements, "In 'objects' können zusätzliche Objekte abgelegt")
		UILabel.new(rowSizerElements, "werden, die als dekorative Elemente im Zusammenhang")
		UILabel.new(rowSizerElements, "mit der Powerline-Infrastruktur dienen.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Segments (lineare Verbindungen):"):setBold(true)
		UILabel.new(rowSizerElements, "Ein Segment besteht aus mehreren Objekten,")
		UILabel.new(rowSizerElements, "die hintereinander im Szenegraph liegen.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Wichtig:")
		UILabel.new(rowSizerElements, "Jedes Objekt muss eine TransformGroup mit dem Namen")
		UILabel.new(rowSizerElements, "'powerLineNodes' enthalten.")
		UILabel.new(rowSizerElements, "Innerhalb dieser Gruppe befinden sich die Verbindungspunkte.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Beispiel:")
		UILabel.new(rowSizerElements, "   segments")
		UILabel.new(rowSizerElements, "   └─ segment01")
		UILabel.new(rowSizerElements, "        ├─ [Object01]")
		UILabel.new(rowSizerElements, "        │  ├─ vis")
		UILabel.new(rowSizerElements, "        │  ├─ col")
		UILabel.new(rowSizerElements, "        │  └─ powerLineNodes")
		UILabel.new(rowSizerElements, "        │      └─ 01")
		UILabel.new(rowSizerElements, "        │      └─ 02")
		UILabel.new(rowSizerElements, "        └─ [Object02]")
		UILabel.new(rowSizerElements, "            ├─ vis")
		UILabel.new(rowSizerElements, "            ├─ col")
		UILabel.new(rowSizerElements, "            └─ powerLineNodes")
		UILabel.new(rowSizerElements, "                └─ 01")
		UILabel.new(rowSizerElements, "                └─ 02")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Verbindung erfolgt immer:")
		UILabel.new(rowSizerElements, "Objekt 1 → Objekt 2")
		UILabel.new(rowSizerElements, "Objekt 2 → Objekt 3")
		UILabel.new(rowSizerElements, "usw.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Die Verbindungspunkte werden indexbasiert verbunden.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Zusätzlich stehen die optionalen Präfixe 'start_'")
		UILabel.new(rowSizerElements, "und 'end_' zur Verfügung.")
		UILabel.new(rowSizerElements, "Diese können verwendet werden, wenn sich die")
		UILabel.new(rowSizerElements, "Kabeleingänge und -ausgänge eines Objekts an")
		UILabel.new(rowSizerElements, "unterschiedlichen Positionen befinden.")
		UILabel.new(rowSizerElements, "Ohne Präfix fungiert ein Node gleichzeitig")
		UILabel.new(rowSizerElements, "als Eingang und Ausgang.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Crossings (hierarchische Verbindungen):"):setBold(true)
		UILabel.new(rowSizerElements, "Crossings funktionieren baumartig über die Hierarchie.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Beispiel:")
		UILabel.new(rowSizerElements, "   crossings")
		UILabel.new(rowSizerElements, "   └─ crossing01")
		UILabel.new(rowSizerElements, "       ├─ point01")
		UILabel.new(rowSizerElements, "       │   ├─ point01_01")
		UILabel.new(rowSizerElements, "       │   │   └─ point01_01_01")
		UILabel.new(rowSizerElements, "       │   └─ point01_02")
		UILabel.new(rowSizerElements, "       └─ point02")
		UILabel.new(rowSizerElements, "           └─ point02_01")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Verbindungen entstehen immer Parent → Child.")
		UILabel.new(rowSizerElements, "Geschwister (z.B. point01 und point02)")
		UILabel.new(rowSizerElements, "werden NICHT miteinander verbunden.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Die Hierarchie bestimmt vollständig die Verbindungsstruktur.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Einstellungen und UserAttributes:"):setBold(true)
		UILabel.new(rowSizerElements, "Jede Segment- oder Crossing-Gruppe verfügt")
		UILabel.new(rowSizerElements, "über eigene UserAttributes:")
		UILabel.new(rowSizerElements, "• useCustomValues")
		UILabel.new(rowSizerElements, "• numOfCuts")
		UILabel.new(rowSizerElements, "• powerLineRadius")
		UILabel.new(rowSizerElements, "• saggingMin")
		UILabel.new(rowSizerElements, "• saggingMax")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Vor dem Generieren werden die aktuellen globalen")
		UILabel.new(rowSizerElements, "UI-Werte automatisch in die Gruppen übernommen,")
		UILabel.new(rowSizerElements, "sofern 'useCustomValues' deaktiviert ist.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Ist 'useCustomValues' aktiviert, bleiben die, in der")
		UILabel.new(rowSizerElements, "Gruppe gespeicherten Parameter unverändert.")
		UILabel.new(rowSizerElements, "Dadurch sind individuelle Einstellungen pro Gruppe möglich.")
	elseif language == 2 then -- PL
		UILabel.new(rowSizerElements, "To narzędzie automatycznie generuje linie energetyczne między")
		UILabel.new(rowSizerElements, "zdefiniowanymi punktami połączeń (TransformGroups) w hierarchii sceny.")
		UILabel.new(rowSizerElements, "Linie są tworzone jako osobny mesh i zapisywane w")
		UILabel.new(rowSizerElements, "'powerlineMeshes'.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Podstawowa struktura w hierarchii sceny:"):setBold(true)
		UILabel.new(rowSizerElements, "   [MainGroup]")
		UILabel.new(rowSizerElements, "    ├─ segments")
		UILabel.new(rowSizerElements, "    │   ├─ segment01")
		UILabel.new(rowSizerElements, "    │   └─ segment02")
		UILabel.new(rowSizerElements, "    ├─ crossings")
		UILabel.new(rowSizerElements, "    │   ├─ crossing01")
		UILabel.new(rowSizerElements, "    │   └─ crossing02")
		UILabel.new(rowSizerElements, "    ├─ powerlineMeshes")
		UILabel.new(rowSizerElements, "    │    ├─ segments")
		UILabel.new(rowSizerElements, "    │    └─ crossings")
		UILabel.new(rowSizerElements, "    └─ objects")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Grupy 'segments' i 'crossings' są kluczowe")
		UILabel.new(rowSizerElements, "dla generowania linii energetycznych.")
		UILabel.new(rowSizerElements, "Wygenerowane siatki linii są automatycznie")
		UILabel.new(rowSizerElements, "importowane i zapisywane w grupie")
		UILabel.new(rowSizerElements, "'powerlineMeshes' po ich utworzeniu.")
		UILabel.new(rowSizerElements, "Grupa 'objects' może zawierać dodatkowe obiekty,")
		UILabel.new(rowSizerElements, "które służą jako elementy dekoracyjne związane")
		UILabel.new(rowSizerElements, "z infrastrukturą linii energetycznych.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Segments (połączenia liniowe):"):setBold(true)
		UILabel.new(rowSizerElements, "Segment składa się z kilku obiektów")
		UILabel.new(rowSizerElements, "ułożonych kolejno w hierarchii sceny.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Ważne:")
		UILabel.new(rowSizerElements, "Każdy obiekt musi zawierać TransformGroup o nazwie")
		UILabel.new(rowSizerElements, "'powerLineNodes'.")
		UILabel.new(rowSizerElements, "W tej grupie znajdują się punkty połączeń.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Przykład:")
		UILabel.new(rowSizerElements, "   segments")
		UILabel.new(rowSizerElements, "   └─ segment01")
		UILabel.new(rowSizerElements, "        ├─ [Object01]")
		UILabel.new(rowSizerElements, "        │  ├─ vis")
		UILabel.new(rowSizerElements, "        │  ├─ col")
		UILabel.new(rowSizerElements, "        │  └─ powerLineNodes")
		UILabel.new(rowSizerElements, "        │      └─ 01")
		UILabel.new(rowSizerElements, "        │      └─ 02")
		UILabel.new(rowSizerElements, "        └─ [Object02]")
		UILabel.new(rowSizerElements, "            ├─ vis")
		UILabel.new(rowSizerElements, "            ├─ col")
		UILabel.new(rowSizerElements, "            └─ powerLineNodes")
		UILabel.new(rowSizerElements, "                └─ 01")
		UILabel.new(rowSizerElements, "                └─ 02")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Połączenia są tworzone zawsze w kolejności:")
		UILabel.new(rowSizerElements, "Obiekt 1 → Obiekt 2")
		UILabel.new(rowSizerElements, "Obiekt 2 → Obiekt 3")
		UILabel.new(rowSizerElements, "itd.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Punkty połączeń są łączone według indeksu (1→1, 2→2, 3→3).")
		UILabel.new(rowSizerElements, "Dostępne są dwa opcjonalne prefiksy: 'start_'")
		UILabel.new(rowSizerElements, "oraz 'end_'.")
		UILabel.new(rowSizerElements, "Można ich używać, gdy punkty wejścia i wyjścia")
		UILabel.new(rowSizerElements, "kabla w obiekcie znajdują się w różnych miejscach.")
		UILabel.new(rowSizerElements, "Bez prefiksu węzeł działa jednocześnie")
		UILabel.new(rowSizerElements, "jako punkt wejścia i wyjścia.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Crossings (połączenia hierarchiczne):"):setBold(true)
		UILabel.new(rowSizerElements, "Crossings działają w sposób drzewiasty zgodnie z hierarchią.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Przykład:")
		UILabel.new(rowSizerElements, "   crossing01")
		UILabel.new(rowSizerElements, "    ├─ point01")
		UILabel.new(rowSizerElements, "    │   ├─ point01_01")
		UILabel.new(rowSizerElements, "    │   └─ point01_02")
		UILabel.new(rowSizerElements, "    └─ point02")
		UILabel.new(rowSizerElements, "        └─ point02_01")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Połączenia są zawsze tworzone jako Parent → Child.")
		UILabel.new(rowSizerElements, "Elementy na tym samym poziomie (np. point01 i point02)")
		UILabel.new(rowSizerElements, "NIE są ze sobą łączone.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Hierarchia całkowicie określa strukturę połączeń.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Ustawienia i UserAttributes:"):setBold(true)
		UILabel.new(rowSizerElements, "Każda grupa segmentu lub crossing posiada własne")
		UILabel.new(rowSizerElements, "UserAttributes:")
		UILabel.new(rowSizerElements, "• useCustomValues")
		UILabel.new(rowSizerElements, "• numOfCuts")
		UILabel.new(rowSizerElements, "• powerLineRadius")
		UILabel.new(rowSizerElements, "• saggingMin")
		UILabel.new(rowSizerElements, "• saggingMax")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Przed generowaniem aktualne globalne wartości z UI")
		UILabel.new(rowSizerElements, "są automatycznie zapisywane do grup,")
		UILabel.new(rowSizerElements, "jeśli 'useCustomValues' jest wyłączone.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Jeśli 'useCustomValues' jest włączone,")
		UILabel.new(rowSizerElements, "zapisane parametry grupy pozostają bez zmian.")
		UILabel.new(rowSizerElements, "Pozwala to na indywidualne ustawienia dla każdej grupy.")
	elseif language == 3 then -- FR
		UILabel.new(rowSizerElements, "Cet outil génère automatiquement des lignes électriques entre")
		UILabel.new(rowSizerElements, "des points de connexion définis (TransformGroups) dans la hiérarchie de la scène.")
		UILabel.new(rowSizerElements, "Les lignes sont générées comme un mesh séparé et enregistrées sous")
		UILabel.new(rowSizerElements, "'powerlineMeshes'.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Structure de base dans la hiérarchie de la scène :"):setBold(true)
		UILabel.new(rowSizerElements, "   [MainGroup]")
		UILabel.new(rowSizerElements, "    ├─ segments")
		UILabel.new(rowSizerElements, "    │   ├─ segment01")
		UILabel.new(rowSizerElements, "    │   └─ segment02")
		UILabel.new(rowSizerElements, "    ├─ crossings")
		UILabel.new(rowSizerElements, "    │   ├─ crossing01")
		UILabel.new(rowSizerElements, "    │   └─ crossing02")
		UILabel.new(rowSizerElements, "    ├─ powerlineMeshes")
		UILabel.new(rowSizerElements, "    │    ├─ segments")
		UILabel.new(rowSizerElements, "    │    └─ crossings")
		UILabel.new(rowSizerElements, "    └─ objects")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Les groupes 'segments' et 'crossings' sont essentiels")
		UILabel.new(rowSizerElements, "pour la génération des lignes électriques.")
		UILabel.new(rowSizerElements, "Les maillages générés sont automatiquement")
		UILabel.new(rowSizerElements, "importés et enregistrés dans le groupe")
		UILabel.new(rowSizerElements, "'powerlineMeshes' après leur création.")
		UILabel.new(rowSizerElements, "Le groupe 'objects' peut contenir des objets")
		UILabel.new(rowSizerElements, "supplémentaires utilisés comme éléments décoratifs")
		UILabel.new(rowSizerElements, "liés à l’infrastructure des lignes électriques.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Segments (connexions linéaires) :"):setBold(true)
		UILabel.new(rowSizerElements, "Un segment se compose de plusieurs objets")
		UILabel.new(rowSizerElements, "placés successivement dans la hiérarchie de la scène.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Important :")
		UILabel.new(rowSizerElements, "Chaque objet doit contenir un TransformGroup nommé")
		UILabel.new(rowSizerElements, "'powerLineNodes'.")
		UILabel.new(rowSizerElements, "Ce groupe contient les points de connexion.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Exemple :")
		UILabel.new(rowSizerElements, "   segments")
		UILabel.new(rowSizerElements, "   └─ segment01")
		UILabel.new(rowSizerElements, "        ├─ [Object01]")
		UILabel.new(rowSizerElements, "        │  ├─ vis")
		UILabel.new(rowSizerElements, "        │  ├─ col")
		UILabel.new(rowSizerElements, "        │  └─ powerLineNodes")
		UILabel.new(rowSizerElements, "        │      └─ 01")
		UILabel.new(rowSizerElements, "        │      └─ 02")
		UILabel.new(rowSizerElements, "        └─ [Object02]")
		UILabel.new(rowSizerElements, "            ├─ vis")
		UILabel.new(rowSizerElements, "            ├─ col")
		UILabel.new(rowSizerElements, "            └─ powerLineNodes")
		UILabel.new(rowSizerElements, "                └─ 01")
		UILabel.new(rowSizerElements, "                └─ 02")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Les connexions sont toujours créées comme suit :")
		UILabel.new(rowSizerElements, "Objet 1 → Objet 2")
		UILabel.new(rowSizerElements, "Objet 2 → Objet 3")
		UILabel.new(rowSizerElements, "etc.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Les points de connexion sont associés par index (1→1, 2→2, 3→3).")
		UILabel.new(rowSizerElements, "Deux préfixes optionnels sont disponibles :")
		UILabel.new(rowSizerElements, "'start_' et 'end_'.")
		UILabel.new(rowSizerElements, "Ils peuvent être utilisés lorsque les points")
		UILabel.new(rowSizerElements, "d’entrée et de sortie des câbles se trouvent")
		UILabel.new(rowSizerElements, "à des positions différentes.")
		UILabel.new(rowSizerElements, "Sans préfixe, un nœud agit à la fois")
		UILabel.new(rowSizerElements, "comme point d’entrée et de sortie.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Crossings (connexions hiérarchiques) :"):setBold(true)
		UILabel.new(rowSizerElements, "Les crossings fonctionnent selon une structure arborescente.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Exemple :")
		UILabel.new(rowSizerElements, "   crossing01")
		UILabel.new(rowSizerElements, "    ├─ point01")
		UILabel.new(rowSizerElements, "    │   ├─ point01_01")
		UILabel.new(rowSizerElements, "    │   └─ point01_02")
		UILabel.new(rowSizerElements, "    └─ point02")
		UILabel.new(rowSizerElements, "        └─ point02_01")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Les connexions sont toujours de type Parent → Child.")
		UILabel.new(rowSizerElements, "Les éléments au même niveau (ex. point01 et point02)")
		UILabel.new(rowSizerElements, "ne sont PAS connectés entre eux.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "La hiérarchie définit entièrement la structure des connexions.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "-------------------------------------------------")
		UILabel.new(rowSizerElements, "Paramètres / UserAttributes :"):setBold(true)
		UILabel.new(rowSizerElements, "Chaque groupe segment ou crossing possède ses propres")
		UILabel.new(rowSizerElements, "UserAttributes :")
		UILabel.new(rowSizerElements, "• useCustomValues")
		UILabel.new(rowSizerElements, "• numOfCuts")
		UILabel.new(rowSizerElements, "• powerLineRadius")
		UILabel.new(rowSizerElements, "• saggingMin")
		UILabel.new(rowSizerElements, "• saggingMax")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Avant la génération, les valeurs globales actuelles de l'UI")
		UILabel.new(rowSizerElements, "sont automatiquement appliquées aux groupes")
		UILabel.new(rowSizerElements, "si 'useCustomValues' est désactivé.")
		UILabel.new(rowSizerElements, "")
		UILabel.new(rowSizerElements, "Si 'useCustomValues' est activé,")
		UILabel.new(rowSizerElements, "les paramètres enregistrés dans le groupe restent inchangés.")
		UILabel.new(rowSizerElements, "Cela permet des réglages individuels par groupe.")
	end

    window:setOnCloseCallback(function() self.windowGuide = nil end)

    window:fit()
    window:refresh()
    window:showWindow()

    return window
end

PowerlineGenerator.new()