function Run()
	local Element = FindNode("\\application\\game\\Hud")
	Element:ShowPanel("HudRootAnalyser", true)
	-- (\GUI\HudRoot\Container\AccuserNameLabel\cl_WinContainer) KEYBOARDHELP
end

function initdeepanalysis()
	local HUD = FindNode("\\application\\game\\Hud")
	HUD:ShowPanel("HudRootAnalyser", false)

	local GetHeaderNode = function(Index)
		local List = {"Application","ResourceMgr","FileSystem","Settings","Console","ScriptMgr","Network","Database","DeviceManager","Renderer","windowmanager","GUI\\HudRoot","SoundSystem","FilterManager","World","World3D"}
		return List[Index+1]
	end

	Element 	  = FindNode("\\GUI\\HudRoot")
	Element       = Element:GetChildAt(24)
	Element       = Element:GetChildAt(0)
	Element       = Element:GetChildAt(7)
	Element 	  = FindNode("\\"..GetHeaderNode(Element:GetValueInt("IDENTIFIER")))

	RunTime = 0
	local Child

	for i = 0, Element:GetChildCnt() - 1 do
		Child = Element:GetChildAt(i)
		LogMessage("@HUD_ANALYSIS ("..i..") Name: "..(Child:GetName() or '<no-name>'))
		if Child:GetChildCnt() > 0 then
			Sleep(0.1)
			if RunTime > 1000 then
				LogMessage("@HUD_ANALYSIS #E Limit reached for this early alpha feature! Consider refining your search criteria.")
				return
			end
			ms_hudrootnodes_deepseek(Child, Child:GetChildCnt(), 0)
		end
	end
end

function deepseek(Node, Count, Depth)
	local Element = FindNode("\\GUI\\HudRoot")
	Element 	  = Element:GetChildAt(24)
	Element 	  = Element:GetChildAt(0)
	Element 	  = Element:GetChildAt(8)

	local Count = Element:GetChildCnt()
	local Value
	local Properties = {}
	local PropCount  = 0

	local function GetHeaderProperty(Index)
		local List = {[1]='NODE_NAME',[3]='TEXT',[6]='EVENTNAME',[8]='Handle',[9]='EVENTSCRIPT',[12]='TITLE',[13]='CAPTION',[15]='TAB_POSITION',[17]='TEXTURE_FILENAME',[20]='STATE',[21]='CamName',[24]='SLIDER_CURRENTVALUE',[26]='ENABLED',[28]='NAT',[29]='IDENTIFIER'}
		return List[Index]
	end

	for Index = 0, Count -1 do
		Value = Element:GetChildAt(Index)
		if Value and Value ~= nil then
			if Value:GetValueInt("IDENTIFIER") ~= nil then
				if Value:GetValueInt("COLOR_A") ~= nil then
					if Value:GetValueInt("COLOR_A") == 1 then
						PropCount = PropCount + 1
						Properties[PropCount] = GetHeaderProperty(Index)
					end
				end
			end
		end
	end

	Depth = Depth or 0
	local Prefix = string.rep("_", Depth * 2)
	local NewChild
	for i = 0, Count - 1 do
		NewChild = Node:GetChildAt(i)
		if NewChild and NewChild ~= nil then
			Sleep(0.00001)
			for _, v in helpfuncs_myipairs(Properties) do
				RunTime = RunTime +1
				local Property = NewChild:GetValueString(v)
				if Property and Property ~= "" then
					LogMessage("@HUD_ANALYSIS #E "..Prefix.." ("..i..") "..v..": "..(NewChild:GetValueString(v) or '<error>'))
				end
			end
			if RunTime > 1000 then
				LogMessage("@HUD_ANALYSIS #W Limit reached for this early alpha feature! Consider refining your search criteria.")
				return
			end
			if NewChild:GetChildCnt() > 0 then

				ms_hudrootnodes_deepseek(NewChild, NewChild:GetChildCnt(), Depth+1)
			end
		end
	end
end