-- Author:Aslan
-- Name:PlaceableImporter
-- Namespace: local
-- Description:
-- Icon:iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAdpJREFUOI21kr1rk1EUxn/nzZsQIYNTyCBUJJi8i92cFKlkS7V7jNA9g4vp0D9ASvI/CGLGQoeaRagtdA2FCuGFNkMQGohgwI8Kyf04DmlDG4gUwbPcy+WcH895ngv/s1rwugX+X4f1e6mkg0JBW6CL+oIFw/752hokk+qAx4UCiyAy//BzfV0xBh2Pcd0u7TimHEV8cw6vyv3TU1kI+FWrKcZgj450OByK7O2p9146xSLlKNKv1uJBoiuQ4FLy+caGkkphDg/50OlIYn8f773kcjkenpzQjmPJhqE4VT7n8/6agvPNTU8iwWR7m3Ycy6N+XzOZjACqqsLF5WM2SzmKpG+Mdns9qYKEAHjPZGdHJgcHPJlMSCaTYq1FderbxSkrZ2f8Bu6WSgT5PPR6hAA7W1tyXK/zyhhEBGPMTGE6nabRaMx8qtVqvFldleVmE2AKqILUQa21+u79WxERFRF5+WJdnXMi956hqP44n2CtFUCrF/6FV1MwxkgYhjN3lpaWGAwGfDr6MlNkzJ1rsc8DkEAQRMbjMYA451i5fTwz3NplADcPSDJdgSAIBND0rTQAo9GISqVymQjGGHZ3d58CCcBdfogUUKzX68fcoJrN5gMgBuxN+v9afwDko+FPXNsnygAAAABJRU5ErkJgggBcAEMAqK5DAUkLAIBcAFIARQBHAEkAUwBUAFIAWQBcAFUAUwBFAFIAXABTAC0AMQAtADUALQAyADEALQAxADkAMgA3ADMAMwA5ADIAMwAtADEAMAAyADMAOQAzADYAMgAxADQALQAyADAANAA2ADIANwA4ADMAOQAxAC0AMQAwADAAMQBfAEMAbABhAHMAcwBlAHMAXABDAEwAUwBJAEQAXAB7ADkAYQBjADkAZgBiAGUAMQAtAGUAMABhADIALQA0AGEAZAA2AC0AYgA0AGUAZQAtAGUAMgAxADIAMAAxADMAZQBhADkAMQA3AH0AXABJAG4AUAByAG8AYwBTAGUAcgB2AGUAcgAzADIAAAAAAG1sWOJMLgAAAHYDAAAAAAYAAAAAAAAAAAAAAAAAAADJPd4AYgBpAG4AAAASAE4AMQAAAAAAT1iUWRAAZGF0YQAAOgAJAAQA774HVzZtbFjiTC4AAAB8AwAAAAAKAAAAAAAAAAAAAAAAAAAAv33kAGQAYQB0AGEAAAAUAE4AMQAAAAAAaFg8XxAAbWFwcwAAOgAJAAQA774HV1VtbFjjTC4AAADFJAUAAAAFAAAAAAAAAAAAAAAAAAAA3hGOAG0AYQBwAHMAAAAUAFAAMQ==
-- Hide: no
-- AlwaysLoaded: no

source("editorUtils.lua")
source("ui/ProgressDialog.lua")
source("ui/ProgressDialog.lua")
local gamePath = EditorUtils.getGameBasePath()
if gamePath == nil then
    return
end

source(gamePath .. "dataS/scripts/std.lua")
source(gamePath .. "dataS/scripts/shared/class.lua")
source(gamePath .. "dataS/scripts/misc/Logging.lua")
source(gamePath .. "dataS/scripts/xml/XMLFile.lua")
source(gamePath .. "dataS/scripts/xml/XMLManager.lua")

PlaceableImporter = {}
PlaceableImporter.WINDOW_WIDTH = 320
PlaceableImporter.WINDOW_HEIGHT = -1
PlaceableImporter.NODE_NAME = "placeablePlaceholders"
PlaceableImporter.SETTINGS_PATH_EDITOR = getAppDataPath() .. "editor.xml"
PlaceableImporter.SETTINGS_PATH = getAppDataPath() .. "placeableImporterSettings.xml"
PlaceableImporter.MOD_PLACEHOLDER_OBJECT_PATH = "modPlaceholders/"

PlaceableImporter.currentLang = 0
PlaceableImporter.langText = {
	[0] = { -- EN
		selectModDescFile = "Select modDesc.xml:",
		useCustomPlaceable = "Use custom placeable.xml file:",
		loadWithExcludeFromSave = "Load placeables with 'excludeFromSave' flag",
		loadWithRemoveScript = "Use 'removePlaceablePlaceholders.lua' Script",
		importPlaceables    = "Insert placeables",
		updateTranslations    = "Update Object transforms to XML",
		countPlaceables     = "Number of placeables",
		countFences         = "Fences",
		countFencesSegments = "Fence segments",
		titleModList        = "%d mods in selected placeable.xml",
		printReloadPlaceableInfos = "[PlaceableImporter] Placeable information reloaded!",

		infoBoxText = {
			loadingInfo = {
				title = "Placeable Loading Modes",
				text = {
					"There are several ways to import and save placeable objects.",
					"If no checkbox is selected, the generated node containing all",
					"loaded objects should be deleted before saving the map,",
					"to avoid visual issues in the game.",
					"",
					"---- ExcludeFromSave ----",
					"Using the 'excludeFromSave' flag prevents objects from being",
					"saved into the I3D file and they only exist while the",
					"Giants Editor is open.",
					"This is recommended if you rarely modify the map.",
					"",
					"---- RemovePlaceablePlaceholders Script ----",
					"Alternatively, the RemovePlaceablePlaceholders script can",
					"be used. All objects are permanently stored in the map,",
					"and a script is generated which removes the node",
					"automatically when the game loads.",
					"This method is recommended for intensive map development."
				}
			},
			useMods = {
				title = "Mods as Placeables",
				text = {
					"To import objects and fences from mods as",
					"placeables, the script creates a new folder on",
					"first start next to the [MAP].i3d file:",
					"",
					"'modPlaceholders'",
					"",
					"All mods shown in the list must be extracted",
					"into this folder.",
					"",
					"If a mod name is displayed in red, at least",
					"one required XML file is missing."
				}
			}
		}
	},
	[1] = { -- DE
		selectModDescFile = "modDesc.xml auswählen:",
		useCustomPlaceable = "Benutzerdefinierte placeable.xml-Datei verwenden:",
		loadWithExcludeFromSave = "Placeables mit 'excludeFromSave'-Flag laden",
		loadWithRemoveScript = "'removePlaceablePlaceholders'-Script verwenden",
		importPlaceables = "Placeables einfügen",
		updateTranslations = "Objekt Transforms in XML aktualisieren",
		countPlaceables = "Anzahl Placeables",
		countFences = "Davon Zäune",
		countFencesSegments = "Davon Zaunsegmente",
		titleModList = "%d Mods in ausgewählter Placeable.xml",
		printReloadPlaceableInfos = "[PlaceableImporter] Placeable Infos neu geladen!",

		infoBoxText = {
			loadingInfo = {
				title = "Placeable Ladetypen",
				text = {
					"Es gibt mehrere Möglichkeiten, Objekte zu importieren und zu speichern.",
					"Ohne Auswahl einer Checkbox sollte der erzeugte Node, in den alle",
					"Objekte geladen werden, vor dem Speichern der Karte gelöscht werden,",
					"um visuelle Fehler im Spiel zu vermeiden.",
					"",
					"---- ExcludeFromSave ----",
					"Mit dem 'excludeFromSave'-Flag werden alle Objekte nicht in der I3D",
					"gespeichert und existieren nur, solange der Giants Editor geöffnet ist.",
					"Dies wird empfohlen, wenn nur selten Änderungen an der Karte erfolgen.",
					"",
					"---- RemovePlaceablePlaceholders Script ----",
					"Alternativ kann das RemovePlaceablePlaceholders-Script genutzt werden.",
					"Dabei werden alle Objekte fest in der Map gespeichert und ein Script",
					"wird erzeugt, das im Spiel geladen wird und den erzeugten Node entfernt.",
					"Diese Methode wird empfohlen, wenn intensiv an der Map gearbeitet wird."
				}
			},
			useMods = {
				title = "Mods als Placeables",
				text = {
					"Damit Objekte und Zäune aus Mods als Placeables",
					"importiert werden können, erstellt das Script beim",
					"ersten Start einen neuen Ordner neben der [MAP].i3d:",
					"",
					"'modPlaceholders'",
					"",
					"In diesen Ordner müssen alle Mods entpackt werden,",
					"die in der Liste angezeigt werden.",
					"",
					"Wird ein Modname rot dargestellt, fehlt mindestens",
					"eine erforderliche XML-Datei."
				}
			}
		}
	},
	[2] = { -- PL
		selectModDescFile = "Wybierz modDesc.xml:",
		useCustomPlaceable = "Użyj niestandardowego pliku placeable.xml:",
		loadWithExcludeFromSave = "Wczytaj obiekty z flagą 'excludeFromSave'",
		loadWithRemoveScript = "Użyj skryptu 'removePlaceablePlaceholders'",
		importPlaceables    = "Wstaw placeables",
		updateTranslations = "Aktualizuj transformacje obiektów do XML",
		countPlaceables     = "Liczba placeables",
		countFences         = "Ogrodzenia",
		countFencesSegments = "Segmenty ogrodzeń",
		titleModList        = "%d modów w wybranym placeable.xml",
		printReloadPlaceableInfos = "[PlaceableImporter] Informacje o placeables zostały ponownie załadowane!",

		infoBoxText = {
			loadingInfo = {
				title = "Tryby ładowania obiektów",
				text = {
					"Istnieje kilka sposobów importowania i zapisywania obiektów.",
					"Jeśli żadna opcja nie jest zaznaczona, utworzony węzeł",
					"zawierający wszystkie obiekty powinien zostać usunięty",
					"przed zapisaniem mapy, aby uniknąć błędów wizualnych w grze.",
					"",
					"---- ExcludeFromSave ----",
					"Opcja 'excludeFromSave' powoduje, że obiekty nie są",
					"zapisywane w pliku I3D i istnieją tylko podczas",
					"otwarcia Giants Editora.",
					"Jest to zalecane przy rzadkich zmianach mapy.",
					"",
					"---- RemovePlaceablePlaceholders Script ----",
					"Alternatywnie można użyć skryptu RemovePlaceablePlaceholders.",
					"Wszystkie obiekty są wtedy trwale zapisane w mapie,",
					"a skrypt usunie wygenerowany węzeł podczas",
					"ładowania gry.",
					"Ta metoda jest zalecana przy intensywnej pracy nad mapą."
				}
			},
			useMods = {
				title = "Mody jako placeables",
				text = {
					"Aby importować obiekty i ogrodzenia z modów",
					"jako placeables, skrypt przy pierwszym",
					"uruchomieniu tworzy folder obok pliku [MAP].i3d:",
					"",
					"'modPlaceholders'",
					"",
					"Wszystkie mody widoczne na liście muszą być",
					"rozpakowane do tego folderu.",
					"",
					"Jeśli nazwa moda jest wyświetlana na czerwono,",
					"brakuje co najmniej jednego pliku XML."
				}
			}
		}
	},
	[3] = { -- FR
		selectModDescFile = "Sélectionner modDesc.xml :",
		useCustomPlaceable = "Utiliser un fichier placeable.xml personnalisé :",
		loadWithExcludeFromSave = "Charger les objets avec l'option 'excludeFromSave'",
		loadWithRemoveScript = "Utiliser le script 'removePlaceablePlaceholders'",
		importPlaceables    = "Insérer les placeables",
		updateTranslations = "Maj. transformations objets XML",
		countPlaceables     = "Nombre de placeables",
		countFences         = "Clôtures",
		countFencesSegments = "Segments de clôture",
		titleModList        = "%d mods dans le placeable.xml sélectionné",
		printReloadPlaceableInfos = "[PlaceableImporter] Informations des placeables rechargées !",

		infoBoxText = {
			loadingInfo = {
				title = "Modes de chargement des objets",
				text = {
					"Il existe plusieurs méthodes pour importer et enregistrer",
					"des objets. Si aucune case n'est cochée, le nœud généré",
					"contenant tous les objets chargés doit être supprimé",
					"avant l'enregistrement de la carte afin d'éviter",
					"des erreurs visuelles en jeu.",
					"",
					"---- ExcludeFromSave ----",
					"Avec l'option 'excludeFromSave', les objets ne sont pas",
					"enregistrés dans le fichier I3D et existent uniquement",
					"tant que le Giants Editor est ouvert.",
					"Ceci est recommandé si la carte est modifiée rarement.",
					"",
					"---- RemovePlaceablePlaceholders Script ----",
					"Il est également possible d'utiliser le script",
					"RemovePlaceablePlaceholders. Les objets sont alors",
					"enregistrés définitivement dans la carte et un script",
					"supprime automatiquement le nœud au chargement du jeu.",
					"Cette méthode est recommandée pour un développement intensif."
				}
			},
			useMods = {
				title = "Mods en tant que placeables",
				text = {
					"Pour importer des objets et clôtures de mods",
					"comme placeables, le script crée au premier",
					"lancement un dossier à côté du fichier [MAP].i3d :",
					"",
					"'modPlaceholders'",
					"",
					"Tous les mods affichés dans la liste doivent",
					"être extraits dans ce dossier.",
					"",
					"Si un nom de mod apparaît en rouge, au moins",
					"un fichier XML requis est manquant."
				}
			}
		}
	}
}

