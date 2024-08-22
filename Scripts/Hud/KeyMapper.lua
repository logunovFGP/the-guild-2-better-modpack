-- Global
function SetEditingForCommand(Command)
	local options = FindNode("\\Settings\\Options")
	options:SetValueString("EditingCommand", Command)
	LogMessage("@HUD_REFORGED #W Currently editing the following command > " .. options:GetValueString("EditingCommand"))
end

function ShowPopup(Command)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper", false)
	object:ShowPanel("Options_Keymapper_Popup", true)
	keymapper_SetEditingForCommand(Command)
end

function BreakGameLabel(Key)
	local options = FindNode("\\Settings\\Options")
	local element = FindNode("\\GUI\\HudRoot")
	local NodeLabel = options:GetValueString("Keymapper_NodeLabel")
	LogMessage("@HUD_REFORGED #W BreakGameLabel with " .. NodeLabel)
	element = element:FindChildDepth(NodeLabel)
	element:SetValueString("CAPTION", keymapper_TranslateKeyToLabel(Key))
end

function BreakGameLabelsForAll()
	local options = FindNode("\\Settings\\Options")
	local toggle = options:GetValueInt("Keymapper_Toggle")
	local Element, Identifier, Default, NodeName
	local keys =
	{
		{"SPEED_UP",82,"SpeedUpBtn"}, {"SPEED_UP2",187,"SpeedUp2Btn"}, {"SPEED_DOWN",81,"SpeedDownBtn"}, {"SPEED_DOWN2",189,"SpeedDown2Btn"}, {"SPEED_NORMAL",207,"SpeedNormalBtn"}, {"TOGGLE_PAUSE",197,"TogglePauseBtn"}, {"TOGGLE_PSEUDOPAUSE",57,"TogglePseudoPauseBtn"}, {"TOGGLE_HUD",35,"ToggleHudBtn"}, {"SHOW_CAMERA_INFO",23,"ShowCameraInfoBtn"}, {"RPG_SAY",19,"RPGSayBtn"}, {"QUICKSAVE",16,"QuicksaveBtn"}, {"QUICKLOAD",38,"QuickloadBtn"}, {"MENU_TOGGLE",1,"MenuToggleBtn"}, {"MENU_TOGGLE_CHARACTER",46,"MenuToggleCharacterBtn"}, {"MENU_TOGGLE_FINANCE",47,"MenuToggleFinanceBtn"}, {"MENU_TOGGLE_BOOKS",48,"MenuToggleBooksBtn"}, {"MENU_TOGGLE_POLITICS",25,"MenuTogglePoliticsBtn"}, {"MENU_TOGGLE_BUILDING",34,"MenuToggleBuildingBtn"}, {"TOGGLE_CLIENTLIST",37,"ToggleClientlistBtn"}, {"TOGGLE_CHAT",28,"ToggleChatBtn"}, {"CHAT_TEAM",20,"ChatTeamBtn"}, {"MAP_TOGGLE",50,"MapToggleBtn"}, {"CURSOR_LEFT",30,"MovementLeftBtn"}, {"CURSOR_RIGHT",32,"MovementRightBtn"}, {"CURSOR_DOWN",31,"MovementDownBtn"}, {"CURSOR_UP",17,"MovementUpBtn"}
	}
	LogMessage("@HUD_REFORGED #W LOADING CUSTOM LABELS")
	for i = 1, 22+4 do
		Identifier, Default, NodeName = keys[i][1], keys[i][2], keys[i][3]
		Element = FindNode("\\GUI\\HudRoot")
		Element = Element:FindChildDepth(NodeName)
		if options:GetValueInt("Keymapper_Toggle") == 1 then
			if options:GetValueString("Keymapper_" .. Identifier) then
				LogMessage("@HUD_REFORGED #W Display custom key: " .. Identifier .. " -> " .. i)
				Element:SetValueString("CAPTION", keymapper_TranslateKeyToLabel(options:GetValueString("Keymapper_" .. Identifier)))
			else
				LogMessage("@HUD_REFORGED #W Display default key (unmodified): " .. Identifier .. " -> " .. i)
				Element:SetValueString("CAPTION", keymapper_TranslateKeyToLabel(""..Default..""))
			end
		else
			LogMessage("@HUD_REFORGED #W Display default key: " .. Identifier .. " -> " .. i)
			Element:SetValueString("CAPTION", keymapper_TranslateKeyToLabel(""..Default..""))
		end
	end
