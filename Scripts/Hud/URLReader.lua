function OnButtonPressed_Discord(x, y, device, key)
	local InputCtrl = FindNode("\\Application\\Game\\InputCtrl")
	InputCtrl:SetInputMapping("https://discord.gg/zhd7e95ZFt", "1", "1")
	InputCtrl:SaveInputMapping("inputurl.ini")
	--InputCtrl:LoadInputMapping("input.ini")
	urlreader_ResetInputMappingToNormal()
end

function OnButtonPressed_Website(x, y, device, key)
	local InputCtrl = FindNode("\\Application\\Game\\InputCtrl")
	InputCtrl:SetInputMapping("http://guild2reforged.com/", "1", "1")
	InputCtrl:SaveInputMapping("inputurl.ini")
	--InputCtrl:LoadInputMapping("input.ini")
	urlreader_ResetInputMappingToNormal()
end

function ResetInputMappingToNormal()
	local Options   = FindNode("\\Settings\\Options")
	local InputCtrl = FindNode("\\Application\\Game\\InputCtrl")

	InputCtrl:LoadInputMapping("inputvoid.ini")

	if Options:GetValueInt("Keymapper_Toggle") == 0 then
		InputCtrl:LoadInputMapping("input.ini")
	elseif Options:GetValueInt("Keymapper_Toggle") == 1 then
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
		    {"CAM_TOGGLE_FOLLOW", 2000, 33},
		    {"CAM_NORTH", 2000, 49},
		    --{"CAM_TOGGLE", 2000, 24},
		    {"MAKE_SCREENSHOT", 2000, 183},
		    {"ADD_TO_SELECTION", 2000, 42},
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
		for v = 1, 47 do
			local command, device, value = KEYS[v][1], KEYS[v][2], KEYS[v][3]
			if Options:GetValueString("Keymapper_" .. command) then
				value = Options:GetValueString("Keymapper_" .. command)
			end
			InputCtrl:SetInputMapping(command, device, value)
		end
	end
end