function PlaceableImporter.setEditorLanguage()
    if not fileExists(PlaceableImporter.SETTINGS_PATH_EDITOR) then
        return
    end

    local xmlFile = XMLFile.loadIfExists("editorSettings", PlaceableImporter.SETTINGS_PATH_EDITOR)
    if xmlFile == nil then
        return PlaceableImporter.currentLang
    end

    local lang = xmlFile:getInt("editor.language#language")
    xmlFile:delete()

    if lang ~= nil and PlaceableImporter.langText[lang] ~= nil then
        PlaceableImporter.currentLang = lang
    end

    return PlaceableImporter.currentLang
end

local function LANG_TEXT(key, ...)
    if type(key) ~= "string" then
        return key
    end

    local lang = PlaceableImporter.currentLang or 0
    local langTable = PlaceableImporter.langText[lang]
    local fallbackTable = PlaceableImporter.langText[0]

    local value = nil

    if langTable and langTable[key] ~= nil then
        value = langTable[key]
    elseif fallbackTable and fallbackTable[key] ~= nil then
        value = fallbackTable[key]
    else
        value = key
    end

    if select("#", ...) > 0 and type(value) == "string" then
        local ok, formatted = pcall(string.format, value, ...)
        if ok then
            return formatted
        end
        return value
    end

    return value
end

function PlaceableImporter:isMap()
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

function PlaceableImporter.new()
    local self = setmetatable({}, { __index = PlaceableImporter })

    -- Check if a map (terrain) is loaded
    if not self:isMap() then
        printError("[PlaceableImporter] This is not a Map!")
        return
    end

    self.window = nil
	self.mapPath = nil
	
	self.modDescFile = ""
	self.placeablesFile = ""
	self.placeablesFileCustom = ""

    self:setEditorLanguage()
    self:generateUI()
	self:setMapPath()
    self:loadSettings()
	
    self:createModFolder()

    return self
end

function PlaceableImporter:setMapPath()
    local fullPath = getSceneFilename()
    if not fullPath then
        self.mapPath = nil
        return
    end

    self.mapPath = fullPath:match("(.*[/\\])")
    if not self.mapPath then
        self.mapPath = nil
    end
	print(string.format("[PlaceableImporter] mapPath: %s", self.mapPath))
end

function PlaceableImporter:getPlaceableFilePath()
	if self.placeablesFileCustom ~= nil and self.placeablesFileCustom ~= "" then
		return self.placeablesFileCustom
	else
		return self.placeablesFile
	end
	return nil
end

function PlaceableImporter:createModFolder()
	local i3dFilePath = getSceneFilename()
    local basePath = i3dFilePath:match("(.*/)")
    local modFolder = basePath .. PlaceableImporter.MOD_PLACEHOLDER_OBJECT_PATH
    if not folderExists(modFolder) then
        createFolder(modFolder)
        print("[PlaceableImporter] Created folder: " .. modFolder)
    end
end

function PlaceableImporter:convertFileText(path)
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