end

function TranslateKeyToLabel(Key)
	local keys =
	{
		["1"] = "Escape",
		["2"] = "1",
		["3"] = "2",
		["4"] = "3",
		["5"] = "4",
		["6"] = "5",
		["7"] = "6",
		["8"] = "7",
		["9"] = "8",
		["10"] = "9",
		["11"] = "0",
		["12"] = "°",
		["13"] = "+",
		["14"] = "Return",
		["16"] = "Q",
		["17"] = "W",
		["18"] = "E",
		["19"] = "R",
		["20"] = "T",
		["21"] = "Y",
		["22"] = "U",
		["23"] = "I",
		["24"] = "O",
		["25"] = "P",
		["26"] = "Down arrow",
		["28"] = "Enter",
		["29"] = "CTRL",
		["30"] = "A",
		["31"] = "S",
		["32"] = "D",
		["33"] = "F",
		["34"] = "G",
		["35"] = "H",
		["36"] = "J",
		["37"] = "K",
		["38"] = "L",
		["42"] = "Shift",
		["44"] = "Z",
		["45"] = "X",
		["46"] = "C",
		["47"] = "V",
		["48"] = "B",
		["49"] = "N",
		["50"] = "M",
		["53"] = "Delete",
		["54"] = "Shift",
		["55"] = "Num. pad. *",
		["56"] = "ALT",
		["58"] = "CAPS",
		["59"] = "F1",
		["60"] = "F2",
		["61"] = "F3",
		["62"] = "F4",
		["63"] = "F5",
		["64"] = "F6",
		["65"] = "F7",
		["66"] = "F8",
		["67"] = "F9",
		["68"] = "F10",
		["69"] = "Num. pad. lock",
		["70"] = "Stp. Scroll",
		["71"] = "Num. pad. 1",
		["72"] = "Num. pad. 2",
		["73"] = "Num. pad. 3",
		["74"] = "Num. pad. 4",
		["75"] = "Num. pad. 5",
		["76"] = "Num. pad. 6",
		["77"] = "Num. pad. 7",
		["78"] = "Num. pad. 8",
		["79"] = "Num. pad. 9",
		["80"] = "Num. pad. 0",
		["81"] = "Num. pad. -",
		["82"] = "Num. pad. +",
		["83"] = "Num. pad. dot",
		["87"] = "F11",
		["88"] = "F12",
		["92"] = "*",
		["115"] = "F4",
		["123"] = "F12",
		["144"] = "Num. pad. lock",
		["145"] = "Stp. Scroll",
		["157"] = "CTRL",
		["181"] = "Num. pad. /",
		["183"] = "Print",
		["186"] = "$",
		["188"] = ",",
		["190"] = ";",
		["191"] = ":",
		["192"] = "ù",
		["197"] = "Pause",
		["199"] = "Top-Left",
		["200"] = "Up arrow",
		["201"] = "Scr. Top",
		["203"] = "Left arrow",
		["205"] = "Right arrow",
		["207"] = "End",
		["208"] = "Down arrow",
		["209"] = "Scr. Bott.",
		["210"] = "Insert",
		["211"] = "Delete",
		["221"] = "^",
		["222"] = "²",
		["226"] = ">"
	}
	LogMessage("@HUD_REFORGED #W ___ Translation: " .. (keys[""..Key..""] or 'Unassigned'))
	return keys[""..Key..""] or 'Unassigned'
