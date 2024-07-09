function CleanUp()
	LogMessage("CleanUp() - Cache, in WeddingCeremony.lua")
end

-- Init.
function Start()
	GetSettlement("#MAIN", "settlement")

	if not FindNearestBuilding("#MAIN", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "#WEDDING_CHAPEL") then
		MsgQuick("#MAIN", "Building #WEDDING_CHAPEL not found!")
		return
	end

    local timer = 
    	{
    		getCurrentRound = math.floor( GetGametime() / 24 ),
    		getCurrentTime = math.mod(GetGametime(),24),
    		getEventDate = 0
    	}

    LogMessage("Current Round: "..timer.getCurrentRound)
    LogMessage("Current Game Time: "..timer.getCurrentTime.."h00.")

	local found = false

	while not found do
	    local slotKey = "CEREMONY_SLOT#"..timer.getCurrentRound.."#"..timer.getEventDate

	    if not HasProperty("#WEDDING_CHAPEL", slotKey) then
	        local currentTime = math.floor(GetGametime() / 24)
	        local timeDifference = timer.getEventDate - timer.getCurrentTime

	        if timer.getCurrentRound == currentTime and timeDifference < 4 then
	            LogMessage("4H PREP TIME IMPOSSIBLE FOR: " .. slotKey)
	            SetProperty("#WEDDING_CHAPEL", slotKey, 0)
	            timer.getEventDate = timer.getEventDate + 6

	            if timer.getEventDate > 24 - 1 then
	                timer.getEventDate = 0
	                timer.getCurrentRound = timer.getCurrentRound + 1
	            end
	        else
	            LogMessage("SLOT FOUND: " .. slotKey)
	            SetProperty("#WEDDING_CHAPEL", slotKey, timer.getEventDate)
	            found = true
	        end
	    else
	        LogMessage("ALREADY TAKEN: " .. slotKey)
	        timer.getEventDate = timer.getEventDate + 6

	        if timer.getEventDate > 24 - 1 then
	            timer.getEventDate = 0
	            timer.getCurrentRound = timer.getCurrentRound + 1
	        end
	    end
	end

	local v = GetProperty("#WEDDING_CHAPEL","CEREMONY_SLOT#"..timer.getCurrentRound.."#"..timer.getEventDate)

	LogMessage("Hour of the next Wedding Ceremony: "..v.."h00.")

	CityScheduleCutsceneEvent("settlement", "ceremony_date", "", "BeginCeremony", v, 4, "@L_WEDDING_CEREMONY_SCHEDULED_EVENT_+0", GetID("#MAIN"), GetID("#COURTED"))

	local eventDate = SettlementEventGetTime("ceremony_date")

	SimAddDatebookEntry("#MAIN", eventDate, "#WEDDING_CHAPEL","You are getting married!","Two love-birds are getting married soon, you should probably attend the event in a great moment of community.")
	SimAddDate("#MAIN","#WEDDING_CHAPEL", "#WEDDING_CHAPEL", eventDate -120, "AttendWedding")

	SimAddDatebookEntry("#COURTED", eventDate, "#WEDDING_CHAPEL","You are getting married!","Two love-birds are getting married soon, you should probably attend the event in a great moment of community.")
	SimAddDate("#COURTED","#WEDDING_CHAPEL", "#WEDDING_CHAPEL", eventDate -120, "AttendWedding")

	CutsceneCallThread("", "InviteGuests", "#WEDDING_CHAPEL")

	local ID = "Event"..GetID("#MAIN")
	local DestTime = math.mod(GetGametime(),24) + eventDate/60 - math.mod(GetGametime(),24)

	MsgNewsNoWait("#MAIN", "#MAIN", "@C[@L_WEDDING_COOLDOWN_+0,%3i,%4l]", "default", -1,"@L_WEDDING_COOLDOWN_HEAD_+0","@L_WEDDING_COOLDOWN_BODY_TO_SELF_+0",GetID("#MAIN"), GetID("#COURTED"), DestTime, ID)
	MsgNewsNoWait("#COURTED", "#COURTED", "@C[@L_WEDDING_COOLDOWN_+0,%3i,%4l]", "default", -1,"@L_WEDDING_COOLDOWN_HEAD_+0","@L_WEDDING_COOLDOWN_BODY_TO_COURTED_+0",GetID("#MAIN"), GetID("#COURTED"), DestTime, ID)
