local function GetElement()
	local Console = FindNode("\\GUI\\HudRoot")
	Console = Console:FindChildDepth("ConsoleTextWnd")
	Console = Console:GetParent()
	Console = Console:GetParent()
	Console = Console:GetChildAt(2)
	return Console
end

local function ConvertIdentToKey(Ident)
	local Table =
	{
		English = {
			["1"] = "Escape", ["2"] = "1", ["3"] = "2", ["4"] = "3", ["5"] = "4", ["6"] = "5", ["7"] = "6", ["8"] = "7", ["9"] = "8", ["10"] = "9", ["11"] = "0",
			["14"] = "Backspace", ["16"] = "Q", ["17"] = "W", ["18"] = "E", ["19"] = "R", ["20"] = "T", ["21"] = "Y", ["22"] = "U", ["23"] = "I", ["24"] = "O", ["25"] = "P", ["26"] = "Down arrow",
			["28"] = "Enter", ["29"] = "CTRL", ["30"] = "A", ["31"] = "S", ["32"] = "D", ["33"] = "F", ["34"] = "G", ["35"] = "H", ["36"] = "J", ["37"] = "K", ["38"] = "L",
			["40"] = "Num. pad. 0", 
			["42"] = "Shift", 
			["44"] = "Z", ["45"] = "X",	["46"] = "C", ["47"] = "V", ["48"] = "B", ["49"] = "N", ["50"] = "M", 
			["52"] = "Delete", 
			["55"] = "Num. pad. *", ["56"] = "ALT",	["57"] = "Space", ["58"] = "Caps Lock", ["59"] = "F1", ["60"] = "F2", ["61"] = "F3", ["62"] = "F4", ["63"] = "F5", ["64"] = "F6", ["65"] = "F7", ["66"] = "F8", ["67"] = "F9", ["68"] = "F10", ["69"] = "Num. pad. lock", ["70"] = "Scroll lock", ["71"] = "Num. pad. 1", ["72"] = "Num. pad. 2", ["73"] = "Num. pad. 3", ["74"] = "Num. pad. 4", ["75"] = "Num. pad. 5", ["76"] = "Num. pad. 6", ["77"] = "Num. pad. 7",	["78"] = "Num. pad. 8", ["79"] = "Num. pad. 9", 
			["81"] = "Num. pad. -", ["82"] = "Num. pad. +", ["83"] = "Num. pad. dot",
			["87"] = "F11", ["88"] = "F12", 
			["91"] = "[", ["92"] = "|", 
			["181"] = "Num. pad. /", 
			["183"] = "Print", 
			["186"] = ";", ["187"] = "+", ["188"] = ",", ["189"] = "_", ["190"] = ".", ["191"] = "/", ["192"] = "`",
			["197"] = "Pause", 
			["199"] = "Home", ["200"] = "Up arrow", ["201"] = "Page up", 
			["203"] = "Left arrow", ["205"] = "Right arrow", 
			["207"] = "End", 
			["209"] = "Page down",
			["210"] = "Insert",
			["221"] = "]", ["222"] = "'",
			["226"] = "|"
		},
		French =
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
			["57"] = " ",
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
	}
	return Table.French[""..Ident..""]
end

local function Print(String)
	local Console = FindNode("\\GUI\\HudRoot")
	Console = Console:FindChildDepth("ConsoleTextWnd")
	local Text = Console:GetValueString("TEXT")
	Console:SetValueString("TEXT", Text.."\n"..String)
end

local function Clear()
	local Console = FindNode("\\GUI\\HudRoot")
	Console = Console:FindChildDepth("ConsoleTextWnd")
	Console:SetValueString("TEXT", "")
	CONSOLE_COMMAND = {}
	CONSOLE_COUNTER = 0
end

local function RecogniseText(ID)
	if CONSOLE_COMMAND == nil then
		CONSOLE_COMMAND = {}
	end
	if CONSOLE_COUNTER == nil then
		CONSOLE_COUNTER = 0
	end
	CONSOLE_COUNTER = CONSOLE_COUNTER +1
	CONSOLE_COMMAND[CONSOLE_COUNTER] = ID
end

local function DeleteFromRight()
	if CONSOLE_COMMAND == nil then
		return
	end
	if CONSOLE_COUNTER > 0 then
		CONSOLE_COUNTER = CONSOLE_COUNTER -1
		CONSOLE_COMMAND[CONSOLE_COUNTER +1] = nil
	end
end

local function Process(Command, ...)
	local Console = GetElement()
	Console:SetValueString("TEXT", "")
	Clear()
	local Parameters = arg
	if Command == "Unstuck" then
		if arg[1] == "help" then
			Print("<unstuck> requires one selection.")
			Print("Selection: the Sim who is currently stuck.")
			Print("Example: unstuck")
		else
			Print("unstucking requires two positional parameters")
			Print("1: Character First Name (String)")
			Print("2: Character Last Name (String)")
		end
	end
	if Command == "XP" then
		if arg[1] == "help" then
			Print("<xp> requires one parameter and one selection.")
			Print("Number: amount of experience points.")
			Print("Selection: the Sim who is getting the experience points.")
			Print("Example: xp 5000")
		else
			Print("XP requires one parameter")
			Print("Distributing " .. Parameters[1] .. " experience points.")
		end
	end
end

local Run = 
{
	Unstuck = function(Parameters) Process('Unstuck', Parameters) end,
	XP = function(Parameters) Process('XP', Parameters) end,
}


-- Events

function OnButtonPressed_SendCommand(x, y, device, key)
	local Console = FindNode("\\GUI\\HudRoot")
	Console = Console:FindChildDepth("ConsoleTextWnd")
	Console = Console:GetParent()
	Console = Console:GetParent()
	Console = Console:GetChildAt(2)
	local Text = Console:GetValueString("TEXT")
	LogMessage("@NAO Name: " .. Console:GetName() .. " and Text: " .. Text )
	console_ProcessCommand()
	Clear()



end

function OnButtonPressed_OpenConsole(x, y, device, key)
	local HUD = FindNode("\\application\\game\\Hud")
	HUD:ShowPanel("Console", true)
	HUD:ShowPanel("MainMenu", false)
end

function OnButtonPressed_CloseConsole(x, y, device, key)
	local HUD = FindNode("\\application\\game\\Hud")
	HUD:ShowPanel("Console", false)
	HUD:ShowPanel("MainMenu", true)
end

function ProcessCommand()
end

function OnTextChanged_TextField()
	LogMessage("@NAO It works!")
end

function OnKeyDown_TextField(Key)
	LogMessage("@NAO #W Key is: " .. Key)

	if Key == 28 then
		local Construct = ""
		for k, v in helpfuncs_myipairs(CONSOLE_COMMAND) do
			Construct = Construct .. v
		end

		if string.find(Construct, "^UNSTUCK HELP") then
		    Run.Unstuck("help")
		elseif string.find(Construct, "^UNSTUCK") then
		    Run.Unstuck()
		end

		if string.find(Construct, "^XP HELP") then
		    Run.XP("help")
		elseif string.find(Construct, "^XP") then
		    Run.XP(2000)
		end

		return
	end

	local Found = false
	local Forbidden = {42, 54, 29, 157}

	for k, v in helpfuncs_myipairs(Forbidden) do
		if Key == v then
			Found = true
			break
		end
	end

	if Found then
		return
	end

	if Key == 14 then
		DeleteFromRight()
		return
	end

	RecogniseText(ConvertIdentToKey(Key))
	--Console:SetValueString("TEXT", "TEST2")
end