end

function SetActiveButton(NodeLabel)
	local options = FindNode("\\Settings\\Options")
	options:SetValueString("Keymapper_NodeLabel", NodeLabel)
end

function CheckDuplicateHotkey(Command, Key)
	local object = FindNode("\\application\\game\\Hud")
	local options = FindNode("\\Settings\\Options")
	local KEYS = 
	{
	    {"SPEED_UP", 2000, 82},
	    {"SPEED_DOWN", 2000, 81},
	    {"SPEED_NORMAL", 2000, 207},
	    {"SPEED_UP2", 2000, 187},
	    {"SPEED_DOWN2", 2000, 189},
	    {"TOGGLE_PAUSE", 2000, 197},
	    {"TOGGLE_PSEUDOPAUSE", 2000, 57},
	    {"TOGGLE_HUD", 2000, 35},
	    {"SHOW_CAMERA_INFO", 2000, 23},
	    {"CURSOR_LEFT", 2000, 203},
	    {"CURSOR_RIGHT", 2000, 205},
	    {"CURSOR_UP", 2000, 200},
	    {"CURSOR_DOWN", 2000, 208},
	    {"CURSOR_LEFT", 2000, 30},
	    {"CURSOR_RIGHT", 2000, 32},
	    {"CURSOR_UP", 2000, 17},
	    {"CURSOR_DOWN", 2000, 31},
	    {"TOGGLE_SHIFT", 2000, 42},
	    {"TOGGLE_SHIFT", 2000, 54},
	    {"TOGGLE_CTRL", 2000, 29},
	    {"TOGGLE_CTRL", 2000, 157},
	    {"TOGGLE_ALT", 2000, 56},
	    {"TOGGLE_ALT", 2000, 184},
	    {"CAM_MOVE_X", 2100, 2004},
	    {"CAM_MOVE_Y", 2100, 2005},
	    {"CAM_ANGLE_AXIS", 2100, 2006},
	    {"MOUSE_LB", 2100, 2101},
	    {"MOUSE_RB", 2100, 2102},
	    {"MOUSE_MB", 2100, 2103},
	    --{"CAM_TOGGLE_FOLLOW", 2000, 33},
	    --{"CAM_NORTH", 2000, 49},
	    --{"CAM_TOGGLE", 2000, 24},
	    {"MAKE_SCREENSHOT", 2000, 183},
	    --{"ADD_TO_SELECTION", 2000, 42},
	    {"MAP_TOGGLE", 2000, 50},
	    {"RPG_SAY", 2000, 19},
	    --{"CAMERA_PATH_1", 2000, 71},
	    --{"CAMERA_PATH_2", 2000, 72},
	    --{"CAMERA_PATH_3", 2000, 73},
	    --{"CAMERA_PATH_4", 2000, 74},
	    --{"CAMERA_PATH_5", 2000, 75},
	    --{"CAMERA_PATH_6", 2000, 76},
	    --{"FREE_PATH_1", 2000, 77},
	    --{"FREE_PATH_2", 2000, 78},
	    --{"FREE_PATH_3", 2000, 79},
	    --{"SWITCH_SKYBOX", 2000, 44},
	    --{"CAPTURE_TOGGLE", 2000, 80},
	    --{"CUTSCENE_TOGGLE", 2000, 46},
	    --{"HIERACHY_STEPUP", 2000, 15},
	    {"TOGGLE_CHAT", 2000, 28},
	    {"CHAT_TEAM", 2000, 20},
	    {"MENU_TOGGLE", 2000, 1},
	    {"MENU_TOGGLE_CHARACTER", 2000, 46},
	    {"MENU_TOGGLE_FINANCE", 2000, 47},
	    {"MENU_TOGGLE_BOOKS", 2000, 48},
	    {"MENU_TOGGLE_POLITICS", 2000, 25},
	    {"MENU_TOGGLE_BUILDING", 2000, 34},
	    {"QUICKSAVE", 2000, 16},
	    {"QUICKLOAD", 2000, 38},
	    {"TOGGLE_CLIENTLIST", 2000, 37},
	    {"ONSCREENHELP_TOGGLE", 2000, 15}
	}
	for v = 1, 61 - (17) do
		local command, value = KEYS[v][1], KEYS[v][3]
		if options:GetValueString("Keymapper_" .. command) ~= nil then
			if options:GetValueString("Keymapper_" .. command) == ""..Key.."" then
				return true
			end
		elseif value == ""..Key.."" then
			return true
		end
	end
	return false