function PlaceableImporter:generateUI()
    local frameRowSizer = UIRowLayoutSizer.new()
    self.window = UIWindow.new(frameRowSizer, "Placeable Importer by Aslan (v1.1)")

    local borderSizer = UIRowLayoutSizer.new()
    UIPanel.new(frameRowSizer, borderSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)

    local rowSizer = UIRowLayoutSizer.new()
    UIPanel.new(borderSizer, rowSizer, -1, -1, PlaceableImporter.WINDOW_WIDTH, PlaceableImporter.WINDOW_HEIGHT, BorderDirection.ALL, 10, 1)

    UILabel.new(rowSizer, LANG_TEXT("selectModDescFile"))
    local pathRow = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, pathRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    self.uiModDescFileText = UITextArea.new(pathRow, self:convertFileText(self.modDescFile), TextAlignment.LEFT, true, false, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
    UIButton.new(pathRow, "🗁", function() self:selectModDescFile() end, nil, -1, -1, 25, -1)
    self.uiClearModDescFileBtn = UIButton.new(pathRow, "X", function() self:onClearModDesc() end, nil, -1, -1, 25, -1)
	self.uiClearModDescFileBtn:setTextColor(1.0, 0.2, 0.2, 1.0)
	
    local pathRow = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, pathRow)
	self.uiCheckboxUseCustomPlaceableFile = UICheckBox.new(pathRow, LANG_TEXT("useCustomPlaceable"), -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
	self.uiCheckboxUseCustomPlaceableFile:setOnChangeCallback(function(bool)
		self:setUseCustomPlaceableFile(bool)
	end)
	self.uiCheckboxUseCustomPlaceableFile:setEnabled(false)
    local pathRow = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, pathRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    self.uiPlaceableFileText = UITextArea.new(pathRow, self:convertFileText(self.placeablesFile), TextAlignment.LEFT, true, false, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
    self.uiSelectPlaceableXML = UIButton.new(pathRow, "🗁", function() self:selectCustomPlaceableFile() end, nil, -1, -1, 25, -1)
	self.uiSelectPlaceableXML:setEnabled(false)
	
    local onClearModFolder = function()
        self:setModFolder(gamePath)
    end
	
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)

    local pathRow = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, pathRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1)
	self.uiUseExecludeSaveFlag = UICheckBox.new(pathRow, LANG_TEXT("loadWithExcludeFromSave"), -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
	self.uiUseExecludeSaveFlag:setOnChangeCallback(function(bool)
		self:updateUseCheckboxes(self.uiUseExecludeSaveFlag)
	end)
	self.uiUseExecludeSaveFlag:setEnabled(false)
	if PlaceableImporter.currentLang == 0 then
		UIButton.new(pathRow, "i", function() self.InfoBox(PlaceableImporter.langText[0].infoBoxText.loadingInfo.title, PlaceableImporter.langText[0].infoBoxText.loadingInfo.text) end, nil, -1, -1, 25, -1)
	elseif PlaceableImporter.currentLang == 1 then
		UIButton.new(pathRow, "i", function() self.InfoBox(PlaceableImporter.langText[1].infoBoxText.loadingInfo.title, PlaceableImporter.langText[1].infoBoxText.loadingInfo.text) end, nil, -1, -1, 25, -1)
	elseif PlaceableImporter.currentLang == 2 then
		UIButton.new(pathRow, "i", function() self.InfoBox(PlaceableImporter.langText[2].infoBoxText.loadingInfo.title, PlaceableImporter.langText[2].infoBoxText.loadingInfo.text) end, nil, -1, -1, 25, -1)
	elseif PlaceableImporter.currentLang == 3 then
		UIButton.new(pathRow, "i", function() self.InfoBox(PlaceableImporter.langText[3].infoBoxText.loadingInfo.title, PlaceableImporter.langText[3].infoBoxText.loadingInfo.text) end, nil, -1, -1, 25, -1)
	end
	
    local pathRow = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, pathRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1)
	self.uiUseScriptFile = UICheckBox.new(pathRow, LANG_TEXT("loadWithRemoveScript"), -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
	self.uiUseScriptFile:setOnChangeCallback(function(bool)
		self:updateUseCheckboxes(self.uiUseScriptFile)
	end)
	self.uiUseScriptFile:setEnabled(false)
	if PlaceableImporter.currentLang == 0 then
		UIButton.new(pathRow, "i", function() self.InfoBox(PlaceableImporter.langText[0].infoBoxText.loadingInfo.title, PlaceableImporter.langText[0].infoBoxText.loadingInfo.text) end, nil, -1, -1, 25, -1)
	elseif PlaceableImporter.currentLang == 1 then
		UIButton.new(pathRow, "i", function() self.InfoBox(PlaceableImporter.langText[1].infoBoxText.loadingInfo.title, PlaceableImporter.langText[1].infoBoxText.loadingInfo.text) end, nil, -1, -1, 25, -1)
	elseif PlaceableImporter.currentLang == 2 then
		UIButton.new(pathRow, "i", function() self.InfoBox(PlaceableImporter.langText[2].infoBoxText.loadingInfo.title, PlaceableImporter.langText[2].infoBoxText.loadingInfo.text) end, nil, -1, -1, 25, -1)
	elseif PlaceableImporter.currentLang == 3 then
		UIButton.new(pathRow, "i", function() self.InfoBox(PlaceableImporter.langText[3].infoBoxText.loadingInfo.title, PlaceableImporter.langText[3].infoBoxText.loadingInfo.text) end, nil, -1, -1, 25, -1)
	end

    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
	
    self.uiImportBtn = UIButton.new(rowSizer, LANG_TEXT("importPlaceables"), function() self:importPlaceables() end, self, -1, -1, -1, 35, BorderDirection.BOTTOM, 5, 0)
	self.uiImportBtn:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
	
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    self.uiUpdateTranslationBtn = UIButton.new(rowSizer, LANG_TEXT("updateTranslations"), function() self:updateObjectTranslations() end, self, -1, -1, -1, -1, BorderDirection.BOTTOM, 5, 1)
	self.uiUpdateTranslationBtn:setBackgroundColor(1.0, 0.9, 0.53, 1.0)
	
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
	
    local pathRow = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, pathRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UITextArea.new(pathRow, LANG_TEXT("countPlaceables"), TextAlignment.LEFT, true, false, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
    self.uiCountPlaceables = UITextArea.new(pathRow, "",  TextAlignment.CENTER, true, false, -1, -1, 100)
	
    local pathRow = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, pathRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UITextArea.new(pathRow, LANG_TEXT("countFences"), TextAlignment.LEFT, true, false, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
    self.uiCountFence = UITextArea.new(pathRow, "",  TextAlignment.CENTER, true, false, -1, -1, 100)
	
    local pathRow = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, pathRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 10)
    UITextArea.new(pathRow, LANG_TEXT("countFencesSegments"), TextAlignment.LEFT, true, false, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
    self.uiCountFenceSegments = UITextArea.new(pathRow, "",  TextAlignment.CENTER, true, false, -1, -1, 100)
	
    UIHorizontalLine.new(rowSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    local pathRow = UIColumnLayoutSizer.new()
    UIPanel.new(rowSizer, pathRow, -1, -1, -1, -1, BorderDirection.BOTTOM, 5)
    self.uiTitleModList = UILabel.new(pathRow, LANG_TEXT("titleModList", 0), false, TextAlignment.LEFT, VerticalAlignment.CENTER, -1, -1, -1, -1, BorderDirection.RIGHT, 5, 1)
	self.uiModListReloadBtn = UIButton.new(pathRow, "↻", function() self:setUIPlaceableInfos() print(LANG_TEXT("printReloadPlaceableInfos"))end, nil, -1, -1, 25, -1)
	self.uiModListReloadBtn:setToolTip("Reload ModList")
	if PlaceableImporter.currentLang == 0 then
		UIButton.new(pathRow, "i", function() self.InfoBox(PlaceableImporter.langText[0].infoBoxText.useMods.title, PlaceableImporter.langText[0].infoBoxText.useMods.text) end, nil, -1, -1, 25, -1)
	elseif PlaceableImporter.currentLang == 1 then
		UIButton.new(pathRow, "i", function() self.InfoBox(PlaceableImporter.langText[1].infoBoxText.useMods.title, PlaceableImporter.langText[1].infoBoxText.useMods.text) end, nil, -1, -1, 25, -1)
	elseif PlaceableImporter.currentLang == 2 then
		UIButton.new(pathRow, "i", function() self.InfoBox(PlaceableImporter.langText[2].infoBoxText.useMods.title, PlaceableImporter.langText[2].infoBoxText.useMods.text) end, nil, -1, -1, 25, -1)
	elseif PlaceableImporter.currentLang == 3 then
		UIButton.new(pathRow, "i", function() self.InfoBox(PlaceableImporter.langText[3].infoBoxText.useMods.title, PlaceableImporter.langText[3].infoBoxText.useMods.text) end, nil, -1, -1, 25, -1)
	end
	self.placeableModList = UIList.new(rowSizer, -1, -1, -1, 200)

    self.window:showWindow()
	self.window:setOnCloseCallback(function() self:saveSettings() end)
end

function PlaceableImporter:setUseCustomPlaceableFile(bool)
	self.uiSelectPlaceableXML:setEnabled(bool)
	if bool == true then
		self.uiSelectPlaceableXML:setBackgroundColor(0.6, 1.0, 0.55, 1.0)
	else
		self.uiSelectPlaceableXML:setBackgroundColor(1.0, 1.0, 1.0, 1.0)
		self.placeablesFileCustom = ""
		self.uiPlaceableFileText:setValue(self:convertFileText(self.placeablesFile))
		self:setUIPlaceableInfos()
	end
end

function PlaceableImporter:updateUseCheckboxes(checkedBox)
	if checkedBox == self.uiUseExecludeSaveFlag then
		if self.uiUseScriptFile:getValue() == true then
			self.uiUseScriptFile:setValue(false)
		end
	elseif  checkedBox == self.uiUseScriptFile then
		if self.uiUseExecludeSaveFlag:getValue() == true then
			self.uiUseExecludeSaveFlag:setValue(false)
		end
	end
end

function PlaceableImporter:loadXMLForValidation(xmlPath)
    if not fileExists(xmlPath) then
        return nil
    end

    local xmlFile = XMLFile.loadIfExists("xmlValidation", xmlPath)
    if xmlFile == nil then
        print("[PlaceableImporter] ERROR: Failed to load XML file:", xmlPath)
        return nil
    end

    return xmlFile
end

function PlaceableImporter:selectModDescFile(filePath)
	if filePath == nil then
		filePath = openFileDialog("", "modDesc XML File|*.xml")
		if not filePath or filePath == "" then
			return
		end
	end

    local xmlFile = self:loadXMLForValidation(filePath)
    if not xmlFile then
        return
    end

    if not xmlFile:hasProperty("modDesc") then
        print("[PlaceableImporter] ERROR: Selected file is not a valid modDesc.xml")
        xmlFile:delete()
        return
    end

    local descVersion = xmlFile:getInt("modDesc#descVersion")
    if not descVersion then
        print("[PlaceableImporter] ERROR: modDesc.xml has no descVersion attribute")
        xmlFile:delete()
        return
    end

    local defaultPlaceables = xmlFile:getString("modDesc.maps.map(0)#defaultPlaceablesXMLFilename")

    xmlFile:delete()

    if not defaultPlaceables or defaultPlaceables == "" then
        print("[PlaceableImporter] ERROR: No defaultPlaceablesXMLFilename found in modDesc")
        return
    end
    local modRoot = filePath:gsub("[^/\\]+$", "")
    local placeablesFullPath = modRoot .. defaultPlaceables
	
    if not fileExists(placeablesFullPath) then
        print("[PlaceableImporter] ERROR: Default placeables.xml not found:", placeablesFullPath)
        return
    end

    self.modDescFile = filePath
    self.placeablesFile = placeablesFullPath

    -- UI aktualisieren
    self.uiModDescFileText:setValue(self:convertFileText(filePath))
    self.uiPlaceableFileText:setValue(self:convertFileText(placeablesFullPath))
	
	self.uiCheckboxUseCustomPlaceableFile:setEnabled(true)
	self.uiUseExecludeSaveFlag:setEnabled(true)
	self.uiUseScriptFile:setEnabled(true)
	
    self:setUIPlaceableInfos()
	self:saveSettings()
end

function PlaceableImporter:selectCustomPlaceableFile()

    local filePath = openFileDialog("", "Placeables XML File|*.xml")
    if not filePath or filePath == "" then
        return
    end

    local xmlFile = self:loadXMLForValidation(filePath)
    if not xmlFile then
        return
    end

    if not xmlFile:hasProperty("placeables") then
        print("[PlaceableImporter] ERROR: Selected file is not a valid placeables.xml")
        xmlFile:delete()
        return
    end

    xmlFile:delete()

    self.placeablesFileCustom = filePath
    self.uiPlaceableFileText:setValue(self:convertFileText(filePath))

    self:setUIPlaceableInfos()
	self:saveSettings()
end

function PlaceableImporter:onClearModDesc()
	self.modDescFile = ""
	self.placeablesFile = ""
	self.placeablesFileCustom = ""

	self.uiModDescFileText:setValue("")
	self.uiPlaceableFileText:setValue("")
	
	self:setUseCustomPlaceableFile(false)
	self.uiCheckboxUseCustomPlaceableFile:setEnabled(false)
	self.uiSelectPlaceableXML:setEnabled(false)
	self.uiUseExecludeSaveFlag:setEnabled(false)
	self.uiUseExecludeSaveFlag:setValue(false)
	self.uiUseScriptFile:setEnabled(false)
	self.uiUseScriptFile:setValue(false)
end

function PlaceableImporter:setUIPlaceableInfos()
    self.uiCountPlaceables:setValue("0")
    self.uiCountFence:setValue("0")
    self.uiCountFenceSegments:setValue("0")
    self.placeableModList:clear()

    local filePath = self:getPlaceableFilePath()

    if filePath == nil or filePath == "" or not fileExists(filePath) then
        return
    end

    local xmlFile = XMLFile.loadIfExists("placeablesPreview", filePath)
    if xmlFile == nil then
        return
    end

    local placeableCount    = 0
    local fenceCount        = 0
    local fenceSegmentCount = 0
	local usedMods = {}

	local i = 0
	while true do
		local baseKey = string.format("placeables.placeable(%d)", i)
		if not xmlFile:hasProperty(baseKey) then
			break
		end

		local isPreplaced = xmlFile:getBool(baseKey .. "#isPreplaced") or false

		if not isPreplaced then

			placeableCount = placeableCount + 1

			local modName  = xmlFile:getString(baseKey .. "#modName")
			local filename = xmlFile:getString(baseKey .. "#filename")

			-- Falls kein modName vorhanden → aus $moddir$ oder placeables/ extrahieren
			if (modName == nil or modName == "") and filename then
				local extracted = filename:match("%$moddir%$([^/]+)")
				              or filename:match("^placeables/([^/]+)")
				              or filename:match("^placeables\\([^/\\]+)")
				if extracted then
					modName = extracted
				end
			end

			-- Wenn wir jetzt einen modName haben → in Tabelle aufnehmen
			if modName and modName ~= "" and filename then

				usedMods[modName] = usedMods[modName] or { ok = true }

				local resolved = self:convertXMLFilePath(filename, true)

				if resolved == nil then
					usedMods[modName].ok = false
				end
			end

			local newFenceKey       = baseKey .. ".newFence"
			local husbandryFenceKey = baseKey .. ".husbandryFence.fence"

			if xmlFile:hasProperty(newFenceKey) then
				fenceCount = fenceCount + 1
				local segments = self:readFenceSegmentsFromPlaceableXML(xmlFile, newFenceKey)
				fenceSegmentCount = fenceSegmentCount + #segments

			elseif xmlFile:hasProperty(husbandryFenceKey) then
				fenceCount = fenceCount + 1
			end
		end

		i = i + 1
	end

	self.uiCountPlaceables:setValue(tostring(placeableCount))
	self.uiCountFence:setValue(tostring(fenceCount))
	self.uiCountFenceSegments:setValue(tostring(fenceSegmentCount))

	self.placeableModList:clear()

	local modNames = {}
	for modName in pairs(usedMods) do
		table.insert(modNames, modName)
	end
	
	local tableCount = #modNames
	self.uiTitleModList:setText(LANG_TEXT("titleModList", tableCount))
	
	table.sort(modNames, function(a, b) return a:lower() < b:lower() end)

	for _, modName in ipairs(modNames) do
		self.placeableModList:appendItem(modName)

		if not usedMods[modName].ok then
			local idx = self.placeableModList:getItemCount() - 1
			self.placeableModList:setItemTextColor(idx, 1, 0.25, 0.25, 1)
		end
	end
end

function PlaceableImporter:setObjectCountForProgressDialog(xmlFile)
    local totalEntries = 0
    local index = 0

    while xmlFile:hasProperty(string.format("placeables.placeable(%d)", index)) do

        local baseKey = string.format("placeables.placeable(%d)", index)
        local isPreplaced = xmlFile:getBool(baseKey .. "#isPreplaced") or false

        if not isPreplaced then
            totalEntries = totalEntries + 1
        end

        index = index + 1
    end

    return totalEntries
end

function PlaceableImporter:convertXMLFilePath(xmlFilename, isMod)

    local resolvedPath = nil

    if xmlFilename == nil then
        return nil
    end

    if xmlFilename:find("%$moddir%$") then
        local cleanedFilename = xmlFilename:gsub("%$moddir%$", "")
        resolvedPath = self.mapPath .. PlaceableImporter.MOD_PLACEHOLDER_OBJECT_PATH .. cleanedFilename
    elseif xmlFilename:match("^placeables/") or xmlFilename:match("^placeables\\") then
        -- Support map-relative "placeables/ModName/file.xml" format — resolve via modPlaceholders/
        local cleanedFilename = xmlFilename:gsub("^placeables[/\\]", "")
        resolvedPath = self.mapPath .. PlaceableImporter.MOD_PLACEHOLDER_OBJECT_PATH .. cleanedFilename
	elseif xmlFilename:find("%$mapdir%$") then

		local cleanedFilename = xmlFilename:gsub("%$mapdir%$", "")
		cleanedFilename = cleanedFilename:gsub("^/", "")
		if self.modDescFile ~= nil and self.modDescFile ~= "" then
			local modRootPath = self.modDescFile:gsub("[^/]+$", "")
			resolvedPath = modRootPath .. cleanedFilename
		else
			printError("[PlaceableImporter] modDescFile not set, cannot resolve $mapdir$")
			return nil
		end

    elseif xmlFilename:find("%$data") or xmlFilename:find("data") then
        local cleanedFilename = xmlFilename:gsub("%$data", "data")
        resolvedPath = gamePath .. cleanedFilename
    else
        resolvedPath = xmlFilename
    end

    if not fileExists(resolvedPath) then
        printError("[PlaceableImporter] XML-Datei existiert nicht: " .. tostring(resolvedPath))
        return nil
    end

    return resolvedPath
end

function PlaceableImporter:importPlaceables()
    local filePath = self:getPlaceableFilePath()
    if not filePath or filePath == "" then
        printError("[PlaceableImporter] Error: No valid file path specified.")
        return
    end

    print("[PlaceableImporter] Loading placeables from: " .. filePath)
    self:loadPlaceablesFromXML(filePath)
	self:createGameScriptFile()
end

function PlaceableImporter:loadPlaceablesFromXML(filePath)
    local progressDialog = ProgressDialog.show("[PlaceableImporter] Load Placeables ...")

    local placeholdersNode, objectsNode, fenceNode = self:createPlaceholdersNode()

    local xmlFile = XMLFile.load("placeables", filePath)
    if xmlFile == nil then
        printError("[PlaceableImporter] Failed to load placeables XML: " .. filePath)
        return
    end

    local totalEntries = self:setObjectCountForProgressDialog(xmlFile)
    local loadedEntries = 0

    local index = 0
    while xmlFile:hasProperty(string.format("placeables.placeable(%d)", index)) do

        local baseKey = string.format("placeables.placeable(%d)", index)
		
		local isPreplaced = xmlFile:getBool(baseKey .. "#isPreplaced") or false
		if not isPreplaced then
			loadedEntries = loadedEntries + 1
			local progress = (loadedEntries / math.max(totalEntries, 1)) * 100
			progressDialog:setProgress(progress, string.format("Lade Placeable %d von %d...", loadedEntries, totalEntries))

			local objectXMLFilePath = xmlFile:getString(baseKey .. "#filename")
			local modName = xmlFile:getString(baseKey .. "#modName")
			local position = xmlFile:getString(baseKey .. "#position")
			local rotation = xmlFile:getString(baseKey .. "#rotation")
			local uniqueId = xmlFile:getString(baseKey .. "#uniqueId") or ""

			-- Wenn kein modName-Tag vorhanden → aus $moddir$ oder placeables/ extrahieren
			if (not modName or modName == "") and objectXMLFilePath then
				local extracted = objectXMLFilePath:match("%$moddir%$([^/]+)")
				              or objectXMLFilePath:match("^placeables/([^/]+)")
				              or objectXMLFilePath:match("^placeables\\([^/\\]+)")
				if extracted then
					modName = extracted
				end
			end

			local newFenceKey       = baseKey .. ".newFence"
			local husbandryFenceKey = baseKey .. ".husbandryFence.fence"

			local hasNewFence       = xmlFile:hasProperty(newFenceKey)
			local hasHusbandryFence = xmlFile:hasProperty(husbandryFenceKey)

			local sourceType = "basegame"

			if objectXMLFilePath then
				if objectXMLFilePath:find("^%$data") or objectXMLFilePath:find("^data/") then
					sourceType = "basegame"
				elseif objectXMLFilePath:find("^%$mapdir%$") then
					sourceType = "map"
				elseif objectXMLFilePath:find("^%$moddir%$") then
					sourceType = "mod"
				elseif objectXMLFilePath:find("^placeables[/\\]") then
					-- map-relative "placeables/ModName/..." paths are mod placeables
					sourceType = "mod"
				end
			end

			objectXMLFilePath = self:convertXMLFilePath(objectXMLFilePath, isMod)

			if objectXMLFilePath ~= nil then

				----------------------------------------------------------------
				-- NEW FENCE
				----------------------------------------------------------------
				if hasNewFence then

					local segments = self:readFenceSegmentsFromPlaceableXML(xmlFile, newFenceKey)

					if #segments > 0 then
						local i3dPath = self:getI3DFile(objectXMLFilePath, sourceType, modName, true)
						local fenceData = self:loadFenceDataFromXML(objectXMLFilePath)

						if i3dPath and fenceData then
							local fenceGroupName = self:getFenceGroupName(objectXMLFilePath, modName)
							local targetFenceNode = fenceGroupName and self:getOrCreateFenceGroup(fenceNode, fenceGroupName) or fenceNode

							self:loadFence(objectXMLFilePath, i3dPath, targetFenceNode, segments, fenceData)
						end
					end

				----------------------------------------------------------------
				-- NORMAL PLACEABLE
				----------------------------------------------------------------
				elseif position and rotation then

					local i3dPath, childDeleteNodes = self:getI3DFile(objectXMLFilePath, sourceType, modName)

					if i3dPath then
						local modGroupNode = self:getOrCreateModGroup(objectsNode, modName)
						local placeableNode = self:loadPlaceable(i3dPath, modGroupNode, position, rotation, uniqueId, childDeleteNodes)

						-- local placeableNode = self:loadPlaceable(i3dPath, objectsNode, position, rotation, uniqueId, childDeleteNodes)

						----------------------------------------------------------------
						-- HUSBANDRY FENCE
						----------------------------------------------------------------
						if placeableNode and hasHusbandryFence then
							local segments =self:readFenceSegmentsFromPlaceableXML(xmlFile, husbandryFenceKey)
							if #segments > 0 then

								local targetFenceNode =self:getOrCreateFenceGroup(fenceNode, "FENCE_TMP")

								self:loadPlaceableHusbandryFence(objectXMLFilePath, segments, targetFenceNode)

								local wx, wy, wz = getWorldTranslation(targetFenceNode)
								local wrx, wry, wrz = getWorldRotation(targetFenceNode)

								link(placeableNode, targetFenceNode)

								local lx, ly, lz = worldToLocal(placeableNode, wx, wy, wz)
								local lrx, lry, lrz = worldRotationToLocal(placeableNode, wrx, wry, wrz)

								setTranslation(targetFenceNode, lx, ly, lz)
								setRotation(targetFenceNode, lrx, lry, lrz)

								setName(targetFenceNode, "FENCE")
							end
						end
					end
				end
			end
		end
		index = index + 1
	end

    progressDialog:close()
    xmlFile:delete()

    print("[PlaceableImporter] Import finish!")
end

function PlaceableImporter:findNodeByNameRecursive(rootNode, targetName)
    if rootNode == nil or rootNode == 0 then
        return nil
    end

    if getName(rootNode) == targetName then
        return rootNode
    end

    for i = 0, getNumOfChildren(rootNode) - 1 do
        local child = getChildAt(rootNode, i)
        local found = self:findNodeByNameRecursive(child, targetName)
        if found then
            return found
        end
    end

    return nil
end

function PlaceableImporter:getI3DFile(objectXMLFilePath, sourceType, modName, onlyFences)
    if not objectXMLFilePath or not fileExists(objectXMLFilePath) then
        printError(string.format("[PlaceableImporter] XML file not found: %s", tostring(objectXMLFilePath)))
        return nil, nil
    end

	if not onlyFences then
		local childDeletedNodes = nil

		local xmlId = loadXMLFile("childCheck", objectXMLFilePath)
		if xmlId ~= 0 then
			local parentFilename = getXMLString(xmlId, "placeable.parentFile#xmlFilename")

			if parentFilename then
				childDeletedNodes = self:getChildDeletedNodes(objectXMLFilePath)

				delete(xmlId)

				local baseDir = objectXMLFilePath:match("(.*/)")
				if not baseDir then
					printError("[PlaceableImporter] Failed to determine base directory")
					return nil, nil
				end

				local parentXMLPath = baseDir .. parentFilename

				local i3dPath = self:getI3DFile(parentXMLPath, sourceType, modName)
				return i3dPath, childDeletedNodes
			end

			delete(xmlId)
		end
	end

    local xmlFile = XMLFile.load("objectXML", objectXMLFilePath)
    if not xmlFile then
        printError(string.format("[PlaceableImporter] Failed to load parent XML: %s", objectXMLFilePath))
        return nil, nil
    end

    local i3dFilename = xmlFile:getString("placeable.base.filename")
    xmlFile:delete()

    if not i3dFilename then
        printError(string.format("[PlaceableImporter] Missing base.filename in %s", objectXMLFilePath))
        return nil, nil
    end

	local fullI3dPath = i3dFilename

	local modRoot = nil
	if self.modDescFile and self.modDescFile ~= "" then
		modRoot = self.modDescFile:gsub("[^/]+$", "")
	end

	if sourceType == "basegame" then
		fullI3dPath = fullI3dPath:gsub("%$data", gamePath .. "data")
		if not fullI3dPath:match("^%a:/") and not fullI3dPath:match("^/") then
			fullI3dPath = gamePath .. fullI3dPath
		end
	elseif sourceType == "map" then
		if not modRoot then
			printError("[PlaceableImporter] Cannot resolve map path (modRoot missing)")
			return nil, nil
		end
		fullI3dPath = fullI3dPath:gsub("%$mapdir%$", "")
		fullI3dPath = modRoot .. fullI3dPath:gsub("^/", "")
	elseif sourceType == "mod" then
		fullI3dPath = fullI3dPath:gsub("%$moddir%$", "")
		-- Strip leading "placeables/ModName/" prefix — mod XMLs store paths relative to
		-- the mod's own root (e.g. "placeables/FS25_UK_CattleShed/FS25_UK_CattleShed.i3d"),
		-- but in modPlaceholders the file sits at modPlaceholders/ModName/FileName.i3d
		if modName then
			local stripPattern = "^placeables[/\\]" .. modName .. "[/\\]"
			fullI3dPath = fullI3dPath:gsub(stripPattern, "")
		end
		fullI3dPath = self.mapPath .. PlaceableImporter.MOD_PLACEHOLDER_OBJECT_PATH .. modName .. "/" .. fullI3dPath
	else
		printError("[PlaceableImporter] Unknown sourceType: " .. tostring(sourceType))
		return nil, nil
	end

    return fullI3dPath, nil
end

function PlaceableImporter:getChildDeletedNodes(childXMLPath)
    local deletedNodes = {}

    if not childXMLPath or not fileExists(childXMLPath) then
        return deletedNodes
    end

    local xmlId = loadXMLFile("childDeletedNodes", childXMLPath)
    if xmlId == 0 then
        return deletedNodes
    end

    local i = 0
    while true do
        local setPath = string.format("placeable.parentFile.attributes.set(%d)", i)
        if not hasXMLProperty(xmlId, setPath) then
            break
        end

        local pathAttr  = getXMLString(xmlId, setPath .. "#path")
        local valueAttr = getXMLString(xmlId, setPath .. "#value")

        if pathAttr
           and valueAttr
           and string.find(pathAttr, "placeable%.deletedNodes%.deletedNode")
           and string.find(pathAttr, "#node") then

            table.insert(deletedNodes, valueAttr)
        end

        i = i + 1
    end

    delete(xmlId)
    return deletedNodes
end

function PlaceableImporter:updateObjectTranslations()
    local filePath = self:getPlaceableFilePath()
    if not filePath then
        printError("[PlaceableImporter] No placeables file selected.")
        return
    end

    local xmlFile = XMLFile.load("placeables", filePath)
    if xmlFile == nil then
        printError("[PlaceableImporter] Failed to load placeables XML: " .. filePath)
        return
    end

    local rootNode = getRootNode()
    local placeholdersNode = getChild(rootNode, PlaceableImporter.NODE_NAME)
    if placeholdersNode == nil or placeholdersNode == 0 then
        print("[PlaceableImporter] No placeholder node found.")
        xmlFile:delete()
        return
    end

    local objectsNode = getChild(placeholdersNode, "Objects")
    if objectsNode == nil or objectsNode == 0 then
        print("[PlaceableImporter] No Objects node found.")
        xmlFile:delete()
        return
    end

    local updatedObjects = {}

    --------------------------------------------------------------------
    -- Iteriere über alle XML Einträge
    --------------------------------------------------------------------
    local index = 0
	while xmlFile:hasProperty(string.format("placeables.placeable(%d)", index)) do

		local baseKey = string.format("placeables.placeable(%d)", index)
		local xmlUniqueId = xmlFile:getString(baseKey .. "#uniqueId")

		if xmlUniqueId then
			local objectNode = self:findObjectByUniqueId(objectsNode, xmlUniqueId)

			if objectNode then
				local px, py, pz = getTranslation(objectNode)
				local rx, ry, rz = getRotation(objectNode)

				rx = math.deg(rx)
				ry = math.deg(ry)
				rz = math.deg(rz)
				
				local modName = xmlFile:getString(baseKey .. "#modName")
				if not modName or modName == "" then
					modName = "BaseGame"
				end

				local oldPos = xmlFile:getString(baseKey .. "#position")
				local oldRot = xmlFile:getString(baseKey .. "#rotation")

				local opx, opy, opz = oldPos:match("([-%.%d]+) ([-%.%d]+) ([-%.%d]+)")
				local orx, ory, orz = oldRot:match("([-%.%d]+) ([-%.%d]+) ([-%.%d]+)")

				opx, opy, opz = tonumber(opx), tonumber(opy), tonumber(opz)
				orx, ory, orz = tonumber(orx), tonumber(ory), tonumber(orz)

				local posChanged = math.abs(px - opx) > 0.001 or math.abs(py - opy) > 0.001 or math.abs(pz - opz) > 0.001
				local rotChanged = math.abs(rx - orx) > 0.01 or math.abs(ry - ory) > 0.01 or math.abs(rz - orz) > 0.01

				if posChanged or rotChanged then
					xmlFile:setString(baseKey .. "#position", string.format("%.3f %.3f %.3f", px, py, pz))
					xmlFile:setString(baseKey .. "#rotation", string.format("%.2f %.2f %.2f", rx, ry, rz))
					
					table.insert(updatedObjects, string.format("%s.%s (%s)", modName, getName(objectNode), xmlUniqueId))
				end
			end
		end

		index = index + 1
	end


    if #updatedObjects > 0 then
        xmlFile:save()
        print(string.format("[PlaceableImporter] Updated Translations of %d Placeables:", #updatedObjects))
        for _, entry in ipairs(updatedObjects) do
            print("[PlaceableImporter] " .. entry)
        end
    else
        print("[PlaceableImporter] No Placeables Transforms changed.")
    end

    xmlFile:delete()
end

function PlaceableImporter:findObjectByUniqueId(parentNode, uniqueId)
    for i = 0, getNumOfChildren(parentNode) - 1 do
        local child = getChildAt(parentNode, i)

        local attrValue = getUserAttribute(child, "uniqueId")
        if attrValue == uniqueId then
            return child
        end

        local found = self:findObjectByUniqueId(child, uniqueId)
        if found then
            return found
        end
    end

    return nil
end

--------------------------------------------------------------------------------- OBJECTS START ---------------------------------------------------------------------------------------

function PlaceableImporter:loadPlaceable(i3dPath, placeholdersNode, position, rotation, uniqueId, childDeletedNodes)
    local px, py, pz = position:match("([-%.%d]+) ([-%.%d]+) ([-%.%d]+)")
    local rx, ry, rz = rotation:match("([-%.%d]+) ([-%.%d]+) ([-%.%d]+)")

    if not px or not py or not pz or not rx or not ry or not rz then
        printError("[PlaceableImporter] Invalid position or rotation for: " .. i3dPath)
        return
    end

    local objectId = createI3DReference(i3dPath, false)

    if objectId == 0 then
        printError("[PlaceableImporter] Failed to create i3d reference: " .. i3dPath)
        return
    end

    link(placeholdersNode, objectId)

    setTranslation(objectId, tonumber(px), tonumber(py), tonumber(pz))
    setRotation(objectId, math.rad(tonumber(rx)), math.rad(tonumber(ry)), math.rad(tonumber(rz)))
	setUserAttribute(objectId, "uniqueId", 3, uniqueId)
    if childDeletedNodes then
        for _, nodeName in ipairs(childDeletedNodes) do
            local nodeId = self:findNodeByNameRecursive(objectId, nodeName)
            if nodeId ~= nil and nodeId ~= 0 then
                delete(nodeId)
            end
        end
    end

    return objectId
end

function PlaceableImporter:getHusbandryFenceXML(objectXMLPath)
    local xml = XMLFile.load("objectXML", objectXMLPath)
    if not xml then
        return nil
    end

    local fenceXML = xml:getString("placeable.husbandry.fence#xmlFilename")
    xml:delete()

    if not fenceXML then
        return nil
    end

    fenceXML = fenceXML:gsub("%$data", "data")
    return gamePath .. fenceXML
end

function PlaceableImporter:loadPlaceableHusbandryFence(objectXMLPath, fenceSegments, fenceNode)
    local fenceXMLPath = self:getHusbandryFenceXML(objectXMLPath)
    if not fenceXMLPath or not fileExists(fenceXMLPath) then
        return
    end

    local fenceData = self:loadFenceDataFromXML(fenceXMLPath)
    if not fenceData then
        return
    end

    local i3dPath = self:getI3DFile(fenceXMLPath, "basegame", nil, true)
    if not i3dPath then
        return
    end

    self:loadFence(fenceXMLPath, i3dPath, fenceNode, fenceSegments, fenceData)
end

--------------------------------------------------------------------------------- OBJECTS END ---------------------------------------------------------------------------------------
--------------------------------------------------------------------------------- FENCES START ---------------------------------------------------------------------------------------

function PlaceableImporter:getOrCreateModGroup(parentNode, modName)
    local groupName = modName or "Basegame"

    local groupNode = getChild(parentNode, groupName)

    if groupNode == nil or groupNode == 0 then
        groupNode = createTransformGroup(groupName)
        link(parentNode, groupNode)
    end

    return groupNode
end

function PlaceableImporter:getFenceGroupName(objectXMLFilePath, modName)
    local filename = objectXMLFilePath:match("([^/\\]+)$")
    if not filename then
        return nil
    end

    filename = filename:gsub("%.xml$", "")

    if modName then
        return string.format("%s.%s", modName, filename)
    else
        return string.format("BaseGame.%s", filename)
    end
end

function PlaceableImporter:getOrCreateFenceGroup(fenceRootNode, groupName)
    for i = 0, getNumOfChildren(fenceRootNode) - 1 do
        local child = getChildAt(fenceRootNode, i)
        if getName(child) == groupName then
            return child
        end
    end

    local newGroup = createTransformGroup(groupName)
    link(fenceRootNode, newGroup)
    return newGroup
end

function PlaceableImporter:getOrCreateSegmentGroup(parentNode, segmentIndex)
    local groupName = string.format("segment%02d", segmentIndex)

    for i = 0, getNumOfChildren(parentNode) - 1 do
        local child = getChildAt(parentNode, i)
        if getName(child) == groupName then
            return child
        end
    end

    local newGroup = createTransformGroup(groupName)
    link(parentNode, newGroup)
    return newGroup
end

function PlaceableImporter:readFenceSegmentsFromPlaceableXML(xmlFile, fenceKey)
    local segments = {}

    if not xmlFile:hasProperty(fenceKey) then
        return segments
    end

    xmlFile:iterate(fenceKey .. ".segment", function(_, segmentKey)
        local start = xmlFile:getString(segmentKey .. "#start")
        local stop  = xmlFile:getString(segmentKey .. "#end")
        local id    = xmlFile:getString(segmentKey .. "#id") or "SEGMENT"

        if start and stop then
            table.insert(segments, {
                start = start,
                stop  = stop,
                id    = id
            })
        end
    end)

    return segments
end

local function getI3DMappingNode(xmlFile, mappingId)
    if not xmlFile or not mappingId then
        return nil
    end

    local i = 0
    while true do
        local key = string.format("placeable.i3dMappings.i3dMapping(%d)", i)
        if not xmlFile:hasProperty(key) then
            break
        end

        local id   = xmlFile:getString(key .. "#id")
        local node = xmlFile:getString(key .. "#node")

        if id == mappingId then
            return node
        end

        i = i + 1
    end

    return nil
end

function PlaceableImporter:loadFenceDataFromXML(objectXMLFilePath)
    local objectXML = XMLFile.load("fenceObjectXML", objectXMLFilePath)
	if not objectXML then
		printError("[PlaceableImporter] Failed to load fence object XML: " .. objectXMLFilePath)
		return nil
	end


    local fenceData = {}

    objectXML:iterate("placeable.fence.segment", function(_, segmentKey)
        local id = objectXML:getString(segmentKey .. "#id")
        local class = objectXML:getString(segmentKey .. "#class") or "FenceSegment"
        local maxVerticalAngle = objectXML:getFloat(segmentKey .. "#maxVerticalAngle") or 45

		if not id then
			printWarning("[PlaceableImporter] Found fence segment or gate without an ID.")
			return
		end

        if class == "FenceSegment" then
            local segment = {
                class = class,
                maxVerticalAngle = maxVerticalAngle,
                poles = {},
                panels = {},
                maxScale = objectXML:getFloat(segmentKey .. ".panels#maxScale") or 1.3,
            }

            objectXML:iterate(segmentKey .. ".poles.pole", function(_, poleKey)
                local nodeName = objectXML:getString(poleKey .. "#node")
                local mapping  = getI3DMappingNode(objectXML, nodeName)

                if nodeName and mapping then
                    table.insert(segment.poles, {
                        nodeName      = nodeName,
                        nodeI3dMapping = mapping,
                        radius        = objectXML:getFloat(poleKey .. "#radius") or 0.0
                    })
                end
            end)

            objectXML:iterate(segmentKey .. ".panels.panel", function(_, panelKey)
                local nodeName = objectXML:getString(panelKey .. "#node")
                local mapping  = getI3DMappingNode(objectXML, nodeName)

                if nodeName and mapping then
                    table.insert(segment.panels, {
                        nodeName       = nodeName,
                        nodeI3dMapping = mapping,
                        length         = objectXML:getFloat(panelKey .. "#length") or 2.0
                    })
                end
            end)

            fenceData[id] = segment

        elseif class == "FenceGate" then
            local nodeName = objectXML:getString(segmentKey .. ".gate#node")
            local mapping  = getI3DMappingNode(objectXML, nodeName)

            fenceData[id] = {
                class = class,
                maxVerticalAngle = maxVerticalAngle,
                nodeName = nodeName,
                nodeI3dMapping = mapping,
                length = objectXML:getFloat(segmentKey .. ".gate#length") or 2.0
            }
        end
    end)

    objectXML:delete()
    return fenceData
end

function PlaceableImporter:loadFence(objectXMLFilePath, i3dPath, targetFenceNode, fenceSegments, fenceData)
    if not fenceSegments or #fenceSegments == 0 then
        return
    end

    local cacheGroup = self:createFenceCache(i3dPath, targetFenceNode)
    if not cacheGroup then
        return
    end

	for segmentIndex, segment in ipairs(fenceSegments) do
		local data = fenceData[segment.id]
		if data then
			local segmentNode = self:getOrCreateSegmentGroup(targetFenceNode, segmentIndex)

			local coordStart = self:convertStringToVector(segment.start)
			local coordEnd   = self:convertStringToVector(segment.stop)

			local coordStartNext = nil
			local forceEndPole = false

			local nextSegment = fenceSegments[segmentIndex + 1]
			if nextSegment then
				local nextData = fenceData[nextSegment.id]

				if nextData and nextData.class == "FenceGate" then
					forceEndPole = true
				else
					coordStartNext = self:convertStringToVector(nextSegment.start)
				end
			end

			if coordStart and coordEnd then
				if data.class == "FenceGate" then
					self:placeFenceGate(coordStart, coordEnd, segmentNode, cacheGroup, data)
				else
					self:generateFenceSegments(coordStart, coordEnd, coordStartNext, forceEndPole, segmentNode, cacheGroup, data)
				end
			end
		end
	end

    delete(cacheGroup)
end

function PlaceableImporter:generateFenceSegments(coordStart, coordEnd, coordStartNext, forceEndPole, targetSegmentNode, cacheGroup, fenceData)
    local panels = fenceData.panels
    if not panels or #panels == 0 then
        return
    end

    local poles = fenceData.poles

    local baseLength = panels[1].length
    local maxScale   = fenceData.maxScale or 1.3
    local minScale   = 1 / maxScale
    local minLen     = baseLength * minScale

    local segmentLength = self:getDistance(coordStart, coordEnd)

    local dx = coordEnd.x - coordStart.x
    local dy = coordEnd.y - coordStart.y
    local dz = coordEnd.z - coordStart.z
    local rotationY = math.atan2(dx, dz)

    local numPanels = math.floor(segmentLength / baseLength)
    local rest = segmentLength - numPanels * baseLength

    local scales = {}

    if rest == 0 then
        for i = 1, numPanels do
            scales[i] = 1.0
        end

    elseif rest >= minLen then
        for i = 1, numPanels do
            scales[i] = 1.0
        end
        table.insert(scales, rest / baseLength)

    else
        for i = 1, numPanels - 1 do
            scales[i] = 1.0
        end

        local scale = (baseLength + rest) / baseLength
        scale = math.max(minScale, math.min(maxScale, scale))
        scales[numPanels] = scale
    end

    local currentPosition = {x = coordStart.x, y = coordStart.y, z = coordStart.z}

	for i, scale in ipairs(scales) do
		local usedLength = baseLength * scale
		local step = usedLength / segmentLength

		-- Panel
		local panelDef = panels[math.random(1, #panels)]
		local panel = self:extractFenceNode(cacheGroup, panelDef.nodeI3dMapping, targetSegmentNode)

		if panel then
			setTranslation(panel, currentPosition.x, currentPosition.y, currentPosition.z)
			setRotation(panel, 0, rotationY, 0)
			setScale(panel, 1, 1, scale)
		end

		-- 🔑 Pole → Pole Höhenvergleich
		local startX, startZ = currentPosition.x, currentPosition.z
		local endX = startX + dx * step
		local endZ = startZ + dz * step

		local terrainId = getChild(getRootNode(), "terrain")
		local yStart = getTerrainHeightAtWorldPos(terrainId, startX, 0, startZ)
		local yEnd   = getTerrainHeightAtWorldPos(terrainId, endX,   0, endZ)

		local yOffset = yEnd - yStart

		if panel then
			self:applyYOffsetRecursive(panel, yOffset)
		end

		if poles and #poles > 0 then
			local poleDef = poles[math.random(1, #poles)]
			local pole = self:extractFenceNode(cacheGroup, poleDef.nodeI3dMapping, targetSegmentNode)

			if pole then
				setTranslation(pole, currentPosition.x, currentPosition.y, currentPosition.z)
				setRotation(pole, 0, rotationY, 0)
			end
		end

		currentPosition.x = endX
		currentPosition.y = currentPosition.y + (yEnd - yStart)
		currentPosition.z = endZ
	end


	local placeEndPole = true

	if not forceEndPole and coordStartNext then
		local dx = math.abs(coordEnd.x - coordStartNext.x)
		local dy = math.abs(coordEnd.y - coordStartNext.y)
		local dz = math.abs(coordEnd.z - coordStartNext.z)

		local EPSILON = 0.001
		if dx < EPSILON and dy < EPSILON and dz < EPSILON then
			placeEndPole = false
		end
	end

	if placeEndPole and fenceData.poles and #fenceData.poles > 0 then
		local poleDef = fenceData.poles[math.random(1, #fenceData.poles)]
		local endPole = self:extractFenceNode(
			cacheGroup,
			poleDef.nodeI3dMapping,
			targetSegmentNode
		)

		if endPole then
			setTranslation(endPole, coordEnd.x, coordEnd.y, coordEnd.z)
			setRotation(endPole, 0, rotationY, 0)
		end
	end
end

function PlaceableImporter:placeFenceGate(coordStart, coordEnd, segmentNode, cacheGroup, gateData)
    if not gateData.nodeName then
        return
    end

    local dx = coordEnd.x - coordStart.x
    local dz = coordEnd.z - coordStart.z
    local rotationY = math.atan2(dx, dz)

	local gateNode = self:extractFenceNode(cacheGroup, gateData.nodeI3dMapping, segmentNode)

    if not gateNode then
        printWarning(string.format("[PlaceableImporter] Gate-Node '%s' nicht gefunden", tostring(gateData.nodeName)))
        return
    end

    setTranslation(gateNode, coordStart.x, coordStart.y, coordStart.z)
    setRotation(gateNode, 0, rotationY, 0)
end

function PlaceableImporter:applyYOffsetRecursive(node, yOffset, depth)
    if node == nil or node == 0 then return end
    depth = depth or 0
    local indent = string.rep("  ", depth)

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
        self:applyYOffsetRecursive(getChildAt(node, i), yOffset, depth + 1)
    end
end



function PlaceableImporter:createFenceCache(i3dPath, targetFenceNode)
    local cacheGroup = createTransformGroup("cached")
    link(targetFenceNode, cacheGroup)

    local fenceId = loadI3DFile(i3dPath)
    if fenceId == 0 then
        delete(cacheGroup)
        return nil
    end

    link(cacheGroup, fenceId)
    return cacheGroup
end

function PlaceableImporter:extractFenceNode(cacheGroup, mappingPath, targetNode)
    if not cacheGroup or cacheGroup == 0 or not mappingPath then
        return nil
    end

    local i3dRoot = getChildAt(cacheGroup, 0)
	if not i3dRoot or i3dRoot == 0 then
		printWarning("[PlaceableImporter] CacheGroup contains no I3D root")
		return nil
	end

	local node = i3dRoot

	for index in string.gmatch(mappingPath, "%d+") do
		index = tonumber(index)

		if index == nil or index >= getNumOfChildren(node) then
			printWarning(string.format("[PlaceableImporter] Invalid i3dMapping path '%s'", tostring(mappingPath)))
			return nil
		end

		node = getChildAt(node, index)
		if node == nil or node == 0 then
			printWarning(string.format("[PlaceableImporter] Node not found in mapping '%s'", tostring(mappingPath)))
			return nil
		end
	end


    local clonedNode = clone(node, false, false, true)
    link(targetNode, clonedNode)
    return clonedNode
end


function PlaceableImporter:getDistance(start, stop)
    if not start or not stop then
        return 0
    end

    local deltaX = stop.x - start.x
    local deltaY = stop.y - start.y
    local deltaZ = stop.z - start.z
    return math.sqrt(deltaX^2 + deltaY^2 + deltaZ^2)
end

--------------------------------------------------------------------------------- FENCES END ---------------------------------------------------------------------------------------

function PlaceableImporter:createPlaceholdersNode()
    local rootNode = getRootNode()
    local placeholdersNode

    for i = 0, getNumOfChildren(rootNode) - 1 do
        local child = getChildAt(rootNode, i)
        if getName(child) == PlaceableImporter.NODE_NAME then
            placeholdersNode = child
            break
        end
    end

    if not placeholdersNode then
        placeholdersNode = createTransformGroup(PlaceableImporter.NODE_NAME)
        link(rootNode, placeholdersNode)
        setUserAttribute(placeholdersNode, "onCreate", UserAttributeType.CALLBACK, "modOnCreate.RemovePlaceholderNode")
    end

	if self.uiUseExecludeSaveFlag:getValue() == true then
		excludeFromSave(placeholdersNode, true)
	else
		excludeFromSave(placeholdersNode, false)
	end
	
    local function recreateChild(parent, name)
        local node = getChild(parent, name)
        if node and node ~= 0 then
            delete(node)
        end
        node = createTransformGroup(name)
        link(parent, node)
        return node
    end

    local objectsNode = recreateChild(placeholdersNode, "Objects")
    local fenceNode   = recreateChild(placeholdersNode, "Fences")

    return placeholdersNode, objectsNode, fenceNode
end

function PlaceableImporter:createGameScriptFile()
    local modDescPath = self.modDescFile
    if not modDescPath or modDescPath == "" or not fileExists(modDescPath) then return end

    local modDir = modDescPath:match("^(.*[/\\])") or ""
    local scriptFilename = "removePlaceablePlaceholders.lua"
    local scriptPath = modDir .. scriptFilename

    local xmlFile = XMLFile.loadIfExists("modDesc", modDescPath)
    if not xmlFile then return end

    local scriptRegisteredIndex = nil
    xmlFile:iterate("modDesc.extraSourceFiles.sourceFile", function(i, key)
        if xmlFile:getString(key .. "#filename") == scriptFilename then scriptRegisteredIndex = i end
    end)

    if self.uiUseScriptFile:getValue() then
		local PLACEHOLDER_SCRIPT_CONTENT = string.format([[
RemovePlaceablePlaceholders = {}

function RemovePlaceablePlaceholders.removePlaceholderNode(node)
	print("Removing '%s' ...")
	if node ~= nil and getName(node) == "%s" then
		delete(node)
		print("Node '%s' was removed during loading.")
	end
end

g_onCreateUtil.addOnCreateFunction("RemovePlaceholderNode", RemovePlaceablePlaceholders.removePlaceholderNode)]],
			PlaceableImporter.NODE_NAME, PlaceableImporter.NODE_NAME, PlaceableImporter.NODE_NAME
		)
			local f = createFile(scriptPath, FileAccess.WRITE)
        if f ~= 0 then fileWrite(f, PLACEHOLDER_SCRIPT_CONTENT) delete(f) else printError("[PlaceableImporter] Failed to write removePlaceablePlaceholders.lua") end

        if scriptRegisteredIndex == nil then
            local index = 0
            while xmlFile:hasProperty(string.format("modDesc.extraSourceFiles.sourceFile(%d)", index)) do index = index + 1 end
            xmlFile:setString(string.format("modDesc.extraSourceFiles.sourceFile(%d)#filename", index), scriptFilename)
            xmlFile:save()
        end
	else
		if fileExists(scriptPath) then deleteFile(scriptPath) end

		xmlFile:iterate("modDesc.extraSourceFiles.sourceFile", function(_, key)
			if xmlFile:getString(key .. "#filename") == scriptFilename then
				xmlFile:removeProperty(key)
			end
		end)

		xmlFile:save()
	end


    xmlFile:delete()
end

function PlaceableImporter:setMapPath()
    local fullPath = getSceneFilename()
    if not fullPath then
        self.mapPath = nil
        return
    end

    self.mapPath = fullPath:match("(.*[/\\])")
    if not self.mapPath then
        self.mapPath = nil
    end
	print(string.format("[PlaceableImporter] mapPath: %s", self.mapPath))
end

function PlaceableImporter:loadSettings()

    local xmlFile = XMLFile.loadIfExists("placeableImporterSettings", PlaceableImporter.SETTINGS_PATH)
    if not xmlFile then return end

    local scene = getSceneFilename()

    local i = 0
    while xmlFile:hasProperty(string.format("settings.map(%d)", i)) do

        if xmlFile:getString(string.format("settings.map(%d)#path", i)) == scene then

            self.modDescFile = xmlFile:getString(string.format("settings.map(%d).modDescFile", i), "")
            self.placeablesFileCustom = xmlFile:getString(string.format("settings.map(%d).placeablesFileCustom", i), "")

            -- Checkbox States
            local useCustom = xmlFile:getBool(string.format("settings.map(%d).useCustomPlaceables", i), false)
            local useExclude = xmlFile:getBool(string.format("settings.map(%d).useExcludeFlag", i), false)
            local useScript = xmlFile:getBool(string.format("settings.map(%d).useScriptFile", i), false)

            self.uiCheckboxUseCustomPlaceableFile:setValue(useCustom)
			self:setUseCustomPlaceableFile(useCustom)
            self.uiUseExecludeSaveFlag:setValue(useExclude)
            self.uiUseScriptFile:setValue(useScript)

            break
        end

        i = i + 1
    end
	self:selectModDescFile(self.modDescFile)
	if self.placeablesFileCustom ~= "" then
		self.uiPlaceableFileText:setValue(self:convertFileText(self.placeablesFileCustom))
	end

    self:setUIPlaceableInfos()

    xmlFile:delete()
end

function PlaceableImporter:saveSettings()
    local xmlFile = XMLFile.loadIfExists("placeableImporterSettings", PlaceableImporter.SETTINGS_PATH)

    if not xmlFile then
        xmlFile = XMLFile.create("placeableImporterSettings", PlaceableImporter.SETTINGS_PATH, "settings")
        if not xmlFile then return end
    end

    local scene = getSceneFilename()

    local i = 0

    while xmlFile:hasProperty(string.format("settings.map(%d)", i)) do
        if xmlFile:getString(string.format("settings.map(%d)#path", i)) == scene then
            xmlFile:removeProperty(string.format("settings.map(%d)", i))
            break
        end
        i = i + 1
    end

    i = 0
    while xmlFile:hasProperty(string.format("settings.map(%d)", i)) do
        i = i + 1
    end

    xmlFile:setString(string.format("settings.map(%d)#path", i), scene)

    xmlFile:setString(string.format("settings.map(%d).modDescFile", i), self.modDescFile or "")
    xmlFile:setString(string.format("settings.map(%d).placeablesFileCustom", i), self.placeablesFileCustom or "")

    -- Checkbox States speichern
    xmlFile:setBool(string.format("settings.map(%d).useCustomPlaceables", i), self.uiCheckboxUseCustomPlaceableFile:getValue() or false)
    xmlFile:setBool(string.format("settings.map(%d).useExcludeFlag", i), self.uiUseExecludeSaveFlag:getValue() or false)
    xmlFile:setBool(string.format("settings.map(%d).useScriptFile", i), self.uiUseScriptFile:getValue() or false)

    xmlFile:save()
    xmlFile:delete()
	print("[PlaceableImporter] Saved Settings")
end

function PlaceableImporter:convertStringToVector(vectorString)
    if not vectorString then
        return nil
    end

    local x, y, z = vectorString:match("([-%.%d]+) ([-%.%d]+) ([-%.%d]+)")
    if not x or not y or not z then
        return nil
    end

    return { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
end

function PlaceableImporter.InfoBox(title, text)
    local windowRowSizer = UIRowLayoutSizer.new()
    local window = UIWindow.new(windowRowSizer, title or "Messagebox", false, true)

    local bgSizer = UIRowLayoutSizer.new()
    UIPanel.new(windowRowSizer, bgSizer, -1, -1, 420, -1, BorderDirection.NONE, 0, 1)

    local uiBorderSizer = UIRowLayoutSizer.new()
    local panel = UIPanel.new(bgSizer, uiBorderSizer, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
    panel:setBackgroundColor(1, 1, 1, 1)

    local contentSizer = UIRowLayoutSizer.new()
    UIPanel.new(uiBorderSizer, contentSizer, -1, -1, -1, -1, BorderDirection.ALL, 15, 1)

    if type(text) == "table" then
        for _, line in ipairs(text) do
            UILabel.new(contentSizer, line, true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
        end
    else
        UILabel.new(contentSizer, tostring(text),true, TextAlignment.LEFT, VerticalAlignment.TOP, -1, -1, -1, -1, BorderDirection.NONE, 0, 1)
    end

    UIHorizontalLine.new(bgSizer, -1, -1, -1, -1, BorderDirection.BOTTOM, 0, 0)

    local columnSizerButtons = UIColumnLayoutSizer.new()
    UIPanel.new(bgSizer, columnSizerButtons, -1, -1, 150, -1, BorderDirection.ALL, 10, 0)

    UILabel.new(columnSizerButtons, "", false, TextAlignment.LEFT, VerticalAlignment.TOP)

    UIButton.new(columnSizerButtons, "OK", function() window:close() end, nil, -1, -1, 80, 24, BorderDirection.RIGHT, 10, 0)

    window:fit()
    window:refresh()
    window:showWindow()

    return window
end

PlaceableImporter.new()
