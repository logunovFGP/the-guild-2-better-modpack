-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_150_AttendApprenticeship"
----
----	With this measure the player can send a child to apprenticeship
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()

	if not GetSettlement("", "MyCity") then
		return
	end

	local FameLvl = dyn_GetFameLevel("")
	local ImpFameLvl = dyn_GetImperialFameLevel("")
	local Appmoney
	local App1 = GL_APPRENTICESHIPMONEY
	local App2 = GL_APPRENTICESHIPMONEY * (2+FameLvl)
	local App3 = GL_APPRENTICESHIPMONEY * (6+ImpFameLvl)
	local BuildingType
	local choice = 0

	if IsStateDriven() then
		--random choice
		choice = Rand(4) + 1
		
		if GetNobilityTitle("") > 7 then
			choice = choice + 4
		end
		
	else
		GetDynasty("", "dynasty")
		
		local button1 = "@B[1,@L_ATTEND_APPRENTICE_NEW_OPTION_+1]" -- Guild manufacturer
		local button2 = "@B[2,@L_ATTEND_APPRENTICE_NEW_OPTION_+2]" -- Guild patron
		local button3 = "@B[3,@L_ATTEND_APPRENTICE_NEW_OPTION_+3]" -- Church
		local button4 = "@B[4,@L_ATTEND_APPRENTICE_NEW_OPTION_+4]" -- Guard
		local button5 = "@B[0,@L_ATTEND_APPRENTICE_NEW_OPTION_+0]" -- Self
		
		if GetNobilityTitle("") > 7 then -- new options if player has a higher title
			button1 = "@B[5,@L_ATTEND_APPRENTICE_NEW_OPTION_+5]" -- Purveyor to the court
			button2 = "@B[6,@L_ATTEND_APPRENTICE_NEW_OPTION_+6]" -- Baker to the court
			button3 = "@B[7,@L_ATTEND_APPRENTICE_NEW_OPTION_+7]" -- Advisor
			button4 = "@B[8,@L_ATTEND_APPRENTICE_NEW_OPTION_+8]" -- Army
			button5 = ""
			GetOutdoorLocator("MapExit1", 1, "Exit")
		else
			App3 = App1
			App2 = App1
		end
		
		choice = MsgBox("dynasty", "", "@P"..
						button1..
						button2..
						button3..
						button4..
						"@B[0,@L_REPLACEMENTS_BUTTONS_CANCEL_+0]",
						"@L_ATTEND_APPRENTICESHIP_NEW_HEAD_+0",
						"@L_ATTEND_APPRENTICESHIP_NEW_BODY_+0",
						GetID(""),App1,App2,App3)
		
	end
	
	if (choice == 1) then
		-- TODO make apprenticeship in actual businesses
		Appmoney = App1
		
		if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_GUILDHOUSE, -1, -1, FILTER_IGNORE, "DestBuilding") then
			if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_JOINERY, -1, -1, FILTER_IGNORE, "DestBuilding") then
				if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_SMITHY, -1, -1, FILTER_IGNORE, "DestBuilding") then 
					return -- paranoia-fix - should never happen
				end
			end
		end
	elseif (choice == 2) then
	
		Appmoney = App1
		
		if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_GUILDHOUSE, -1, -1, FILTER_IGNORE, "DestBuilding") then
			if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_TAVERN, -1, -1, FILTER_IGNORE, "DestBuilding") then
				if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_BAKERY, -1, -1, FILTER_IGNORE, "DestBuilding") then 
					return -- paranoia-fix - should never happen
				end
			end
		end
	elseif (choice == 3) then
	
		Appmoney = App1
		
		if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, -1, FILTER_IGNORE, "DestBuilding") then
			if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_CHURCH_EV, -1, -1, FILTER_IGNORE, "DestBuilding") then
				if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_CHURCH_CATH, -1, -1, FILTER_IGNORE, "DestBuilding") then
					return -- paranoia-fix - should never happen
				end
			end
		end
	elseif (choice == 4) then
	
		Appmoney = App1
		
		if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_SCHOOL, -1, -1, FILTER_IGNORE, "DestBuilding") then
			if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_TOWNHALL, -1, -1, FILTER_IGNORE, "DestBuilding") then -- alternative go to townhall
				return
			end	
		end
	elseif (choice == 0) then
		Appmoney = 0
		GetHomeBuilding("", "DestBuilding")
	elseif (choice == 5) or (choice == 6) then
		Appmoney = App2
	else 
		Appmoney = App3
	end
	
	if choice < 5 then 
		GetLocatorByName("DestBuilding", "Entry1", "DestPos")
	else
		GetOutdoorLocator("MapExit1", 1, "DestPos")
	end

	if not HasProperty("", "ApprenticeshipPayed"..choice) then
		
		if not chr_SpendMoney("Dynasty", Appmoney, "CostEducation") then
			MsgQuick("", "@L_FAMILY_150_ATTENDAPPRENTICESHIP_FAILURES_+0", GetID(""), Appmoney)
			StopMeasure()
		end
		
		SetProperty("", "ApprenticeshipPayed"..choice, 1)	
	end
	
	if not GetHomeBuilding("", "Home") then
		StopMeasure()
	end

	local Time = GL_APPRENTICESHIPTIME
	
	SetData("MaxTime",Time)
	local SchoolStart = math.floor(0+GetGametime())
	SetData("StartTime", SchoolStart)
	
	if HasProperty("", "Time_done_apprenticeship") then
		local TimeLeft = 0 + GetProperty("", "Time_done_apprenticeship")
		Time = 0 + Time - TimeLeft
	end
	
	SetMeasureRepeat(Time)
	StartGameTimer(Time)
	
	local EndTime = GetGametime() + Time
	SetData("EndTime", EndTime)
	SetData("Time", Time)
	SetProcessMaxProgress("", Time*10)
	SendCommandNoWait("", "Progress")

	-- get to the destpos a first time
	if f_MoveTo("", "DestPos",GL_MOVESPEED_RUN) then
		SetState("", STATE_INVISIBLE, true)
	end
		
	while not CheckGameTimerEnd() do
		Sleep(30)
	end	
		
	RemoveProperty("", "Time_done_apprenticeship")
	RemoveProperty("", "ApprenticeshipPayed")
	SetProperty("", "is_apprentice")
	SetData("Finished", 1)
		
	--create the skill bonus
	local DestClass = choice
	local run = 1
	local Skill = {"consti","dex","charisma","fighting","craftman","shadow","rhetoric","empathy","bargain","secret"}
	
	while Skill[run]~=nil do
		local NewSkillValue = GetDatabaseValue("Apprentice",choice,Skill[run])
		if NewSkillValue and NewSkillValue > 0 then
			IncrementSkillValue("", run, NewSkillValue)
		end
		run = run+1
	end
	
	local ClassNr = GetDatabaseValue("Apprentice", choice, "class")
	if ClassNr == 0 then
		ClassNr = Rand(4) + 1
	end
	SimSetClass("", ClassNr)
	GetDynasty("","AppDyn")
	if AliasExists("AppDyn") then
		DynastyGetMember("AppDyn",0,"AppBoss")
		achievements_Unlock("AppBoss", "MISC_ATTEND_APPRENTICESHIP")
	end
	
	-- Preparations for the certificate
	GetSettlement("", "Settlement")
	
	local ClassName = GetDatabaseValue("Classes", ClassNr, "name")
	
	xp_Apprenticeship("")
	
	-- Certificate -- TODO!
	MsgNewsNoWait("", "", "panel_nobility_title_deed", "intrigue", -1, "@L_FAMILY_150_ATTENDAPPRENTICESHIP_END_CERTIFICATE_HEADER", "@L_FAMILY_150_ATTENDAPPRENTICESHIP_END_CERTIFICATE_DOCUMENT_NEW_+"..choice,
				GetID(""),
				"@L_FAMILY_150_ATTENDAPPRENTICESHIP_END_CERTIFICATE_CLASS_"..ClassName.."_+0",
				GetID("Settlement"),
				Gametime2Total(GetGametime()))
	
	ResetProcessProgress("")
	f_ExitCurrentBuilding("")
	SimBeamMeUp("", "DestPos", false)
	SetState("", STATE_INVISIBLE, false)
	PlayAnimation("", "cheer_01")
	
	if GetHomeBuilding("", "Home") then
		f_MoveToNoWait("", "Home",GL_MOVESPEED_WALK)
	end
	StopMeasure()
