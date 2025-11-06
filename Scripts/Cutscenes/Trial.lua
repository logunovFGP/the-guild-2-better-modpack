----------------------------------------------------------------------------------
--- Main Body
----------------------------------------------------------------------------------
-- Setup / Termin / Einladung

function returnMembers()
	GetAliasByID(GetProperty("SIM","trial_destination_ID"),"CutsceneAlias")
	GetAliasByID(GetProperty("SIM","trial_destination_ID"),"trial_destination_ID")
	GetAliasByID(GetProperty("CutsceneAlias","NextCutsceneID"),"CutsceneAlias")
	local list = { {"judge","accuser","accused","assessor1","assessor2"}, {} }

	for i = 1, 5 do
		CutsceneGetData(GetProperty("Townhall","NextCutsceneID"),list[1][i])
		list[2][i] = GetData(list[1][i])
	end

  return list[2]
end --eed

function Start()
	-- get trial roles
	CityAssignTrialRoles("", "settlement")
	
	-- create assessor list
	CityGetDynastyCharList("settlement", "assessor_candidates")
	ListRemove("assessor_candidates", "judge")
	ListRemove("assessor_candidates", "accuser")
	ListRemove("assessor_candidates", "accused")
	
	-- Get 2 assessors
	local lsize = ListSize("assessor_candidates")
	if lsize >= 1 then
		local index = Rand(lsize)
		ListGetElement("assessor_candidates", index, "assessor1")
		ListRemove("assessor_candidates", "assessor1")
	end
	
	-- update the list for the second assessor
	lsize = ListSize("assessor_candidates")
	if lsize >= 1 then
		local index = Rand(lsize)
		ListGetElement("assessor_candidates", index, "assessor2")
		ListRemove("assessor_candidates", "assessor2")
	end

	-- schedule the event: event_alias, settlement, cutscene, function
	-- we have 2 time slots for the event
	
	if not HasProperty("courtbuilding", "UpcomingTrials") then
		LogMessage("@TRIAL #W Setting UpcomingTrials value to -1 (default)")
		SetProperty("courtbuilding", "UpcomingTrials", -1)
	end

	local UpcomingTrials = GetProperty("courtbuilding", "UpcomingTrials")
	SetProperty("courtbuilding", "UpcomingTrials", UpcomingTrials +1)
	
	UpcomingTrials = GetProperty("courtbuilding", "UpcomingTrials")

	LogMessage("@TRIAL #W The following slot was assigned to this trial: " .. UpcomingTrials)

	local debug = false

	if debug then 

		trialData.debug()

		CityScheduleCutsceneEvent("settlement", "trial_date", "", "EverybodySitDown", math.mod(GetGametime(),24), 0, "@L_LAWSUIT_DIARY_CITY_+0", GetID("accuser"), GetID("accused"))	-- hourofday=4, mintimeinfuture=6
		CityGetRandomBuilding("Settlement",GL_BUILDING_CLASS_PUBLICBUILDING,GL_BUILDING_TYPE_TOWNHALL,-1,-1,FILTER_IGNORE,"CouncilBuilding")
		GetLocatorByName("CouncilBuilding", "ApproachUsherPos", "destpos")
		BuildingGetRoom("CouncilBuilding", "Judge", "Room")

		local locations = {["judge"]="JudgeChairPos",["accuser"]="AccuserStandPos",["accused"]="AccusedStandPos",["assessor1"]="RightAssessorChairPos",["assessor2"]="LeftAssessorChairPos"}
		LogMessage("Teleporting the usual trial participants to the Town Hall before sorting them out.")
		for i = 1,5 do
			SimBeamMeUp(trialData.list[i], "destpos", false)
			if trialData.Attending[i] ~= nil then 
				SimBeamMeUp(trialData.Attending[i], "Room", false) 
				local LocatorNameTemp = locations[trialData.Attending[i]]
				GetLocatorByName("courtbuilding", LocatorNameTemp, LocatorNameTemp)
				SimBeamMeUp(trialData.Attending[i], LocatorNameTemp, false)
				LogMessage("Our "..trialData.Attending[i].." was teleported to the Court Room.")
			end
		end

	-- No trials ahead, take the first slot
	elseif UpcomingTrials == 0 then
		CityScheduleCutsceneEvent("settlement", "trial_date", "", "EverybodySitDown", 4, 6, "@L_LAWSUIT_DIARY_CITY_+0", GetID("accuser"), GetID("accused"))	-- hourofday=4, mintimeinfuture=6
	-- else take the second slot
	elseif UpcomingTrials == 1 then
		CityScheduleCutsceneEvent("settlement", "trial_date", "", "EverybodySitDown", 11, 6, "@L_LAWSUIT_DIARY_CITY_+0", GetID("accuser"), GetID("accused"))	-- hourofday=11, mintimeinfuture=6
	-- after that take the first slot again
	elseif UpcomingTrials == 2 then
		CityScheduleCutsceneEvent("settlement", "trial_date", "", "EverybodySitDown", 4, 6, "@L_LAWSUIT_DIARY_CITY_+0", GetID("accuser"), GetID("accused"))	-- hourofday=4, mintimeinfuture=6
	-- default: take the second slot
	else
		CityScheduleCutsceneEvent("settlement", "trial_date", "", "EverybodySitDown", 11, 6, "@L_LAWSUIT_DIARY_CITY_+0", GetID("accuser"), GetID("accused"))	-- hourofday=11, mintimeinfuture=6
	end
	

	
	local EventTime = SettlementEventGetTime("trial_date")
	local EventTimeInvite = EventTime/60
	local CurrentTime = math.mod(GetGametime(),24)
	local GameTime = GetGametime()*60
	local WaitTime = EventTime - GameTime - 180
	local ImpactTime = math.floor(WaitTime/60)
	local CityID = GetID("settlement")

	LogMessage("@TRIAL #W Internal timecode for event: " .. EventTime)
	LogMessage("@TRIAL #W Current gametime: " .. GameTime)
	LogMessage("@TRIAL #W Planned total wait time: " .. WaitTime)
	LogMessage("@TRIAL #W Alternative round-up final time minus two hours: " .. EventTime - 180)

	--if (WaitTime < 0) then
		--trial_SetBuildingInfo()
	--else
		CutsceneAddEvent("", "SetBuildingInfo", WaitTime)
	--end

	local Evidences = 0+CutsceneCollectEvidences("", "accuser", "accused")

	--to the judge
	if GetID("judge")>0 then
			
		-- Property for AI
		SetProperty("judge", "DefendTrial", 1)
		AddImpact("judge", "TrialTimer", 1, ImpactTime)
		
		-- start countdown
		if GetDynasty("judge", "InviteDyn") and ReadyToRepeat("InviteDyn", "COUNTDOWN_TRIAL"..CityID) then
			SetRepeatTimer("InviteDyn", "COUNTDOWN_TRIAL"..CityID, ImpactTime)
			local ImpactTimeCorrect = EventTimeInvite - CurrentTime
			local DestTime = CurrentTime + ImpactTimeCorrect
			local ID = "Event"..GetID("judge")
			MsgNewsNoWait("judge", "judge", "@C[@L_TRIAL_IN_TOWN_COUNTDOWN_+0,%i7,%l8]", "default", -1,
						"@L_LAWSUIT_2_MESSAGES_2A_SEND_RICHTER_+0",
						"@L_LAWSUIT_2_MESSAGES_2A_SEND_RICHTER_+1", 
						GetID("judge"), GetID("accuser"), GetID("accused"), EventTime, SettlementEventGetTime("trial_date"), GetID("settlement"), DestTime, ID)
		else				
			
			feedback_MessagePolitics("judge",
							"@L_LAWSUIT_2_MESSAGES_2A_SEND_RICHTER_+0",
							"@L_LAWSUIT_2_MESSAGES_2A_SEND_RICHTER_+1",
							GetID("judge"),GetID("accuser"),GetID("accused"), EventTime, SettlementEventGetTime("trial_date"), GetID("settlement"))
		end
		
		SimAddDate("judge","courtbuilding", "Court Hearing", EventTime-120, "AttendTrialMeeting")
		SimAddDatebookEntry("judge", EventTime, "courtbuilding", "@L_NEWSTUFF_TRIAL_DATEBOOK_HEADER", "@L_LAWSUIT_2_MESSAGES_2B_TIMEPLANNERENTRY_RICHTER",
						GetID("accuser"), GetID("accused"), GetID("settlement"))
		
	end
		
	SetData("judge",GetID("judge"))

	-- To the accuser
	if GetID("accuser")>0 then
	
		-- Property for AI
		SetProperty("accuser", "DefendTrial", 1)
		SetProperty("accuser", "TrialOpponent", GetID("accused"))
		SetProperty("accuser", "TrialJudge", GetID("judge"))
		AddImpact("accuser", "TrialTimer", 1, ImpactTime)
		
		-- start countdown
		if GetDynasty("accuser", "InviteDyn") and ReadyToRepeat("InviteDyn", "COUNTDOWN_TRIAL"..CityID) then
			SetRepeatTimer("InviteDyn", "COUNTDOWN_TRIAL"..CityID, ImpactTime)
			local ImpactTimeCorrect = EventTimeInvite - CurrentTime
			local DestTime = CurrentTime + ImpactTimeCorrect
			local ID = "Event"..GetID("accuser")
			MsgNewsNoWait("accuser", "accuser", "@C[@L_TRIAL_IN_TOWN_COUNTDOWN_+0,%i7,%l8]", "default", -1,
						"@L_LAWSUIT_2_MESSAGES_2A_SEND_KLAEGER_+0",
						"@L_LAWSUIT_2_MESSAGES_2A_SEND_KLAEGER_+1", 
						GetID("accuser"), GetID("accused"), GetID("settlement"), Evidences, EventTime, EventTime, DestTime, ID)
		else				
			feedback_MessagePolitics("accuser",
							"@L_LAWSUIT_2_MESSAGES_2A_SEND_KLAEGER_+0",
							"@L_LAWSUIT_2_MESSAGES_2A_SEND_KLAEGER_+1",
							GetID("accuser"), GetID("accused"), GetID("settlement"), Evidences, EventTime, EventTime)
		end
		
		SimAddDate("accuser", "courtbuilding", "Court Hearing", EventTime-120, "AttendTrialMeeting")
		SimAddDatebookEntry("accuser", EventTime, "courtbuilding", "@L_NEWSTUFF_TRIAL_DATEBOOK_HEADER", "@L_LAWSUIT_2_MESSAGES_2B_TIMEPLANNERENTRY_KLAEGER",
						GetID("accused"), GetID("settlement"))

		SetProperty("accuser","trial_destination_ID",GetID(""))
		SetProperty("accuser","HaveCutscene",1)
	end
	
	SetData("accuser",GetID("accuser"))

	if GetID("accused") > 0 then
		
		-- Property for AI
		SetProperty("accused", "DefendTrial", 1)
		SetProperty("accused", "TrialOpponent", GetID("accuser"))
		SetProperty("accused", "TrialJudge", GetID("judge"))
		AddImpact("accused", "TrialTimer", 1, ImpactTime)
		
		-- start countdown
		if GetDynasty("accused", "InviteDyn") and ReadyToRepeat("InviteDyn", "COUNTDOWN_TRIAL"..CityID) then
			SetRepeatTimer("InviteDyn", "COUNTDOWN_TRIAL"..CityID, ImpactTime)
			local ImpactTimeCorrect = EventTimeInvite - CurrentTime
			local DestTime = CurrentTime + ImpactTimeCorrect
			local ID = "Event"..GetID("accused")
			MsgNewsNoWait("accused", "accused", "@C[@L_TRIAL_IN_TOWN_COUNTDOWN_+0,%i6,%l7]", "default", -1,
						"@L_LAWSUIT_2_MESSAGES_2A_SEND_ANGEKLAGTER_+0",
						"@L_LAWSUIT_2_MESSAGES_2A_SEND_ANGEKLAGTER_+1", 
						GetID("accused"), GetID("accuser"), GetID("settlement"), SettlementEventGetTime("trial_date"), SettlementEventGetTime("trial_date"), DestTime, ID)
		else		
			feedback_MessagePolitics("accused",
							"@L_LAWSUIT_2_MESSAGES_2A_SEND_ANGEKLAGTER_+0",
							"@L_LAWSUIT_2_MESSAGES_2A_SEND_ANGEKLAGTER_+1",
							GetID("accused"), GetID("accuser"), GetID("settlement"), SettlementEventGetTime("trial_date"), SettlementEventGetTime("trial_date"))
		end
		
		SimAddDate("accused", "courtbuilding", "Court Hearing", EventTime-120, "AttendTrialMeeting")
		SimAddDatebookEntry("accused", EventTime, "courtbuilding", "@L_NEWSTUFF_TRIAL_DATEBOOK_HEADER", "@L_LAWSUIT_2_MESSAGES_2B_TIMEPLANNERENTRY_ANGEKLAGTER",
						GetID("accuser"), GetID("settlement"))
		
		SetProperty("accused", "trial_destination_ID", GetID(""))
		SetProperty("accused", "HaveCutscene", 1)
	end
	
	SetData("accused", GetID("accused"))

	if (GetID("assessor1") ~= -1) then
		SimAddDate("assessor1","courtbuilding","Court Hearing", EventTime-90,"AttendTrialMeeting")
		SetProperty("accused", "TrialAssessor1", GetID("assessor1"))
		SetProperty("accuser", "TrialAssessor1", GetID("assessor1"))
		
		-- start countdown
		if GetDynasty("assessor1", "InviteDyn") and ReadyToRepeat("InviteDyn", "COUNTDOWN_TRIAL"..CityID) then
			SetRepeatTimer("InviteDyn", "COUNTDOWN_TRIAL"..CityID, ImpactTime)
			local ImpactTimeCorrect = EventTimeInvite - CurrentTime
			local DestTime = CurrentTime + ImpactTimeCorrect
			local ID = "Event"..GetID("assessor1")
			MsgNewsNoWait("assessor1", "assessor1", "@C[@L_TRIAL_IN_TOWN_COUNTDOWN_+0,%i7,%l8]", "default", -1,
						"@L_LAWSUIT_2_MESSAGES_2A_SEND_BEISITZER_+0",
						"@L_LAWSUIT_2_MESSAGES_2A_SEND_BEISITZER_+1", 
						GetID("assessor1"), GetID("accuser"), GetID("accused"), EventTime, EventTime, GetID("settlement"), DestTime, ID)
		else	
			feedback_MessagePolitics("assessor1",
								"@L_LAWSUIT_2_MESSAGES_2A_SEND_BEISITZER_+0",
								"@L_LAWSUIT_2_MESSAGES_2A_SEND_BEISITZER_+1",
								GetID("assessor1"), GetID("accuser"), GetID("accused"), EventTime, EventTime, GetID("settlement"))
		end

		SimAddDatebookEntry("assessor1", EventTime, "courtbuilding", "@L_NEWSTUFF_TRIAL_DATEBOOK_HEADER", "@L_LAWSUIT_2_MESSAGES_2B_TIMEPLANNERENTRY_BEISITZER",
						GetID("accuser"), GetID("accused"), GetID("settlement"))
	end
	
	SetData("assessor1", GetID("assessor1"))

	if (GetID("assessor2") ~= -1) then
		SimAddDate("assessor2", "courtbuilding", "Court Hearing", EventTime-90, "AttendTrialMeeting")
		SetProperty("accused", "TrialAssessor2", GetID("assessor2"))
		SetProperty("accuser", "TrialAssessor2", GetID("assessor2"))
		
		-- start countdown
		if GetDynasty("assessor2", "InviteDyn") and ReadyToRepeat("InviteDyn", "COUNTDOWN_TRIAL"..CityID) then
			SetRepeatTimer("InviteDyn", "COUNTDOWN_TRIAL"..CityID, ImpactTime)
			local ImpactTimeCorrect = EventTimeInvite - CurrentTime
			local DestTime = CurrentTime + ImpactTimeCorrect
			local ID = "Event"..GetID("assessor2")
			MsgNewsNoWait("assessor2", "assessor2", "@C[@L_TRIAL_IN_TOWN_COUNTDOWN_+0,%i7,%l8]", "default", -1,
						"@L_LAWSUIT_2_MESSAGES_2A_SEND_BEISITZER_+0",
						"@L_LAWSUIT_2_MESSAGES_2A_SEND_BEISITZER_+1", 
						GetID("assessor2"), GetID("accuser"), GetID("accused"), EventTime, EventTime, GetID("settlement"), DestTime, ID)
		else	
			feedback_MessagePolitics("assessor2",
								"@L_LAWSUIT_2_MESSAGES_2A_SEND_BEISITZER_+0",
								"@L_LAWSUIT_2_MESSAGES_2A_SEND_BEISITZER_+1",
								GetID("assessor2"), GetID("accuser"), GetID("accused"), EventTime, EventTime, GetID("settlement"))
		end

		SimAddDatebookEntry("assessor2", EventTime, "courtbuilding", "@L_NEWSTUFF_TRIAL_DATEBOOK_HEADER", "@L_LAWSUIT_2_MESSAGES_2B_TIMEPLANNERENTRY_BEISITZER",
						GetID("accuser"), GetID("accused"), GetID("settlement"))
	end
	
	SetData("assessor2", GetID("assessor2"))
