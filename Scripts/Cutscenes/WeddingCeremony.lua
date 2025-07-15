-- Native calls
function CleanUp()
	LogMessage("@NAO [WeddingCeremony] CleanUp().")

	if AliasExists("Musician0") then
		for i = 1, 2 do
			StopAnimation("Musician"..i)
			PlayAnimation("Musician"..i, "play_instrument_03_out")
			CarryObject("Musician"..i, "", false)
			CarryObject("Musician"..i, "", true)
			Kill("Musician"..i)
		end
		StopAnimation("Musician0")
		Detach3DSound("Musician0")
		Kill("Musician0")
	end

	f_EndUseLocator("Orphan#1", "flowerchild1", GL_STANCE_STAND)
	f_EndUseLocator("Orphan#2", "flowerchild2", GL_STANCE_STAND)

	if AliasExists("#COURTED") then 
		f_EndUseLocator("#COURTED", "MarryPos2", GL_STANCE_STAND)
		ReleaseAvoidanceGroup("#COURTED")
		RemoveProperty("#COURTED", "OCCURING_MARRIAGE")
		RemoveProperty("#COURTED", "Wedding")
		RemoveProperty("#COURTED", "courted")
		RemoveProperty("#COURTED", "WEDDING_FORCED")
	end

	if AliasExists("#MAIN") then
		RemoveProperty("#MAIN", "IsAllowedSpecialMeasuresForWeddings")
		f_EndUseLocator("#MAIN", "MarryPos1", GL_STANCE_STAND)
		AllowAllMeasures("#MAIN")
		ReleaseAvoidanceGroup("#MAIN")
		RemoveProperty("#MAIN","InWedding")
		RemoveProperty("#MAIN", "OCCURING_MARRIAGE")
		RemoveProperty("#MAIN", "WEDDING_FORCED")
	end

	GetInsideBuilding("#MAIN", "#WEDDING_CHAPEL")

	if AliasExists("Visitors") then
		ListClear("Visitors")
	end

	BuildingGetInsideSimList("#WEDDING_CHAPEL", "tmp")
	BuildingFindSimByProperty("#WEDDING_CHAPEL", "BUILDING_NPC", 11, "#PRIEST")
	ListRemove("tmp","#PRIEST")

	LogMessage("@NAO [WeddingCeremony] Length of list:" .. ListSize("tmp"))
 
	BuildingLockForCutscene("#WEDDING_CHAPEL", 0)

	SetState("#MAIN", STATE_CUTSCENE, false)

	for i = 0, ListSize("tmp") -1 do
		ListGetElement("tmp", i, "#SIM"..i)

		if SimGetAge("#SIM"..i) > 15 then
			LogMessage("@NAO [WeddingCeremony] CleanUp ['"..GetName("#SIM"..i).."']")

			AllowMeasure("#SIM"..i, "BuyNobilityTitle", EN_BOTH)

			if HasProperty("#SIM"..i, "AttendingWedding") then
				RemoveProperty("#SIM"..i, "AttendingWedding")
			end
			if HasProperty("#SIM"..i, "WEDDING_GUEST") then
				RemoveProperty("#SIM"..i, "WEDDING_GUEST")
			end

			SimResetBehavior("#SIM"..i)
			f_ExitCurrentBuilding("#SIM"..i)
			
			if GetInsideBuilding("#SIM"..i, "#BUILDING") ~= false then
				if GetID("#BUILDING") == GetID("#WEDDING_CHAPEL") then
					ReleaseAvoidanceGroup("#SIM"..i)
					MoveSetActivity("#SIM"..i)
				end
			end
		end
	end

	ListClear("tmp")
end

function OnCameraEnable()
end

function OnCameraDisable()
end

