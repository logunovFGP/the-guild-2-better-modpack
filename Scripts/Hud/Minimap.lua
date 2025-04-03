function OnButtonPressed_TopLeft(x, y, device, key)
	local Setting = FindNode("\\Settings\\Options")
	Setting:SetValueInt("MinimapPos", 1)
	minimap_Refresh()
end

function OnButtonPressed_BottomRight(x, y, device, key)
	local Setting = FindNode("\\Settings\\Options")
	Setting:SetValueInt("MinimapPos", 2)
	minimap_Refresh()
end

function OnButtonPressed_Top(x, y, device, key)
	local Setting = FindNode("\\Settings\\Options")
	Setting:SetValueInt("MinimapPos", 3)
	minimap_Refresh()
end

function OnButtonPressed_Show(x, y, device, key)
	local Setting = FindNode("\\Settings\\Options")
	Setting:SetValueInt("MinimapVisibility", 2)
	minimap_Refresh()
end

function OnButtonPressed_Hide(x, y, device, key)
	local Setting = FindNode("\\Settings\\Options")
	Setting:SetValueInt("MinimapVisibility", 1)
	minimap_Refresh()
end

function Refresh()
	local Node = FindNode("\\GUI\\HudRoot")
	local Count = Node:GetChildCnt()
	local Child

	for i = 0, Count - 1 do
		Child = Node:GetChildAt(i)
		if Child ~= nil then
			if Child:GetValueString("PanelName") ~= nil then
				if Child:GetValueString("PanelName") == "MiniMapPanel" then
					break
				end
			end
		end
	end

	local Node = Child
	local Count = Node:GetChildCnt()

	local Visibility, Position
	local Setting = FindNode("\\Settings\\Options")

	Visibility = Setting:GetValueInt("MinimapVisibility")
	Position   = Setting:GetValueInt("MinimapPos")

	-- MiniMapPanel 82305 (PanelID) 291544032.000000 (Handle) 193688864.000000 (check)

	if Visibility == 0 then
		Visibility = 1
	end

	if Position == 0 then
		Position = 3
	end

	local Setting = FindNode("\\Settings\\GFX")
	local ScreenResolution = {w=Setting:GetValueInt("ScreenWidth"), h=Setting:GetValueInt("ScreenHeight")}

	if Position == 1 then 
		Node:SetValueInt("ABS_X", 10)
		Node:SetValueInt("ABS_Y", 260)
	end
	if Position == 2 then 
		Node:SetValueInt("ABS_X", ScreenResolution.w-380)
		Node:SetValueInt("ABS_Y", ScreenResolution.h-320)
	end
	if Position == 3 then 
		Node:SetValueInt("ABS_X", ScreenResolution.w/2 - 250/4)
		Node:SetValueInt("ABS_Y", 65)
	end

	Node:SetValueInt("ABS_HEIGHT", 250+1)
	Node:SetValueInt("ABS_WIDTH", 250+1)

	Node:SetValueInt("VISIBILITY", Visibility-1)

	local Child
	local Table = {}

	for i = 0, Count - 1 do
		Child = Node:GetChildAt(i)
		if Child ~= nil then
			if Child:GetName() ~= "Decorator" then
				Child:SetValueInt("ABS_HEIGHT", 250)
				Child:SetValueInt("ABS_WIDTH", 250)
			end
		end
	end
end