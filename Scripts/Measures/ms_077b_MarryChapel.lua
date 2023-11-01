--[[ Code Rework.

Changelog:
- Fixed multiple bugs & optimised overall code.
- Created cutscene event for ceremonies.
- Added guests' reactions based on personality & favour.

Bugs fixed:
- Unlike previous dev. version, wedding ceremonies won't cause game crash when saving or loading anymore.
- Fixed an issue where Sims would never sit down on a given bench.

TODO: Royal Weddings;
TODO: Rhetoric challenge;
TODO: EventSchedules.

Preparations.

	[Royal Weddings]

	The entire country is made aware of the wedding to come (shall the Sim be considered Royal) with a MsgNews. Town Criers will spread the news in immersive in-game dialogs throughout the different town centers. Special NPCs will spawn at the town which is considered to be holding the Royal's main residence (Royal Guards) and will be protecting the Residence, the Royal and their soon-to-be spouse/husband.

	Both the Royal and the spouse/husband will be able to interact with one another in order to get ready for the ceremony, most especially the Rhetoric challenge. Three choices are available based on money spendings (from the cheapest to the most expensive):
	- train / prepare speech without help at the main residence;
	- train / prepare speech with a famous writer who is commissioned for this very event;
	- train / prepare speech at the court of some nobles' in a foreign Kingdom (Sims temporarily leave the map).

	Any of these three choices will be situational, and will vary according to the Sims' skills and reputation. For example, the first choice may be convenient if the Sims' skills in rhetoric are high enough. On the other hand, the third choice may be valuable to gain favours from another country.

	Note: a Royal can be assigned a fiancé(e) from abroad and / or get married to a foreign Royal with a special action measure. 

	In the case of a Royal assigning a foreign Royal fiancé(e) to their own children, the Royal adult will be introduced to several candidates and will have to choose one of them. Both fiancés will be required to spend time together in both respective kingdoms and will require private tutorship as a special education, until they reach adulthood and can get married.

	In the case of an adult Royal seeking mariage with another adult foreign Royal, the process will be similar to the exception of the tutorship and time spent together. The Royal seeking mariage may chose to purposedly not meet their soon-to-be spouse / husband, which would be an option for a political wedding. Should the Royal seek true love, they may chose to meet the new "candidate" beforehand.

	Rhetoric challenge: Royals will be asked to deliver a speech to the people and may chose to do so in different locations:
	- during the wedding ceremony at the chapel: the speech will have a limited audience, which may upset the commoners and satisfy the wealthiest;
	- upon exiting the chapel: which will have no favour modifier to either the commoners nor the wealthiest;
	- at the town's market: this will grant a positive favour modifier to the commoners;
	- in the town hall's meeting room: positive bonus for all holders of political offices and wealthy sims attending.

	The town criers reportedly give updates on the ceremony. Certain actions may modify the favour of a large group of sims, should they hear about it.
]]

local function GetCost()
	return ( math.max(GetNobilityTitle(""), IsDynastySim("Destination") and GetNobilityTitle("Destination") or 0) *2) *300
end

local function CutsceneAddSims(data, list)
	for i = 1, list[1] do
		CutsceneAddSim(data, list[i+1])
	end
end

function Run()
	LogMessage("CodeRework, Ceremony :: Starting!")

	if not SimGetCourtLover("", "Destination") or not FindNearestBuilding("", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "#WEDDING_CHAPEL") then
		return
	end

	LogMessage("Marriage cost: "..GetCost())

	if not HasProperty("", "WeddingPaid") then
		if not chr_SpendMoney("", GetCost(), "Wedding") then
			if not HasProperty("", "Tutorial") then
				MsgQuick("","@L_MEASURE_WEDDING_FAILURE_+1", GetID(""))
				SetProperty("", "WEDDING_IS_OVER", 1) 
				RemoveProperty("","WEDDING_DATE")
	        	RemoveProperty("","WEDDING_HOUR")
	        	RemoveProperty("","WEDDING_FORCED")
	        	RemoveProperty("","WEDDING_GUESTS(Amount)")
				RemoveProperty("Destination","WEDDING_DATE")
				RemoveProperty("Destination","WEDDING_HOUR")
				RemoveProperty("Destination","WEDDING_FORCED")
				RemoveProperty("Destination","WEDDING_GUESTS(Amount)")
				StopMeasure("")
				StopMeasure("Destination")
			end
		end
		SetProperty("", "WeddingPaid", 1)
	end

	BuildingFindSimByProperty("#WEDDING_CHAPEL", "BUILDING_NPC", 11, "Priest")	

	SetProperty("#WEDDING_CHAPEL", "WedSim01", GetName(""))
	SetProperty("#WEDDING_CHAPEL", "WedSim02", GetName("Destination"))

	GetLocatorByName("#WEDDING_CHAPEL", "WeddingPriest", "PriestPos")
	GetLocatorByName("#WEDDING_CHAPEL", "Exit1", "E1")
	GetLocatorByName("#WEDDING_CHAPEL", "Exit2", "E2")
	GetLocatorByName("#WEDDING_CHAPEL", "Front1", "MarryPos1") 
	GetLocatorByName("#WEDDING_CHAPEL", "Front2", "MarryPos2") 

	SetProperty("#WEDDING_CHAPEL", "Wedding", 1)
	BlockChar("Destination")
	f_MoveTo("Priest", "PriestPos")
	ms_077b_marrychapel_GotoChurch()
	ms_077b_marrychapel_StartCutscene()
