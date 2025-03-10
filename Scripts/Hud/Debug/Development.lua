function OnButtonPressed_ModuleOffBtn(x, y, device, key)
	LogMessage("OnButtonPressed_ModuleOffBtn")
	--local World = FindNode("\\ScriptMgr")
	--World:DisableModule("ScriptCtrl")
	--World:DetachModule("ScriptCtrl")

	--local World = FindNode("\\Application\\Game")
	--World:AttachModule("TestSuite", "cl_TestSuite")
	--World:EnableModule("TestSuite", 4)

	GetScenario("World")
	LogMessage("@REFORGED_NETWORK Messages: " .. GetProperty("World", "messages", 999))
	LogMessage("@REFORGED_NETWORK Ambient: " .. GetProperty("World", "ambient", 999))
	LogMessage("@REFORGED_NETWORK Messages: " .. GetProperty("World", "messages", 999))
	LogMessage("@REFORGED_NETWORK Messages: " .. GetProperty("World", "messages", 999))

	local WorldName
	WorldName = GetSettingString("NETWORK", "World", "")
	local options = FindNode("\\Settings\\Network")


	local PlayerDescNode = FindNode("\\Application\\Game\\PlayerDesc0")

	LogMessage("@REFORGED_NETWORK #W NETWORK World -> " .. WorldName)
	LogMessage("@REFORGED_NETWORK #W NETWORK Difficulty -> " .. ScenarioGetDifficulty())
	LogMessage("@REFORGED_NETWORK #W NETWORK Money -> " .. GetSettingNumber("INIT-PLAYER-" .. ScenarioGetDifficulty(), "Money", 5000))
	
	local PlayerDescNode = nil
	local PlayerDescPath = "\\Application\\Game\\PlayerDesc"..PlayerDescLabel
	PlayerDescNode = FindNode(PlayerDescPath)
	CityName = PlayerDescNode:GetValueString("City")
	LogMessage("@REFORGED_NETWORK #W ("..ID..") City -> " .. CityName)

end

function OnButtonPressed_ModuleOnBtn(x, y, device, key)

	GetScenario("World")
	local test = FindNode("\\World")
	LogMessage(test:GetValueInt("fos",9))--GetProperty("World", "fos", 999))

	LogMessage("OnButtonPressed_ModuleOnBtn")
	--local World = FindNode("\\Application\\Game")
	--World:AttachModule("ScriptCtrl", "cl_ScriptGameModule")
	--World:EnableModule("ScriptCtrl", 1)
	
	LogMessage("@REFORGED_NETWORK World: " .. GetSettingString("NETWORK", "World", "")) -- GetValueInt("NETWORK", "QuoteCitizen", 1))

		local element, v, v2 = FindNode("\\World\\Scenario")
		if element ~= nil then
			LogMessage("@HUD_REFORGED #W Found.")
			GetScenario("World")
			GetProperty("World",'QuoteCitizen',0)
		end
		

		LogMessage("@HUD_REFORGED #W GetValueInt: " .. element:GetProperty('QuoteCitizen',0))
		LogMessage("@HUD_REFORGED #W GetChildCnt: " .. element:GetChildCnt())
		LogMessage("@HUD_REFORGED #W GetLinkCnt: " .. element:GetLinkCnt())
		
		local properties = {"NODE_NAME","QuoteCitizen","messages","fos","World","NAT"}

		local function LogProperties(element, prefix)
		    for _, property in helpfuncs_myipairs(properties) do
		        local value = element:GetValueString(property)
		        if value and value ~= '' then
		            LogMessage("@HUD_REFORGED #W " .. prefix .. property .. ": '" .. value .. "'")
		        else
		            value = element:GetValueInt(property)
		            if value and value ~= 0 then
		                LogMessage("@HUD_REFORGED #W " .. prefix .. property .. ": '" .. value .. "'")
		            else
		                value = element:GetValueFloat(property)
		                if value and value ~= 0 then
		                    LogMessage("@HUD_REFORGED #W " .. prefix .. property .. ": '" .. value .. "'")
		                end
		            end
		        end
		    end
		end

		local function ProcessElement(element, depth)
			Sleep(0.0001)
		    depth = depth or 0
		    local prefix = string.rep("_", depth * 2)
		    local childCount = element:GetChildCnt()

		    for i = 0, childCount - 1 do
		        local child = element:GetChildAt(i)
		        if child then
		            local childName = child:GetName() or '<no-name>'
		            LogMessage("@HUD_REFORGED #W " .. prefix .. "(" .. (i + 1) .. "): " .. childName)
		            LogProperties(child, prefix .. "___ ")
		            ProcessElement(child, depth + 1)
		        end
		    end
		end

		ProcessElement(element)

		local cl_DPlayPeer = FindNode("\\Network")

		if cl_DPlayPeer ~= nil then 

		end

		
 	--local object = FindNode("\\application\\game\\Hud")
	--object:ShowPanel("DynStatus", true)
end