end 

-- Call Threads

function InitSims()
	BuildingFindSimByProperty("", "BUILDING_NPC", 11, "#PRIEST")

	BuildingGetInsideSimList("", "tmp")
	ListRemove("tmp", "#PRIEST")
	ListRemove("tmp", "#MAIN")
	ListRemove("tmp", "#COURTED")

	ListNew("Visitors")
	for i = 0, ListSize("tmp") -1 do
		ListGetElement("tmp", i, "#SIM"..i)
		if SimGetAge("#SIM"..i) > 15 then
			ListAdd("Visitors","#SIM"..i)
			CutsceneAddSim("","#SIM"..i)
		end
	end
	ListClear("tmp")

	CutsceneAddSim("","#MAIN")
	CutsceneAddSim("","#COURTED")
	CutsceneAddSim("","#PRIEST")
end

function InviteGuests()

    local function canInvite(GuestAlias, GuestDyn)
        return math.max(GetNobilityTitle("#MAIN"), GetNobilityTitle("#COURTED")) >= GetNobilityTitle(GuestAlias) - 2 and f_SimIsValid(GuestAlias) and not GetState(GuestAlias, STATE_SICK) and CanBeInterruptetBy(GuestAlias, "#MAIN", "Flirt")
    end

    local function invite(GuestAlias)
        local Invitation = MsgNews(GuestAlias, "", "@P"..
            "@B[O, @L_THIEF_067_LETABDUCTEEOUT_ACTION_BTN_+0]"..
            "@B[C, @L_THIEF_067_LETABDUCTEEOUT_ACTION_BTN_+1]", 
            weddingceremony_AIInitAnswer, "politics", 2, 
            "@L_FAMILY_1_MARRIAGE_MESSAGE_HEAD_LEAVE_+0",
            "@L_MEASURE_MARRY_CEREMONY_ASK_BODY_+0",
            GetID("#MAIN"), GetID("#COURTED"), GetID("#WEDDING_CHAPEL"), GetID(GuestAlias))

        	if Invitation == "O" then
        		SimAddDate(GuestAlias, "#WEDDING_CHAPEL", "#WEDDING_CHAPEL", SettlementEventGetTime("ceremony_date")-120, "AttendWedding")
        		SimAddDatebookEntry(GuestAlias, SettlementEventGetTime("ceremony_date"), "#WEDDING_CHAPEL", "@L_WEDDING_CEREMONY_DIARY_BODY_+0","@L_WEDDING_CEREMONY_DIARY_HEAD_+0")
        		SetProperty(GuestAlias, "AttendingWedding", 1)
        		MsgNewsNoWait("#MAIN", GuestAlias, "", "politics", -1, "Answer to the Wedding invitation","I will be happy to attend your Wedding Ceremony.")
        		MsgNewsNoWait("#COURTED", GuestAlias, "", "politics", -1, "Answer to the Wedding invitation","I will be happy to attend your Wedding Ceremony.")
        		SetProperty(GuestAlias,"SIM1",GetID("#MAIN"))
        		SetProperty(GuestAlias,"SIM2",GetID("#COURTED"))
        		SetProperty(GuestAlias,"WEDDING_canChat",1)
        		MsgNewsNoWait(GuestAlias, GuestAlias, "@C[@L_WEDDING_COOLDOWN_BODY_+0,%3i,%4l]", "default", -1,"@L_WEDDING_COOLDOWN_HEAD_+0","@L_WEDDING_COOLDOWN_BODY_+0",GetID("#MAIN"), GetID("#COURTED"), DestTime, ID)
        	else
        		return false
        	end
    end

    local function returnSim(index, dynasty)
		if not DynastyGetFamilyMember(dynasty, index, "Guest") then
			return false
		end

		if SimGetAge("Guest") < 16 then
			return false
		end

		if GetID("Guest") == GetID("#MAIN") or GetID("Guest") == GetID("#COURTED") then
			return false
		end

		if GetID(dynasty) ~= GetDynastyID("Guest") then
			return false
		end

		if canInvite("Guest", "GuestDyn") then
			return invite("Guest")
		end
    end

    if GetSettlement("#MAIN", "#SETTLEMENT") then
        for i = 0, CityGetBuildings("#SETTLEMENT", GL_BUILDING_CLASS_LIVINGROOM, -1, -1, -1, FILTER_HAS_DYNASTY, "Residence") - 1 do
            if GetDynasty("Residence"..i, "GuestDyn") then
                local limit = 0
                for u = 0, DynastyGetFamilyMemberCount("GuestDyn") - 1 do
                    if returnSim(u, "GuestDyn") then
                    	limit = limit + 1
                    	if limit == 2 then
                        	break
                    	end
                    end
                end
            end
        end
    end
