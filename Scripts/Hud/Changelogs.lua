function OnButtonPressed_Open(x, y, device, key)
	local object = FindNode("\\application\\game\\Hud")
	object:ShowPanel("ChangeLogs", true)
	object:ShowPanel("MainMenu", false)
end

function OnButtonPressed_Back(x, y, device, key)
	local Node = FindNode("\\application\\game\\Hud")
	Node:ShowPanel("ChangeLogs", false)
	Node:ShowPanel("MainMenu", true)
end

function OnButtonPressed_Logs1(x, y, device, key)
	changelogs_Display(0)
end

function OnButtonPressed_Logs2(x, y, device, key)
	changelogs_Display(1)
end

function OnButtonPressed_Logs3(x, y, device, key)
	changelogs_Display(2)
end

function OnButtonPressed_Logs4(x, y, device, key)
	changelogs_Display(3)
end

function OnButtonPressed_Logs5(x, y, device, key)
	changelogs_Display(4)
end

function OnButtonPressed_Logs6(x, y, device, key)
	changelogs_Display(5)
end

function OnButtonPressed_Logs7(x, y, device, key)
	changelogs_Display(6)
end

function OnButtonPressed_Logs8(x, y, device, key)
	changelogs_Display(7)
end

function Display(Number)
	local Node 		= FindNode("\\GUI\\HudRoot")
	local Author 	= Node:FindChildDepth("Author")
	local Title 	= Node:FindChildDepth("LogsHeader")
	local Desc 		= Node:FindChildDepth("LogsDesc")
	Author:SetValueString("TEXT", "@LChangelog#"..Number.."_+0")
	Title:SetValueString("TEXT", "@LChangelog#"..Number.."_+1")
	Desc:SetValueString("TEXT", "@LChangelog#"..Number.."_+2")
end