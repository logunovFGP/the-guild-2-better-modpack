function Start()

	GetSettlement("Spouse1", "Settlement")
	GetPosition("Spouse1", "Position")
	CutsceneAddSim("", "Spouse1")

	local Sims = {"Spouse2", "Guest1", "Guest2", "Guest3"}

	for k, v in helpfuncs_myipairs(Sims) do
		SimCreate(918, "Settlement", "Position", v)
		SimSetFirstname(v, v)
		CutsceneAddSim("", v)
	end

	CutsceneCameraCreate("", "Position")

	TrialHUDSetSims("", GetID("Spouse1"), GetID("Spouse2"), GetID("Guest1"), GetID("Guest2"), GetID("Guest3"))

	-- Progress, Guest1, Guest2, Guest3, Arrow, Timer
	TrialHUDSetStatus("", 0, 0, 0, 0, 0, 0.0)
	Sleep(0.5)

	TrialHUDSetStatus("", 8, 7, 8, 9, 8, 2.0)
	Sleep(2.5)

	CutsceneHUDShow("","LetterBoxPanel")
	CutsceneHUDShow("","TrialPanel")

	weddingpanel_ChangeNode(true)

	SetExclusiveMeasure("Spouse1",2310,EN_BOTH)
	AllowMeasure("Spouse1",240,EN_BOTH)

	CutsceneCameraSetRelativePosition("", "CameraPortrait", "Spouse1")
	--CutsceneSetTimeBar("", 5)
	CutsceneShowCharacterPanel("",true)

	if GetLocalPlayerDynasty("LocalPlayerDyn") then
		GetDynasty("Spouse1", "SimDyn")
		if( GetID("SimDyn") == GetID("LocalPlayerDyn")) then
			HudClearSelection()
			HudAddToSelection("Spouse1")
		end
	end

	ProgressBar:SetValueInt("VISIBILITY",1)
	local Width
	while true do
		Width = ProgressBar:GetValueInt("ABS_WIDTH")
		ProgressBar:SetValueInt("ABS_WIDTH", Width-50)
		Sleep(0.1)
		if Width < 10 then
			break
		end
	end

	ProgressBar:SetValueInt("VISIBILITY",0)
	ProgressBar:SetValueInt("ABS_WIDTH",1000)

	Sleep(0.5)

	CutsceneHUDShow("","LetterBoxPanel",false)
	CutsceneHUDShow("","TrialPanel",false)

	EndCutscene("")
end

function OnCameraEnable()
	LogMessage("@NAO Camera Enable.")
	CutsceneHUDShow("","LetterBoxPanel")
	CutsceneHUDShow("","TrialPanel")
	weddingpanel_ChangeNode(true)
end

function OnCameraDisable()
	LogMessage("@NAO Camera Disable.")
	CutsceneHUDShow("","LetterBoxPanel", false)
	CutsceneHUDShow("","TrialPanel", false)
	weddingpanel_ChangeNode(false)
end

function ChangeNode(Bool)
	local Node = FindNode("\\GUI\\HudRoot")
	local Child, _Child

	for i = 0, Node:GetChildCnt() - 1 do
		Child = Node:GetChildAt(i)
		if Child:GetValueString("IDENTIFIER") ~= nil then
			if Child:GetValueString("IDENTIFIER") == "WeddingPanel" then
				LogMessage("@NAO ("..i..") -> "..Child:GetName())
				break
			end
		end
	end

	local NewLabels

	if Bool then
		NewLabels = {
		    'Cheap',        -- Very low-budget, unimpressive
		    'Modest',       -- A simple and decent ceremony
		    'Respectable',  -- A proper, well-organized wedding
		    'Grand',        -- A lavish event with notable guests
		    'Magnificent',  -- Extravagant and highly prestigious
		    'Legendary', 	-- A wedding that will be remembered for generations
		    'Disastrous',   -- Worst possible wedding, maybe barely legal

		}
	else
		NewLabels = {
		    '@L_REPLACEMENTS_PENALTIES_+1',
		    '@L_REPLACEMENTS_PENALTIES_+2',
		    '@L_REPLACEMENTS_PENALTIES_+3',
		    '@L_REPLACEMENTS_PENALTIES_+4',
		    '@L_REPLACEMENTS_PENALTIES_+5',
		    '@L_REPLACEMENTS_PENALTIES_+6',
		    '@L_REPLACEMENTS_PENALTIES_+0'
		}
	end

	ProgressBar = nil

	for i = 0, Child:GetChildCnt() - 1 do
		Node = Child:GetChildAt(i)
		if Node ~= nil then
			if Node:GetName() == "AccuserNameLabel" then
				LogMessage("@NAO Found AccuserNameLabel;")
				Node:SetValueString("TEXT", GetName("Spouse1"))
			end
			if Node:GetName() == "AccusedNameLabel" then
				LogMessage("@NAO Found AccusedNameLabel;")
				Node:SetValueString("TEXT", GetName("Spouse2"))
			end
			if Node:GetName() == "cl_WinContainer" then
				_Child = Node:GetChildAt(1)
				LogMessage("@NAO cl_WinContainer ("..i..") -> "..(_Child:GetValueString("TEXT") or 'nil'))
				_Child:SetValueString("TEXT",NewLabels[i-28])
				LogMessage("@NAO #W cl_WinContainer ("..i..") -> "..(_Child:GetValueString("TEXT") or 'nil'))
			end
			if Node:GetName() == "ProgressBarDesc" then
				ProgressBar = Node
				LogMessage("@NAO Found progress bar.")
			end
		end
	end
end

function CleanUp()
	local Sims = {"Spouse2", "Guest1", "Guest2", "Guest3"}
	for k, v in helpfuncs_myipairs(Sims) do
		if AliasExists(v) then
			RemoveProperty(v, "InWedding")
		end
	end
	if AliasExists("Spouse1") then
		AllowAllMeasures("Spouse1")
	end
end