end

function EndCeremony()
	LogMessage("EndCeremony() called in WeddingCeremony.lua")

	--StopScheduledScript()
	--LogMessage("CleanUp() in WeddingCeremony.lua")

	RemoveProperty("#MAIN","OCCURING_MARRIAGE")
	RemoveProperty("#COURTED","OCCURING_MARRIAGE")

	f_EndUseLocator("#MAIN", "MarryPos1", GL_STANCE_STAND)
	f_EndUseLocator("#COURTED", "MarryPos2", GL_STANCE_STAND)

	ReleaseAvoidanceGroup("#COURTED")
	ReleaseAvoidanceGroup("#MAIN")

	if AliasExists("Visitors") then
		ListClear("Visitors")
	end

	BuildingGetInsideSimList("#WEDDING_CHAPEL", "tmp")
	BuildingFindSimByProperty("#WEDDING_CHAPEL", "BUILDING_NPC", 11, "#PRIEST")
	ListRemove("tmp","#PRIEST")
 
	if GetInsideRoom("#PRIEST","#CHAPEL") then
		RoomLockForCutscene("#CHAPEL",0)
	end

	LogMessage("Attempting to clear Sims' status, in WeddingCeremony.lua")

	SetState("#MAIN", STATE_CUTSCENE, false)

	for i = 0, ListSize("tmp") -1 do
		ListGetElement("tmp", i, "#SIM"..i)

		if SimGetAge("#SIM"..i) > 15 then
			LogMessage("CleanUp [ '"..GetName("#SIM"..i).."']")

			if HasProperty("#SIM"..i,"WEDDING_FORCED") then
				RemoveProperty("#SIM"..i,"WEDDING_FORCED")
			end
			if HasProperty("#SIM"..i,"WEDDING_canChat") then
				RemoveProperty("#SIM"..i,"WEDDING_canChat")
			end
			if HasProperty("#SIM"..i,"WEDDING_IGNORE") then
				RemoveProperty("#SIM"..i,"WEDDING_IGNORE")
			end
			if HasProperty("#SIM"..i,"Busy") then
				RemoveProperty("#SIM"..i,"Busy")
			end
			if HasProperty("#SIM"..i,"AttendingWedding") then
				RemoveProperty("#SIM"..i,"AttendingWedding")
			end
			if HasProperty("#SIM"..i,"SIM1") then
				RemoveProperty("#SIM"..i,"SIM1")
			end
			if HasProperty("#SIM"..i,"SIM2") then
				RemoveProperty("#SIM"..i,"SIM2")
			end

			if GetInsideBuilding("#SIM"..i, "#BUILDING") ~= false then
				if GetID("#BUILDING") == GetID("#WEDDING_CHAPEL") then
					--f_ExitCurrentBuilding("#SIM"..i)
					ReleaseAvoidanceGroup("#SIM"..i)
					MoveSetActivity("#SIM"..i)
					SimStopMeasure("#SIM"..i)
				end
			end

		end

	end

	ListClear("tmp")
