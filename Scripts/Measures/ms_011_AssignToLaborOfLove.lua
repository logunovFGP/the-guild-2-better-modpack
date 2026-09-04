-- Income: attracting a man is Rand(101) > 50 - Charisma, so about 50% at Charisma 0
-- and 65% at 15. Radius 1000, opposite sex, 16+, not already FullOfLove. A man she
-- fails to charm ignores her 4 hours, one she wins over 6.
function Run()

	if not ai_GetWorkBuilding("", GL_BUILDING_TYPE_DIVEHOUSE, "WorkBuilding") then
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

	-- A player order arrives with the clicked spot already in Destination, and that
	-- must win: overwriting it here is what made her work where she stood. Only fall
	-- back to the persisted assigned area when we were handed nothing -- that covers
	-- the AI re-dispatch from idlelib_CocotteIdle, which anchors on the work building.
	-- Same guard as the identical block inside the loop below.
	if not AliasExists("Destination")
			and BuildingGetAISetting("WorkBuilding", "Enable") == 0
			and SimGetAssignedAreaID("") ~= SimGetWorkingPlaceID("") then
		SimGetAssignedArea("", "Destination")
	end

	LogMessage("@TALENT ms_011 entered, destination "..(AliasExists("Destination")
			and GetName("Destination") or "NONE").." leash from "..GetName(""))

	if not AliasExists("Destination") then
		StopMeasure()
	end
	
	-- Move to Destination
	local Offset = 150 + Rand(200) -- how far off her post she stands
	local PostLeash = 600 -- how far she may drift before walking back; must exceed Offset
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
	
		if HasProperty("", "OutdoorPos") and BuildingGetAISetting("WorkBuilding", "Enable") > 0 then
			local MyPos = GetProperty("", "OutdoorPos")
			if GetOutdoorLocator(MyPos, 1, "Pos") < 1 then
				--no locator found? Select Market then
				local Market = Rand(5)+1
				if not CityGetRandomBuilding("City", 5, 14, Market, -1, FILTER_IGNORE, "Pos") then
					break
				end
			end
			CopyAlias("Pos", "Destination")
		end
		
		if not AliasExists("Destination")
				and BuildingGetAISetting("WorkBuilding", "Enable") == 0
				and SimGetAssignedAreaID("") ~= SimGetWorkingPlaceID("") then
			SimGetAssignedArea("", "Destination")
		end
		
		if GetDistance("", "Destination") > PostLeash then
			f_MoveTo("", "Destination", GL_MOVESPEED_WALK, Offset)
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
			
			if not ReadyToRepeat(DestAlias, GetMeasureRepeatName2("UseLaborOfLove")) then
				AddImpact(DestAlias, "FullOfLove", 1, 6)
			end
			
			-- Try to attract him. Bonus for high charisma.
			if Rand(101) > (50-GetSkillValue("", CHARISMA)) then
				MeasureRun(DestAlias, "", "UseLaborOfLove")
			else
				AddImpact(DestAlias, "FullOfLove", 1, 4)
			end
		else
			CancelCount = CancelCount +1 -- only for AI
		end
		
		if BuildingGetAISetting("WorkBuilding", "Enable") > 0 and not HasProperty("", "OutdoorPos") then -- AI has no fixed pos? then get one.
			-- Find a good spot for AI
			local MaxDistance = 10000
			local trys = 20
			local DistanceFound = 0
			local BestDistance = MaxDistance
			local Found = false
				
			for i=1, trys do
				local LocName = "Crowded"..i
				if GetOutdoorLocator(LocName, 1, "Pos") and AliasExists("Pos") then
					if not HasProperty("WorkBuilding", "OutdoorPos"..LocName) then -- check if we already have one employee here
						DistanceFound = GetDistance("", "Pos") -- check how far that pos is
						if DistanceFound < BestDistance then
							BestDistance = DistanceFound
							CopyAlias("Pos", "Destination")
							-- store the locator NAME: it is read back via GetOutdoorLocator,
							-- which takes a name, and dive_AssignToLaborOfLove stores it the same way
							SetProperty("", "OutdoorPos", LocName)
							Found = true
							
							if BestDistance < 2000 then -- it's near? great, then don't waste any more time!
								break
							end
						end
					end
				end
			end
				
			if Found then
				local MyPos = GetProperty("", "OutdoorPos")
				SetProperty("WorkBuilding", "OutdoorPos"..MyPos, 1) -- set WorkBuilding pos
			else
				SetProperty("", "OutdoorPos", 0) -- this only happens on older maps or if maps are bugged
			end
		end
		
		if CancelCount >= 15 and BuildingGetAISetting("WorkBuilding", "Enable") > 0 then
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
	mdata_ShowTalentOSH(MeasureID)
end
