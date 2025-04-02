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

function OnButtonPressed_Logs8(x, y, device, key)
	changelogs_Display(7)
end

function OnButtonPressed_Logs9(x, y, device, key)
	changelogs_Display(8)
end

function OnButtonPressed_Logs10(x, y, device, key)
	changelogs_Display(9)
end

function OnButtonPressed_Logs11(x, y, device, key)
	changelogs_Display(10)
end

function OnButtonPressed_Logs12(x, y, device, key)
	changelogs_Display(11)
end

function OnButtonPressed_Logs13(x, y, device, key)
	changelogs_Display(12)
end

function OnButtonPressed_Logs14(x, y, device, key)
	changelogs_Display(13)
end

function OnButtonPressed_Logs15(x, y, device, key)
	changelogs_Display(14)
end

function OnButtonPressed_Logs16(x, y, device, key)
	changelogs_Display(15)
end

function OnButtonPressed_Logs17(x, y, device, key)
	changelogs_Display(16)
end

function OnButtonPressed_Logs18(x, y, device, key)
	changelogs_Display(17)
end

function OnButtonPressed_Logs19(x, y, device, key)
	changelogs_Display(18)
end

function OnButtonPressed_Logs20(x, y, device, key)
	changelogs_Display(19)
end

function OnButtonPressed_Logs21(x, y, device, key)
	changelogs_Display(20)
end

function OnButtonPressed_Logs22(x, y, device, key)
	changelogs_Display(21)
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