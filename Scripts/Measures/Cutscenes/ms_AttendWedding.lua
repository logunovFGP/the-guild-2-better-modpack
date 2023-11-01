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
		f_MoveToNoWait("", "#POS", GL_MOVESPEED_RUN)
	else
		f_MoveTo("", "destination", GL_MOVESPEED_RUN)
	end

	local isInside = false

	if not HasProperty("","WEDDING_IGNORE") then 
		repeat
			local Building = GetInsideBuilding("", "#BUILDING")
			if Building ~= false then
				if GetID("#BUILDING") == GetID("#WEDDING_CHAPEL") then
					isInside = true
					SetProperty("","WEDDING_IGNORE",1)
					break
				else
					isInside = false
					Sleep(1)
				end
			else
				Sleep(1)
			end
		until (isInside == true)
	end

	local canStart = false

	local filterSims = function()
		FindNearestBuilding("", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "#WEDDING_CHAPEL")
		BuildingFindSimByProperty("#WEDDING_CHAPEL", "BUILDING_NPC", 11, "Priest")

		if GetName("") == GetName("Priest") then
			return true
		end

		if HasProperty("","WEDDING_FORCED") then
			return true
		end

		return false
	end

	local returnDialog = function(Sim)

		GetAliasByID(GetProperty("","WEDDING_SIM1(GUEST)"),"#SIM1")
		GetAliasByID(GetProperty("","WEDDING_SIM2(GUEST)"),"#SIM2")

		local Rand = Rand(2)+1
		
		local Diplomacy, Reputation = DynastyGetDiplomacyState("", "#SIM"..Rand), SimGetAlignment("#SIM"..Rand)

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

	local isOver = function()
		GetAliasByID(GetProperty("","WEDDING_SIM1(GUEST)"),"#SIM1")
		if GetProperty("", "WEDDING_IS_OVER") == 1 then
			return true
		else
			return false
		end
	end

	if isInside then

		repeat
			Sleep(1)

			local current = GetGametime()

			if HasProperty("","#WEDDING_MAIN") then
				local planned = GetProperty("", "WEDDING_HOUR")
				if current > planned then
					MeasureCreate("MarryChapel")
					MeasureStart("MarryChapel", "", "#WEDDING_CHAPEL", "MarryChapel", true)
					canStart = true
					break
				end
			end

			if HasProperty("","WEDDING_HOUR(GUEST)") then

				local planned = GetProperty("", "WEDDING_HOUR(GUEST)")

				if current > (planned/60) -0.5 then

					local allSeats = {}

					for i = 1, 29 do 
						if LocatorStatus("#WEDDING_CHAPEL", "Sit"..i, true) == 1 then
							allSeats[i] = false
						else
							allSeats[i] = true
						end
					end

					BuildingGetInsideSimList("#WEDDING_CHAPEL", "#SIMS")
					ListNew("#GUESTS")

					local Count = 0

					if SimGetAge("") > 16 and not filterSims() then
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

						ListAdd("#GUESTS","")

						GetAliasByID(GetProperty("","WEDDING_SIM1(GUEST)"),"#SIM1")

						if not HasProperty("#SIM1","#WEDDING_GUESTS(Amount)") then
							SetProperty("#SIM1","#WEDDING_GUESTS(Amount)", -1)
						end

						local temp = GetProperty("#SIM1","#WEDDING_GUESTS(Amount)")

						SetProperty("#SIM1","#WEDDING_GUESTS(Amount)", temp+1)

						GetFreeLocatorByName("#WEDDING_CHAPEL", "Sit", Seat, Seat, "#POS", false)
						f_BeginUseLocator("", "#POS", GL_STANCE_SITBENCH, true)

						repeat
							local isOver = false
							Sleep(5)
							--GetAliasByID(GetProperty("","WEDDING_SIM1(GUEST)"),"#SIM1")
							--GetAliasByID(GetProperty("","WEDDING_SIM2(GUEST)"),"#SIM2")

							if HasProperty("","WEDDING_HOUR(GUEST)") then
								if HasProperty("#WEDDING_CHAPEL","DEBUG_IS_OVER") and GetProperty("#WEDDING_CHAPEL","DEBUG_IS_OVER") == 1 then
									RemoveProperty("","AttendingWedding")
									RemoveProperty("","WEDDING_HOUR(GUEST)")
									RemoveProperty("","WEDDING_SIM1(GUEST)")
									RemoveProperty("","WEDDING_SIM2(GUEST)")
									LogMessage(GetName("").." is leaving the ceremony.")
									f_ExitCurrentBuilding("")
									MoveSetActivity("")
									isOver = true
									StopMeasure("")
									break
								end
							end

						until (isOver == true)

						canStart = true
						break
					end

				else

					if not HasProperty("", "WEDDING_FORCED") and not HasProperty("","Busy") and HasProperty("", "WEDDING_HOUR(GUEST)") then

						FindNearestBuilding("", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "#WEDDING_CHAPEL")
						BuildingGetInsideSimList("#WEDDING_CHAPEL", "#SIMS")
						local count = ListSize("#SIMS")

						if count > 1 then 

							ListGetElement("#SIMS", Rand(count), "#DEST")

							if not HasProperty("#DEST","Busy") and HasProperty("#DEST", "WEDDING_HOUR(GUEST)") then

								SetProperty("#DEST","Busy",1)
								SetProperty("","Busy",1)

								f_WeakMoveTo("","#DEST",GL_MOVESPEED_WALK,128)
								f_WeakMoveTo("#DEST","",GL_MOVESPEED_WALK,128)

								AlignTo("","#DEST")
								AlignTo("#DEST","")

								LoopAnimation("", "talk", -1)

								local dialog = returnDialog()
								MsgSay("", dialog[1], dialog[2])

								StopAnimation("")

								LoopAnimation("#DEST", "talk", -1)

								local answer = {"Oh really?","Is that so?","I believe you must be right.","Never saw it this way but I see what you mean.","You're probably right.","Let's hope for the best."}

								MsgSay("#DEST", answer[Rand(6)+1])
								StopAnimation("#DEST")

								GetFleePosition("","#DEST",Rand(75)+150,"#POS")
								f_WeakMoveTo("","#POS")

								Sleep(6+Rand(4))

								RemoveProperty("#DEST","Busy")
								RemoveProperty("","Busy")

							end

						end

					end

					Sleep(Rand(10)+10)
				end

			end

		until (canStart == true)
		
	end

end

--[[
LogMessage(GetName("").." (GUEST) is leaving the ceremony.")
	if HasProperty("","#SEAT") then
		local seat = GetProperty("","#SEAT")
		GetFreeLocatorByName("#WEDDING_CHAPEL", "Sit", seat, seat, "#POS", false)
		f_EndUseLocator("", "#POS")
		RemoveProperty("","#SEAT")
		Sleep(1)
		f_ExitCurrentBuilding("")
		MoveSetActivity("")
		LogMessage("attempting to stop using seat")
	end
]]