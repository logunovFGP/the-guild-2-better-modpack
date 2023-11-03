-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_077_Marry"
----
----	with this measure the player can marry a courted sim
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()
	local XP = GetData("BaseXP")
	local Title = GetNobilityTitle("")
	local InteractionDistance = 128
	local ProposeInteractionDistance = 116
		
	-- Get the court lover and call it "Destination" because the older version of the measure worked with a selection
	if not SimGetCourtLover("", "Destination") then
		return
	end
	
	if IsDynastySim("Destination") then
		if GetNobilityTitle("Destination") > Title then
			Title = GetNobilityTitle("Destination")
		end
	end
	
	local Cost = (Title * 2) * 300
	
	if not HasProperty("", "ContinueWedding") then
	
		if SimGetProfession("Destination") > 0 then -- don't marry workers please
			if SimGetWorkingPlace("Destination", "MyWork") then
				if BuildingGetOwner("MyWork", "MyBoss") then
					MsgBoxNoWait("", "Destination",  "@L_GENERAL_MEASURES_MARRY_FAILURES_HEAD_+0", "@L_GENERAL_MEASURES_MARRY_FAILURES_+1", GetID("Destination"), GetID("MyWork"), GetID("MyBoss"), GetID(""))
					SimReleaseCourtLover("")
					chr_GainXP("", XP/2)
					StopMeasure()
					return
				end
			end
			
			-- something missing, send alternative message
			MsgBoxNoWait("", "Destination",  "@L_GENERAL_MEASURES_MARRY_FAILURES_HEAD_+0", "@L_GENERAL_MEASURES_MARRY_FAILURES_+2", GetID("Destination"), GetID(""))
			SimReleaseCourtLover("")
			chr_GainXP("", XP/2)
			return
		end
		
		-- destination is already married
		if SimGetSpouse("Destination", "Spouse") then
			SimReleaseCourtLover("")
			LogMessage("Destination has Spouse")
			StopMeasure()
		end
		
		if not ai_StartInteraction("", "Destination", 500, InteractionDistance) then
			MsgQuick("", "@L_GENERAL_MEASURES_MARRY_FAILURES_+0", GetID("Destination"))
			LogMessage("Start Interaction fail Marriage")
			StopMeasure()
			return
		end
		
		SetAvoidanceGroup("", "Destination")
		MoveSetActivity("", "converse")
		MoveSetActivity("Destination", "converse")
		CreateCutscene("default", "cutscene")
		CutsceneAddSim("cutscene", "")
		CutsceneAddSim("cutscene", "Destination")
		CutsceneCameraCreate("cutscene", "")			

		-------------
		-- Propose --
		-------------
		camera_CutsceneBothLock("cutscene", "")
		
		chr_MultiAnim("", "proposal_male", "Destination", "proposal_female", ProposeInteractionDistance, 0.3)
		MsgSay("", talk_AskMarriage(GetSkillValue("", RHETORIC), SimGetGender("")));
		
		
		camera_CutscenePlayerLock("cutscene", "Destination")
		MsgSay("Destination", talk_AnswerMarriage(GetSkillValue("Destination", RHETORIC), SimGetGender("Destination")));
		
		if IsPartyMember("Destination") then
			SetProperty("Destination", "Wedding", 1)
			GetDynasty("Destination", "DesDyn")
			DynastyRemoveMember("Destination", "DesDyn")
		end
		
		ReleaseAvoidanceGroup("")
		DestroyCutscene("cutscene")
	end
	
	--------------------------------
	-- Ask for the place to marry --
	--------------------------------
	
	local choice

	FindNearestBuilding("", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "Weddingchapel")

	if AliasExists("Weddingchapel") then

		if DynastyIsAI("") then
			if Cost > (GetMoney("") - 1000) then
				choice = 0
			else
				if DynastyIsShadow("") then
					choice = 0
				else
					choice = 1
				end
			end
		else
			if HasProperty("", "ContinueWedding") then
				choice = 1
			else
				
				choice = MsgBox("", "", 
								"@B[0,@L_MEASURE_WEDDING_OPTION_+0]"..
								"@B[1,@L_MEASURE_WEDDING_OPTION_+1]"..
								"@B[2,@L_MEASURE_WEDDING_OPTION_+2]",
								"@L_FAMILY_1_MARRIAGE_MESSAGE_HEAD_LEAVE_+0",
								"@L_MEASURE_WEDDING_QUESTION_+0",
								GetID(""), GetID("Destination"), Cost)
			end
		end
	else
		if DynastyIsAI("") then
			choice = 0
		else
			choice = MsgBox("", "", 
								"@B[0,@L_MEASURE_WEDDING_OPTION_+0]"..
								"@B[2,@L_MEASURE_WEDDING_OPTION_+2]",
								"@L_FAMILY_1_MARRIAGE_MESSAGE_HEAD_LEAVE_+0",
								"@L_MEASURE_WEDDING_QUESTION_+0",
								GetID(""), GetID("Destination"))
		end
	end

	--------------------------------
	--  at this place and nowhere else
	--------------------------------
	if choice == 0 then
		if ai_StartInteraction("", "Destination", 500, InteractionDistance) then
			
			if AliasExists("Weddingchapel") then
				PlaySound3D("Weddingchapel", "locations/bell_stroke_cathedral_loop+0.wav", 1.0)
			end
			
			f_StartHighPriorMusic(MUSIC_MARRIAGE)
			SetState("", STATE_DUEL, true)
			SetState("Destination", STATE_DUEL, true)

			SetAvoidanceGroup("", "Destination")
			CreateCutscene("default", "cutscene")
			CutsceneAddSim("cutscene", "")
			CutsceneAddSim("cutscene", "Destination")
			CutsceneCameraCreate("cutscene", "")
			camera_CutsceneBothLock("cutscene", "")

			ShowOverheadSymbol("", false, true, 0, "@L$S[2001]")
			ShowOverheadSymbol("Destination", false, true, 0, "@L$S[2001]")
			
			local AnimLength = chr_MultiAnim("", "kiss_male", "Destination", "kiss_female", InteractionDistance, 1.0, true)
			
			Sleep(AnimLength * 0.5)
			ShowOverheadSymbol("Destination", false, true, 0, "@L$S[2001]")
			ShowOverheadSymbol("", false, true, 0, "@L$S[2001]")
			
			Sleep(AnimLength * 0.5)
			ShowOverheadSymbol("Destination", false, true, 0, "@L$S[2001]")
			ShowOverheadSymbol("", false, true, 0, "@L$S[2001]")
			
			if not HasProperty("", "CourtingDiff") then			
				gameplayformulas_CalcCourtingDifficulty("Destination", "")
			end
			
			local Difficulty = GetProperty("", "CourtingDiff")
			xp_CourtingSuccess("Owner", Difficulty)
			xp_CourtingSuccess("Destination", Difficulty)
			RemoveProperty("", "CourtingDiff")
	
			MeasureSetNotRestartable()
			RemoveProperty("Destination", "courted")
			if IsDynastySim("Destination") then
				DynastySetMinDiplomacyState("", "Destination", DIP_ALLIANCE, GetID(""), 24)
				DynastyForceCalcDiplomacy("")
				DynastyForceCalcDiplomacy("Destination")
				-- add the new property
				dyn_AddAlly("", "Destination")
				
				-- get a new title if the nob title is higher than yours
				local MyTitle = GetNobilityTitle("") or 1
				local SpouseTitle = GetNobilityTitle("Destination") or 1
				
				if MyTitle > 2 and SpouseTitle > MyTitle then
					SetNobilityTitle("", (MyTitle + 1), true)
				end
			end
			
			-- remember old dynastyID
			local OldDyn = GetDynastyID("Destination")
			SetProperty("Destination", "FamilyID", OldDyn)
			SetState("", STATE_DUEL, false)
			SetState("Destination", STATE_DUEL, false)
			
			AddImpact("", "LoveLevel", 10, 24) -- add some love for the next 24 hours
			AddImpact("Destination", "LoveLevel", 10, 24)
			SetState("Destination", STATE_INLOVE, false)

			if GetImpactValue("Destination", "LoveLevel") >= 10 then -- you are irresistable!
				MsgNewsNoWait("", "Destination", "", "schedule", -1,
							"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_HEAD_+0",
							"@L_FAMILY_2_COHIBITATION_FULLOFLOVE_BODY_+0", GetID("Destination"))
			end
			
			SimMarry("", "Destination")	-- the destination is removed through this function

		else
		
			MsgQuick("", "@L_MEASURE_WEDDING_FAILURE_+0", GetID(""), GetID("Destination"))
		end

	--------------------------------
	--  visit the wedding chapel --
	--------------------------------
	elseif choice == 1 then

		Sleep(1)
		--MeasureRun("", "Destination", "MarryChapel", true)
		--Sleep(1)

			local function returnSlot()

				local schedule = { 
					getYear = 0,
					getHour = 6,
					setHour = 0,
					getRounds = math.floor( GetGametime() / 24 ),
					getDate = nil,
					minDelay = 4 
				}

				-- Possible slots: 06:00 | 12:00 | 18:00 | 00:00

				FindNearestBuilding("", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "#WEDDING_CHAPEL")

				-- Init. properties (if unexisting)
				if not HasProperty("#WEDDING_CHAPEL", "AMOUNT") then 
					SetProperty("#WEDDING_CHAPEL", "AMOUNT", 0)
				end

				if not HasProperty("#WEDDING_CHAPEL", "YEAR") then
					SetProperty("#WEDDING_CHAPEL", "YEAR", 0)
				end

				if not HasProperty("#WEDDING_CHAPEL", "HOUR_ADDON") then
					SetProperty("#WEDDING_CHAPEL", "HOUR_ADDON", 1)
				end

				-- Inst. properties (won't be conflicting)
				local ID = GetProperty("#WEDDING_CHAPEL","AMOUNT")
				SetProperty("#WEDDING_CHAPEL", "AMOUNT", ID+1)

				local YEAR = GetProperty("#WEDDING_CHAPEL", "YEAR")
				schedule.getYear = YEAR

				local HOUR = GetProperty("#WEDDING_CHAPEL", "HOUR_ADDON") + 1
				SetProperty("#WEDDING_CHAPEL", "HOUR_ADDON", HOUR)

				-- Script calculations.
				schedule.getHour = 6 + (HOUR - 1) * 6

				if HOUR > 4 then
				    SetProperty("#WEDDING_CHAPEL", "HOUR_ADDON", 1)
				    schedule.getHour = 6
				end

				LogMessage("Hour slot defined: "..schedule.getHour.."h00.")

				if math.floor(GetProperty("#WEDDING_CHAPEL","AMOUNT")) == math.floor((GetProperty("#WEDDING_CHAPEL","AMOUNT")) / 4) * 4 then
					SetProperty("#WEDDING_CHAPEL", "YEAR", YEAR + 1)
					schedule.getYear = YEAR + 1
				end

				schedule.getDate = ( ( ( 24 * ( schedule.getRounds+schedule.getYear ) ) * 60 - GetGametime() * 60 ) / 60 ) + schedule.getHour

				LogMessage("("..schedule.getHour.."h00). Will there be enough time? ".. schedule.getDate .." ("..schedule.minDelay.." hours required).")

				if schedule.getDate > schedule.minDelay then
					schedule.getDate = ( ( 24 * ( schedule.getRounds+schedule.getYear ) ) * 60 ) + schedule.getHour * 60
					LogMessage("Script confirmed "..schedule.getHour.."h00 as a perfect date for this Wedding Ceremony.")
				else

					local timeMessages = {
					    [6] = 12,
					    [12] = 18,
					    [18] = 24,
					    [24] = 6
					}

					if timeMessages[schedule.getHour] then
					    LogMessage("Script determined " .. timeMessages[schedule.getHour] .. "h00 as a better fit for this ceremony.")
					    schedule.getDate = (24 * (schedule.getRounds + schedule.getYear) * 60) + timeMessages[schedule.getHour] * 60
					end

				end

				-- Utilities.

				local function SetProperties(data, result)
					SetProperty("",			data, result)
					SetProperty("#Courted", data, result)
				end

				local function SimAddDates(date)
					local list = {"","#Courted"}
					for i = 1, 2 do
						SimAddDatebookEntry(list[i],date, "#WEDDING_CHAPEL","Your Wedding Ceremony...","Two love-birds are getting married soon, you should probably attend the event in a great moment of community.")
						SimAddDate(list[i],"#WEDDING_CHAPEL", "#WEDDING_CHAPEL", date -120, "AttendWedding")
					end
				end

				SimGetCourtLover("", "#Courted")

				-- Dual properties
				SetProperties("WEDDING_IS_OVER", 0)
				SetProperties("WEDDING_DATE", schedule.getDate)
				SetProperties("WEDDING_HOUR", schedule.getHour)
				SetProperties("WEDDING_FORCED", 1)
				SetProperties("WEDDING_GUESTS(Amount)", -1)

				-- Single properties
				SetProperty("", "#WEDDING_MAIN", 1)

				-- Callbacks
				SimAddDates(schedule.getDate)

				return schedule.getDate

			end

			do
				local v = returnSlot()
				ms_077_marry_InviteGuests("#WEDDING_CHAPEL", "", "#Courted", v)
			end


		return
	end
end

local function AIInitAnswer()
	local list, timer = {"Office","Trial","Duel"}
	LogMessage("local function AIInitAnswer()")

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

function InviteGuests(Chapel, Sim1, Sim2, Hour)
LogMessage("InviteGuests() func.")

    local function canInviteGuest(GuestAlias, GuestDyn)
        return math.max(GetNobilityTitle(Sim1), GetNobilityTitle(Sim2)) >= GetNobilityTitle(GuestAlias) - 2 and f_SimIsValid(GuestAlias) and not GetState(GuestAlias, STATE_SICK) and CanBeInterruptetBy(GuestAlias, Sim1, "Flirt")
    end

    local function inviteGuest(GuestAlias)
        local Invitation = MsgNews(GuestAlias, "", "@P"..
            "@B[O, @L_THIEF_067_LETABDUCTEEOUT_ACTION_BTN_+0]"..
            "@B[C, @L_THIEF_067_LETABDUCTEEOUT_ACTION_BTN_+1]", 
            AIInitAnswer, "politics", 2, 
            "@L_FAMILY_1_MARRIAGE_MESSAGE_HEAD_LEAVE_+0",
            "@L_MEASURE_MARRY_CEREMONY_ASK_BODY_+0",
            GetID(Sim1), GetID(Sim2), GetID(Chapel), GetID(GuestAlias))

        	if Invitation == "O" then
        		setProperties("Guest")
        		SimAddDate("Guest", "#WEDDING_CHAPEL", "#WEDDING_CHAPEL", date-120, "AttendWedding")
        		SimAddDatebookEntry("Guest", date, "#WEDDING_CHAPEL","@L_WEDDING_CEREMONY_DIARY_BODY_+0","@L_WEDDING_CEREMONY_DIARY_HEAD_+0")
        	else
        		return false
        	end
    end

    local function returnSim(index, dynasty)
		if not DynastyGetFamilyMember(dynasty, index, "Guest") then
			return false
		end

		if GetID("Guest") == GetID(Sim1) or GetID("Guest") == GetID(Sim2) then
			return false
		end

		if GetID(dynasty) ~= GetDynastyID("Guest") then
			return false
		end

		if canInviteGuest("Guest", "GuestDyn") then
			return inviteGuest("Guest")
		end
    end

    local function setProperties(GuestAlias)
		SetProperty(GuestAlias, "AttendingWedding",    1			)
		SetProperty(GuestAlias, "WEDDING_HOUR(GUEST)", Hour			)
		SetProperty(GuestAlias, "WEDDING_SIM1(GUEST)", GetID(Sim1)	)
		SetProperty(GuestAlias, "WEDDING_SIM2(GUEST)", GetID(Sim2)	)
    end

    if GetSettlement(Sim1, "MyCity") then
        for i = 0, CityGetBuildings("MyCity", GL_BUILDING_CLASS_LIVINGROOM, -1, -1, -1, FILTER_HAS_DYNASTY, "Residence") - 1 do
            if GetDynasty("Residence"..i, "GuestDyn") then
                local limit, date = 0, GetProperty(Sim1,"WEDDING_DATE")
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
		
function CleanUp()
	EndCutscene("")
	DestroyCutscene("cutscene")
	MoveSetActivity("")
	MoveSetActivity("Destination")
	ReleaseAvoidanceGroup("")
	SetState("", STATE_DUEL, false)
	SetState("Destination", STATE_DUEL, false)
end