end

function SitGuest()
	LogMessage(GetName("").." is attending the Wedding Ceremony.")
	RemoveProperty("","WEDDING_canChat")

	local allSeats = {}

	for i = 1, 29 do 
		if LocatorStatus("#WEDDING_CHAPEL", "Sit"..i, true) == 1 then
			allSeats[i] = false
		else
			allSeats[i] = true
		end
	end

	local Seat = Rand(29) +1

	repeat
		if allSeats[Seat] == false then
			LogMessage("Seat ("..Seat..") assigned to "..GetName("")..".")
			allSeats[Seat] = true
			break
		else
			LogMessage("Seat ("..Seat..") is already occupied! Restarting rolls.")
		end
		Seat = Rand(29)+1
	until (allSeats[Seat] == true)

	GetFreeLocatorByName("#WEDDING_CHAPEL", "Sit", Seat, Seat, "#POS", false)
	f_BeginUseLocator("", "#POS", GL_STANCE_SITBENCH,true)
end

-- Utilies
local function GetCost()
	return ( math.max(GetNobilityTitle("#MAIN"), IsDynastySim("#COURTED") and GetNobilityTitle("#COURTED") or 0) *2) *300
end

function AIInitAnswer()
	local list, timer = {"Office","Trial","Duel"}

	for i = 1, 3 do
		if GetImpactValue("Guest", list[i].."Timer") > 0 then
			if ImpactGetMaxTimeleft("Guest", list[i].."Timer") <= 4 then
				return "C"
			end
		end
	end
		
	if Rand(3) == 0 then
		return "O"
	else
		return "C"
	end
end

