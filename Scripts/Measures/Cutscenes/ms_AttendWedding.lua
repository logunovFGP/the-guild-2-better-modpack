function Run()

	FindNearestBuilding("", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "#WEDDING_CHAPEL")

	if not HasProperty("","#WEDDING_FORCED") then 
		if GetState("", STATE_CUTSCENE) then
			return
		end
		
		local CurrentMeasure = GetCurrentMeasureName("")

		local list = {"AttendTrialMeeting","AttendOfficeMeeting","AttendDuel","AttendFestivity"}

		for i = 1, 4 do
			if CurrentMeasure == list[i] then
				return
			end
		end
		
		if GetImpactValue("", "SuppressAttendMessage") > 0 then
			return
		end
	end
	
	if f_SimIsValid("") == false then 
		return
	end

	LogMessage(GetName("")..' is on the way to '..GetName("#WEDDING_CHAPEL"))

	if HasProperty("","#WEDDING_FORCED") then
		if SimGetGender("") == GL_GENDER_FEMALE then
			GetLocatorByName("#WEDDING_CHAPEL", "Exit1", "#POS")
		else
			GetLocatorByName("#WEDDING_CHAPEL", "Exit2", "#POS")
		end
		f_MoveTo("", "#POS", GL_MOVESPEED_RUN)
	else
		f_MoveTo("", "destination", GL_MOVESPEED_RUN)
	end

	local isInside = false

	repeat
		Sleep(5)
		if GetInsideBuilding("", "#BUILDING") ~= false then
			if GetID("#BUILDING") == GetID("#WEDDING_CHAPEL") then
				if not HasProperty("","#WEDDING_FORCED") then
					if HasProperty("","WEDDING_canChat") and not HasProperty("","Busy") then
						ms_attendwedding_ChatterGuests("")
					end
					if not HasProperty("","WEDDING_canChat") then
						Sleep(1)
						break
					end
				end
			end
		end
	until (HasProperty("","WEDDING_canChat") == false)
end

function ChatterGuests()

	if not HasProperty("","Busy") and HasProperty("","AttendingWedding") then
		BuildingFindSimByProperty("#WEDDING_CHAPEL", "BUILDING_NPC", 11, "#PRIEST")
		BuildingGetInsideSimList("#WEDDING_CHAPEL", "#SIMS")
		ListRemove("#SIMS","#PRIEST")

		local count = ListSize("#SIMS")

		if count > 1 then 
			ListGetElement("#SIMS", Rand(count), "#DEST")

			if GetID("") ~= GetID("#DEST") and SimGetAge("#DEST") > 15 and not HasProperty("#DEST","Busy") and HasProperty("#DEST","AttendingWedding") then

				MoveStop("#DEST")

				SetProperty("#DEST","Busy",1)
				SetProperty("","Busy",1)

				f_WeakMoveTo("","#DEST",GL_MOVESPEED_WALK,128)
				f_WeakMoveTo("#DEST","",GL_MOVESPEED_WALK,128)

				AlignTo("","#DEST")
				AlignTo("#DEST","")

				LoopAnimation("", "talk", -1)

				local dialog = ms_attendwedding_returnDialog("")
				MsgSay("", dialog[1], dialog[2])

				StopAnimation("")

				LoopAnimation("#DEST", "talk", -1)

				local answer = {"Oh really?","Is that so?","I believe you must be right.","Never saw it this way but I see what you mean.","You're probably right.","Let's hope for the best."}

				MsgSay("#DEST", answer[Rand(6)+1])
				StopAnimation("#DEST")

				GetFleePosition("","#DEST",Rand(75)+150,"#POS")
				f_WeakMoveTo("","#POS")

				RemoveProperty("#DEST","Busy")
				RemoveProperty("","Busy")

				Sleep(Rand(5)+5)
			end
		end
	end
end

function returnDialog(Sim)

    local Sim1 = GetAliasByID(GetProperty(Sim,"SIM1"),"#SIM1")
    local Sim2 = GetAliasByID(GetProperty(Sim,"SIM2"),"#SIM2")

	local Rand = Rand(2)+1
	
	local Diplomacy, Reputation = DynastyGetDiplomacyState(Sim, "#SIM"..Rand), SimGetAlignment("#SIM"..Rand)

	if Diplomacy == DIP_NEUTRAL then
		if Reputation >= 62.5 then
			return {"_WEDDING_CHATTERING_NEUTRAL_REACTING_TO_GOOD_REPUTATION_+0", GetID("#SIM"..Rand)}
		elseif Reputation >= 37.5 then
			return {"_WEDDING_CHATTERING_NEUTRAL_REACTING_TO_NORMAL_REPUTATION_+0", GetID("#SIM"..Rand)}
		else
			return {"_WEDDING_CHATTERING_NEUTRAL_REACTING_TO_BAD_REPUTATION_+0", GetID("#SIM"..Rand)}
		end
	end

	if Diplomacy == DIP_ALLIANCE or Diplomacy == DIP_NAP then
		if Reputation >= 62.5 then
			return {"_WEDDING_CHATTERING_FRIENDLY_REACTING_TO_GOOD_REPUTATION_+0", GetID("#SIM"..Rand)}
		elseif Reputation >= 37.5 then
			return {"_WEDDING_CHATTERING_FRIENDLY_REACTING_TO_NORMAL_REPUTATION_+0", GetID("#SIM"..Rand)}
		else
			return {"_WEDDING_CHATTERING_FRIENDLY_REACTING_TO_BAD_REPUTATION_+0", GetID("#SIM"..Rand)}
		end
	end

	if Diplomacy == DIP_FOE then
		if Reputation >= 62.5 then
			return {"_WEDDING_CHATTERING_HOSTILE_REACTING_TO_GOOD_REPUTATION_+0", GetID("#SIM"..Rand)}
		elseif Reputation >= 37.5 then
			return {"_WEDDING_CHATTERING_HOSTILE_REACTING_TO_NORMAL_REPUTATION_+0", GetID("#SIM"..Rand)}
		else
			return {"_WEDDING_CHATTERING_HOSTILE_REACTING_TO_BAD_REPUTATION_+0", GetID("#SIM"..Rand)}
		end
	end
end