function Weight()
	local Time = math.mod(GetGametime(), 24)
	if Time<6 and Time>21 then	
		return 0
	end
	
	if not GetSettlement("SIM", "City") then
		return 0
	end
	
	if not SimGetWorkingPlace("SIM", "WorkBuilding") then
		return 0
	end
	
	-- Find a good spot for AI
	local MaxDistance = 10000
	local trys = 20
	local DistanceFound = 0
	local BestDistance = MaxDistance
				
	for i=1, trys do
		if GetOutdoorLocator("Crowded"..i, 1, "Pos") then
			if not HasProperty("WorkBuilding", "OutdoorPos"..i) then -- check if we already have one employee here
				DistanceFound = GetDistance("SIM", "Pos") -- check how far that pos is
				if DistanceFound < BestDistance then
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
			
	return 100
end

function Execute()
	local MyPos = GetProperty("SIM", "OutdoorPos")
	SetProperty("WorkBuilding", "OutdoorPos"..MyPos, 1) -- set WorkBuilding pos
	
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", 2)
	MeasureStart("Measure", "SIM", "Destination", "PickpocketPeople")
end

