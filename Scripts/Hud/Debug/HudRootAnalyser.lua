function OnButtonPressed_Cancel(x, y, device, key)
	local Element, HUD = FindNode("\\GUI\\HudRoot"), FindNode("\\application\\game\\Hud")
	HUD:ShowPanel("HudRootAnalyser", false)
end
	
function OnButtonPressed_Ok(x, y, device, key)
	cl_LoadingScreen:GetInstance():ShowLoadingScreen("LoadingScreen/balken.dds", 183, 684, 657, 32, 7, 3)
	ms_hudrootnodes_initdeepanalysis()
	cl_LoadingScreen:GetInstance():HideLoadingScreen(10)
end

--[[
function Run()
	local element = FindNode("\\GUI\\HudRoot")
	if element then 
		LogMessage("Found it")

		--ms_debug_weddings_DeepAnalysis("HUD_ANALYSIS", "\\GUI\\HudRoot")

		local childCount = element:GetChildCnt()

		for i = 0, childCount - 1 do
	        local child = element:GetChildAt(i)
	        if child then
	        	--if child:GetName() == 'ContainerTRIAL' then
					local childName = child:GetName() or '<no-name>'
					LogMessage('@HUD_ANALYSIS #E '..childName..': '..child:GetValueString("NODE_NAME"))
				--end
			end
		end
	end
	
	ShowPanel("TrialPanel", false)
	Sleep(2)


	local skip = true

	if not skip then
		--ms_debug_weddings_DeepAnalysis("BEFORE")
		CreateCutscene("default", "cutscene")
		CutsceneAddSim("cutscene", "")
		CutsceneAddSim("cutscene", "")
		CutsceneCameraCreate("cutscene", "")		
		camera_CutsceneBothLockCam("cutscene", "", "Far_HUpYRight")
		GetPosition("", "Position")

		if CutsceneLocalPlayerIsWatching("") then
			HudClearSelection()
		end

		local time = math.mod(GetGametime(), 24)

		--CutsceneHUDShow("cutscene","LetterBoxPanel")
		CutsceneHUDShow("cutscene","DevelopmentPanel")
		CutsceneHUDShow("cutscene","TrialPanel")
			
		--TrialHUDSetStatus("", 5, JudgePos, Assessor1Pos, Assessor2Pos, AccuserSentence, time)
		--TrialHUDSetStatus(24,24,24,24,5,1)
		TrialHUDSetSims("cutscene", GetID(""), GetID(""), GetID(""), GetID(""), GetID(""))
		Sleep(1)
		
		Sleep(1)
		CutsceneHUDShow("cutscene","DevelopmentPanel", false)

		MsgSay("", "@L_CHARACTERS_3_TITLES_AQUIRE_TOWNHALL_1_+0", GetID(""))
			
		--CutsceneHUDShow("cutscene","LetterBoxPanel", false)

		--ms_debug_weddings_DeepAnalysis("AFTER")
	end
end--]]

function OnButtonPressed_NodeMinus(x, y, device, key)
	local Element = FindNode("\\GUI\\HudRoot")
	Element 	  = Element:GetChildAt(24)
	Element 	  = Element:GetChildAt(0)
	Element 	  = Element:GetChildAt(7)
	local Message = Element:GetChildAt(4)

	Element:SetValueInt("IDENTIFIER",Element:GetValueInt("IDENTIFIER")-1)

	if Element:GetValueInt("IDENTIFIER") < 0 then
		Element:SetValueInt("IDENTIFIER", 15)
	end

	Message:SetValueString("TEXT", "@L_NODE_FINDER_+"..Element:GetValueInt("IDENTIFIER"))
end

function OnButtonPressed_NodePlus(x, y, device, key)
	local Element = FindNode("\\GUI\\HudRoot")
	Element 	  = Element:GetChildAt(24)
	Element 	  = Element:GetChildAt(0)
	Element 	  = Element:GetChildAt(7)
	local Message = Element:GetChildAt(4)

	Element:SetValueInt("IDENTIFIER",Element:GetValueInt("IDENTIFIER")+1)

	if Element:GetValueInt("IDENTIFIER") > 15 then
		Element:SetValueInt("IDENTIFIER", 0)
	end

	Message:SetValueString("TEXT", "@L_NODE_FINDER_+"..Element:GetValueInt("IDENTIFIER"))
end

function OnButtonPressed_Enabled(x, y, device, key)
	hudrootanalyser_SwitchState(26)
end

function OnButtonPressed_Identifier(x, y, device, key)
	hudrootanalyser_SwitchState(29)
end

function OnButtonPressed_Nat(x, y, device, key)
	hudrootanalyser_SwitchState(28)
end

function OnButtonPressed_SliderCurrentValue(x, y, device, key)
	hudrootanalyser_SwitchState(24)
end

function OnButtonPressed_CamName(x, y, device, key)
	hudrootanalyser_SwitchState(21)
end

function OnButtonPressed_State(x, y, device, key)
	hudrootanalyser_SwitchState(20)
end

function OnButtonPressed_TextureFilename(x, y, device, key)
	hudrootanalyser_SwitchState(17)
end

function OnButtonPressed_TabPosition(x, y, device, key)
	hudrootanalyser_SwitchState(15)
end

function OnButtonPressed_Title(x, y, device, key)
	hudrootanalyser_SwitchState(12)
end

function OnButtonPressed_Caption(x, y, device, key)
	hudrootanalyser_SwitchState(13)
end

function OnButtonPressed_Handle(x, y, device, key)
	hudrootanalyser_SwitchState(8)
end

function OnButtonPressed_EventName(x, y, device, key)
	hudrootanalyser_SwitchState(6)
end

function OnButtonPressed_Text(x, y, device, key)
	hudrootanalyser_SwitchState(3)
end

function OnButtonPressed_NodeName(x, y, device, key)
	hudrootanalyser_SwitchState(1)
end

function OnButtonPressed_EventScript(x, y, device, key)
	hudrootanalyser_SwitchState(9)
end

function SwitchState(Index)
	local Element = FindNode("\\GUI\\HudRoot")
	Element 	  = Element:GetChildAt(24)
	Element 	  = Element:GetChildAt(0)
	Element 	  = Element:GetChildAt(8)
	local Button  = Element:GetChildAt(Index)
	if Button:GetValueInt("COLOR_A") == 0 then
		Button:SetValueInt("COLOR_A", 1)
		LogMessage("@HUD_ANALYSIS ("..Button:GetName()..") -> 1")
	else
		Button:SetValueInt("COLOR_A", 0)
		LogMessage("@HUD_ANALYSIS ("..Button:GetName()..") -> 0")
	end
end