function Init()
    GetSettlement("#MAIN", "settlement")

	if not FindNearestBuilding("#MAIN", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "#WEDDING_CHAPEL") then
		MsgQuick("#MAIN", "Building #WEDDING_CHAPEL not found!")
		return
	end

	LogMessage("@NAO [WeddingCeremony] Init of: " .. GetName("#MAIN") .. " and " .. GetName("#COURTED"))

	local function getDate()

		local timer = 
			{
				getCurrentRound = math.floor(GetGametime()/24),
				getCurrentTime = math.mod(GetGametime(), 24),
				getEventDate = 0
			}

		LogMessage("@NAO [WeddingCeremony] Current Round: "..timer.getCurrentRound)
		LogMessage("@NAO [WeddingCeremony] Current Game Time: "..timer.getCurrentTime.."h00.")

		local found = false

		while not found do
		    local slotKey = "CEREMONY_SLOT#"..timer.getCurrentRound.."#"..timer.getEventDate

		    if not HasProperty("#WEDDING_CHAPEL", slotKey) then
		        local currentTime = math.floor(GetGametime() / 24)
		        local timeDifference = timer.getEventDate - timer.getCurrentTime

		        if timer.getCurrentRound == currentTime and timeDifference < 4 then
		            LogMessage("@NAO [WeddingCeremony] 4H PREP TIME IMPOSSIBLE FOR: " .. slotKey)
		            SetProperty("#WEDDING_CHAPEL", slotKey, 0)
		            timer.getEventDate = timer.getEventDate + 6

		            if timer.getEventDate > 24 - 1 then
		                timer.getEventDate = 0
		                timer.getCurrentRound = timer.getCurrentRound + 1
		            end
		        else
		            LogMessage("@NAO [WeddingCeremony] SLOT FOUND: " .. slotKey)
		            SetProperty("#WEDDING_CHAPEL", slotKey, timer.getEventDate)
		            found = true
		            return timer.getEventDate
		        end
		    else
		        LogMessage("@NAO [WeddingCeremony] ALREADY TAKEN: " .. slotKey)
		        timer.getEventDate = timer.getEventDate + 6

		        if timer.getEventDate > 24 - 1 then
		            timer.getEventDate = 0
		            timer.getCurrentRound = timer.getCurrentRound + 1
		        end
		    end
		end
	end

    local date = getDate()
    CityScheduleCutsceneEvent("settlement", "Date(Wedding)", "", "Start", date, 4, "@L_WEDDING_CITYEVENT_+0", GetID("#MAIN"), GetID("#COURTED"))

	SimAddDatebookEntry("#MAIN", SettlementEventGetTime("Date(Wedding)"), "#WEDDING_CHAPEL","You are getting married!","This is your big day! You are getting married soon, you should probably attend the event in a great moment of community.")
	SimAddDate("#MAIN","#WEDDING_CHAPEL", "#WEDDING_CHAPEL", SettlementEventGetTime("Date(Wedding)")-120, "AttendWedding")

	SimAddDatebookEntry("#COURTED", SettlementEventGetTime("Date(Wedding)"), "#WEDDING_CHAPEL","You are getting married!","This is your big day! You are getting married soon, you should probably attend the event in a great moment of community.")
	SimAddDate("#COURTED","#WEDDING_CHAPEL", "#WEDDING_CHAPEL", SettlementEventGetTime("Date(Wedding)")-120, "AttendWedding")

    local function canInvite(GuestAlias, GuestDyn)
        return math.max(GetNobilityTitle("#MAIN"), GetNobilityTitle("#COURTED")) >= GetNobilityTitle(GuestAlias) - 2 and f_SimIsValid(GuestAlias) and not GetState(GuestAlias, STATE_SICK)
    end

    local function invite(GuestAlias)
        local Invitation = MsgNews(GuestAlias, "", "@P"..
            "@B[O, @L_THIEF_067_LETABDUCTEEOUT_ACTION_BTN_+0]"..
            "@B[C, @L_THIEF_067_LETABDUCTEEOUT_ACTION_BTN_+1]", 
            weddingceremony_AIInitAnswer, "politics", 2, 
            "@L_FAMILY_1_MARRIAGE_MESSAGE_HEAD_LEAVE_+0",
            "@L_MEASURE_MARRY_CEREMONY_ASK_BODY_+0",
            GetID("#MAIN"), GetID("#COURTED"), GetID("#WEDDING_CHAPEL"), GetID(GuestAlias))

        	if Invitation == "O" or Invitation == "C" then
        		SimAddDate(GuestAlias, "#WEDDING_CHAPEL", "#WEDDING_CHAPEL", SettlementEventGetTime("Date(Wedding)")-120, "AttendWedding")
        		SimAddDatebookEntry(GuestAlias, SettlementEventGetTime("Date(Wedding)"), "#WEDDING_CHAPEL", "@L_WEDDING_CEREMONY_DIARY_BODY_+0","@L_WEDDING_CEREMONY_DIARY_HEAD_+0")
        		SetProperty(GuestAlias, "AttendingWedding", 1)
        		--MsgNewsNoWait("#MAIN", GuestAlias, "", "politics", -1, "Answer to the Wedding invitation","I will be happy to attend your Wedding Ceremony.")
        		--MsgNewsNoWait("#COURTED", GuestAlias, "", "politics", -1, "Answer to the Wedding invitation","I will be happy to attend your Wedding Ceremony.")
        		SetProperty(GuestAlias, "WEDDING_GUEST", 1) 
        		MsgNewsNoWait(GuestAlias, GuestAlias, "@C[@L_WEDDING_COOLDOWN_BODY_+0,%3i,%4l]", "default", -1, "@L_WEDDING_COOLDOWN_HEAD_+0", "@L_WEDDING_COOLDOWN_BODY_+0", GetID("#MAIN"), GetID("#COURTED"), DestTime, ID)
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
    	local i, u
        for i = 0, CityGetBuildings("#SETTLEMENT", GL_BUILDING_CLASS_LIVINGROOM, -1, -1, -1, FILTER_HAS_DYNASTY, "Residence") - 1 do
            if GetDynasty("Residence"..i, "GuestDyn") then
                local limit = 0
                for u = 0, DynastyGetFamilyMemberCount("GuestDyn") - 1 do
                    if returnSim(u, "GuestDyn") then
                    	limit = limit + 1
                    	if limit == 3 then
                        	break
                    	end
                    end
                end
            end
        end
    end

	local ID = "Event" .. GetID("#MAIN")
	local DestTime = math.mod(GetGametime(),24) + date/60 - math.mod(GetGametime(),24)

	MsgNewsNoWait("#MAIN", "#MAIN", "@C[@L_WEDDING_COOLDOWN_+0,%3i,%4l]", "default", -1, "@L_WEDDING_COOLDOWN_HEAD_+0", "@L_WEDDING_COOLDOWN_BODY_TO_SELF_+0", GetID("#MAIN"), GetID("#COURTED"), DestTime, ID)
	MsgNewsNoWait("#COURTED", "#COURTED", "@C[@L_WEDDING_COOLDOWN_+0,%3i,%4l]", "default", -1, "@L_WEDDING_COOLDOWN_HEAD_+0", "@L_WEDDING_COOLDOWN_BODY_TO_COURTED_+0", GetID("#MAIN"), GetID("#COURTED"), DestTime, ID)
end

-- Call Threads
function InitSims()
	BuildingFindSimByProperty("", "BUILDING_NPC", 11, "#PRIEST")

	BuildingGetInsideSimList("", "tmp")
	ListRemove("tmp", "#PRIEST")
	ListRemove("tmp", "#MAIN")
	ListRemove("tmp", "#COURTED")

	local OrphanCount = 0

	ListNew("Visitors")
	for i = 0, ListSize("tmp") -1 do
		ListGetElement("tmp", i, "#SIM"..i)
		if SimGetAge("#SIM"..i) > 15 then
			ListAdd("Visitors","#SIM"..i)
			CutsceneAddSim("","#SIM"..i)
			LogMessage("@NAO [WeddingCeremony] Visitor added to list: " .. GetName("#SIM"..i))
			SimResetBehavior("#SIM"..i)
			SimSetBehavior("#SIM"..i, "idle")
			SimStopMeasure("#SIM"..i)
		else
			OrphanCount = OrphanCount +1
			ChangeAlias("#SIM"..i, "Orphan#"..OrphanCount)
			LogMessage("@NAO [WeddingCeremony] Minor (" .. OrphanCount .. "): " .. GetName("Orphan#"..OrphanCount))
		end
	end
	ListClear("tmp")

	CutsceneAddSim("", "#MAIN")
	CutsceneAddSim("", "#COURTED")
	CutsceneAddSim("", "#PRIEST")
	if AliasExists("Orphan#1") and AliasExists("Orphan#2") then
		CutsceneAddSim("","Orphan#1")
		CutsceneAddSim("","Orphan#2")
	end
end

function SetUpOrphan1()
	GetLocatorByName("#WEDDING_CHAPEL", "FlowerChild1", "FC1")
	f_MoveTo("", "FC1")
	f_BeginUseLocator("", "FC1", GL_STANCE_STAND, true)
	GetPosition("", "Pos1")
	StartSingleShotParticle("particles/pray_glow.nif", "Pos1", 1, 15)
end

function SetUpOrphan2()
	GetLocatorByName("#WEDDING_CHAPEL", "FlowerChild2", "FC2")
	f_MoveTo("", "FC2")
	f_BeginUseLocator("", "FC2", GL_STANCE_STAND, true)
	GetPosition("", "Pos2")
	StartSingleShotParticle("particles/pray_glow.nif", "Pos2", 1, 15)
end