-- Scheduled Event
function BeginCeremony()

	LogMessage("Starting a Wedding event @ "..GetName("#WEDDING_CHAPEL").."!")
	LogMessage("| Celebrating "..GetName("#MAIN").." and "..GetName("#COURTED").."'s union. |")

	CutsceneCallThread("", "InitSims", "#WEDDING_CHAPEL")

	if not GetInsideBuilding("#MAIN", "#WEDDING_CHAPEL") then
		MsgQuick("#MAIN", GetName("#MAIN").." is missing!")
		CutsceneCallThread("", "EndCeremony", "#WEDDING_CHAPEL")
		EndCutscene("")
		DestroyCutscene("")
		return
	end

	if not GetInsideBuilding("#COURTED", "#WEDDING_CHAPEL") then
		MsgQuick("#MAIN", GetName("#COURTED").." is missing!")
		CutsceneCallThread("", "EndCeremony", "#WEDDING_CHAPEL")
		EndCutscene("")
		DestroyCutscene("")
		return
	end

	if not chr_SpendMoney("#MAIN", GetCost(), "Wedding") then
		if not HasProperty("", "Tutorial") then
			MsgQuick("#MAIN","@L_MEASURE_WEDDING_FAILURE_+1", GetID(""))
			CutsceneCallThread("", "EndCeremony", "#WEDDING_CHAPEL")
			EndCutscene("")
			DestroyCutscene("")
			return
		end
	end

	BuildingGetInsideSimList("#WEDDING_CHAPEL", "Sit_Visitors")

	ListRemove("Sit_Visitors", "#MAIN")
	ListRemove("Sit_Visitors", "#COURTED")

	for i = 0, ListSize("Sit_Visitors") -1 do
		ListGetElement("Sit_Visitors", i, "#SIM")
		if SimGetAge("#SIM") > 15 and HasProperty("#SIM","AttendingWedding") then
			CutsceneCallThread("", "SitGuest", "#SIM")
		end
	end
	ListClear("Sit_Visitors")

	RemoveProperty("#MAIN","WEDDING_canChat")
	RemoveProperty("#COURTED","WEDDING_canChat")

	BuildingFindSimByProperty("#WEDDING_CHAPEL", "BUILDING_NPC", 11, "#PRIEST")

	if GetInsideRoom("#PRIEST","#CHAPEL") then
		RoomLockForCutscene("#CHAPEL","")
	end

	GetLocatorByName("#WEDDING_CHAPEL", "WeddingPriest", "PriestPos", false)
	GetLocatorByName("#WEDDING_CHAPEL", "Exit1", "E1")
	GetLocatorByName("#WEDDING_CHAPEL", "Exit2", "E2")
	GetLocatorByName("#WEDDING_CHAPEL", "Front1", "MarryPos1") 
	GetLocatorByName("#WEDDING_CHAPEL", "Front2", "MarryPos2") 

	--f_MoveToNoWait("#PRIEST", "PriestPos")

    CutsceneCallThread("", "GoToMarryPos", "#COURTED")

    f_MoveTo("#MAIN", "E1")
    f_BeginUseLocator("#MAIN", "E1", GL_STANCE_STAND, true)

    while not HasData("There") do
        Sleep(1)
    end

    Sleep(12.5)

	SetAvoidanceGroup("#MAIN", "#COURTED")

	Sleep(0.25)
	AlignTo("#MAIN", "#COURTED")
	AlignTo("#COURTED", "#MAIN")

	local Guests = ListSize("Visitors")

	CutsceneCameraCreate("","#PRIEST")

	f_StartHighPriorMusic(MUSIC_MARRIAGE)

	CutsceneCameraSetRelativePosition("","#CHAPEL_INTRO(01)","#PRIEST")
	CutsceneCameraBlend("", 5, 1)
	CutsceneCameraSetRelativePosition("","#CHAPEL_INTRO(02)","#PRIEST")
	Sleep(5.5)

	PlayFE("#MAIN", "smile", 2, 2.5, 0)
	PlayFE("#COURTED", "smile", 2, 2.5, 0)

	Sleep(1.5)
	AlignTo("#MAIN", "#PRIEST")
	AlignTo("#COURTED", "#PRIEST")
	Sleep(1.5)

	f_MoveToNoWait("#MAIN", "MarryPos1", GL_MOVESPEED_WALK)	
	f_MoveToNoWait("#COURTED", "MarryPos2", GL_MOVESPEED_WALK)

	Sleep(0.5)
	CutsceneCameraSetRelativePosition("","#CHAPEL_INTRO(BACK)","#MAIN")
	Sleep(0.5)
	CutsceneCameraBlend("", 15, 1)
	CutsceneCameraSetRelativePosition("","#CHAPEL_PRIEST(FAR)","#PRIEST")

	f_BeginUseLocator("#COURTED", "MarryPos2", GL_STANCE_STAND, true)
	f_BeginUseLocator("#MAIN", "MarryPos1", GL_STANCE_STAND, true)

	Sleep(1)

	local list = { {"#COURTED","#MAIN"}, {"#MAIN","#COURTED"} }

	-- We are gathered together today to join %1ST %1SN and %2ST %2SN in the bonds of holy matrimony.
	MsgSay("#PRIEST", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_HUSBAND_+0", GetID(list[SimGetGender("#MAIN")+1][1]), GetID(list[SimGetGender("#MAIN")+1][2]))

	CutsceneCameraSetRelativePosition("","#CHAPEL_PRIEST","#PRIEST")

	-- And you, %1ST %1SN, do you wish to take %2ST %2SN to be your lawfully wedded wife, to love and honour, til death do you part? If so, answer with: yes.
	MsgSay("#PRIEST", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_HUSBAND_+1", GetID(list[SimGetGender("#MAIN")+1][1]), GetID(list[SimGetGender("#MAIN")+1][2]))

	CutsceneCameraBlend("", 2, 1)
	CutsceneCameraSetRelativePosition("","#CHAPEL_RIGHT","#PRIEST")
	Sleep(1.25)
	PlayAnimationNoWait("#COURTED","giggle")
	Sleep(0.5)
	PlayAnimationNoWait("#MAIN","curtsy")

	-- Yes, I do.
	MsgSay(list[SimGetGender("#MAIN")+1][1], "_FAMILY_1_MARRIAGE_CEREMONY_ANSWER_+0")

	CutsceneCameraSetRelativePosition("","#CHAPEL_PRIEST(FAR)","#PRIEST")

	-- And you, %1ST %1SN, do you wish to take %2ST %2SN to be your lawfully wedded husband, to love and honour, til death do you part? If so, answer with: yes.
	MsgSay("#PRIEST", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_WIFE_+0", GetID(list[SimGetGender("#MAIN")+1][2]), GetID(list[SimGetGender("#MAIN")+1][1]))

	CutsceneCameraBlend("", 2, 1)
	CutsceneCameraSetRelativePosition("","#CHAPEL_LEFT","#PRIEST")
	Sleep(1.25)
	PlayAnimationNoWait("#MAIN","giggle")
	Sleep(0.75)
	PlayAnimationNoWait("#COURTED","nod")

	-- Yes, I do.
	MsgSay(list[SimGetGender("#MAIN")+1][2], "_FAMILY_1_MARRIAGE_CEREMONY_ANSWER_+0")

	CutsceneCameraSetRelativePosition("","#CHAPEL_PRIEST(FAR)","#PRIEST")

	-- I hereby declare you man and wife. You may now kiss the bride, %1ST %1SV.
	MsgSay("#PRIEST", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_FINALE_+0", GetID(list[SimGetGender("#MAIN")+1][1]))

	CutsceneCameraBlend("", 8, 1)
	CutsceneCameraSetRelativePosition("","#CHAPEL_PRIEST(UP)","#PRIEST")

	AlignTo("#MAIN", "#COURTED")
	AlignTo("#COURTED", "#MAIN")
	Sleep(1)

	ShowOverheadSymbol("#MAIN", false, true, 0, "@L$S[2001]")
	ShowOverheadSymbol("#COURTED", false, true, 0, "@L$S[2001]")

	AnimLength = chr_MultiAnim(list[SimGetGender("#MAIN")+1][1], "kiss_male", list[SimGetGender("#MAIN")+1][2], "kiss_female", 128, 1.0, true)
	Sleep(AnimLength * 0.25)

	ShowOverheadSymbol("#COURTED", false, true, 0, "@L$S[2001]")
	ShowOverheadSymbol("#MAIN", false, true, 0, "@L$S[2001]")

	if not HasProperty("#MAIN", "CourtingDiff") then			
		gameplayformulas_CalcCourtingDifficulty("#COURTED", "#MAIN")
	end

	local Difficulty = GetProperty("#MAIN", "CourtingDiff")
	xp_CourtingSuccess("#MAIN", Difficulty, 1)
	xp_CourtingSuccess("#COURTED", Difficulty, 1)

	Sleep(0.25)

	for i = 0, Guests-1 do
		ListGetElement("Visitors", i, "#SIM")
		if IsDynastySim("#SIM") and not GetState("#SIM", STATE_NPC) then
			if GetID("#SIM") ~= GetID("#MAIN") and GetID("#SIM") ~= GetID("#COURTED") then
				chr_GainXP("#SIM", GL_EXP_GAIN_RARE)
				ReleaseLocator("#SIM")
				if GetDynasty("#SIM", "CheckDyn") then
					if GetImpactValue("CheckDyn", "Ceremony") == 0 then
						AddImpact("CheckDyn", "Ceremony", 1, 6)
					end
				end
			end
		end

		ModifyFavorToSim("#SIM", "#MAIN", GL_FAVOR_MOD_VERYSMALL)
	end

	if Guests > 8 then
    	dyn_AddFame("#MAIN", 3)
	elseif Guests > 5 then
	    dyn_AddFame("#MAIN", 2)
	elseif Guests > 2 then
	    dyn_AddFame("#MAIN", 1)
	end

	MsgNewsNoWait("All", "", "", "politics", -1,"@L_MEASURE_MARRY_CEREMONY_HEAD_+0","@L_MEASURE_MARRY_CEREMONY_NEWS_BODY_+0",GetID("#MAIN"),GetID("#COURTED"),GetID("#WEDDING_CHAPEL"),Guests)

	Sleep(0.5)

	LogMessage("There are "..ListSize("Visitors").." visitors. ("..Guests.." guests)")

	if Guests > 1 then

		ListNew("Reacting")

		for INDEX = 0, (Guests -1) do
			local CONFLICTING = false
			ListGetElement("Visitors", INDEX, "#REACT")
			LogMessage("Currently processing "..GetName("#REACT").." (Sim "..INDEX..").")
			if ListSize("Reacting") > 0 then
				for CHECK = 0, ListSize("Reacting")-1 do
					ListGetElement("Reacting", CHECK, "#VERIFY")
					if GetName("#VERIFY") == GetName("#REACT") then 
						CONFLICTING = true
					end
				end
			end
			if not CONFLICTING then
				LogMessage("Script confirmed no double data for "..GetName("#REACT").." (Sim "..INDEX..").")
				ListAdd("Reacting", "#REACT")
			end
		end

		for INDEX = 0, ListSize("Reacting") -1 do
			ListGetElement("Reacting", INDEX, "#SIM")
			CutsceneCameraSetRelativePosition("","#CHAPEL_GUEST","#SIM")

			local DIALOG, EMOTE = "_POSITIVE", "bench_talk_short"

			if DynastyGetDiplomacyState("#MAIN","#SIM") == DIP_FOE or GetFavorToDynasty("#MAIN", "#SIM") < 40 or SimGetAlignment("#MAIN") >= 70 then
				DIALOG = "_NEGATIVE"
				EMOTE = "bench_talk_offended"
			elseif GetFavorToDynasty("#MAIN", "#SIM") <= 55 and DynastyGetDiplomacyState("#MAIN", "#SIM") < DIP_ALLIANCE then
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

		ListClear("Reacting")

	end

	--[[ Next expansion
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
	}--]]

	RemoveProperty("#COURTED", "CourtDiff")
	MeasureSetNotRestartable()
	PlaySound3D("#WEDDING_CHAPEL", "locations/bell_stroke_cathedral_loop+0.wav", 1.0)

	AddImpact("#MAIN", "LoveLevel", 10, 24)
	AddImpact("#COURTED", "LoveLevel", 10, 24)

	if GetImpactValue("#COURTED", "LoveLevel") >= 10 then
		MsgNewsNoWait("#MAIN", "#COURTED", "", "schedule", -1,"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0","@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("#COURTED"))
	end

	CutsceneCameraBlend("", 4, 0)
	CutsceneCameraSetRelativePosition("","Far_HUpYLeft","#MAIN")
	Sleep(6)

	RemoveProperty("#COURTED", "Wedding")
	RemoveProperty("#COURTED", "courted")
	RemoveProperty("#MAIN","#WEDDING_MAIN")

	SetState("#COURTED", STATE_INLOVE, false)

	RemoveProperty("#MAIN", "#WEDDING_FORCED")
	RemoveProperty("#COURTED", "#WEDDING_FORCED")
	RemoveProperty("#WEDDING_CHAPEL", "Wedding")

	PlaySound3D("#WEDDING_CHAPEL", "locations/bell_stroke_cathedral_loop+0.wav", 1.0)
	ClearImportantPersonSection("Wedding")
	SimMarry("#MAIN", "#COURTED")

	Sleep(1)

	SimResetBehavior("#COURTED")

	CutsceneCallThread("", "EndCeremony", "#WEDDING_CHAPEL")

	Sleep(5)

	EndCutscene("")
	DestroyCutscene("")
end

-- Misc.
function GoToMarryPos()
	f_MoveTo("", "E2")
	f_BeginUseLocator("", "E2", GL_STANCE_STAND, true) 
	SetData("There", 1)
	while true do
		Sleep(5)
	end
end