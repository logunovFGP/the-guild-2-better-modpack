-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_068_PickpocketPeople"
----
----	with this measure, the player can send a thief, to pickpocket people
---- impact HaveBeenPickpocketed
-------------------------------------------------------------------------------

-- changes: added about 50 base gold to all successful pickpocketings

function Run()
	
	if not SimGetWorkingPlace("", "WorkBuilding") then
		if IsPartyMember("") then
			local NextBuilding = ai_GetNearestDynastyBuilding("", GL_BUILDING_CLASS_WORKSHOP,GL_BUILDING_TYPE_THIEF)
			if not NextBuilding then
				return
			end
			CopyAlias(NextBuilding, "WorkBuilding")
		else
			return
		end
	end
	
	f_MoveTo("", "Destination", GL_MOVESPEED_RUN, Rand(300))
	f_Stroll("", 400, 3)
	--the time, a thief must wait to rob the same person again
	local TimeToWait = 8
	local Value
	local CancelCount = 0 -- only for AI
	
	while true do
	
		if HasProperty("", "OutdoorPos") and BuildingGetAISetting("WorkBuilding", "Produce_Selection") > 0 then
			local MyPos = GetProperty("", "OutdoorPos")
			GetOutdoorLocator("Crowded"..MyPos, 1, "Pos")
			CopyAlias("Pos", "Destination")
		end
	
		if IsStateDriven() then
			-- TimeOut
			if math.mod(GetGametime(), 24) < 7 then
				break
			end
		end
		
		local NumOfObjects = Find("Owner","__F((Object.GetObjectsByRadius(Sim)== 1100) AND NOT(Object.BelongsToMe()) AND NOT(Object.HasImpact(HaveBeenPickpocketed)) AND NOT(Object.GetState(cutscene))AND NOT(Object.GetProfession() == 18)AND NOT(Object.GetProfession() == 21)AND NOT(Object.GetProfession() == 25)AND NOT(Object.GetState(townnpc))AND(Object.MinAge(16)))","Sims",-1)
		if NumOfObjects >0 then
			local DestAlias = "Sims"..Rand(NumOfObjects-1)
			local DoIt = 1

			if IsPartyMember(DestAlias) then
				DoIt = 0
			end
			
			local VictimSkill		
			if IsDynastySim(DestAlias) then 
				VictimSkill = GetSkillValue(DestAlias, EMPATHY)
			else
				VictimSkill = Rand(6) + 1
			end
			
			if BuildingGetAISetting("WorkBuilding", "Produce_Selection") > 0 and not HasProperty("", "OutdoorPos") then -- AI has no fixed pos? then get one.
				-- Find a good spot for AI
				local MaxDistance = 10000
				local trys = 20
				local DistanceFound = 0
				local BestDistance = MaxDistance
				
				for i=1, trys do
					if GetOutdoorLocator("Crowded"..i, 1, "Pos") then
						if not HasProperty("WorkBuilding", "OutdoorPos"..i) then -- check if we already have one employee here
							DistanceFound = GetDistance("", "Pos") -- check how far that pos is
							if DistanceFound < BestDistance then
								BestDistance = DistanceFound
								CopyAlias("Pos", "Destination")
								SetProperty("", "OutdoorPos", i) -- save this for later
								
								if BestDistance < 2000 then -- it's near? great, then don't waste any more time!
									break
								end
							end
						end
					end
				end
				
				local MyPos = GetProperty("", "OutdoorPos")
				SetProperty("WorkBuilding", "OutdoorPos"..MyPos, 1) -- set WorkBuilding pos
			end
			
			if DoIt == 1 then
				if SendCommandNoWait(DestAlias, "BlockMe") then 
					if CheckSkill("", 2, VictimSkill) then
						SetData("Blocked", 1)
							
						f_MoveTo("", DestAlias, GL_MOVESPEED_WALK, 140)
						AlignTo("Owner", DestAlias)
						Sleep(0.7)
						PlayAnimation("Owner", "pickpocket")
						AddImpact(DestAlias, "HaveBeenPickpocketed", 1, TimeToWait)
						
						local ThiefLevel = SimGetLevel("")
						local VictimSpendValue = Rand(40) + ThiefLevel * 20 + 25
						
						if Rand(100) > (100-ThiefLevel*2) then
							VictimSpendValue = VictimSpendValue*3
						end
						
						IncrementXPQuiet("Owner", 15)
						chr_RecieveMoney("Owner", VictimSpendValue, "IncomeThiefs")
						--for the mission
						mission_ScoreCrime("", VictimSpendValue)
						-- Play a coin sound for the local player
						if dyn_IsLocalPlayer("") then
							PlaySound3D("", "Effects/coins_to_moneybag+0.wav", 1.0)
						end
						
						if IsPartyMember(DestAlias) then
						
							local Value = GetMoney(DestAlias) * 0.05
							if VictimSpendValue > Value then
								VictimSpendValue = Value
							end
							chr_SpendMoney(DestAlias, VictimSpendValue, "CostThiefs")
							
							if VictimSpendValue > 25 then
								feedback_MessageCharacter(DestAlias,
									"@L_THIEF_068_PICKPOCKETPEOPLE_MSG_VICTIM_HEAD_+0",
									"@L_THIEF_068_PICKPOCKETPEOPLE_MSG_VICTIM_BODY_+0", GetID(DestAlias), VictimSpendValue)
							end
						end
	
						Sleep(0.75)
						SetData("Blocked", 0)
					else
					
						SetData("Blocked", 1)
						f_MoveTo("", DestAlias, GL_MOVESPEED_WALK, 140)
						AlignTo("Owner", DestAlias)
						AddImpact(DestAlias, "HaveBeenPickpocketed", 1, TimeToWait)
						PlayAnimationNoWait("","pickpocket")
						Sleep(3)
						StopAnimation("")
						SetData("Blocked", 0)
						if chr_GetTitle(DestAlias) > 3 then
							chr_ModifyFavor(DestAlias,"",-5)
							CommitAction("pickpocket", "", "", DestAlias)
							feedback_OverheadComment(DestAlias,
								"@L_THIEF_068_PICKPOCKETPEOPLE_SCREAM_+0", false, true)
							if BuildingHasUpgrade("WorkBuilding", "ShadowCloak") then
								if GetState("", STATE_FIGHTING) == false then
									ms_068_pickpocketpeople_FastHide()
								end
							else
								f_MoveTo("", "WorkBuilding", GL_MOVESPEED_RUN, 0)
								StopAction("pickpocket", "")
								if BuildingGetAISetting("WorkBuilding", "Produce_Selection") > 0 then
									StopMeasure()
								else
									Sleep(20)
								end
							end
							f_MoveTo("", "Destination", GL_MOVESPEED_WALK, 50) -- go back
						end
					end
				end
			end	
		else
			if CancelCount >= 15 and BuildingGetAISetting("WorkBuilding", "Produce_Selection") > 0 then
				StopMeasure()
				break
			end
			
			CancelCount = CancelCount + 1
			f_Stroll("", 450, 4)	
		end
		Sleep(3)
	end
