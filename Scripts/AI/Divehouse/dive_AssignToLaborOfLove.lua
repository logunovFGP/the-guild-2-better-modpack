function Weight()

	if not GetSettlement("SIM", "City") then
		return 0
	end
	
	if IsDynastySim("SIM") then
		return 0
	end	

	if not SimGetWorkingPlace("SIM", "WorkBuilding") then
		return 0
	end
	
	if not HasProperty("WorkBuilding", "ServiceActive") then
		return 0			
	end	
	
	-- Find a good spot for AI
	local MaxDistance = 10000
	local trys = 20
	local DistanceFound = 0
	local BestDistance = MaxDistance
	local Found = false	
		
	for i=1, trys do
		if GetOutdoorLocator("Crowded"..i, 1, "Pos") then
			if not HasProperty("WorkBuilding", "OutdoorPos"..i) then -- check if we already have one employee here
				DistanceFound = GetDistance("SIM", "Pos") -- check how far that pos is
				if DistanceFound < BestDistance then
					Found = true
					BestDistance = DistanceFound
					CopyAlias("Pos", "Destination")
					SetProperty("SIM", "OutdoorPos", i) -- save this for later
							
					if BestDistance < 2000 then -- it's near? great, then don't waste any more time!
						break
					end
				end
			end
		end
	end
	
	if Found then
		local MyPos = GetProperty("SIM", "OutdoorPos")
		SetProperty("WorkBuilding", "OutdoorPos"..MyPos, 1) -- set WorkBuilding pos
	end
	
	if not AliasExists("Destination") then
		-- still no Destination? Select Market then
		local Market = Rand(5)+1
		if not CityGetRandomBuilding("City", 5, 14, Market, -1, FILTER_IGNORE, "Destination") then
			return 0
		end
	end

	if BuildingGetLevel("WorkBuilding") > 1 then
		if not HasProperty("MyWork", "DanceShow") then
			return 33
		end	
	end

	return 100
end

function Execute()

	MeasureRun("SIM", "Destination", "AssignToLaborOfLove")
end

