function Run()

	if not ai_GetWorkBuilding("", GL_BUILDING_TYPE_PIRAT, "WorkBuilding") then
		StopMeasure() 
	end 

	if not GetSettlement("WorkBuilding", "City") then
		StopMeasure()
	end
	
	if not BuildingGetOwner("WorkBuilding", "MyBoss") then
		StopMeasure()
	end
	
	if GetInsideBuilding("", "InsideBuilding") then
		f_ExitCurrentBuilding("")
	end

	if not AliasExists("Destination") then
		StopMeasure()
	end
	
	-- Move to Destination
	local Offset = Rand(350)
	f_MoveTo("", "Destination", GL_MOVESPEED_RUN, Offset)

	MeasureSetStopMode(STOP_NOMOVE)
	SetProperty("", "CocotteHasClient", 0)
	SetProperty("", "CocotteProvidesLove", 1)
	
	-- start the labor
	SetData("IsProductionMeasure", 0)
	SimSetProduceItemID("", -GetCurrentMeasureID(""), -1)
	SetData("IsProductionMeasure", 1)
	local CancelCount = 0 -- for AI

	while true do
	
		if HasProperty("", "OutdoorPos") and BuildingGetAISetting("WorkBuilding", "Produce_Selection") > 0 then
			local MyPos = GetProperty("", "OutdoorPos")
			GetOutdoorLocator("Crowded"..MyPos, 1, "Pos")
			CopyAlias("Pos", "Destination")
		end
		
		if GetDistance("", "Destination") > 600 then
			f_MoveTo("", "Destination", GL_MOVESPEED_WALK)
		end
		
		if Rand(10) == 0 then
			PlayAnimation("", "cogitate")
			f_Stroll("", 300, 3)
		end
		
		if Rand(3) == 0 then
			PlayAnimation("", "watch_for_guard")
		end
		
		-- some animation stuff
		local SimFilter = "__F( (Object.GetObjectsByRadius(Sim)==1000)AND(Object.HasDifferentSex())AND(Object.GetState(idle))AND NOT(Object.GetState(townnpc))AND(Object.MinAge(16))AND(Object.CanBeInterrupted(UseLaborOfLove))AND NOT(Object.HasImpact(FullOfLove)))"
		local NumSims = Find("", SimFilter, "Sims", -1)

		-- Found someone?
		if NumSims > 0 then
			local DestAlias = "Sims"..Rand(NumSims-1)
			AlignTo("", DestAlias)
			Sleep(1)
			local AnimTime = PlayAnimationNoWait("", "point_at")
			MsgSayNoWait("", "@L_PIRATE_LABOROFLOVE_PROPOSE")
			Sleep(AnimTime)
			
			-- Try to attract him. Bonus for high charisma.
			if Rand(101) > (50-GetSkillValue("", CHARISMA)) then
				MeasureRun(DestAlias, "", "UseLaborOfLove")
			else
				AddImpact(DestAlias, "FullOfLove", 1, 4)
			end
		else
			CancelCount = CancelCount +1 -- only for AI
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
		
		if CancelCount >= 20 and BuildingGetAISetting("WorkBuilding", "Produce_Selection") > 0 then
			StopMeasure()
			break
		end
		
		Sleep(3)
	end	
end

function CleanUp()
	StopAnimation("")
 	RemoveProperty("", "CocotteProvidesLove")
	if HasProperty("", "OutdoorPos") then
		local MyPos = GetProperty("", "OutdoorPos")
		RemoveProperty("WorkBuilding", "OutdoorPos"..MyPos)
		RemoveProperty("", "OutdoorPos")
	end
end

function GetOSHData(MeasureID)
end