function ImportantSimIsMissing()
	LogMessage("@NAO [WeddingCeremony] " .. GetName("") .. " has missed their wedding.")
	MsgQuick("#MAIN", GetName("#MISSING").." is missing!")

	CutsceneCameraSetRelativePosition("", "#CHAPEL_PRIEST", "#PRIEST")
	MsgSay("#PRIEST", "_MEASURE_MARRY_CEREMONY_UNEXPECTED_SITUATION_+0")
	MsgSay("#PRIEST", "_MEASURE_MARRY_CEREMONY_MISSING_+0", GetID("MISSING"))
	MsgSay("#PRIEST", "_MEASURE_MARRY_CEREMONY_MISSING_+1")
	MsgSay("#PRIEST", "_MEASURE_MARRY_CEREMONY_UNEXPECTED_SITUATION_+1")
	ClearImportantPersonSection("Wedding")
	Sleep(5)
	EndCutscene("")
	DestroyCutscene("")
	return
end

function ImportantSimCannotPay()
	LogMessage("@NAO [WeddingCeremony] " .. GetName("") .. " cannot cover the expenses of the ceremony.")
	MsgQuick("#MAIN","@L_MEASURE_WEDDING_FAILURE_+1", GetID(""))

	CutsceneCameraSetRelativePosition("", "#CHAPEL_PRIEST", "#PRIEST")
	MsgSay("#PRIEST", "_MEASURE_MARRY_CEREMONY_UNEXPECTED_SITUATION_+0")
	MsgSay("#PRIEST", "_MEASURE_MARRY_CEREMONY_NO_MONEY_+0", GetID("#MAIN"))
	MsgSay("#PRIEST", "_MEASURE_MARRY_CEREMONY_NO_MONEY_+1")
	MsgSay("#PRIEST", "_MEASURE_MARRY_CEREMONY_UNEXPECTED_SITUATION_+1")
	ClearImportantPersonSection("Wedding")
	Sleep(5)
	EndCutscene("")
	DestroyCutscene("")
	return
end

function GoToMarryPos()
	f_MoveTo("", "E2")
	f_BeginUseLocator("", "E2", GL_STANCE_STAND, true) 
	SetData("There", 1)
	CutsceneSetData("", "There")
	while true do
		Sleep(5)
	end
end

function DoReactGuest()
	local DIALOG, EMOTE = "_POSITIVE", "bench_talk_short"

	if DynastyGetDiplomacyState("#MAIN", "#SIM") == DIP_FOE or GetFavorToDynasty("#MAIN", "#SIM") < 40 or SimGetAlignment("#MAIN") >= 70 then
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
		
	if Rand(2) == 0 then
		return "O"
	else
		return "C"
	end
end

function UseSitGuest()
	MoveSetStance("", GL_STANCE_SITBENCH)
end

function GoToSitGuest()
	LogMessage("@NAO SitGuest with "..GetName(""))
	if SimGetAge("") > 15 and HasProperty("", "AttendingWedding") then
		GetFreeLocatorByName("#WEDDING_CHAPEL", "Sit", 1, 29, "#POS", false)
		f_BeginUseLocator("", "#POS", GL_STANCE_STAND, true)
	end
end

function GetUp()
	local Random = Rand(5)
	Sleep(1/Random)
	MoveSetStance("", GL_STANCE_STAND)
end