end

function StartCutscene()
	FindNearestBuilding("", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "#WEDDING_CHAPEL")
	f_MoveTo("Priest", "PriestPos")
	SetAvoidanceGroup("", "Destination")

    GetLocatorByName("#WEDDING_CHAPEL", "Front1", "MarryPos1")
    GetLocatorByName("#WEDDING_CHAPEL", "Front2", "MarryPos2")

	--f_MoveToNoWait("", "MarryPos1", GL_MOVESPEED_WALK)
	--f_MoveToNoWait("Destination", "MarryPos2", GL_MOVESPEED_WALK)

	Sleep(0.25)
	AlignTo("", "Destination")
	AlignTo("Destination", "")
	
	CreateCutscene("default", "cutscene")
	CutsceneAddSims("cutscene", {3, "", "Destination", "Priest"})

	BuildingGetInsideSimList("#WEDDING_CHAPEL", "#SIMS")
	ListNew("#GUESTS")

	for i = 1, ListSize("#SIMS")-1 do
		ListGetElement("#SIMS", i, "#GUEST"..i)
		if HasProperty("#GUEST"..i, "WEDDING_HOUR(GUEST)") then
			ListAdd("#GUESTS", "#GUEST"..i)
			SetProperty("", "WEDDING_GUESTS(Amount)", i)
		end
	end

	for i = 1, ListSize("#GUESTS") do
		ListGetElement("#GUESTS", i, "#GUEST"..i)
		CutsceneAddSim("cutscene", "#GUEST"..i)
		LogMessage("Added guest "..GetName("#GUEST"..i).." to the cutscene!")
	end

	CutsceneCameraCreate("cutscene", "")

	BuildingLockForCutscene("#WEDDING_CHAPEL","cutscene")

	f_StartHighPriorMusic(MUSIC_MARRIAGE)

	--filterGuests({GetName(""),GetName("Destination"),GetName("Priest")})

	CutsceneCameraSetRelativePosition("cutscene","#CHAPEL_INTRO(DOWN)","")
	CutsceneCameraBlend("cutscene", 5, 1)
	CutsceneCameraSetRelativePosition("cutscene","#CHAPEL_INTRO(UP)","")
	Sleep(5.5)

	PlayFE("", "smile", 2, 2.5, 0)
	PlayFE("Destination", "smile", 2, 2.5, 0)

	Sleep(1.5)
	AlignTo("", "Priest")
	AlignTo("Destination", "Priest")
	Sleep(1.5)

	f_MoveToNoWait("", "MarryPos1", GL_MOVESPEED_WALK)	
	f_MoveToNoWait("Destination", "MarryPos2", GL_MOVESPEED_WALK)

	Sleep(0.5)
	CutsceneCameraSetRelativePosition("cutscene","#CHAPEL_INTRO(BACK)","")
	Sleep(0.5)
	CutsceneCameraBlend("cutscene", 15, 1)
	CutsceneCameraSetRelativePosition("cutscene","#CHAPEL_PRIEST(FAR)","Priest")

	f_BeginUseLocator("Destination", "MarryPos2", GL_STANCE_STAND, true)
	f_BeginUseLocator("", "MarryPos1", GL_STANCE_STAND, true)

	Sleep(1)

	local list = { {"Destination",""}, {"","Destination"} }

	-- We are gathered together today to join %1ST %1SN and %2ST %2SN in the bonds of holy matrimony.
	MsgSay("Priest", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_HUSBAND_+0", GetID(list[SimGetGender("")+1][1]), GetID(list[SimGetGender("")+1][2]))

	CutsceneCameraSetRelativePosition("cutscene","#CHAPEL_PRIEST","Priest")

	-- And you, %1ST %1SN, do you wish to take %2ST %2SN to be your lawfully wedded wife, to love and honour, til death do you part? If so, answer with: yes.
	MsgSay("Priest", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_HUSBAND_+1", GetID(list[SimGetGender("")+1][1]), GetID(list[SimGetGender("")+1][2]))

	CutsceneCameraBlend("cutscene", 2, 1)
	CutsceneCameraSetRelativePosition("cutscene","#CHAPEL_RIGHT","Priest")
	Sleep(1.25)
	PlayAnimationNoWait("Destination","giggle")
	PlayAnimationNoWait("","curtsy")

	-- Yes, I do.
	MsgSay(list[SimGetGender("")+1][1], "_FAMILY_1_MARRIAGE_CEREMONY_ANSWER_+0")

	CutsceneCameraSetRelativePosition("cutscene","#CHAPEL_PRIEST(FAR)","Priest")

	-- And you, %1ST %1SN, do you wish to take %2ST %2SN to be your lawfully wedded husband, to love and honour, til death do you part? If so, answer with: yes.
	MsgSay("Priest", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_WIFE_+0", GetID(list[SimGetGender("")+1][2]), GetID(list[SimGetGender("")+1][1]))

	CutsceneCameraBlend("cutscene", 2, 1)
	CutsceneCameraSetRelativePosition("cutscene","#CHAPEL_LEFT","Priest")
	Sleep(1.25)
	PlayAnimationNoWait("","giggle")
	PlayAnimationNoWait("Destination","nod")

	-- Yes, I do.
	MsgSay(list[SimGetGender("")+1][2], "_FAMILY_1_MARRIAGE_CEREMONY_ANSWER_+0")

	CutsceneCameraSetRelativePosition("cutscene","#CHAPEL_PRIEST(FAR)","Priest")

	-- I hereby declare you man and wife. You may now kiss the bride, %1ST %1SV.
	MsgSay("Priest", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_FINALE_+0", GetID(list[SimGetGender("")+1][1]))

	CutsceneCameraBlend("cutscene", 8, 1)
	CutsceneCameraSetRelativePosition("cutscene","#CHAPEL_PRIEST(UP)","Priest")

	AlignTo("", "Destination")
	AlignTo("Destination", "")
	Sleep(1)

	ShowOverheadSymbol("", false, true, 0, "@L$S[2001]")
	ShowOverheadSymbol("Destination", false, true, 0, "@L$S[2001]")

	AnimLength = chr_MultiAnim(list[SimGetGender("")+1][1], "kiss_male", list[SimGetGender("")+1][2], "kiss_female", 128, 1.0, true)
	Sleep(AnimLength * 0.25)

	ShowOverheadSymbol("Destination", false, true, 0, "@L$S[2001]")
	ShowOverheadSymbol("", false, true, 0, "@L$S[2001]")

	if not HasProperty("", "CourtingDiff") then			
		gameplayformulas_CalcCourtingDifficulty("Destination", "")
	end

	local Difficulty = GetProperty("", "CourtingDiff")
	xp_CourtingSuccess("Owner", Difficulty, 1)
	xp_CourtingSuccess("Destination", Difficulty, 1)

	Sleep(0.25)

	BuildingGetInsideSimList("#WEDDING_CHAPEL", "#ALL_SIMS")

	for i = 0, ListSize("#ALL_SIMS") -1 do
		ListGetElement("#ALL_SIMS", i, "#SIM")
		if IsDynastySim("#SIM") and not GetState("#SIM", STATE_NPC) then
			if GetID("#SIM") ~= GetID("") and GetID("#SIM") ~= GetID("Destination") then
				chr_GainXP("#SIM", GL_EXP_GAIN_RARE)
				ReleaseLocator("#SIM")
				if GetDynasty("#SIM", "CheckDyn") then
					if GetImpactValue("CheckDyn", "Ceremony") == 0 then
						AddImpact("CheckDyn", "Ceremony", 1, 6)
					end
				end
			end
		end

		ModifyFavorToSim("#SIM", "", GL_FAVOR_MOD_VERYSMALL)
	end

	local GuestAmount = GetProperty("","WEDDING_GUESTS(Amount)")

	if GuestAmount > 8 then
    	dyn_AddFame("", 3)
	elseif GuestAmount > 5 then
	    dyn_AddFame("", 2)
	elseif GuestAmount > 2 then
	    dyn_AddFame("", 1)
	end

	MsgNewsNoWait("All", "", "", "politics", -1,"@L_MEASURE_MARRY_CEREMONY_HEAD_+0","@L_MEASURE_MARRY_CEREMONY_NEWS_BODY_+0",GetID(""),GetID("Destination"),GetID("#WEDDING_CHAPEL"),GuestAmount)

	Sleep(0.5)

	local function createReacting()
		ListNew("#REACT_GUESTS")

		local COUNT = Rand(GetProperty("","#WEDDING_GUESTS(Amount)"))+1
		LogMessage("A total of "..COUNT.." guests will be reacting to this cutscene!")

		for INDEX = 0, COUNT-1 do
			local CONFLICTING = false
			ListGetElement("#GUESTS", INDEX, "#REACT")
			LogMessage("Currently processing "..GetName("#REACT").." (Sim "..INDEX..").")
			if ListSize("#REACT_GUESTS") > 0 then
				for CHECK = 0, ListSize("#REACT_GUESTS")-1 do
					ListGetElement("#REACT_GUESTS", CHECK, "#VERIFY")
					if GetName("#VERIFY") == GetName("#REACT") then 
						CONFLICTING = true
					end
				end
			end
			if not CONFLICTING then 
				LogMessage("Script confirmed no double data for "..GetName("#REACT").." (Sim "..INDEX..").")
				ListAdd("#REACT_GUESTS", "#REACT")
			end
		end

		local COUNT = 0

		for RESULT = 0, ListSize("#REACT_GUESTS")-1 do
			COUNT = RESULT
		end

		return COUNT
	end

	LogMessage("CodeRework, Ceremony :: [createReacting] is running...")

	local COUNT = createReacting()

	-- Next expansion
	local ROYAL = 
	{
		["ROYAL"] = 
			{
				["POSITIVE"] =
					{
						"@L_PRIVILEGES_FLAMINGSPEECH_COMMENTS_+6",
						"@L_PRIVILEGES_FLAMINGSPEECH_COMMENTS_+5",
						"@L_PRIVILEGES_FLAMINGSPEECH_COMMENTS_+8",
						"@L_PRIVILEGES_FLAMINGSPEECH_COMMENTS_+10",
						"@L_PRIVILEGES_FLAMINGSPEECH_COMMENTS_+9",
						"@L_PRIVILEGES_FLAMINGSPEECH_COMMENTS_+2",
						"@L_PRIVILEGES_FLAMINGSPEECH_COMMENTS_+1"
					},

				["NEGATIVE"] =
					{
						"@L_FEAST_4_GOODBYE_B_COMMENTS_NEUTRAL_+0",
						"@L_FEAST_4_GOODBYE_B_COMMENTS_BAD_+0",
						"@L_FEAST_4_GOODBYE_B_COMMENTS_BAD_+2",
						"@L_FEAST_4_GOODBYE_B_COMMENTS_BAD_+3"
					}
			}
	}

	for INDEX = 0, COUNT do
		ListGetElement("#REACT_GUESTS", INDEX, "#SIM")
		CutsceneCameraSetRelativePosition("cutscene","#CHAPEL_GUEST","#SIM")

		local DIALOG, EMOTE = "_POSITIVE", "bench_talk_short"

		if DynastyGetDiplomacyState("","#SIM") == DIP_FOE or GetFavorToDynasty("", "#SIM") < 40 or SimGetAlignment("") >= 70 then
			DIALOG = "_NEGATIVE"
			EMOTE = "bench_talk_offended"
		elseif GetFavorToDynasty("", "#SIM") <= 55 and DynastyGetDiplomacyState("", "#SIM") < DIP_ALLIANCE then
			if Rand(2) == 0 then
				DIALOG = "_NEGATIVE"
				EMOTE = "bench_talk_offended"
			end
		end

		local SKILL = GetSkillValue("#SIM", RHETORIC)

		if SKILL >= 7 then
			DIALOG = DIALOG.."_GOOD_RHETORIC"
		elseif SKILL >= 4 then
			DIALOG = DIALOG.."_NORMAL_RHETORIC"
		else
			DIALOG = DIALOG.."_WEAK_RHETORIC"
		end

		Sleep(0.25)
		DIALOG = "@L_FAMILY_1_MARRIAGE_COMMENT"..DIALOG

		PlayAnimationNoWait("#SIM", EMOTE)
		MsgSay("#SIM", DIALOG)
	end

	RemoveProperty("Destination", "CourtDiff")
	MeasureSetNotRestartable()
	PlaySound3D("#WEDDING_CHAPEL", "locations/bell_stroke_cathedral_loop+0.wav", 1.0)

	AddImpact("", "LoveLevel", 10, 24)
	AddImpact("Destination", "LoveLevel", 10, 24)

	if GetImpactValue("Destination", "LoveLevel") >= 10 then
		MsgNewsNoWait("", "Destination", "", "schedule", -1,"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0","@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("Destination"))
	end

	CutsceneCameraBlend("cutscene", 4, 0)
	CutsceneCameraSetRelativePosition("cutscene","Far_HUpYLeft","")
	Sleep(6)

	SetProperty("#WEDDING_CHAPEL","DEBUG_IS_OVER", 1)
	SetProperty("", "WEDDING_IS_OVER", 1)
	SetProperty("Destination", "WEDDING_IS_OVER", 1)

	RemoveProperty("","WEDDING_DATE")
	RemoveProperty("","WEDDING_HOUR")
	RemoveProperty("","WEDDING_FORCED")
	RemoveProperty("","WEDDING_GUESTS(Amount)")
	RemoveProperty("Destination","WEDDING_DATE")
	RemoveProperty("Destination","WEDDING_HOUR")
	RemoveProperty("Destination","WEDDING_FORCED")
	RemoveProperty("Destination","WEDDING_GUESTS(Amount)")

	RemoveProperty("Destination", "Wedding")
	RemoveProperty("Destination", "courted")

	RemoveProperty("Destination", "WEDDING_DATE")
	RemoveProperty("", "WEDDING_DATE")

	RemoveProperty("","#WEDDING_MAIN") 

	SetState("Destination", STATE_INLOVE, false)
	RemoveProperty("", "#WEDDING_FORCED", 1)
	RemoveProperty("Destination", "#WEDDING_FORCED", 1)

	RemoveProperty("#WEDDING_CHAPEL", "Wedding")
	SimResetBehavior("Destination")
	RemoveProperty("", "WeddingPaid")
	PlaySound3D("#WEDDING_CHAPEL", "locations/bell_stroke_cathedral_loop+0.wav", 1.0)

	ClearImportantPersonSection("Wedding")
	SimMarry("", "Destination")

	DestroyCutscene("cutscene")

end

function GotoChurch()
	LogMessage("GotoChurch()")
    --f_MoveToNoWait("", "#WEDDING_CHAPEL", GL_MOVESPEED_WALK)
    --f_MoveTo("Destination", "#WEDDING_CHAPEL", GL_MOVESPEED_WALK)

--[[if GetSettingNumber("DEBUG", "UseDebugMeasures", 0) == 1 then
		if GetProperty("","DEBUG_WEDDING_TELEPORT_GUESTS") == 1 then
			SimBeamMeUp("", "#WEDDING_CHAPEL", false)
			SimBeamMeUp("Destination", "#WEDDING_CHAPEL", false)
		end
	end]]

	GetLocatorByName("#WEDDING_CHAPEL", "Exit1", "E1")
	GetLocatorByName("#WEDDING_CHAPEL", "Exit2", "E2")

    SendCommandNoWait("Destination", "GoToMarryPos")
    f_MoveTo("", "E1")
    f_BeginUseLocator("", "E1", GL_STANCE_STAND, true)

    while not HasData("There") do
        Sleep(1)
        LogMessage("Awaiting Sim at Locator E2.")
    end
end

function GoToMarryPos()	
    if GetState("", STATE_SICK) then -- temporary
        SimBeamMeUp("", "E2", false)
    end

	LogMessage("GoToMarryPos()")
	f_MoveTo("", "E2")
	f_BeginUseLocator("", "E2", GL_STANCE_STAND, true) 
	SetData("There", 1)
	while true do
		Sleep(5)
	end
end

function CleanUp()
	ReleaseLocator("")
	ReleaseLocator("Destination")
	EndCutscene("")
	DestroyCutscene("cutscene")
	MoveSetActivity("")
	MoveSetActivity("Destination")
	ReleaseAvoidanceGroup("")
	RemoveProperty("","AttendingWedding") 
end