end

function SetBuildingInfo()
	LogMessage("@TRIAL #W Setting judgeroom information (this is where NextCutsceneID is set to " .. GetID("") ..")")
	BuildingGetRoom("courtbuilding", "Judge", "judgeroom")
	SetProperty("judgeroom", "NextCutsceneID", GetID(""))
end

-- Prepare and sit down
function EverybodySitDown()
	LogMessage("Trial. Let's begin!")
	
	BuildingGetRoom("courtbuilding", "Judge", "judgeroom")
	-- check if assessor1 is present
	GetInsideRoom("assessor1", "Room")
	if (GetID("assessor1")==-1) or (GetHP("assessor1")<1) or (GetID("Room")~=GetID("judgeroom")) then  
		if AliasExists("assessor1") and GetID("assessor1")>0 then
			CityAddPenalty("settlement","assessor1", PENALTY_MONEY, GL_TRIAL_COST_PER_LEVEL)
			feedback_MessagePolitics("assessor1","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+0",
								"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+1", GetID("assessor1"), 500) 
		end
		BuildingFindSimByProperty("courtbuilding","BUILDING_NPC", 2,"assessor1")
	end

	-- check if assessor2 is present
	GetInsideRoom("assessor2","Room")
	if (GetID("assessor2")==-1) or (GetHP("assessor2")<1) or  (GetID("Room")~=GetID("judgeroom")) then
		if AliasExists("assessor2") and GetID("assessor2")>0 then
			CityAddPenalty("settlement","assessor2", PENALTY_MONEY, GL_TRIAL_COST_PER_LEVEL)
			feedback_MessagePolitics("assessor2","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+0",
								"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+1",GetID("assessor2"), 500) 
		end
		BuildingFindSimByProperty("courtbuilding", "BUILDING_NPC", 3,"assessor2")
	end
		
	-- find the townhall executioner
	local execfound = false
	if BuildingFindSimByProperty("courtbuilding", "BUILDING_NPC", 4, "executioner") then
		execfound = true
	end
		
	-- lock the building
	trial_StopAllMeasures()
	RoomLockForCutscene("judgeroom", "")
	LogMessage("Trial: Room is locked")
		
	-- visitor list (remove participants)
	RoomGetInsideSimList("judgeroom", "visitor_list")
	
	ListRemove("visitor_list", "judge")
	ListRemove("visitor_list", "accuser")
	ListRemove("visitor_list", "accused")
	ListRemove("visitor_list", "assessor1")
	ListRemove("visitor_list", "assessor2")
	if execfound then
		ListRemove("visitor_list","executioner")
	end

	-- sit down
	local wait_cnt = 0
	wait_cnt = wait_cnt + trial_SitAt("assessor2", "LeftAssessorChairPos")
	wait_cnt = wait_cnt + trial_SitAt("assessor1", "RightAssessorChairPos")
	wait_cnt = wait_cnt + trial_SitAt("judge", "JudgeChairPos")
	wait_cnt = wait_cnt + trial_StandAt("accuser", "AccuserStandPos")
	wait_cnt = wait_cnt + trial_StandAt("accused", "AccusedStandPos")
	if execfound then
		wait_cnt = wait_cnt + trial_StandAt("executioner", "ExecutionerTrialPos")
	end

	local visitors = ListSize("visitor_list")
	
	-- Kick out visitors (ToDo: Let visitors watch!)
	for i=0, visitors-1 do
		ListGetElement("visitor_list", i, "visitor")
		if HasProperty("visitor","BUILDING_NPC") == false then
			wait_cnt = wait_cnt + trial_LeaveBuilding("visitor")
		end
	end
	
	ListClear("visitor_list")		

	-- set next event or wait a bit
	CutsceneAddTriggerEvent("", "Go", "Reached", wait_cnt, 30)