end

function BlockMe()
	while GetData("Blocked") == 1 do
		Sleep(4)
	end
end

function FastHide()

	StopAction("pickpocket", "")
	GetPosition("", "standPos")
	PlayAnimationNoWait("", "crouch_down")
	Sleep(1)
	local filter ="__F((Object.GetObjectsByRadius(Building) == 1300))"
	local k = Find("", filter, "Umgebung", 15)
	if k > 0 then
		GfxAttachObject("tarn", "Handheld_Device/barrel_new.nif")
	else
		GfxAttachObject("tarn", "Outdoor/Bushes/bush_08_big.nif")
	end
	GfxSetPositionTo("tarn", "standPos")
	SetState("", STATE_INVISIBLE, true)
	Sleep(10)

	SimBeamMeUp("", "standPos", false)
	GfxDetachAllObjects()
	SetState("", STATE_INVISIBLE, false)
	PlayAnimationNoWait("", "crouch_up")
end

function CleanUp()
	
	GfxDetachAllObjects()
	StopAnimation("")
	StopAction("pickpocket", "")
	if HasProperty("", "OutdoorPos") then
		local MyPos = GetProperty("", "OutdoorPos")
		RemoveProperty("WorkBuilding", "OutdoorPos"..MyPos)
		RemoveProperty("", "OutdoorPos")
	end
end

