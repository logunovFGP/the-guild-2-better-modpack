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

function CheckDuplicateHotkey(Command, Key)
	local object = FindNode("\\application\\game\\Hud")
	local options = FindNode("\\Settings\\Options")
	LogMessage("@HUD_REFORGED test " .. Command .. Key)
	local KEYS = 
	{
	    {"SPEED_UP", 2000, 59},
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
	    {"CAM_TOGGLE_FOLLOW", 2000, 33},
	    {"CAM_NORTH", 2000, 49},
	    {"CAM_TOGGLE", 2000, 24},
	    {"MAKE_SCREENSHOT", 2000, 183},
	    {"ADD_TO_SELECTION", 2000, 42},
	    {"MAP_TOGGLE", 2000, 50},
	    {"RPG_SAY", 2000, 19},
	    {"CAMERA_PATH_1", 2000, 71},
	    {"CAMERA_PATH_2", 2000, 72},
	    {"CAMERA_PATH_3", 2000, 73},
	    {"CAMERA_PATH_4", 2000, 74},
	    {"CAMERA_PATH_5", 2000, 75},
	    {"CAMERA_PATH_6", 2000, 76},
	    {"FREE_PATH_1", 2000, 77},
	    {"FREE_PATH_2", 2000, 78},
	    {"FREE_PATH_3", 2000, 79},
	    {"SWITCH_SKYBOX", 2000, 44},
	    {"CAPTURE_TOGGLE", 2000, 80},
	    {"CUTSCENE_TOGGLE", 2000, 46},
	    {"HIERACHY_STEPUP", 2000, 15},
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
	for v = 1, 61 do
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

function OnButtonPressed_SaveBtn(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper", false)
	object:ShowPanel("Options_Keymapper_Restart", true)
	--object:ShowPanel("MainMenu", true)
	local options = FindNode("\\Settings\\Options")
	options:SetValueInt("Keymapper_Toggle", 1)
	LogMessage("@HUD_REFORGED #W Game set to load custom keys.")
end

function OnButtonPressed_RevertToDefaultBtn(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	local options = FindNode("\\Settings\\Options")
	options:SetValueInt("Keymapper_Toggle", 0)
	object:ShowPanel("Options_Keymapper", false)
	--object:ShowPanel("MainMenu", true)
	object:ShowPanel("Options_Keymapper_Restart", true)
	LogMessage("@HUD_REFORGED #W Game set to load default keys.")
end

-- Debug
function OnKeyDown(key)
	LogMessage("@HUD_REFORGED #W OnButtonPressed")
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
end

function OnButtonPressed_KeyAlreadyAssignedNoBtn(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper_Duplicate", false)
	object:ShowPanel("Options_Keymapper", true)
end

-- Container Popup
function OnKeyDown_ContainerPopup(key)
	local options = FindNode("\\Settings\\Options")
	local command = options:GetValueString("EditingCommand")
	local object = FindNode("\\application\\game\\Hud")
	if keymapper_CheckDuplicateHotkey(command, key) == true then
		options:SetValueString("EditingKey", key)
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
end

function OnButtonPressed_ContainerPopupCancel(key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("Options_Keymapper_Popup", false)
	object:ShowPanel("Options_Keymapper", true)
end

-- Keys
function OnButtonPressed_EditSpeedUp(x, y, device, key)
	keymapper_ShowPopup("SPEED_UP")
end

function OnButtonPressed_EditSpeedUp2(x, y, device, key)
	keymapper_ShowPopup("SPEED_UP2")
end

function OnButtonPressed_EditSpeedDown(x, y, device, key)
	keymapper_ShowPopup("SPEED_DOWN")
end

function OnButtonPressed_EditSpeedDown2(x, y, device, key)
	keymapper_ShowPopup("SPEED_DOWN2")
end

function OnButtonPressed_EditSpeedNormal(x, y, device, key)
	keymapper_ShowPopup("SPEED_NORMAL")
end

function OnButtonPressed_EditTogglePause(x, y, device, key)
	keymapper_ShowPopup("TOGGLE_PAUSE")
end

function OnButtonPressed_EditTogglePseudoPause(x, y, device, key)
	keymapper_ShowPopup("TOGGLE_PSEUDOPAUSE")
end

function OnButtonPressed_EditToggleHud(x, y, device, key)
	keymapper_ShowPopup("TOGGLE_HUD")
end

function OnButtonPressed_EditShowCameraInfo(x, y, device, key)
	keymapper_ShowPopup("SHOW_CAMERA_INFO")
end

function OnButtonPressed_EditRPGSay(x, y, device, key)
	keymapper_ShowPopup("RPG_SAY")
end

function OnButtonPressed_EditQuicksave(x, y, device, key)
	keymapper_ShowPopup("QUICKSAVE")
end

function OnButtonPressed_EditQuickload(x, y, device, key)
	keymapper_ShowPopup("QUICKLOAD")
end

function OnButtonPressed_EditMenuToggle(x, y, device, key)
	keymapper_ShowPopup("MENU_TOGGLE")
end

function OnButtonPressed_EditMenuToggleCharacter(x, y, device, key)
	keymapper_ShowPopup("MENU_TOGGLE_CHARACTER")
end

function OnButtonPressed_EditMenuToggleFinance(x, y, device, key)
	keymapper_ShowPopup("MENU_TOGGLE_FINANCE")
end

function OnButtonPressed_EditMenuToggleBooks(x, y, device, key)
	keymapper_ShowPopup("MENU_TOGGLE_BOOKS")
end

function OnButtonPressed_EditMenuTogglePolitics(x, y, device, key)
	keymapper_ShowPopup("MENU_TOGGLE_POLITICS")
end

function OnButtonPressed_EditMenuToggleBuilding(x, y, device, key)
	keymapper_ShowPopup("MENU_TOGGLE_BUILDING")
end

function OnButtonPressed_EditToggleClientlist(x, y, device, key)
	keymapper_ShowPopup("TOGGLE_CLIENTLIST")
end

function OnButtonPressed_EditToggleChat(x, y, device, key)
	keymapper_ShowPopup("TOGGLE_CHAT")
end

function OnButtonPressed_EditChatTeam(x, y, device, key)
	keymapper_ShowPopup("CHAT_TEAM")
end

function OnButtonPressed_EditMapToggle(x, y, device, key)
	keymapper_ShowPopup("MAP_TOGGLE")
end