end

function Progress()

	while true do
		local Time = GetData("Time")
		local EndTime = GetData("EndTime")
		local CurrentTime = GetGametime()
		CurrentTime = EndTime - CurrentTime
		CurrentTime = Time - CurrentTime
		SetProcessProgress("", CurrentTime*10)
		Sleep(10)
	end
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()

	ResetProcessProgress("")
	SetMeasureRepeat(0.01)
	
	if GetState("", STATE_INVISIBLE) then
		SimBeamMeUp("", "DestPos", false)
		SetState("", STATE_INVISIBLE, false)
	end
	
	if HasData("StartTime") and not HasData("Finished") then
		local SchoolEnd = math.floor(0+GetGametime())
		local SchoolStart = 0 + GetData("StartTime")
		local Difference = 0 + SchoolEnd - SchoolStart
		local MaxTime = 0 +GetData("MaxTime")
		
		if HasProperty("", "Time_done_apprenticeship") then
			Difference = Difference + GetProperty("", "Time_done_apprenticeship")
		end
		
		if Difference < MaxTime then
		
			SetProperty("", "Time_done_apprenticeship", Difference)
			feedback_MessageSchedule("",
								"@L_FAMILY_150_ATTENDAPPRENTICESHIP_NOTFINISHED_HEAD",
								"@L_FAMILY_150_ATTENDAPPRENTICESHIP_NOTFINISHED_BODY", GetID(""), (MaxTime-Difference), GetID("Destination"))
			
			if GetHomeBuilding("", "Home") and GetInsideBuildingID("") ~= GetID("Home") then
				f_MoveToNoWait("", "Home", GL_MOVESPEED_WALK)
			end				
		end
	end
end

function GetOSHData(MeasureID)
	-- OSHSetMeasureCost("@L_INTERFACE_HEADER_+6",GL_APPRENTICESHIPMONEY)
end