end

-- Let's begin the trial
function Go()
	LogMessage("Trial: Go")
	
	-- lower UpcomingTrialCount by 1
	local UpcomingTrials = GetProperty("courtbuilding", "UpcomingTrials")
	LogMessage("@TRIAL #W This trial is starting. Lowering UpcomingTrials value by 1 (from " .. UpcomingTrials .. ")")
	SetProperty("courtbuilding", "UpcomingTrials", UpcomingTrials-1)

	BuildingGetRoom("courtbuilding", "Judge", "judgeroom")
	
	-- set the camera
	GetLocatorByName("courtbuilding", "TableChair0", "CameraCreatePos")
	CutsceneCameraCreate("", "CameraCreatePos") 
	trial_Cam("TrialMainCam")
	
	-- important values
	SetData("TotalEvidenceValue", 0)
	SetData("AccuserSentence", -1) 

	-- is judge present?
	if trial_SimIsPresent("judge")==1 then
		
		local time = PlayAnimationNoWait("judge", "sit_judge_hammer")
		Sleep(1.5)
		CarryObject("judge", "Handheld_Device/Anim_judge_hammer.nif",false)
		Sleep(0.6)
		for i=0,10 do
			PlaySound3DVariation("judge", "Locations/hammer")
			Sleep(0.3)
		end
		Sleep(time - 7)
		CarryObject("judge", "", false)
		Sleep(0.5)
	else
		-- assessor starts
		MsgSay("assessor1","@L_LAWSUIT_3_INTRO_START")
	end
	
	--the fine, judge has to pay when he forgets the court
	local fine = GL_TRIAL_COST_PER_LEVEL * 2
	local NumCrimes = 0 + CutsceneCollectEvidences("", "accuser", "accused")
	local RawPenalty = 0
	
	if NumCrimes > 0 then
		for i=0, NumCrimes-1 do
			RawPenalty = RawPenalty + GetData("evidence"..i.."value") -- evidence data is collected hardcoded
		end
	end
	
	-- how many years do you become an outlaw if you miss the trial?
	local FugitiveYears = math.floor(RawPenalty/4 + 1)
	if FugitiveYears > 16 then 
		FugitiveYears = 16
	end

	local Options = FindNode("\\Settings\\Options")
	local YearsPerRound = Options:GetValueInt("YearsPerRound")
	local FugitiveHours = FugitiveYears * 24 / YearsPerRound

	--judge is lost and jailed somewhere
	if trial_SimIsPresent("judge") == 0 and GetState("judge", STATE_HIJACKED) then
		MsgSay("assessor1", "@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_RICHTER")
		feedback_MessagePolitics("judge","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_RICHTER_MESSAGES_+0",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_RICHTER_MESSAGES_+1", GetID("judge"))
		feedback_MessagePolitics("accuser","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_RICHTER_MESSAGES_+2",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_RICHTER_MESSAGES_+3", GetID("accuser"))
		feedback_MessagePolitics("accused","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_RICHTER_MESSAGES_+2",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_RICHTER_MESSAGES_+3", GetID("accused"))
		feedback_MessagePolitics("assessor1","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_RICHTER_MESSAGES_+2",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_RICHTER_MESSAGES_+3", GetID("assessor1"))
		feedback_MessagePolitics("assessor2","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_RICHTER_MESSAGES_+2",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_RICHTER_MESSAGES_+3", GetID("assessor2"))
		EndCutscene("")
	end

	--accused has immunity
	if GetImpactValue("accused","HaveImmunity") == 1 and GetImpactValue("accused","HasRepealedImmunity") < 1 then
		local list = {"accuser","accused","judge","assessor1","assessor2"}
		for i = 1, 5 do
			feedback_MessagePolitics(list[i],"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_RICHTER_MESSAGES_+0","@L_NEWSTUFF_TRIALCANCELLED_IMMUNITY_+0", GetID("accused"))
		end
		BuildingFindSimByProperty("courtbuilding","BUILDING_NPC", 2,"guard")
		MsgSay("guard","@L_LAWSUIT_1_INSTALL_USHER_IMMUNITY_+0", GetID("accused"))
		MsgSay("judge","@L_LAWSUIT_6_DECISION_C_JUDGEMENT_CLOSE_+0")
		EndCutscene("")
	end

	local list = {"accuser","accused","KLAEGER","ANGEKLAGTER","judge","assessor1","assessor2"}
	local callbacks = 
	{
		{
			{GetID("accuser"), GetID("accused"), nil},
			{GetID("judge"), GetID("accuser"), GetID("accused")},
			{GetID("assessor1"), GetID("accuser"), GetID("accused")},
			{GetID("assessor2"), GetID("accuser"), GetID("accused")},
			{GetID("accused"), GetID("accuser"), GetID("accused")}
		},
		{
			{GetID("accused"), nil, nil},
			{GetID("accused"), nil, nil},
			{GetID("accused"), nil, nil},
			{GetID("accused"), nil, nil},
			{GetID("accused"), nil, nil}
		}
	}
	for i = 1, 2 do
		LogMessage("RUNNING")
		if trial_SimIsPresent(list[i]) == 0 and GetState(list[i], STATE_HIJACKED) then
			local newlist = helpfuncs_diff({"judge","assessor1","assessor2","accuser","accused"},list[i])
			LogMessage("newlist="..newlist)

			PlayAnimationNoWait("judge", "sit_talk")
			MsgSay("judge","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_"..list[i+2])

			feedback_MessagePolitics(list[i],"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_"..list[i+2].."_MESSAGES_+0",
			"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_"..list[i+2].."_MESSAGES_+1", callbacks[i][1][1], callbacks[i][1][2])
			local newlist = {"judge","assessor1","assessor2"}

			for dest = 5, 7 do 
				feedback_MessagePolitics(list[dest],"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_"..list[i+2].."_MESSAGES_+2",
				"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_"..list[i+2].."_MESSAGES_+3", callbacks[i][2][1], callbacks[i][2][2], callbacks[i][2][3])
			end

			local newlist = helpfuncs_diff({"accuser","accused"},list[i])
			LogMessage("newlist="..newlist)

			feedback_MessagePolitics(newlist[1],"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_"..list[i+2].."_MESSAGES_+2",
			"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ENTFUEHRT_"..list[i+2].."_MESSAGES_+3", callbacks[i][5][1], callbacks[i][5][2], callbacks[i][5][3])

			EndCutscene("")
		end
	end

	--judge is not in here
	if trial_SimIsPresent("judge")==0 then
		MsgSay("assessor1","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER", GetID("judge"), fine)
		feedback_MessagePolitics("judge","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+0",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+1", GetID("judge"), fine)
		feedback_MessagePolitics("accuser","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+2",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+3", GetID("judge"))
		feedback_MessagePolitics("accused","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+2",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+3", GetID("judge"))
		feedback_MessagePolitics("assessor1","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+2",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+3", GetID("judge"))
		feedback_MessagePolitics("assessor2","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+2",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_RICHTER_MESSAGES_+3", GetID("judge"))
		EndCutscene("")
	end
	
	--accuser is not in here
	if trial_SimIsPresent("accuser")==0 then
		PlayAnimationNoWait("judge", "sit_talk")
		MsgSay("judge","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_KLAEGER", GetID("accuser"), GetID("accused"))
		CutsceneCollectEvidences("", "accuser", "accused", true)		-- mark collected evidences as used
		feedback_MessagePolitics("accuser","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_KLAEGER_MESSAGES_+0",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_KLAEGER_MESSAGES_+1", GetID("accuser"), GetID("accused"))
		feedback_MessagePolitics("accused","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_KLAEGER_MESSAGES_+2",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_KLAEGER_MESSAGES_+3", GetID("accuser"), GetID("accused"))
		feedback_MessagePolitics("judge","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_KLAEGER_MESSAGES_+2",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_KLAEGER_MESSAGES_+3", GetID("accuser"), GetID("accused"))
		feedback_MessagePolitics("assessor1","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_KLAEGER_MESSAGES_+2",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_KLAEGER_MESSAGES_+3", GetID("accuser"), GetID("accused"))
		feedback_MessagePolitics("assessor2","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_KLAEGER_MESSAGES_+2",
						"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_KLAEGER_MESSAGES_+3", GetID("accuser"), GetID("accused"))
		EndCutscene("")
	end
	
	--accused is not in here
	if trial_SimIsPresent("accused") == 0 then
		LogMessage("Trial: Accused is not present")
		PlayAnimationNoWait("judge", "sit_talk")
		MsgSay("judge", "@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ANGEKLAGTER", GetID("accused"), FugitiveYears)
	
		if (RawPenalty <16) then
			-- give the accused a chance to surrender himself or pay a fee
			CreateCutscene("queries", "myquery")
			LogMessage("Trial: Cutscene created: Outlaw may decide to surrender or pay a fee")
			CopyAliasToCutscene("accused", "myquery", "Sim")
			CopyAliasToCutscene("accuser", "myquery", "Accuser")
			CopyAliasToCutscene("assessor1", "myquery", "Assessor1")
			CopyAliasToCutscene("assessor2", "myquery", "Assessor2")
			CopyAliasToCutscene("judge", "myquery", "Judge")
			CopyAliasToCutscene("settlement", "myquery", "settlement")
			SetData("RawPenalty", RawPenalty)
			SetData("FugitiveYears", FugitiveYears)
			CutsceneSetData("myquery", "RawPenalty")
			CutsceneSetData("myquery", "FugitiveYears")
			CutsceneCallScheduled("myquery", "DecideFugitive")
		else 
			-- punish him
			LogMessage("Trial: Outlaw gets punished because rawpenalty is >= 16")
			CityAddPenalty("settlement", "accused", PENALTY_FUGITIVE, FugitiveYears)
			AddImpact("accused", "REVOLT", 1, FugitiveHours)
			SetState("accused", STATE_REVOLT, true)
			
			feedback_MessagePolitics("accused", "@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ANGEKLAGTER_MESSAGES_+0",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ANGEKLAGTER_MESSAGES_+1", GetID("accused"), FugitiveYears)
			feedback_MessagePolitics("accuser", "@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ANGEKLAGTER_MESSAGES_+2",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ANGEKLAGTER_MESSAGES_+3", GetID("accused"), FugitiveYears)
			feedback_MessagePolitics("judge", "@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ANGEKLAGTER_MESSAGES_+2",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ANGEKLAGTER_MESSAGES_+3", GetID("accused"), FugitiveYears)
			feedback_MessagePolitics("assessor1", "@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ANGEKLAGTER_MESSAGES_+2",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ANGEKLAGTER_MESSAGES_+3", GetID("accused"), FugitiveYears)
			feedback_MessagePolitics("assessor2", "@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ANGEKLAGTER_MESSAGES_+2",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_ANGEKLAGTER_MESSAGES_+3", GetID("accused"), FugitiveYears)
		end
		
		EndCutscene("")
	end

	--judge is dead
	if trial_SimIsPresent("judge") == 2 then
		MsgSay("assessor1","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_JUDGE_+0")
		feedback_MessagePolitics("accuser","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_JUDGE_MSG_HEAD",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_JUDGE_MSG_BODY")
		feedback_MessagePolitics("accused","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_JUDGE_MSG_HEAD",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_JUDGE_MSG_BODY")
		feedback_MessagePolitics("assessor1","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_JUDGE_MSG_HEAD",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_JUDGE_MSG_BODY")
		feedback_MessagePolitics("assessor2","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_JUDGE_MSG_HEAD",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_JUDGE_MSG_BODY")
		EndCutscene("")
	end

	--accuser is dead
	if trial_SimIsPresent("accuser")==2 then
		PlayAnimationNoWait("judge", "sit_talk")
		MsgSay("judge","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSER_+0")
		CutsceneCollectEvidences("", "accuser", "accused", true)		-- mark collected evidences as used
		feedback_MessagePolitics("judge","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSER_MSG_HEAD",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSER_MSG_BODY")
		feedback_MessagePolitics("accused","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSER_MSG_HEAD",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSER_MSG_BODY")
		feedback_MessagePolitics("assessor1","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSER_MSG_HEAD",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSER_MSG_BODY")
		feedback_MessagePolitics("assessor2","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSER_MSG_HEAD",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSER_MSG_BODY")
		EndCutscene("")
	end
	
	--accused dead
	if trial_SimIsPresent("accused")==2 then
		PlayAnimationNoWait("judge", "sit_talk")
		MsgSay("judge","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSED_+0")
		CutsceneCollectEvidences("", "accuser", "accused", true)		-- mark collected evidences as used
		feedback_MessagePolitics("judge","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSED_MSG_HEAD",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSED_MSG_BODY")
		feedback_MessagePolitics("accuser","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSED_MSG_HEAD",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSED_MSG_BODY")
		feedback_MessagePolitics("assessor1","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSED_MSG_HEAD",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSED_MSG_BODY")
		feedback_MessagePolitics("assessor2","@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSED_MSG_HEAD",
							"@L_LAWSUIT_3_INTRO_PERSON_NOT_PRESENT_DEAD_ACCUSED_MSG_BODY")
		EndCutscene("")
	end
	
	--get rhetoric and gender from accuser and accused
	local AccuserRhetoric = GetSkillValue("accuser", RHETORIC)
	local AccusedRhetoric = GetSkillValue("accused", RHETORIC)
	local AccuserGender = SimGetGender("accuser")
	local AccusedGender = SimGetGender("accused")

	Sleep(0.1)
	trial_Cam("JudgeFromBelowCam")
	PlayAnimationNoWait("judge", "sit_talk")
	LogMessage("Trial: Everyone abord")
	MsgSay("judge", "@L_LAWSUIT_3_INTRO_EVERYONE_ABORD_1")
	PlayAnimationNoWait("judge", "sit_talk")
	MsgSay("judge", "@L_LAWSUIT_3_INTRO_EVERYONE_ABORD_2", GetID("accuser"), GetID("accused"))
	
	
	StopAnimation("judge")

	--combine textlabel by checking rhetoric skill and gender for text
	local RhetoricReplace
	if AccuserRhetoric < 4 then
		if Rand(4) == 0 then
			RhetoricReplace = "_AVERAGE"
		else
			RhetoricReplace = "_DUMB"
		end
	elseif AccuserRhetoric < 7 then
		if Rand(4) == 0 then
			RhetoricReplace = "_SMART"
		else
			RhetoricReplace = "_AVERAGE"
		end
	else
		if Rand(5) == 0 then
			RhetoricReplace = "_AVERAGE"
		else
			RhetoricReplace = "_SMART"
		end
	end

	local GenderType
	if AccusedGender == 0 then
		GenderType = "_TOFEMALE"
	else
		GenderType = "_TOMALE"
	end
	
	-- accuser may speak first
	
	local AlignmentReplace
	local Alignment = SimGetAlignment("accuser")
	if Alignment < 40 then
		AlignmentReplace = "_GOOD"
	elseif Alignment < 65 then
		AlignmentReplace = "_NORMAL"
	else
		AlignmentReplace = "_EVIL"
	end
	
	camera_CutsceneDialogCam("", "accuser", 0, 0)
	trial_PlayRelevantTalkAni("accuser")
	MsgSay("accuser"," @L_LAWSUIT_4_ACCUSAL_A_HELLO"..RhetoricReplace..AlignmentReplace)
	Sleep(0.2)
	LogMessage("Trial: Accuser says hello")
	
	if CutsceneLocalPlayerIsWatching("") then
		HudClearSelection()
	end
	
	local CityLevel = 2
	if GetSettlement("accuser", "TheCity") then
		CityLevel = CityGetLevel("TheCity")
	end
	
	local TrialCosts = GL_TRIAL_COST_BASE + GL_TRIAL_COST_PER_LEVEL*CityLevel
	local JudgeMoney = TrialCosts / 2
	local AssessorMoney = TrialCosts / 4
	
	if NumCrimes == 0 then -- somehow all evidences are gone
		trial_Cam("TrialMainCam")
		local NobTitle = GetNobilityTitle("accuser")
		local TrialFee = GL_TRIAL_COST_BASE + math.floor(NobTitle*NobTitle * GL_TRIAL_PENALTY_LOW)
		local TrialIncome = GetProperty("settlement", "TrialIncome") or 0
		SetProperty("settlement", "TrialIncome", (TrialIncome + TrialFee))
		PlayAnimationNoWait("accuser", "cogitate")
		MsgSay("accuser","@L_LAWSUIT_4_ACCUSAL_NOEVIDENCE_ACCUSER")
		PlayAnimationNoWait("judge", "sit_no")
		MsgSay("judge","@L_LAWSUIT_4_ACCUSAL_NOEVIDENCE_JUDGE", TrialFee)
		PlayAnimationNoWait("judge", "sit_talk")
		MsgSay("judge","@L_LAWSUIT_6_DECISION_C_JUDGEMENT_CLOSE_+0")
		chr_SpendMoney("accuser", TrialFee, "trialfee", true)
	else
		-- Go through all evidences
		
		local EvidenceType
		local VictimID
		local EvidenceQuality
		local EvidenceValue
		local EvidenceTime
		
		for i=0, NumCrimes -1 do
			
			EvidenceType = GetData("evidence"..i.."type")
			VictimID = GetData("evidence"..i.."victim")
			EvidenceQuality = GetData("evidence"..i.."quality")
			EvidenceValue = GetData("evidence"..i.."value")
			EvidenceTime = GetData("evidence"..i.."time")
			
			if i == 0 then
				if GetImpactValue("accused", "EvidenceSuppression") == 1 then -- Impact: Heiligenschein
					camera_CutsceneDialogCam("", "accused", 0, 0)
					EvidenceQuality = 0
					MsgSay("accused", "@L_LAWSUIT_4_ACCUSAL_G_ACCUSED_HALO")
				end
			end
			
			-- only talk once about every crime type (max 3)
			trial_ProduceEvidence(EvidenceType, VictimID, EvidenceQuality, EvidenceValue, GenderType, EvidenceTime, NumCrimes-1, i)
			-- More evidences of the same type?
			trial_ProduceMultipleEvidence(NumCrimes, EvidenceType, EvidenceValue, GenderType)

		end

		trial_Cam("TrialMainCam")
		GetDynasty("accused", "accuseddynasty")
		
		-- inquisition bonus
		if GetImpactValue("accuser", "AimForInquisitionalProceeding") ~= 0 then
			trial_ModifyTotalEvidenceValue(3)
			PlayAnimationNoWait("judge", "sit_talk")
			MsgSay("judge", "@L_PRIVILEGES_113_AIMFORINQUISITIONALPROCEEDING_LAWSUIT_JUDGE", GetID("accuser"))
		end

		local TEV = GetData("TotalEvidenceValue")
		
		-- severity of law
		local SeverityOfLaw = GetProperty("settlement", "SeverityOfLaw")
		local LawReplace
		if SeverityOfLaw == 0 then
			LawReplace = "_LIBERAL"
			trial_ModifyTotalEvidenceValue(-3)
		elseif SeverityOfLaw==1 then
			LawReplace = "_NORMAL"
		else
			LawReplace = "_HARD"
			trial_ModifyTotalEvidenceValue(3)
		end
		
		PlayAnimationNoWait("judge", "sit_talk")
		MsgSay("judge", "@L_LAWSUIT_5_DEFENSE_A_LAW"..LawReplace)
		
		if CutsceneLocalPlayerIsWatching("") then
			HudClearSelection()
		end
		
		-- You are noble? Good for you
		if (GetNobilityTitle("accused") >= NOBILITY_LANDGRAF) then
			PlayAnimationNoWait("judge", "sit_talk")
			MsgSay("judge", "@L_LAWSUIT_5_DEFENSE_A_NOBLEFROMBLOOD", GetID("accused"))
			if CutsceneLocalPlayerIsWatching("") then
				HudClearSelection()
			end
			trial_ModifyTotalEvidenceValue(-2)
		end
		
		-- Is the accused good natured or a bad guy?
		if SimGetAlignment("accused") < 15 then
			PlayAnimationNoWait("judge", "sit_talk")
			MsgSay("judge", "@L_LAWSUIT_5_DEFENSE_A_GOOD_ALIGNMENT", GetID("accused"))
			trial_ModifyTotalEvidenceValue(-2)
		elseif SimGetAlignment("accused") > 80 then
			PlayAnimationNoWait("judge", "sit_talk")
			MsgSay("judge", "@L_LAWSUIT_5_DEFENSE_A_BAD_ALIGNMENT", GetID("accused"))
			trial_ModifyTotalEvidenceValue(2)
		end

		-- accuser may propose a good sentence
		trial_Cam("JudgeFromBelowCam")
		PlayAnimationNoWait("judge", "talk_sit_short")
		MsgSay("judge", "@L_LAWSUIT_5_DEFENSE_A_TO_ACCUSER")

		trial_Cam("TrialMainCam")
		LogMessage("TRIAL: Accuser is deciding which sanction to suggest.")
		local AccuserSentence = MsgSayInteraction("accuser", "accuser", 0,
										-- PanelParam
										"@B[1,@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+1]"..
										"@B[2,@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+2]"..
										"@B[3,@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+3]"..
										"@B[4,@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+4]"..
										"@B[5,@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+5]"..
										"@B[6,@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+6]",
										trial_AccuserDecideSentence, --AIFunc
										"@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+0", GetID("accused")) --Message Text
		SetData("AccuserSentence", AccuserSentence)
		
		-- calculate default sentence level
		local SentenceLevel = math.floor(GetData("TotalEvidenceValue") / 3)
		SetData("DefaultSentence", SentenceLevel)	-- for judge AI func
		camera_CutsceneDialogCam("","accuser",0,0)
		local SentenceAnnouncer = "accuser"
		
		if AccuserSentence=="C" then	
			LogMessage("TRIAL: Accuser decided to let the Jury decide on a sanction.")
			trial_PlayRelevantTalkAni("accuser")
			MsgSay("accuser","@L_LAWSUIT_5_DEFENSE_A_SPEAK_ACCUSER_NOCOMMENT_+0")

			SentenceLevel = MsgSayInteraction("judge","judge",0,
			-- PanelParam
			"@B[1,@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+1]"..
			"@B[2,@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+2]"..
			"@B[3,@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+3]"..
			"@B[4,@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+4]"..
			"@B[5,@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+5]"..
			"@B[6,@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+6]",
			trial_JudgeDecideSentence, --AIFunc
			"@L_LAWSUIT_5_DEFENSE_A_SCREENPLAYER_ACCUSER_+0",GetID("accused")) --Message Text
			if not (SentenceLevel>=1 and SentenceLevel<=6) then
				SentenceLevel = trial_GetSubjectiveSentence("judge")/6+1
			end
			LogMessage("@NAO Trials. Jury decides sentence, of level: " .. SentenceLevel)
			SetData("AccuserSentence", SentenceLevel)
		else
			SentenceLevel = AccuserSentence
		end

		if (SentenceLevel<1) then
			SentenceLevel = 1
		elseif (SentenceLevel>6) then
			SentenceLevel = 6
		end
			
		PlayAnimationNoWait(SentenceAnnouncer, "talk") -- ERROR TO CHECK ON CONC FIELD

		local list = {"MONEY","PILLORY","MOREMONEY","TITLE","PRISON","DEATH"}
		
		if not AccuserSentence == "C" then
			SentenceLevel = AccuserSentence	
			MsgSay(SentenceAnnouncer,"@L_LAWSUIT_5_DEFENSE_A_SPEAK_ACCUSER_"..list[AccuserSentence]..GenderType) -- END OF ERROR TO CHECK ON CONC FIELD
			LogMessage("@L_LAWSUIT_5_DEFENSE_A_SPEAK_ACCUSER_"..list[AccuserSentence]..GenderType)
		end
		

		SetData("AccuserSentence",SentenceLevel)
		
		-- accused may speak now
		local confession = 1

		trial_UpdatePanelTrial(0)
		trial_Cam("TrialMainCam")
		StopAnimation(SentenceAnnouncer)
		PlayAnimationNoWait("judge", "talk_sit_short")
		MsgSay("judge", "@L_LAWSUIT_5_DEFENSE_A_TO_DEFENDER"..GenderType,GetID("accused"))
		Sleep(0.1)
		HudClearSelection()
		Sleep(0.1)

		local AccusedStatement = MsgSayInteraction("accused", "accused", 0,
										"@B[1,@L_LAWSUIT_5_DEFENSE_B_DEFENDER_SCREENPLAYER_+1]"..
										"@B[2,@L_LAWSUIT_5_DEFENSE_B_DEFENDER_SCREENPLAYER_+2]"..
										"@B[3,@L_LAWSUIT_5_DEFENSE_B_DEFENDER_SCREENPLAYER_+3]",
										trial_AccusedDecideConfess,
										"@L_LAWSUIT_5_DEFENSE_B_DEFENDER_SCREENPLAYER_+0", GetID("accused"))
		local DecisionReplacement
		
		if AccusedStatement == 1 then -- innocent
			
			DecisionReplacement = "_NOTGUILTY"
			confession = 0
			
			local BelieveFactorDefenseBonus = trial_CalcBelieveFactorBonus("accused")
			BelieveFactorDefenseBonus = 0 - BelieveFactorDefenseBonus -- a positive bonus decreases difficulty on skill check
			local HasWonSkillCheck = chr_SkillCheck("accused", RHETORIC, BelieveFactorDefenseBonus, "judge", EMPATHY)
			
			trial_Cam("JudgeFromBelowCam")
			if HasWonSkillCheck then
				trial_ModifyTotalEvidenceValue(-3) 
				PlayAnimationNoWait("judge", "nod")
			else
				trial_ModifyTotalEvidenceValue(3)
				PlayAnimationNoWait("judge", "shake_head")				
			end
			
		elseif AccusedStatement == 2 then -- say nothing
			
			DecisionReplacement = "_STAYQUIET"
			confession = 1
		elseif AccusedStatement == 3 then -- guilty, confess
			
			DecisionReplacement = "_GUILTY"
			trial_ModifyTotalEvidenceValue(-3)
			confession = 2
		else
			DecisionReplacement = "_STAYQUIET" -- default (?)
			confession = 1
		end
		
		camera_CutsceneDialogCam("", "accused", 0, 0)
		
		if (confession == 0) then
			PlayAnimationNoWait("accused", "shake_head")
		elseif (confession == 1) then
			PlayAnimationNoWait("accused", "cogitate")
		elseif (confession == 2) then
			PlayAnimationNoWait("accused", "nod")
		end
		
		MsgSay("accused", "@L_LAWSUIT_5_DEFENSE_B_DEFENDER_SPEAKS"..DecisionReplacement)
		
		trial_Cam("TrialMainCam")
		CarryObject("judge", "Handheld_Device/Anim_ink_feather.nif", false)
		PlayAnimation("judge", "sit_write_in")
		LoopAnimation("judge", "sit_write_loop", 1.5)
		PlayAnimation("judge",  "sit_write_out")
		CarryObject("judge", "", false)
		StopAnimation("judge")

		-- Final judgement
		
		local DecisionTextLabel, AnnouncementLabel

		trial_UpdatePanelTrial(0)

		trial_PlayRelevantJuryAni("judge",60)

		if confession == 2 then
			-- The court decides whether the proposed sentence is just
			MsgSay("judge","@L_LAWSUIT_6_DECISION_A_APPROPRIATEQ_INTRO")
			DecisionTextLabel = "@L_LAWSUIT_6_DECISION_A_APPROPRIATEQ_SCREENPLAYER_"
			AnnouncementLabel = "@L_LAWSUIT_6_DECISION_A_APPROPRIATEQ_ANNOUNCEMENTS_"
		else
			MsgSay("judge","@L_LAWSUIT_6_DECISION_A_GUILTYQ_INTRO")
			DecisionTextLabel = "@L_LAWSUIT_6_DECISION_A_GUILTYQ_SCREENPLAYER_"
			AnnouncementLabel = "@L_LAWSUIT_6_DECISION_A_GUILTYQ_ANNOUNCEMENTS_"
		end

		-- Jury decides
		local conviction_cnt = 0
		-- judge and assessor may select decisions if they are players
		SetData("DecisionParam", "judge")
		SetData("JudgeDecision", -1)
		
		local JudgeDecision = MsgSayInteraction("judge", "judge", 0,
									"@B[1,"..DecisionTextLabel.."+1]"..
									"@B[2,"..DecisionTextLabel.."+2]",
									trial_ConvictionDecision,
									""..DecisionTextLabel.."+0", GetID("judge"))

		if JudgeDecision == "C" then
			JudgeDecision = trial_ConvictionDecision()
		end

		if JudgeDecision == 1 then
			conviction_cnt = conviction_cnt+1
			trial_PlayRelevantJuryAni("judge", 100)
			MsgSay("judge", ""..AnnouncementLabel.."+0")
		else
			trial_PlayRelevantJuryAni("judge",0)
			MsgSay("judge", ""..AnnouncementLabel.."+1")
		end
		
		SetData("JudgeDecision", JudgeDecision)

		--assessor1
		SetData("DecisionParam", "assessor1")
		local Assessor1Decision = MsgSayInteraction("assessor1", "assessor1", 0,
										"@B[1,"..DecisionTextLabel.."+1]"..
										"@B[2,"..DecisionTextLabel.."+2]",
										trial_ConvictionDecision,
										""..DecisionTextLabel.."+0", GetID("assessor1"))

		if Assessor1Decision == "C" then
			Assessor1Decision = trial_ConvictionDecision()
		end

		if Assessor1Decision == 1 then
			conviction_cnt = conviction_cnt+1
			trial_PlayRelevantJuryAni("assessor1",100)
			MsgSay("assessor1", ""..AnnouncementLabel.."+0")
		else
			trial_PlayRelevantJuryAni("assessor1",0)
			MsgSay("assessor1", ""..AnnouncementLabel.."+1")
		end

		--assessor2
		SetData("DecisionParam", "assessor2")
		local Assessor2Decision = MsgSayInteraction("assessor2", "assessor2", 0,
										"@B[1,"..DecisionTextLabel.."+1]"..
										"@B[2,"..DecisionTextLabel.."+2]",
										trial_ConvictionDecision,
										""..DecisionTextLabel.."+0", GetID("assessor2"))

		if Assessor2Decision == "C" then
			Assessor2Decision = trial_ConvictionDecision()
		end

		if Assessor2Decision == 1 then
			conviction_cnt = conviction_cnt+1
			trial_PlayRelevantJuryAni("assessor2", 100)
			MsgSay("assessor2", ""..AnnouncementLabel.."+0")
		else
			trial_PlayRelevantJuryAni("assessor2", 0)
			MsgSay("assessor2", ""..AnnouncementLabel.."+1")
		end

		SetData("judgedecision", -1)
		SetData("assessor1decision", -1)
		SetData("assessor2decision", -1)
		
		local DecisionForFinalComment = 0
		trial_Cam("JudgeFromBelowCam")
		-- Present the final verdict--------------------------------------------

		--MsgSay("judge","@L_LAWSUIT_6_DECISION_B_JUDGE_DECISION_+0")
		if confession == 2 or conviction_cnt >= 2 then
			if confession == 2 and conviction_cnt < 2 then
				PlayAnimationNoWait("judge", "sit_talk")
				MsgSay("judge", "@L_LAWSUIT_6_DECISION_B_JUDGE_DECISION_GUILTY_BUT_MILD"..GenderType)
				PlayAnimationNoWait("judge", "sit_talk")
				MsgSay("judge", "@L_LAWSUIT_6_DECISION_B_JUDGE_DECISION_GUILTY_BUT_MILD_TOBOTH_+0")
				PlayAnimationNoWait("judge", "sit_talk")
				MsgSay("judge", "@L_LAWSUIT_6_DECISION_B_JUDGE_DECISION_GUILTY_BUT_MILD_TOBOTH_+1")
				SentenceLevel = SentenceLevel - 1
			else
				PlayAnimationNoWait("judge", "sit_talk")
				MsgSay("judge","@L_LAWSUIT_6_DECISION_B_JUDGE_DECISION_GUILTY"..GenderType, GetID("accused"))
				if conviction_cnt == 2 then
					PlayAnimationNoWait("judge", "sit_talk")
					MsgSay("judge","@L_LAWSUIT_6_DECISION_B_JUDGE_DECISION_GUILTY_HALF")
					SentenceLevel = SentenceLevel - 1;
				else
					PlayAnimationNoWait("judge", "sit_talk")
					MsgSay("judge","@L_LAWSUIT_6_DECISION_B_JUDGE_DECISION_GUILTY_FULL")
				end
			end

			local PenaltyType = -1
			local PenaltyValue = 0
			local PenaltyTitle = GetNobilityTitle("accused")
			local PenaltyMsg = 0

			PlayAnimationNoWait("judge", "sit_talk")
			
			if SentenceLevel < 1 then
				MsgSay("judge", "@L_LAWSUIT_6_DECISION_C_JUDGEMENT_ANNOUNCEMENT_+0", GetID("accused"), PenaltyValue)
			elseif SentenceLevel == 1 then
				PenaltyValue = PenaltyTitle * PenaltyTitle * GL_TRIAL_PENALTY_MEDIUM
				MsgSay("judge", "@L_LAWSUIT_6_DECISION_C_JUDGEMENT_ANNOUNCEMENT_+1", GetID("accused"), PenaltyValue)
				PenaltyType = PENALTY_MONEY
				local PenaltyIncome = GetProperty("settlement", "TrialIncome") or 0
				PenaltyIncome = PenaltyIncome + PenaltyValue
				SetProperty("settlement", "TrialIncome", PenaltyIncome)
			elseif SentenceLevel == 2 then
				PenaltyValue = 12
				MsgSay("judge", "@L_LAWSUIT_6_DECISION_C_JUDGEMENT_ANNOUNCEMENT_+2", GetID("accused"), PenaltyValue)
				PenaltyType = PENALTY_PILLORY
			elseif SentenceLevel == 3 then
				PenaltyValue = PenaltyTitle * PenaltyTitle * GL_TRIAL_PENALTY_HIGH
				MsgSay("judge", "@L_LAWSUIT_6_DECISION_C_JUDGEMENT_ANNOUNCEMENT_+4", GetID("accused"), PenaltyValue)
				PenaltyType = PENALTY_MONEY
				local PenaltyIncome = GetProperty("settlement", "TrialIncome") or 0
				PenaltyIncome = PenaltyIncome + PenaltyValue
				SetProperty("settlement", "TrialIncome", PenaltyIncome)
			elseif SentenceLevel == 4 then
				PenaltyType = PENALTY_TITLE
				if (SimGetOfficeID("accused") ~= -1) then
					MsgSay("judge", "@L_LAWSUIT_6_DECISION_C_JUDGEMENT_ANNOUNCEMENT_+3", GetID("accused"))
				elseif (GetNobilityTitle("accused") > 1) then
					MsgSay("judge", "@L_LAWSUIT_6_DECISION_C_JUDGEMENT_ANNOUNCEMENT_+5", GetID("accused"))
				else
					MsgSay("judge", "@L_NEWSTUFF_NOTITLEPENALTY_+0")
					PlayAnimationNoWait("judge", "sit_talk")
					PenaltyType = PENALTY_PRISON
					local YearsPerRound = Options:GetValueInt("YearsPerRound")
					PenaltyValue = 48 * YearsPerRound
					PenaltyMsg = PenaltyValue / 24
					MsgSay("judge","@L_LAWSUIT_6_DECISION_C_JUDGEMENT_ANNOUNCEMENT_+6", GetID("accused"), PenaltyMsg)
				end
			elseif SentenceLevel == 5 then
				PlayAnimationNoWait("judge", "sit_talk")
				PenaltyType = PENALTY_PRISON
				local YearsPerRound = Options:GetValueInt("YearsPerRound")
				PenaltyValue = 48 * YearsPerRound
				PenaltyMsg = PenaltyValue / 24
				MsgSay("judge", "@L_LAWSUIT_6_DECISION_C_JUDGEMENT_ANNOUNCEMENT_+6", GetID("accused"), PenaltyMsg)
			elseif SentenceLevel == 6 then
				PlayAnimationNoWait("judge", "sit_talk")
				MsgSay("judge", "@L_LAWSUIT_6_DECISION_C_JUDGEMENT_ANNOUNCEMENT_+7", GetID("accused"), PenaltyValue)
				PenaltyType = PENALTY_DEATH
				SetProperty("accused", "ExecutedBy", GetID("accuser"))
				--mission_ScoreAccuse("accuser")
			end

			if SentenceLevel >=1 then
				
				DecisionForFinalComment = 1
				PlayAnimationNoWait("judge", "talk_sit_short")
				MsgSay("judge","@L_LAWSUIT_6_DECISION_C_JUDGEMENT_EXECUTE_+0")
			end

			if PenaltyType>-1 then
				CityAddPenalty("settlement", "accused", PenaltyType, PenaltyValue)
				xp_ChargeCharacter("accuser", SentenceLevel)
			else
				DecisionForFinalComment = 0
			end

		else -- judicial costs for the accuser
			trial_PlayRelevantJuryAni("judge", 0)
			MsgSay("judge", "@L_LAWSUIT_6_DECISION_B_JUDGE_DECISION_NOTGUILTY"..GenderType,GetID("accused"))
			MsgSay("judge", "@L_LAWSUIT_6_DECISION_B_JUDGE_DECISION_NOTGUILTY_TOBOTH", TrialCosts)
			chr_SpendMoney("accuser", TrialCosts, "trialfee", true)
			local TrialIncome = GetProperty("settlement", "TrialIncome") or 0
			TrialIncome = TrialIncome + TrialCosts
			SetProperty("settlement", "TrialIncome", TrialIncome)
			
			DecisionForFinalComment = 0
			local XPLevel = 1
			if HasData("AccuserSentence") then
				XPLevel = GetData("AccuserSentence")
			end
			xp_ChargeCharacter("accused", XPLevel)
		end

		trial_Cam("TrialMainCam")
		local time = PlayAnimationNoWait("judge", "sit_judge_hammer")
		Sleep(1.5)
		CarryObject("judge","Handheld_Device/Anim_judge_hammer.nif",false)
		Sleep(0.6)
		for i=0,12 do
			PlaySound3DVariation("judge", "Locations/hammer")
			Sleep(0.3)
		end
		Sleep(time - 7)
		CarryObject("judge", "", false)
		Sleep(0.5)
		PlayAnimationNoWait("judge", "talk_sit_short")
		MsgSay("judge", "@L_LAWSUIT_6_DECISION_C_JUDGEMENT_CLOSE_+0")

		--Reactions
		if DecisionForFinalComment == 1 then
			if confession ~= 2 then -- only react negative if you did not confess!
				camera_CutsceneDialogCam("", "accused", 0, 0)
				PlayAnimationNoWait("accused", "shake_head")
				MsgSay("accused", "@L_LAWSUIT_6_DECISION_D_REACTIONS_GUILTY")
			end
		else
			camera_CutsceneDialogCam("", "accuser", 0, 0)
			PlayAnimationNoWait("accuser", "shake_head")
			MsgSay("accuser", "@L_LAWSUIT_6_DECISION_D_REACTIONS_NOTGUILTY")
		end
		
		-- money
		local TrialIncome = GetProperty("settlement", "TrialIncome") or 0
		TrialIncome = TrialIncome - TrialCosts
		SetProperty("settlement", "TrialIncome", TrialIncome)
		chr_CreditMoney("judge", JudgeMoney, "Office")
		chr_CreditMoney("assessor1", AssessorMoney, "Office")
		chr_CreditMoney("assessor2", AssessorMoney, "Office")
	end

	--Be done
	CutsceneCollectEvidences("", "accuser", "accused", true)		-- mark collected evidences as used
	--BuildingLockForCutscene("courtbuilding", 0)
	if execfound then
		SimResetBehavior("executioner")
	end
	EndCutscene("")

	if debugTrial then
		Sleep(1) ms_debug_trials_triggerDebug()
	end
end

-- Helping functions

function ProduceEvidence(EvidenceType, VictimID, EvidenceQuality, EvidenceValue, GenderType, EvidenceTime, NumCrimes, CurrentCrime)
	
	--anklaeger
	trial_Cam("TrialMainCam")
	AlignTo("accuser", "accused")
	AlignTo("accused", "accuser")

	trial_Cam("Accuserback")
	CutsceneCameraBlend("", 10, 2)
	trial_Cam("TrailCenter")

	PlayAnimationNoWait("accuser", "point_at")
	PlayAnimationNoWait("accused", "shake_head")
	
	local EvidenceData = {
					[1] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_SABOTAGE",
					[3] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_ATTACK",
					[4] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_BRIBERY",
					[6] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_BLACKMAIL",
					[7] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_SLUGGING",
					[10] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_CALUMNY",
					[11] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_POISON",
					[12] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_RAIDING",
					[13] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_REVOLT",
					[14] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_MARAUDING",
					[15] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_ABDUCTION",
					[16] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_MURDER",
					[17] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_SHARED",
					[18] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_ATTACK",
					[19] = "@L_NEWSTUFF_CARTATTACK",
					[20] = "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_THEFT",
					[21] = "@L_NEWSTUFF_CARTATTACK"
					}
					
	local EvidenceString = EvidenceData[EvidenceType]..GenderType or "@L_LAWSUIT_4_ACCUSAL_C_CHARGES_INVALID"
	MsgSay("accuser", EvidenceString, GetID("accused"), VictimID, EvidenceTime)
	LogMessage(GetName("accuser")..': '..EvidenceString)
	LogMessage("Against "..GetName("accused"))
	
	StopAnimation("accuser")
	StopAnimation("accused")

	AlignTo("accuser", "judge")
	AlignTo("accused", "judge")
	
	local FinalEvidenceQuality = trial_CalcBelieveFactor(EvidenceQuality, VictimID)
	-- local EvidenceWeight = CalcEvidenceWeight(BelieveFactor, EvidenceValue)
	
	local QualityText
	local EvidenceModifier = 0
	
	if FinalEvidenceQuality >= 150 then
		EvidenceModifier = EvidenceValue + 2
		QualityText = "_100QUALITY"
	elseif FinalEvidenceQuality >= 100 then
		EvidenceModifier = EvidenceValue
		QualityText = "_100QUALITY"
	elseif FinalEvidenceQuality >= 75 then
		EvidenceModifier = math.ceil(EvidenceValue * FinalEvidenceQuality / 100)
		QualityText = "_75QUALITY"
	elseif FinalEvidenceQuality >= 50 then
		EvidenceModifier = math.ceil(EvidenceValue * FinalEvidenceQuality / 100)
		QualityText = "_50QUALITY"
	elseif FinalEvidenceQuality >= 25 then
		EvidenceModifier = math.ceil(EvidenceValue * FinalEvidenceQuality / 100)
		QualityText = "_25QUALITY"
	end
	
	trial_ModifyTotalEvidenceValue(EvidenceModifier)
	
	CutsceneCameraBlend("", 0.01, 0)
--	trial_Cam("TrialMainCam")
--	trial_RandomVisitorComment("@L_LAWSUIT_4_ACCUSAL_F_AUDIENCE_STANDARD")
	trial_Cam("JudgeFromBelowCam")

	trial_PlayRelevantJuryAni("judge", EvidenceQuality)
	MsgSay("judge", "@L_LAWSUIT_4_ACCUSAL_D_JUDGE_COMMENTS"..QualityText)
	
	-- more evidences?
	if NumCrimes > CurrentCrime then
		if FinalEvidenceQuality < 50 then
			QualityText = "_LOWQUALITY"
		elseif FinalEvidenceQuality < 80 then
			QualityText = "_MEDIUMQUALITY"
		else
			QualityText = "_HIGHQUALITY"
		end

		trial_Cam("TrialMainCam")
		MsgSay("judge", "@L_LAWSUIT_4_ACCUSAL_D_JUDGE_CONTINUE"..QualityText)
		
	end
end

function ProduceMultipleEvidence(NumCrimes, EvidenceType, EvidenceValue, GenderType)
	
	local Found = 0
	
	for i=0, NumCrimes -1 do
			
		local CheckType = GetData("evidence"..i.."type")
		if CheckType == EvidenceType then
			Found = Found +1
		end
	end
	
	if Found > 1 then
		camera_CutsceneDialogCam("", "accuser", 0, 0)
		PlayAnimationNoWait("accuser", "point_at")
		PlayAnimationNoWait("accused", "shake_head")
		MsgSay("accuser", "@L_LAWSUIT_ACCUSAL_D_ACCUSER_MORE_SAME_TYPE", GetID("accused"), Found)
		StopAnimation("accuser")
	else
		return
	end
	
	local Weight = math.floor(EvidenceValue/2)
	if Weight < 1 then 
		Weight = 1
	end
	
	Weight = Weight*(Found-1)
	trial_ModifyTotalEvidenceValue(Weight)
end

function CalcBelieveFactor(EvidenceQuality, VictimID)
	EvidenceQuality = EvidenceQuality or 50
	LogMessage("Trial: EvidenceQuality base value: " .. EvidenceQuality)
	
	-- Are we the victim? Gives a bonus on Rhetoric skill check since telling your own story is always more believable
	GetAliasByID(VictimID, "VictimAlias")
	local VictimDynID = GetDynastyID("VictimAlias")
	local RhetCheckDifficulty = 0
	if GetDynastyID("accuser") == VictimDynID then
		RhetCheckDifficulty = -4
	end
	
	-- 1. Chance to improve Quality: Roll of Accuser.Rhetoric vs Judge.Empathy (can only improve quality, chance for critical improvement)
	-- this would have the option to make the skill check harder for the accuser
	local HasRhetoricBonus = chr_SkillCheck("accuser", RHETORIC, RhetCheckDifficulty, "judge", EMPATHY)
	if HasRhetoricBonus then
		EvidenceQuality = EvidenceQuality * 1.5
	end
	
	-- 2. Calculate bonuses of accuser
	local AccuserBonus = trial_CalcBelieveFactorBonus("accuser")
	
	-- 3. Calculate bonuses of accused
	local AccusedBonus = trial_CalcBelieveFactorBonus("accused")
	
	
	-- 4. Subtract the bonuses and run the result through an empathy check with the judge
	local TotalBonus = AccuserBonus - AccusedBonus
	local JudgeEmpathy = GetSkillValue("judge", EMPATHY)
	if TotalBonus > 0 and TotalBonus > JudgeEmpathy then
		EvidenceQuality = EvidenceQuality * 1.5
	elseif TotalBonus < 0 and math.abs(TotalBonus) > JudgeEmpathy then
		EvidenceQuality = EvidenceQuality * 0.5
	end
	
	LogMessage("Trial: Final EvidenceQuality is " .. EvidenceQuality)
	return EvidenceQuality
end

function CalcBelieveFactorBonus(SimAlias) 
	local Bonus = 0
	if GetImpactValue(SimAlias, "fragranceofholiness") > 0 then
		Bonus = 4 + Bonus
	end
	
	if GetImpactValue(SimAlias, "GoldenSpoon") > 0 then
		Bonus = 2 + Bonus
	end
		
	-- are we good natured?
	local AlignmentBonus = 0
	if SimGetAlignment(SimAlias) < 30 then -- good
		Bonus = Bonus + 2
	elseif SimGetAlignment(SimAlias) > 70 then -- evil
		Bonus = Bonus - 2
	end

	-- office level also factors in
	Bonus = Bonus + (SimGetOfficeLevel(SimAlias) - 1)
	
	-- is the judge our friend?
	local FriendBonus = 0
	local FavorToJudge = GetFavorToSim(SimAlias, "judge")
	if FavorToJudge >= 80 then
		FriendBonus = 4
	elseif FavorToJudge >= 70 then
		FriendBonus = 3
	elseif FavorToJudge >= 60 then 
		FriendBonus = 2
	end
	
	if FavorToJudge < 20 then
		FriendBonus = -4
	elseif FavorToJudge < 30 then
		FriendBonus = -3
	elseif FavorToJudge < 40 then
		FriendBonus = -2
	elseif FavorToJudge < 50 then
		FriendBonus = -1
	end
	Bonus = Bonus + FriendBonus
	return Bonus
end


function GetSubjectiveSentence(Sim)
	
	local TotalEV = GetData("TotalEvidenceValue")
	if TotalEV == nil then
		SetData("TotalEvidenceValue", 0)
		TotalEV = 0
	end
	local Sentence = TotalEV + trial_GetFavorModifier(Sim)

	if (Sentence<0) then
		Sentence = 0
	elseif (Sentence>24) then
		Sentence = 24
	end

	return Sentence
end

function UpdatePanel()
	trial_UpdatePanelTrial(1)
end

function UpdatePanelTrial(time)
	local JudgePos = trial_GetSubjectiveSentence("judge")
	local Assessor1Pos = trial_GetSubjectiveSentence("assessor1")
	local Assessor2Pos = trial_GetSubjectiveSentence("assessor2")
	local TotalEV = GetData("TotalEvidenceValue")
	local AccuserSentence = GetData("AccuserSentence")
	LogMessage("TRIAL | 1453. AccuserSentence is: "..(AccuserSentence or '<void>'))
	if AccuserSentence == nil or AccuserSentence == "C" then
		AccuserSentence = 0
	elseif AccuserSentence > 0 then
		AccuserSentence = AccuserSentence*3+1
	end

	TrialHUDSetStatus("", TotalEV, JudgePos, Assessor1Pos, Assessor2Pos, AccuserSentence, time)
end

function OnCameraEnable() 
	BuildingGetRoom("courtbuilding", "Judge", "judgeroom")
	CutsceneHUDShow("","LetterBoxPanel")
	CutsceneHUDShow("","TrialPanel")
	TrialHUDSetSims("", GetID("accuser"), GetID("accused"), GetID("judge"), GetID("assessor1"), GetID("assessor2"))
	trial_UpdatePanelTrial(0)
	
	if GetLocalPlayerDynasty("playerdyn")	then
		local PlayerDynID = GetID("playerdyn")
		HudClearSelection()
		if PlayerDynID == GetDynastyID("accuser") then
			GetInsideRoom("accuser", "Room")
			if GetID("Room") == GetID("judgeroom") then
				HudAddToSelection("accuser")
			end
		end
		if PlayerDynID == GetDynastyID("accused") then
			GetInsideRoom("accused", "Room")
			if GetID("Room") == GetID("judgeroom") then
				HudAddToSelection("accused")
			end
		end
	end
end

function OnCameraDisable()
	CutsceneHUDShow("", "TrialPanel", false)
	CutsceneHUDShow("", "LetterBoxPanel", false)
	HudCancelUserSelection()
	HudClearSelection()
	HudAddToSelection("courtbuilding") 
end

function GetFavorModifier(Sim)
	local FavorAccused = GetFavorToSim(Sim, "accused")
	local FavorAccuser = GetFavorToSim(Sim, "accuser")
	GetDynasty(Sim, "SimDyn")
	GetDynasty("accused", "AccDyn")
	
	if not AliasExists("SimDyn") then
		return 0
	elseif not AliasExists("AccDyn") then
		return 0
	end
	
	local v = 0
	
	if FavorAccused > FavorAccuser then
		if (FavorAccused - FavorAccuser) < 10 then
			v = -1
		elseif (FavorAccused - FavorAccuser) < 20 then
			v = - 3
		elseif (FavorAccused - FavorAccuser) < 30 then
			v = -5
		elseif (FavorAccused - FavorAccuser) < 40 then
			v = -7
		else
			v = -10
		end
	elseif FavorAccuser > FavorAccused then
		if (FavorAccuser - FavorAccused) < 10 then
			v = 1
		elseif (FavorAccuser - FavorAccused) < 20 then
			v = 2
		elseif (FavorAccuser - FavorAccused) < 30 then
			v = 3
		elseif (FavorAccuser - FavorAccused) < 40 then
			v = 4
		else
			v = 5
		end
	end
	
	if DynastyGetDiplomacyState(Sim, "accuser") == DIP_ALLIANCE then
		v = v + 2
	elseif DynastyGetDiplomacyState(Sim, "accused") == DIP_ALLIANCE then
		v = v - 6
	end
	
	return v
end

function StopAllMeasures()
	BuildingGetRoom("courtbuilding", "Judge", "judgeroom")
	RoomGetInsideSimList("judgeroom","visitor_list")
	local i
	local num = ListSize("visitor_list")
	for i=0,num-1 do
		ListGetElement("visitor_list",i,"visitor")
		if (HasProperty("visitor","BUILDING_NPC") == false) then
			if (DynastyIsAI("visitor")) then
				SimSetBehavior("visitor","Idle")
			end
			SimStopMeasure("visitor")
		end
	end
end

function RandomVisitorComment(comment) -- currently not used
	local lsize = ListSize("visitor_list")
	if lsize>=1 then
		local index = Rand(lsize)
		ListGetElement("visitor_list",index,"random_visitor")
		PlayAnimationNoWait("random_visitor", "talk")
		MsgSay("random_visitor",comment)
	end
end

function ConvictionDecision()

	local x = GetData("DecisionParam")
	local AccuserSentence = GetData("AccuserSentence") * 3 + 1
	local JudgeDecision = GetData("JudgeDecision")
	
	if (JudgeDecision ~= -1) then
		local DipState = DynastyGetDiplomacyState("judge",x)
		if (DipState == DIP_FOE) then
			if (JudgeDecision == 1) then
				return 2
			else
				return 1
			end
		end
		
		if (DipState == DIP_ALLIANCE) then
			if (JudgeDecision == 1) then
				return 1
			else
				return 2
			end
		end		
	end
	
	if (trial_GetSubjectiveSentence(x) + 1) >= AccuserSentence then
		return 1
	else
		return 2
	end
end

function SimIsPresent(SimAlias)
	BuildingGetRoom("courtbuilding", "Judge", "judgeroom")
	
	if GetID(SimAlias)>0 then
		local list = {"DefendTrial","TrialOpponent","TrialJudge","TrialAssessor1","TrialAssessor2"}
		for i = 1,5 do
			if HasProperty(SimAlias,list[i]) then -- remove AI properties here
				RemoveProperty(SimAlias,list[i])
			end
		end
		
		if GetState(SimAlias, STATE_DEAD) then
			return 2 -->sim is dead
		end
		
		if GetState(SimAlias, STATE_HPFZ_TRAUMLAND) then
			return 0 -->sim is not useful
		end
		
		if GetState(SimAlias, STATE_UNCONSCIOUS) then
			return 0 -->sim is not useful
		end

		if not GetInsideRoom(SimAlias,"currentroom") then 
			return 0 -->sim is not in building
		end
		if GetID("currentroom")==GetID("judgeroom") then
			return 1 -->sim is in building
		end
		return 0	-- sim is not in building
	end
	
	return 2 -->sim does not exists -> sim is dead
end


function CreateSim(SimAlias,LocatorName,templateID)
	if GetLocatorByName("courtbuilding",LocatorName,"DestPos") then
		SimCreate(templateID,"courtbuilding","DestPos",SimAlias)
		SimSetLastname(SimAlias,SimAlias)
		SimSetFirstname(SimAlias,SimAlias)
	end
end

function SitAt(SimAlias, LocatorName)
	if trial_SimIsPresent(SimAlias)==1 then
		CutsceneCallThread("", "SimSitDown", SimAlias, LocatorName)
		return 1
	end
	return 0
end

function StandAt(SimAlias, LocatorName)
	if trial_SimIsPresent(SimAlias)==1 then
		CutsceneCallThread("", "SimStandAt", SimAlias, LocatorName)
		return 1
	end
	return 0
end

function LeaveBuilding(SimAlias)
	if trial_SimIsPresent(SimAlias)==1 then
		feedback_MessagePolitics(SimAlias,"@L_TOWNHALL_CLOSED_HEADER_+0","@L_TOWNHALL_CLOSED_TEXT_+0",GetID(SimAlias))
		CutsceneCallThread("", "SimExitBuilding", SimAlias)
		return 1
	end
	return 0
end

function ModifyTotalEvidenceValue(x)
	local lx = GetData("TotalEvidenceValue")
	lx = lx + x
	SetData("TotalEvidenceValue",lx)
	trial_UpdatePanelTrial(2)
end

function AccusedDecideConfess()
	local Sentence = GetData("AccuserSentence")
	local SentenceValue = Sentence * 3 + 1
	local Jury = { "judge", "assessor1", "assessor2" }
	local tendency = 0
	for i = 1, 3 do
		tendency = tendency + trial_GetSubjectiveSentence(Jury[i])
	end
	
	tendency = tendency / 3
	
	if SentenceValue >= tendency*1.5 then -- judges are on my side, accuser sentence is far too high
		return (Rand(2) + 1) -- innocent or nothing
	else
		
		if GetSkillValue("accused", RHETORIC) < 4 then
			if trial_GetSubjectiveSentence("judge") < 5 then
				return 3 -- confess
			elseif trial_GetSubjectiveSentence("judge") > 21 then
				return 3 -- confess
			end
			
			return 2 -- say nothing
		else
			if trial_GetSubjectiveSentence("judge") < 5 then
				return 3 -- confess
			end
			
			return (Rand(2)+1) -- innocent or say nothing
		end
	end

	return (Rand(3)+1)	--should never happen
end

function JudgeDecideSentence()
	return GetData("DefaultSentence")
end

function AccuserDecideSentence()
	local maxmod = 0
	if GetFavorToSim("accuser","accused")<30 then 
		maxmod = Rand(2)+1
	end

	local av = (trial_GetSubjectiveSentence("judge")+maxmod)/3
	local bv = (trial_GetSubjectiveSentence("assessor1")+maxmod)/3
	local cv = (trial_GetSubjectiveSentence("assessor2")+maxmod)/3
	local majority = 1 
	for i=1,6 do
		if (av>=i and bv>=i) or (av>=i and cv>=i) or (bv>=i and cv>=i) then
			majority = i
		end
	end

	return majority
end

function GetLocalPlayerRepresentative(alias)
	local list = {"accuser","accused","judge","assessor1","assessor2"}
	for i = 1,5 do
		if DynastyIsPlayer(list[i]) then
			CopyAlias(list[i],alias)
			return true
		end
	end
	return false
end

function Cam(LocatorName)
	GetLocatorByName("courtbuilding",LocatorName,"DestPos")
	CutsceneCameraSetAbsolutePosition("","DestPos")
end

function SimSitDown(LocatorName)
	if GetLocatorByName("courtbuilding", LocatorName, LocatorName) then
		f_BeginUseLocator("",LocatorName, GL_STANCE_SIT, true)
	end

	CutsceneSendEventTrigger("owner", "Reached")
end

function SimStandAt(LocatorName)
	if(GetLocatorByName("courtbuilding", LocatorName, LocatorName)) then
		f_MoveTo("",LocatorName)
	end
	CutsceneSendEventTrigger("owner", "Reached")
end

function SimExitBuilding()
	f_ExitCurrentBuilding("")
	f_Stroll("", 250.0,1.0)
	CutsceneRemoveSim("owner","")
	CutsceneSendEventTrigger("owner", "Reached")
end

function CleanUp()
	BuildingGetRoom("courtbuilding", "Judge", "judgeroom")
	RoomGetInsideSimList("judgeroom","visitor_list")
	for i=0,ListSize("visitor_list")-1 do
		ListGetElement("visitor_list",i,"Sim")
		if not HasProperty("Sim","BUILDING_NPC") then
			ReleaseLocator("Sim")
		end
	end
	
	RemoveProperty("judgeroom", "NextCutsceneID")
	RoomLockForCutscene("judgeroom",0)
	
	local TargetArray = {"judge","accuser","accused","assessor1","assessor2"}
	for Voter = 1, 5 do
		if AliasExists(TargetArray[Voter]) and (HasProperty(TargetArray[Voter],"trial_destination_ID") == true) then
			RemoveProperty(TargetArray[Voter],"trial_destination_ID")
		end
	end	
end

function IsIndoor(SimAlias)
	BuildingGetRoom("courtbuilding", "Judge", "judgeroom")
	--check if sim exist and is in the building. then run the function "FuncName" for the SIM @ SimAlias
	if GetID(SimAlias)>0 then
		if GetInsideRoom(SimAlias,"currentroom") then
			if GetID("currentroom")==GetID("judgeroom") then
				return 1
			else
				-- sim is not in the building
				return 0
			end
		else
			return 0
		end
	end
	return 0
end
 
function PlayRelevantTalkAni(sim)
	if (SimGetGender(sim) == GL_GENDER_FEMALE) then
		PlayAnimationNoWait(sim,"talk_female_"..(Rand(2)+1))
	else
		if (Rand(2) == 0) then
			PlayAnimationNoWait(sim, "talk")
		else
			PlayAnimationNoWait(sim, "talk_2")
		end
	end
end

function PlayRelevantJuryAni(Sim, Quality)

	local AniToPlay
	
	if Quality < 51 then
		AniToPlay = "sit_no"
	elseif Quality < 76 then
		AniToPlay = "talk_sit_short"
	elseif Quality < 100 then
		AniToPlay = "sit_talk"
	else
		AniToPlay = "sit_yes"
	end
	
	PlayAnimationNoWait(Sim, AniToPlay)
end

-- is there a player who actively participates?
function HumanPlayerWantsInteraction()
	if DynastyIsPlayer("accuser") or DynastyIsPlayer("accused") then
		return true
	end
	return false
end

function EvidenceIntToString(EvidenceType)

	local EvidenceData = {
					[1] = "_SABOTAGE",
					[4] = "_BRIBE",
					[6] = "B_BLACKMAIL", -- B_ was already present before edit
					[7] = "_SLUGGING",
					[10] = "_CALUMNY",
					[11] = "_POISON",
					[12] = "_ASSAULT",
					[13] = "_REVOLT",
					[14] = "_MARAUDER",
					[15] = "_ABDUCTION",
					[16] = "_MURDER",
					[17] = "_ESPIONAGE",
					[18] = "_PERSONASSAULT",
					[19] = "_CARTASSAULT",
					[20] = "_THEFT"
					}
	
	local EvidenceString = "@L_TRIAL_START_QUESTION_TO_JUDGE_EVIDENCETYPE"..EvidenceData[EvidenceType].."_+0"
	
	-- DEBUG: invalid case
	if EvidenceString == nil then
		return "@L_TRIAL_START_QUESTION_TO_JUDGE_THEFT_+0"
	end
end