-- Scheduled Event
function Start()

	LogMessage("@NAO [WeddingCeremony] Celebrating "..GetName("#MAIN").." and "..GetName("#COURTED").."'s union. |")

	CutsceneCallThread("", "InitSims", "#WEDDING_CHAPEL")

	BuildingFindSimByProperty("#WEDDING_CHAPEL", "BUILDING_NPC", 11, "#PRIEST")

	local doMusicians = true

	if doMusicians then
		local Templates = {719, 720, 721}
		GetPosition("#PRIEST", "Position")
		GetSettlement("#PRIEST", "Settlement")

		local Count = -1
		repeat
			Count = Count + 1
			SimCreate(Templates[Count+1], "Settlement", "Position", "Musician"..Count)
		until (Count == 2)

		for i = 0, 2 do 
			CopyAliasToCutscene("Musician"..i, "", "Musician"..i)
			CutsceneAddSim("", "Musician"..i)
		end

		for i = 0, 2 do
			CutsceneCallThread("", "PrepareInstrument"..i, "Musician"..i)
		end
	end

	MsgSayNoWait("#PRIEST", "_MEASURE_MARRY_CEREMONY_TAKE_A_SEAT_+0")

	if not chr_SpendMoney("#MAIN", GetCost(), "Wedding") then
		if not HasProperty("", "Tutorial") then
			CutsceneCallThread("", "ImportantSimCannotPay", "#MAIN")
			return
		end
	end

	BuildingGetInsideSimList("#WEDDING_CHAPEL", "Sit_Visitors")

	ListRemove("Sit_Visitors", "#MAIN")
	ListRemove("Sit_Visitors", "#COURTED")
	ListRemove("Sit_Visitors", "#PRIEST")

	for i = 0, ListSize("Sit_Visitors") -1 do
		ListGetElement("Sit_Visitors", i, "#SIM")
		CutsceneCallThread("", "GoToSitGuest", "#SIM")
	end

	if AliasExists("Orphan#1") and AliasExists("Orphan#2") then
		CutsceneCallThread("", "SetUpOrphan1", "Orphan#1")
		CutsceneCallThread("", "SetUpOrphan2", "Orphan#2")
		ListRemove("Sit_Visitors", "Orphan#1")
		ListRemove("Sit_Visitors", "Orphan#2")
	end

	BuildingLockForCutscene("#WEDDING_CHAPEL", "")

	GetLocatorByName("#WEDDING_CHAPEL", "WeddingPriest", "PriestPos", false)
	GetLocatorByName("#WEDDING_CHAPEL", "Exit1", "E1")
	GetLocatorByName("#WEDDING_CHAPEL", "Exit2", "E2")
	GetLocatorByName("#WEDDING_CHAPEL", "Front1", "MarryPos1") 
	GetLocatorByName("#WEDDING_CHAPEL", "Front2", "MarryPos2")

	Sleep(2)

	f_StartHighPriorMusic(13)

	CutsceneCameraCreate("", "#PRIEST")

	SetExclusiveMeasure("#MAIN", 3000, EN_BOTH)
	ForbidMeasure("#MAIN", 3000, EN_BOTH)

	if not GetInsideBuilding("#COURTED", "#WEDDING_CHAPEL") then
		CopyAlias("#COURTED", "#MISSING")
	elseif not GetInsideBuilding("#COURTED", "#WEDDING_CHAPEL") then 
		CopyAlias("#MAIN", "#MISSING")
	end

	if AliasExists("#MISSING") then
		CutsceneCallThread("", "ImportantSimIsMissing", "#MISSING")
		return
	end

    CutsceneCallThread("", "GoToMarryPos", "#COURTED")

    f_MoveToNoWait("#MAIN", "E1")
    f_BeginUseLocatorNoWait("#MAIN", "E1", GL_STANCE_STAND, true)

    LogMessage("@NAO #E Saving now will crash")
    --local hasData
    --while true do
	--	CutsceneGetData("", "There")
    --	if GetData("There") ~= 1 then
	--		CutsceneCameraBlend("", 0.1, 1)
	--		CutsceneCameraSetRelativePosition("", "#CHAPEL_PRIEST", "#MAIN")
	--		Sleep(0.1)
	--	elseif GetData("There") == 1 then
	--		break
	--	end
    --end
    LogMessage("@NAO #E Saving now will not crash")

	SetState("#MAIN", STATE_CUTSCENE, false)

	SetData("SkipProgressBar", 0)
	CutsceneSetData("", "SkipProgressBar")

	TrialHUDSetSims("", GetID("#MAIN"), GetID("#COURTED"), GetID("#PRIEST"), GetID("#PRIEST"), GetID("#PRIEST"))
	
	CutsceneCallThread("", "SetWeddingHUD", "#MAIN")

	-- Progress, Guest1, Guest2, Guest3, Arrow, Timer
	TrialHUDSetStatus("", 0, 0, 0, 0, 0, 0.0)
	Sleep(0.5)

	TrialHUDSetStatus("", 8, 7, 8, 9, 8, 2.0)
	Sleep(0.5)

    if doMusicians then
		for i = 1, 2 do
			CutsceneCallThread("", "StartPlaying", "Musician"..i)
		end
		CutsceneCallThread("", "StartSinging", "Musician0")
	end

    CutsceneCameraSetRelativePosition("", "#CHAPEL_PRIEST", "#PRIEST")
    PlayFE("#PRIEST", "smile", 2, 2.5, 0)
    Sleep(2.5)

	AlignTo("#MAIN", "#COURTED")
	AlignTo("#COURTED", "#MAIN")

	SetAvoidanceGroup("#MAIN", "#COURTED")

	local Guests = ListSize("Visitors")

	CutsceneCameraSetRelativePosition("", "#CHAPEL_INTRO(01)", "#PRIEST")
	CutsceneCameraBlend("", 5, 1)
	CutsceneCameraSetRelativePosition("", "#CHAPEL_INTRO(02)", "#PRIEST")
	Sleep(5.5)

	PlayFE("#MAIN", "smile", 2, 2.5, 0)
	PlayFE("#COURTED", "smile", 2, 2.5, 0)

	Sleep(1.5)
	AlignTo("#MAIN", "#PRIEST")
	AlignTo("#COURTED", "#PRIEST")
	Sleep(1.5)

	f_MoveToNoWait("#MAIN", "MarryPos1", GL_MOVESPEED_WALK)	
	f_MoveToNoWait("#COURTED", "MarryPos2", GL_MOVESPEED_WALK)

	if doMusicians then
		LogMessage("@NAO Start Camera Musicians")
		CutsceneCameraSetRelativePosition("", "CameraPortrait", "Musician1")
		CutsceneCameraBlend("", 5, 1)
		CutsceneCameraSetRelativePosition("", "CameraPortrait", "Musician2")
		LogMessage("@NAO End Camera Musicians")
		Sleep(10)
	end

	Sleep(0.5)
	CutsceneCameraSetRelativePosition("", "#CHAPEL_INTRO(BACK)", "#MAIN")
	Sleep(0.5)
	CutsceneCameraBlend("", 15, 1)
	CutsceneCameraSetRelativePosition("", "#CHAPEL_PRIEST(FAR)", "#PRIEST")

	f_BeginUseLocator("#COURTED", "MarryPos2", GL_STANCE_STAND, true)
	f_BeginUseLocator("#MAIN", "MarryPos1", GL_STANCE_STAND, true)

	Sleep(1)

	local list = { {"#COURTED","#MAIN"}, {"#MAIN","#COURTED"} }

	MsgSay("#PRIEST", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_HUSBAND_+0", GetID(list[SimGetGender("#MAIN")+1][1]), GetID(list[SimGetGender("#MAIN")+1][2]))

	for i = 0, ListSize("Sit_Visitors") -1 do
		ListGetElement("Sit_Visitors", i, "#SIM")
		CutsceneCallThread("", "UseSitGuest", "#SIM")
	end

	ListClear("Sit_Visitors")

	CutsceneCameraSetRelativePosition("", "#CHAPEL_PRIEST", "#PRIEST")

	MsgSay("#PRIEST", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_HUSBAND_+1", GetID(list[SimGetGender("#MAIN")+1][1]), GetID(list[SimGetGender("#MAIN")+1][2]))

	CutsceneCameraSetRelativePosition("", "#CHAPEL_PRIEST(FAR)","#PRIEST")

	Sleep(1)

	CutsceneHUDShow("", "LetterBoxPanel")
	CutsceneHUDShow("", "TrialPanel")
	CutsceneShowCharacterPanel("", true)
	SetProperty("#MAIN", "IsAllowedSpecialMeasuresForWeddings", "1")

	SetExclusiveMeasure("#MAIN", 3000, EN_BOTH)
	AllowMeasure("#MAIN", 3001, EN_BOTH)
	AllowMeasure("#MAIN", 3002, EN_BOTH)

	if GetLocalPlayerDynasty("LocalPlayerDyn") then
		GetDynasty("#MAIN", "SimDyn")
		if (GetID("SimDyn") == GetID("LocalPlayerDyn")) then
			HudClearSelection()
			HudAddToSelection("#MAIN")
		end
	end

	ProgressBar:SetValueInt("VISIBILITY", 1)
	local Width
	while true do
		Width = ProgressBar:GetValueInt("ABS_WIDTH")
		ProgressBar:SetValueInt("ABS_WIDTH", Width-5)
		Sleep(0.1)
		if Width < 10 or CutsceneGetData("", "SkipProgressBar") then
			break
		end
	end

	ProgressBar:SetValueInt("VISIBILITY",0)
	ProgressBar:SetValueInt("ABS_WIDTH",1000)

	if CutsceneGetData("", "SkipProgressBar") then
		LogMessage("@NAO #E No Skip detected.")
		CutsceneCallThread("", "SayYes", "#MAIN")
	end
end

function ContinueAfterYes()
	SimGetCutscene("#MAIN", "Cutscene")

	local list = { {"#COURTED","#MAIN"}, {"#MAIN","#COURTED"} }

	CutsceneHUDShow("Cutscene", "LetterBoxPanel", false)
	CutsceneHUDShow("Cutscene", "TrialPanel", false)

	CutsceneCameraBlend("Cutscene", 2, 1)
	CutsceneCameraSetRelativePosition("Cutscene", "#CHAPEL_RIGHT", "#PRIEST")
	Sleep(1.25)
	PlayAnimationNoWait("#COURTED", "giggle")
	Sleep(0.5)
	PlayAnimationNoWait("#MAIN", "curtsy")

	MsgSay(list[SimGetGender("#MAIN")+1][1], "_FAMILY_1_MARRIAGE_CEREMONY_ANSWER_+0")

	CutsceneCameraSetRelativePosition("Cutscene", "#CHAPEL_PRIEST(FAR)","#PRIEST")

	MsgSay("#PRIEST", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_WIFE_+0", GetID(list[SimGetGender("#MAIN")+1][2]), GetID(list[SimGetGender("#MAIN")+1][1]))

	CutsceneCameraBlend("", 2, 1)
	CutsceneCameraSetRelativePosition("", "#CHAPEL_LEFT", "#PRIEST")
	Sleep(1.25)
	PlayAnimationNoWait("#MAIN", "giggle")
	Sleep(0.75)
	PlayAnimationNoWait("#COURTED", "nod")

	MsgSay(list[SimGetGender("#MAIN")+1][2], "_FAMILY_1_MARRIAGE_CEREMONY_ANSWER_+0")

	CutsceneCameraSetRelativePosition("", "#CHAPEL_PRIEST(FAR)", "#PRIEST")

	MsgSay("#PRIEST", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_FINALE_+0", GetID(list[SimGetGender("#MAIN")+1][1]))

	CutsceneCameraBlend("", 8, 1)
	CutsceneCameraSetRelativePosition("", "#CHAPEL_PRIEST(UP)", "#PRIEST")

	AlignTo("#MAIN", "#COURTED")
	AlignTo("#COURTED", "#MAIN")
	Sleep(1)

	ShowOverheadSymbol("#MAIN", false, true, 0, "@L$S[2001]")
	ShowOverheadSymbol("#COURTED", false, true, 0, "@L$S[2001]")

	if AliasExists("Orphan#1") and AliasExists("Orphan#2") then
		PlayAnimationNoWait("Orphan#1", "pray_standing")
		PlayAnimationNoWait("Orphan#2", "pray_standing")
	end

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

	MsgNewsNoWait("All", "", "", "politics", -1, "@L_MEASURE_MARRY_CEREMONY_HEAD_+0", "@L_MEASURE_MARRY_CEREMONY_NEWS_BODY_+0", GetID("#MAIN"), GetID("#COURTED"), GetID("#WEDDING_CHAPEL"), Guests)

	Sleep(0.5)

	LogMessage("@NAO [WeddingCeremony] There are "..ListSize("Visitors").." visitors. ("..Guests.." guests)")

	if Guests > 1 then
		ListNew("Reacting")
		for INDEX = 0, (Guests -1) do
			local CONFLICTING = false
			ListGetElement("Visitors", INDEX, "#REACT")
			LogMessage("@NAO [WeddingCeremony] Currently processing "..GetName("#REACT").." (Sim "..INDEX..").")

			if ListSize("Reacting") > 0 then
				for CHECK = 0, ListSize("Reacting")-1 do
					ListGetElement("Reacting", CHECK, "#VERIFY")
					if GetName("#VERIFY") == GetName("#REACT") then 
						CONFLICTING = true
					end
				end
			end
			if not CONFLICTING then
				LogMessage("@NAO [WeddingCeremony] Script confirmed no double data for "..GetName("#REACT").." (Sim "..INDEX..").")
				ListAdd("Reacting", "#REACT")
			end
		end

		for INDEX = 0, ListSize("Reacting") -1 do
			ListGetElement("Reacting", INDEX, "#SIM")
			Sleep(Rand(0.7,2))
			CutsceneCameraSetRelativePosition("", "#CHAPEL_GUEST", "#SIM")
			CutsceneCallThread("", "DoReactGuest", "#SIM")
		end

		ListClear("Reacting")
	end

	Sleep(7.5)

	RemoveProperty("#COURTED", "CourtDiff")
	MeasureSetNotRestartable()
	PlaySound3D("#WEDDING_CHAPEL", "locations/bell_stroke_cathedral_loop+0.wav", 1.0)

	AddImpact("#MAIN", "LoveLevel", 10, 24)
	AddImpact("#COURTED", "LoveLevel", 10, 24)

	if GetImpactValue("#COURTED", "LoveLevel") >= 10 then
		MsgNewsNoWait("#MAIN", "#COURTED", "", "schedule", -1, "@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0", "@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("#COURTED"))
	end

	CutsceneCameraBlend("", 2.5, 0)
	CutsceneCameraSetRelativePosition("", "Far_HUpYLeft", "#MAIN")

	Sleep(4)

	RemoveProperty("#COURTED", "Wedding")
	RemoveProperty("#COURTED", "courted")
	RemoveProperty("#MAIN", "#WEDDING_MAIN")

	RemoveProperty("#MAIN", "#WEDDING_FORCED")
	RemoveProperty("#COURTED", "#WEDDING_FORCED")

	PlaySound3D("#WEDDING_CHAPEL", "locations/bell_stroke_cathedral_loop+0.wav", 1.0)
	ClearImportantPersonSection("Wedding")

	LogMessage("@NAO [WeddingCeremony] Marrying sims...")
	SimMarry("#MAIN", "#COURTED")

	SetState("#COURTED", STATE_INLOVE, false)

	Sleep(1)

	SimResetBehavior("#COURTED")
	ClearImportantPersonSection("Wedding")

	Sleep(4)

	EndCutscene("")
	DestroyCutscene("")
end

function ContinueAfterNo()
	SimGetCutscene("#MAIN", "Cutscene")

	local list = { {"#COURTED","#MAIN"}, {"#MAIN","#COURTED"} }

	CutsceneHUDShow("Cutscene", "LetterBoxPanel", false)
	CutsceneHUDShow("Cutscene", "TrialPanel", false)

	CutsceneCameraBlend("Cutscene", 2, 1)
	CutsceneCameraSetRelativePosition("Cutscene", "#CHAPEL_RIGHT", "#PRIEST")
	Sleep(1.25)
	PlayAnimationNoWait("#COURTED", "giggle")
	Sleep(0.5)
	PlayAnimationNoWait("#MAIN", "curtsy")

	MsgSay(list[SimGetGender("#MAIN")+1][1], "_FAMILY_1_MARRIAGE_CEREMONY_ANSWER_+0")

	CutsceneCameraSetRelativePosition("Cutscene", "#CHAPEL_PRIEST(FAR)","#PRIEST")

	MsgSay("#PRIEST", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_WIFE_+0", GetID(list[SimGetGender("#MAIN")+1][2]), GetID(list[SimGetGender("#MAIN")+1][1]))

	CutsceneCameraBlend("", 2, 1)
	CutsceneCameraSetRelativePosition("", "#CHAPEL_LEFT", "#PRIEST")
	Sleep(1.25)
	PlayAnimationNoWait("#MAIN", "giggle")
	Sleep(0.75)
	PlayAnimationNoWait("#COURTED", "nod")

	MsgSay(list[SimGetGender("#MAIN")+1][2], "_FAMILY_1_MARRIAGE_CEREMONY_ANSWER_+0")

	CutsceneCameraSetRelativePosition("", "#CHAPEL_PRIEST(FAR)", "#PRIEST")

	MsgSay("#PRIEST", "_FAMILY_1_MARRIAGE_CEREMONY_PRIEST_FINALE_+0", GetID(list[SimGetGender("#MAIN")+1][1]))

	CutsceneCameraBlend("", 8, 1)
	CutsceneCameraSetRelativePosition("", "#CHAPEL_PRIEST(UP)", "#PRIEST")

	AlignTo("#MAIN", "#COURTED")
	AlignTo("#COURTED", "#MAIN")
	Sleep(1)

	ShowOverheadSymbol("#MAIN", false, true, 0, "@L$S[2001]")
	ShowOverheadSymbol("#COURTED", false, true, 0, "@L$S[2001]")

	if AliasExists("Orphan#1") and AliasExists("Orphan#2") then
		PlayAnimationNoWait("Orphan#1", "pray_standing")
		PlayAnimationNoWait("Orphan#2", "pray_standing")
	end

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

	MsgNewsNoWait("All", "", "", "politics", -1, "@L_MEASURE_MARRY_CEREMONY_HEAD_+0", "@L_MEASURE_MARRY_CEREMONY_NEWS_BODY_+0", GetID("#MAIN"), GetID("#COURTED"), GetID("#WEDDING_CHAPEL"), Guests)

	Sleep(0.5)

	LogMessage("@NAO [WeddingCeremony] There are "..ListSize("Visitors").." visitors. ("..Guests.." guests)")

	if Guests > 1 then
		ListNew("Reacting")
		for INDEX = 0, (Guests -1) do
			local CONFLICTING = false
			ListGetElement("Visitors", INDEX, "#REACT")
			LogMessage("@NAO [WeddingCeremony] Currently processing "..GetName("#REACT").." (Sim "..INDEX..").")

			if ListSize("Reacting") > 0 then
				for CHECK = 0, ListSize("Reacting")-1 do
					ListGetElement("Reacting", CHECK, "#VERIFY")
					if GetName("#VERIFY") == GetName("#REACT") then 
						CONFLICTING = true
					end
				end
			end
			if not CONFLICTING then
				LogMessage("@NAO [WeddingCeremony] Script confirmed no double data for "..GetName("#REACT").." (Sim "..INDEX..").")
				ListAdd("Reacting", "#REACT")
			end
		end

		for INDEX = 0, ListSize("Reacting") -1 do
			ListGetElement("Reacting", INDEX, "#SIM")
			Sleep(Rand(0.7,2))
			CutsceneCameraSetRelativePosition("", "#CHAPEL_GUEST", "#SIM")
			CutsceneCallThread("", "DoReactGuest", "#SIM")
		end

		ListClear("Reacting")
	end

	Sleep(7.5)

	RemoveProperty("#COURTED", "CourtDiff")
	MeasureSetNotRestartable()
	PlaySound3D("#WEDDING_CHAPEL", "locations/bell_stroke_cathedral_loop+0.wav", 1.0)

	AddImpact("#MAIN", "LoveLevel", 10, 24)
	AddImpact("#COURTED", "LoveLevel", 10, 24)

	if GetImpactValue("#COURTED", "LoveLevel") >= 10 then
		MsgNewsNoWait("#MAIN", "#COURTED", "", "schedule", -1, "@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0", "@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("#COURTED"))
	end

	CutsceneCameraBlend("", 2.5, 0)
	CutsceneCameraSetRelativePosition("", "Far_HUpYLeft", "#MAIN")

	Sleep(4)

	RemoveProperty("#COURTED", "Wedding")
	RemoveProperty("#COURTED", "courted")
	RemoveProperty("#MAIN", "#WEDDING_MAIN")

	RemoveProperty("#MAIN", "#WEDDING_FORCED")
	RemoveProperty("#COURTED", "#WEDDING_FORCED")

	PlaySound3D("#WEDDING_CHAPEL", "locations/bell_stroke_cathedral_loop+0.wav", 1.0)
	ClearImportantPersonSection("Wedding")

	LogMessage("@NAO [WeddingCeremony] Marrying sims...")
	SimMarry("#MAIN", "#COURTED")

	SetState("#COURTED", STATE_INLOVE, false)

	Sleep(1)

	SimResetBehavior("#COURTED")
	ClearImportantPersonSection("Wedding")

	Sleep(4)

	EndCutscene("")
	DestroyCutscene("")
end

function ContinueAfterSuccessfulMurder()
	SimGetCutscene("#MAIN", "Cutscene")

	BuildingGetInsideSimList("#WEDDING_CHAPEL", "Sit_Visitors")

	ListRemove("Sit_Visitors", "#MAIN")
	ListRemove("Sit_Visitors", "#COURTED")
	ListRemove("Sit_Visitors", "#PRIEST")

	if AliasExists("Orphan#1") and AliasExists("Orphan#2") then
		ListRemove("Sit_Visitors", "Orphan#1")
		ListRemove("Sit_Visitors", "Orphan#2")
	end

	CutsceneCameraSetRelativePosition("Cutscene", "Far_HUpYLeft", "#MAIN")

	for i = 0, ListSize("Sit_Visitors") -1 do
		ListGetElement("Sit_Visitors", i, "#SIM")
		CutsceneCallThread("Cutscene", "GetUp", "#SIM")
	end

	ListClear("Sit_Visitors")

	f_StartHighPriorMusic(35)

	MoveSetStance("#PRIEST", GL_STANCE_CROUCH)

	-- Progress, Guest1, Guest2, Guest3, Arrow, Timer
	TrialHUDSetStatus("Cutscene", 2, 1, 2, 3, 2, 2.0)
	Sleep(0.5)

	local Guests = ListSize("Visitors")
	local list = { {"#COURTED","#MAIN"}, {"#MAIN","#COURTED"} }

	Sleep(2)

	CutsceneHUDShow("Cutscene", "LetterBoxPanel", false)
	CutsceneHUDShow("Cutscene", "TrialPanel", false)

	Sleep(1)

	CutsceneCameraSetRelativePosition("Cutscene", "#CHAPEL_PRIEST(FAR)","#PRIEST")

	MsgSay("#PRIEST", "_FAMILY_1_MARRIAGE_CEREMONY_MURDER_+1")

	MoveSetStance("#PRIEST", GL_STANCE_STAND)

	CutsceneCameraBlend("Cutscene", 2, 1)
	CutsceneCameraSetRelativePosition("Cutscene", "#CHAPEL_PRIEST","#PRIEST")
	Sleep(0.5)
	AlignTo("#MAIN", "#PRIEST")
	AlignTo("#PRIEST", "#MAIN")
	MsgSay("#PRIEST", "_FAMILY_1_MARRIAGE_CEREMONY_MURDER_+2")

	Sleep(0.5)

	LogMessage("@NAO ???")

	--local Next = MsgSayInteraction("#MAIN", "#MAIN", "#MAIN",
	--									"@B[1,@L_MEASURE_MARRY_CEREMONY_THREATEN_+0]"..
	--									"@B[2,@L_MEASURE_MARRY_CEREMONY_THREATEN_+1]",
	--									nil,
	--									"test")

	local Next = 1

	if Next == 1 then
		CutsceneCallThread("Cutscene", "ThreatenAfterMurder", "#MAIN")
	else
		CutsceneCallThread("Cutscene", "GetOutAfterMurder", "#MAIN")
	end
	LogMessage("@NAO ???")
end

function ThreatenAfterMurder()
	SimGetCutscene("#MAIN", "Cutscene")

	BuildingGetInsideSimList("#WEDDING_CHAPEL", "Sit_Visitors")

	ListRemove("Sit_Visitors", "#MAIN")
	ListRemove("Sit_Visitors", "#COURTED")
	ListRemove("Sit_Visitors", "#PRIEST")

	if AliasExists("Orphan#1") and AliasExists("Orphan#2") then
		ListRemove("Sit_Visitors", "Orphan#1")
		ListRemove("Sit_Visitors", "Orphan#2")
	end

	CutsceneCameraBlend("Cutscene", 2, 1)
	CutsceneCameraSetRelativePosition("Cutscene", "CameraPortrait", "#MAIN")

	MsgSay("#MAIN", "Now listen up, if you wish to live...")

	local Size = ListSize("Sit_Visitors")
	local TargetSim = ListGetElement("Sit_Visitors", Rand(Size), "TargetSim")

	AlignTo("#MAIN", "TargetSim")

	MsgSay("#MAIN", "You seem like a reasonable folk. Give me your gold.")

	Sleep(2)

	local test = InitAlias("#MAIN", MEASUREINIT_SELECTION, "__F( NOT(Object.BelongsToMe())AND(Object.Type == Sim)) )",
			"@L_ARTEFACTS_184_USEFLOWEROFDISCORD_TARGET2_+0", 0)
 -- MEASUREINIT_PANEL_CLASS
	if test ~= nil then
		Sleep(4)

		RemoveProperty("#MAIN", "#WEDDING_MAIN")
		RemoveProperty("#MAIN", "#WEDDING_FORCED")

		ClearImportantPersonSection("Wedding")

		EndCutscene("Cutscene")
		DestroyCutscene("Cutscene")
	end

end

function GetOutAfterMurder()
	SimGetCutscene("#MAIN", "Cutscene")

	BuildingGetInsideSimList("#WEDDING_CHAPEL", "Sit_Visitors")

	ListRemove("Sit_Visitors", "#MAIN")
	ListRemove("Sit_Visitors", "#COURTED")
	ListRemove("Sit_Visitors", "#PRIEST")

	if AliasExists("Orphan#1") and AliasExists("Orphan#2") then
		ListRemove("Sit_Visitors", "Orphan#1")
		ListRemove("Sit_Visitors", "Orphan#2")
	end

	for i = 0, Guests - 1 do
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
		ShowOverheadSymbol("#SIM", false, true, 0, "@L$S[2001]")
		ModifyFavorToSim("#SIM", "#MAIN", -GL_FAVOR_MOD_EPIC)
		ModifyFavorToSim("#MAIN", "#SIM", -GL_FAVOR_MOD_EPIC)
	end

	dyn_AddFame("#MAIN", -1)
	ShowOverheadSymbol("#MAIN", false, true, 0, "@L$S[2001]")

	f_StartHighPriorMusic(19)

	MsgNewsNoWait("All", "", "", "politics", -1, "@L_MEASURE_MARRY_CEREMONY_HEAD_+0", "@L_MEASURE_MARRY_CEREMONY_MURDER_NEWS_BODY_+0", GetID("#MAIN"), GetID("#COURTED"))

	Sleep(0.5)

	if Guests > 1 then
		ListNew("Reacting")
		for INDEX = 0, (Guests -1) do
			local CONFLICTING = false
			ListGetElement("Visitors", INDEX, "#REACT")

			if ListSize("Reacting") > 0 then
				for CHECK = 0, ListSize("Reacting")-1 do
					ListGetElement("Reacting", CHECK, "#VERIFY")
					if GetName("#VERIFY") == GetName("#REACT") then 
						CONFLICTING = true
					end
				end
			end
			if not CONFLICTING then
				ListAdd("Reacting", "#REACT")
			end
		end

		local MaxReact, MaxReactCount = 3, 0

		for INDEX = 0, ListSize("Reacting") -1 do
			MaxReactCount = MaxReactCount +1
			if MaxReactCount == MaxReact then
				break
			else
				ListGetElement("Reacting", INDEX, "#SIM")
				Sleep(Rand(0.7,2))
				CutsceneCameraSetRelativePosition("Cutscene", "CameraPortrait", "#SIM")
				ReleaseLocator("SIM")
				--PlayAnimationNoWait("#SIM", "bench_talk_offended")
				MsgSay("#SIM", "Horrible!")
			end
		end
		ListClear("Reacting")
	end

	MeasureSetNotRestartable()

	CutsceneCameraSetRelativePosition("Cutscene", "Far_HUpYLeft", "#MAIN")

	Sleep(4)

	RemoveProperty("#MAIN", "#WEDDING_MAIN")
	RemoveProperty("#MAIN", "#WEDDING_FORCED")

	ClearImportantPersonSection("Wedding")

	EndCutscene("Cutscene")
	DestroyCutscene("Cutscene")
end

function SetWeddingHUD()
	local Bool = true
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
				Node:SetValueString("TEXT", GetName("#MAIN"))
			end
			if Node:GetName() == "AccusedNameLabel" then
				Node:SetValueString("TEXT", GetName("#COURTED"))
			end
			if Node:GetName() == "cl_WinContainer" then
				_Child = Node:GetChildAt(1)
				LogMessage("@NAO cl_WinContainer ("..i..") -> "..(_Child:GetValueString("TEXT") or 'nil'))
				_Child:SetValueString("TEXT",NewLabels[i-28])
				LogMessage("@NAO #W cl_WinContainer ("..i..") -> "..(_Child:GetValueString("TEXT") or 'nil'))
			end
			if Node:GetName() == "ProgressBarDesc" then
				ProgressBar = Node
			end
		end
	end
end

function ForbidWeddingMeasures()
	ForbidMeasure("#MAIN", 3000, EN_BOTH)
	ForbidMeasure("#MAIN", 3001, EN_BOTH)
	ForbidMeasure("#MAIN", 3002, EN_BOTH)
	LogMessage("@NAO ForbidWeddingMeasures")
end

function SayYes()
	SimGetCutscene("#MAIN","Cutscene")
	CutsceneCallThread("Cutscene", "ForbidWeddingMeasures", "#MAIN")
	CutsceneSetData("Cutscene","SkipProgressBar","1")
	local Charisma = GetSkillValue("#MAIN", CHARISMA)
	local Rethoric = GetSkillValue("#MAIN", RHETORIC)
	local Alignment = SimGetAlignment("#MAIN")
	local AlignmentVariant = f_GetAlignmentVariant(Alignment)

	local EndValue = Charisma + Rethoric

	if EndValue < 3 then
		MsgSay("#MAIN", "@L_FAMILY_1_MARRIAGE_CEREMONY_POSITIVE_ANSWER_"..AlignmentVariant.."_+1")
	elseif EndValue < 6 then
		MsgSay("#MAIN", "@L_FAMILY_1_MARRIAGE_CEREMONY_POSITIVE_ANSWER_"..AlignmentVariant.."_+2")
	elseif EndValue > 5 then
		MsgSay("#MAIN", "@L_FAMILY_1_MARRIAGE_CEREMONY_POSITIVE_ANSWER_"..AlignmentVariant.."_+3")
	end
	CutsceneCallThread("Cutscene", "ContinueAfterYes", "#MAIN")
end

function SayNo()
	SimGetCutscene("#MAIN", "Cutscene")
	CutsceneCallThread("Cutscene", "ForbidWeddingMeasures", "#MAIN")
	CutsceneSetData("Cutscene", "SkipProgressBar","1")
	local Charisma = GetSkillValue("#MAIN", CHARISMA)
	local Rethoric = GetSkillValue("#MAIN", RHETORIC)
	local Alignment = SimGetAlignment("#MAIN")
	local AlignmentVariant = f_GetAlignmentVariant(Alignment)

	local EndValue = Charisma + Rethoric

	if EndValue < 3 then
		MsgSay("#MAIN", "@L_FAMILY_1_MARRIAGE_CEREMONY_NEGATIVE_ANSWER_"..AlignmentVariant.."_+1")
	elseif EndValue < 6 then
		MsgSay("#MAIN", "@L_FAMILY_1_MARRIAGE_CEREMONY_NEGATIVE_ANSWER_"..AlignmentVariant.."_+2")
	elseif EndValue > 5 then
		MsgSay("#MAIN", "@L_FAMILY_1_MARRIAGE_CEREMONY_NEGATIVE_ANSWER_"..AlignmentVariant.."_+3")
	end
	CutsceneCallThread("Cutscene", "Continue", "#MAIN")
end

function Murder()
	SimGetCutscene("#MAIN","Cutscene")
	CutsceneCallThread("Cutscene", "ForbidWeddingMeasures", "#MAIN")
	CutsceneSetData("Cutscene", "SkipProgressBar", "1")
	AddItems("#MAIN", "Dagger", 1, INVENTORY_EQUIPMENT)

	MsgSay("#MAIN", "_FAMILY_1_MARRIAGE_CEREMONY_MURDER_+0")

	SetProperty("#MAIN", "KillAction_start", 1)
	feedback_OverheadActionName("#MAIN")
	GetPosition("#COURTED", "ParticleSpawnPos")

	BattleWeaponPresent("#MAIN")
	Sleep(2)

	PlayAnimationNoWait("#MAIN","finishing_move_01")
	Sleep(1)	

	local SimCount = Find("#MAIN", "__F((Object.GetObjectsByRadius(Sim) == 2000))", "SIM", -1)
	for i = 0, SimCount -1 do
		AddEvidence("SIM"..i, "#MAIN", "#COURTED", 16)
	end

	AddEvidence("#MAIN", "#MAIN", "#COURTED", 16)

	Kill("#COURTED")

	StartSingleShotParticle("particles/bloodsplash.nif", "ParticleSpawnPos", 2, 4)
	PlaySound3DVariation("#COURTED", "Effects/combat_strike_mace", 1)
	
	Sleep(2)
	BattleWeaponStore("#MAIN")

	CutsceneCallThread("Cutscene", "ContinueAfterSuccessfulMurder", "#MAIN")
end

-- Musicians

function PrepareInstrument0()
	GetInsideBuilding("", "MarryRoom")
	GetLocatorByName("MarryRoom", "Musician0", "MusicianPosition", false)
	f_MoveTo("", "MusicianPosition")
	f_BeginUseLocator("", "MusicianPosition", GL_STANCE_STAND)
end

function PrepareInstrument1()
	CarryObject("", "Handheld_Device/ANIM_Violinestock.nif", false)
	CarryObject("", "Handheld_Device/ANIM_Violine.nif", true)
	GetInsideBuilding("", "MarryRoom")
	GetLocatorByName("MarryRoom", "Musician1", "MusicianPosition", false)
	f_MoveTo("", "MusicianPosition")
	f_BeginUseLocator("", "MusicianPosition", GL_STANCE_STAND)
end

function PrepareInstrument2()
	CarryObject("", "Handheld_Device/ANIM_Violinestock.nif", false)
	CarryObject("", "Handheld_Device/ANIM_Violine.nif", true)
	GetInsideBuilding("", "MarryRoom")
	GetLocatorByName("MarryRoom", "Musician2", "MusicianPosition", false)
	f_MoveTo("", "MusicianPosition")
	f_BeginUseLocator("", "MusicianPosition", GL_STANCE_STAND)
	CutsceneSendEventTrigger("owner", "Musician2Ready")
end

function StartPlaying()
	local Duration = PlayAnimationNoWait("", "play_instrument_03_in")
	Sleep(Duration)
	LoopAnimation("", "play_instrument_03_loop", 30)
end

function StartSinging()
	LogMessage("@NAO Start Singing")
	Attach3DSound("", "measures/singforpeacefulness/female_songofpeacefulness+0.wav", 1.0)
	LoopAnimation("", "sing_for_peace", 30)
	LogMessage("@NAO End Singing")
end

--PlayAnimationNoWait("","play_instrument_01_in")
--CarryObject("","Handheld_Device/ANIM_Flute.nif",false)
--PlayAnimation("", "play_instrument_01_loop")


--PlayAnimationNoWait("","play_instrument_03_in")
--CarryObject("","Handheld_Device/ANIM_laute.nif",true)
--PlayAnimation("","play_instrument_03_loop")