end

-- Main
function OnButtonPressed_TabInit(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper", true)
	object:ShowPanel("Options_Sound", false)
	object:ShowPanel("Options_Game", false)
	object:ShowPanel("Options_Gfx", false)
	keymapper_BreakGameLabelsForAll()
end

function OnButtonPressed_TabGame(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper", false)
	object:ShowPanel("Options_Game", true)
end

function OnButtonPressed_TabSound(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper", false)
	object:ShowPanel("Options_Sound", true)
end

function OnButtonPressed_TabGFX(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper", false)
	object:ShowPanel("Options_Gfx", true)
end

function OnButtonPressed_KeySaveCustomBtn(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper", false)
	object:ShowPanel("Options_Keymapper_Restart", true)
	local options = FindNode("\\Settings\\Options")
	options:SetValueInt("Keymapper_Toggle", 1)
	LogMessage("@HUD_REFORGED #W Game set to load custom keys.")
end

function OnButtonPressed_RevertToDefaultBtn(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	local options = FindNode("\\Settings\\Options")
	options:SetValueInt("Keymapper_Toggle", 0)
	object:ShowPanel("Options_Keymapper", false)
	object:ShowPanel("Options_Keymapper_Restart", true)
	LogMessage("@HUD_REFORGED #W Game set to load default keys.")
end

function OnButtonPressed_WipeCustomBtn(x, y, device, key)
	local options = FindNode("\\Settings\\Options")
	local Identifier, Default
	local keys =
	{
		{"SPEED_UP",82}, {"SPEED_UP2",187}, {"SPEED_DOWN",81}, {"SPEED_DOWN2",189}, {"SPEED_NORMAL",207}, {"TOGGLE_PAUSE",197}, {"TOGGLE_PSEUDOPAUSE",57}, {"TOGGLE_HUD",35}, {"SHOW_CAMERA_INFO",23}, {"RPG_SAY",19}, {"QUICKSAVE",16}, {"QUICKLOAD",38}, {"MENU_TOGGLE",1}, {"MENU_TOGGLE_CHARACTER",46}, {"MENU_TOGGLE_FINANCE",47}, {"MENU_TOGGLE_BOOKS",48}, {"MENU_TOGGLE_POLITICS",25}, {"MENU_TOGGLE_BUILDING",34}, {"TOGGLE_CLIENTLIST",37}, {"TOGGLE_CHAT",28}, {"CHAT_TEAM",20}, {"MAP_TOGGLE",50}, {"CURSOR_LEFT",30}, {"CURSOR_RIGHT",32}, {"CURSOR_DOWN",31}, {"CURSOR_UP",17}
	}
	LogMessage("@HUD_REFORGED #W WIPE CUSTOM KEYS")
	for i = 1, 22+4 do
		Identifier, Default = keys[i][1], keys[i][2]
		options:SetValueString("Keymapper_" .. Identifier, Default)
	end
	keymapper_BreakGameLabelsForAll()
end

-- Restart
function OnButtonPressed_RestartBtn(x, y, device, key)
	local options = FindNode("\\World")
	local object = FindNode("\\application\\game\\Hud")
	if options:GetValueString("File Location") ~= "Worlds/charactercreation.wld" then 
		LogMessage("@HUD_REFORGED #W Game in active play. Restart manually to apply changes.")
		object:ShowPanel("Options_Keymapper_Restart", false)
		object:ShowPanel("Options_Keymapper_RestartActivePlay", true)
	else
		LogMessage("@HUD_REFORGED #W Game restart (RestartBtn).")
		local game = FindNode("\\Application\\Game")
		game:ChangeGameState("GameStartUp")
	end
end

function OnButtonPressed_RestartActivePlayOkBtn(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper_RestartActivePlay", false)
	object:ShowPanel("InGameMenu", true)
end

-- Key already assigned
function OnButtonPressed_KeyAlreadyAssignedYesBtn(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper_Duplicate", false)
	object:ShowPanel("Options_Keymapper", true)
	local options = FindNode("\\Settings\\Options")
	local C, K = options:GetValueString("EditingCommand"), options:GetValueString("EditingKey")
	options:SetValueString("Keymapper_" .. C, K)
	LogMessage("@HUD_REFORGED #W Modified " .. C .. " to KEY ID " .. K .. ".")
	keymapper_BreakGameLabel(options:GetValueString("EditingKey"))
end

function OnButtonPressed_KeyAlreadyAssignedNoBtn(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper_Duplicate", false)
	object:ShowPanel("Options_Keymapper", true)
end

-- Assign a key
function OnKeyDown_KeyTextFieldEdit(key)
	local options = FindNode("\\Settings\\Options")
	local command = options:GetValueString("EditingCommand")
	local object = FindNode("\\application\\game\\Hud")
	options:SetValueString("EditingKey", key)
	if keymapper_CheckDuplicateHotkey(command, key) == true then
		LogMessage("@HUD_REFORGED #W Key " .. key .. " is already assigned.")
		object:ShowPanel("Options_Keymapper_Popup", false)
		object:ShowPanel("Options_Keymapper_Duplicate", true)
		return
	end
	options:SetValueString("Keymapper_" .. command, key)
	LogMessage("@HUD_REFORGED #W Modified " .. command .. " to KEY ID " .. key .. ".")
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper", true)
	object:ShowPanel("Options_Keymapper_Popup", false)
	keymapper_BreakGameLabel(key)
end

function OnButtonPressed_ContainerPopupCancel(key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper_Popup", false)
	object:ShowPanel("Options_Keymapper", true)
end

-- Keys
function OnButtonPressed_EditSpeedUp(x, y, device, key)
	keymapper_ShowPopup("SPEED_UP")
	keymapper_SetActiveButton("SpeedUpBtn")
end

function OnButtonPressed_EditSpeedUp2(x, y, device, key)
	keymapper_ShowPopup("SPEED_UP2")
	keymapper_SetActiveButton("SpeedUp2Btn")
end

function OnButtonPressed_EditSpeedDown(x, y, device, key)
	keymapper_ShowPopup("SPEED_DOWN")
	keymapper_SetActiveButton("SpeedDownBtn")
end

function OnButtonPressed_EditSpeedDown2(x, y, device, key)
	keymapper_ShowPopup("SPEED_DOWN2")
	keymapper_SetActiveButton("SpeedDown2Btn")
end

function OnButtonPressed_EditSpeedNormal(x, y, device, key)
	keymapper_ShowPopup("SPEED_NORMAL")
	keymapper_SetActiveButton("SpeedNormalBtn")
end

function OnButtonPressed_EditTogglePause(x, y, device, key)
	keymapper_ShowPopup("TOGGLE_PAUSE")
	keymapper_SetActiveButton("TogglePauseBtn")
end

function OnButtonPressed_EditTogglePseudoPause(x, y, device, key)
	keymapper_ShowPopup("TOGGLE_PSEUDOPAUSE")
	keymapper_SetActiveButton("TogglePseudoPauseBtn")
end

function OnButtonPressed_EditToggleHud(x, y, device, key)
	keymapper_ShowPopup("TOGGLE_HUD")
	keymapper_SetActiveButton("ToggleHudBtn")
end

function OnButtonPressed_EditShowCameraInfo(x, y, device, key)
	keymapper_ShowPopup("SHOW_CAMERA_INFO")
	keymapper_SetActiveButton("ShowCameraInfoBtn")
end

function OnButtonPressed_EditRPGSay(x, y, device, key)
	keymapper_ShowPopup("RPG_SAY")
	keymapper_SetActiveButton("RPGSayBtn")
end

function OnButtonPressed_EditQuicksave(x, y, device, key)
	keymapper_ShowPopup("QUICKSAVE")
	keymapper_SetActiveButton("QuicksaveBtn")
end

function OnButtonPressed_EditQuickload(x, y, device, key)
	keymapper_ShowPopup("QUICKLOAD")
	keymapper_SetActiveButton("QuickloadBtn")
end

function OnButtonPressed_EditMenuToggle(x, y, device, key)
	keymapper_ShowPopup("MENU_TOGGLE")
	keymapper_SetActiveButton("MenuToggleBtn")
end

function OnButtonPressed_EditMenuToggleCharacter(x, y, device, key)
	keymapper_ShowPopup("MENU_TOGGLE_CHARACTER")
	keymapper_SetActiveButton("MenuToggleCharacterBtn")
end

function OnButtonPressed_EditMenuToggleFinance(x, y, device, key)
	keymapper_ShowPopup("MENU_TOGGLE_FINANCE")
	keymapper_SetActiveButton("MenuToggleFinanceBtn")
end

function OnButtonPressed_EditMenuToggleBooks(x, y, device, key)
	keymapper_ShowPopup("MENU_TOGGLE_BOOKS")
	keymapper_SetActiveButton("MenuToggleBooksBtn")
end

function OnButtonPressed_EditMenuTogglePolitics(x, y, device, key)
	keymapper_ShowPopup("MENU_TOGGLE_POLITICS")
	keymapper_SetActiveButton("MenuTogglePoliticsBtn")
end

function OnButtonPressed_EditMenuToggleBuilding(x, y, device, key)
	keymapper_ShowPopup("MENU_TOGGLE_BUILDING")
	keymapper_SetActiveButton("MenuToggleBuildingBtn")
end

function OnButtonPressed_EditToggleClientlist(x, y, device, key)
	keymapper_ShowPopup("TOGGLE_CLIENTLIST")
	keymapper_SetActiveButton("ToggleClientlistBtn")
end

function OnButtonPressed_EditToggleChat(x, y, device, key)
	keymapper_ShowPopup("TOGGLE_CHAT")
	keymapper_SetActiveButton("ToggleChatBtn")
end

function OnButtonPressed_EditChatTeam(x, y, device, key)
	keymapper_ShowPopup("CHAT_TEAM")
	keymapper_SetActiveButton("ChatTeamBtn")
end

function OnButtonPressed_EditMapToggle(x, y, device, key)
	keymapper_ShowPopup("MAP_TOGGLE")
	keymapper_SetActiveButton("MapToggleBtn")
end

function OnButtonPressed_EditMovementLeft(x, y, device, key)
	keymapper_ShowPopup("CURSOR_LEFT")
	keymapper_SetActiveButton("MovementLeftBtn")
end

function OnButtonPressed_EditMovementRight(x, y, device, key)
	keymapper_ShowPopup("CURSOR_RIGHT")
	keymapper_SetActiveButton("MovementRightBtn")
end

function OnButtonPressed_EditMovementDown(x, y, device, key)
	keymapper_ShowPopup("CURSOR_DOWN")
	keymapper_SetActiveButton("MovementDownBtn")
end

function OnButtonPressed_EditMovementUp(x, y, device, key)
	keymapper_ShowPopup("CURSOR_UP")
	keymapper_SetActiveButton("MovementUpBtn")
end