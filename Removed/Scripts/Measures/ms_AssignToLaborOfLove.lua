function Run()

	if not ai_GetWorkBuilding("", GL_BUILDING_TYPE_PIRAT, "WorkBuilding") then
		StopMeasure() 
		return
	end 

	if not GetSettlement("WorkBuilding", "City") then
		return
	end
	
	if not BuildingGetOwner("WorkBuilding", "MyBoss") then
		StopMeasure()
		return
	end
	
	if GetInsideBuilding("", "InsideBuilding") then
		f_ExitCurrentBuilding("")
	end

	-- Find a good spot for AI
	if not AliasExists("Destination") then
		if not chr_CityFindCrowdedPlace("City", "", "Destination") then
			StopMeasure()
		end 
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

	while true do
		if GetDistance("", "Destination") > 500 then
			-- Go back to start location
			if not f_MoveTo("", "Destination", GL_MOVESPEED_WALK) then
				return
			end
		end
		
		if Rand(10) == 0 then
			PlayAnimation("", "cogitate")
			f_Stroll("", 250, 3)
		end
		

		PlayAnimation("", "watch_for_guard")
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
		end
		
		Sleep(2)
	end	
end

function CleanUp()
	StopAnimation("")
 	RemoveProperty("", "CocotteProvidesLove")
end

function GetOSHData(MeasureID)
end
