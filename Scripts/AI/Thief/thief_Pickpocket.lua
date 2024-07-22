function Weight()
	local Time = math.mod(GetGametime(), 24)
	if Time < 6 and Time > 21 then	
		return 0
	end
	
	if not GetSettlement("SIM", "City") then
		return 0
	end
	
	if not SimGetWorkingPlace("SIM", "WorkBuilding") then
		return 0
	end
	
	local CrowdedLocation = chr_CityFindCrowdedPlace("City", "SIM", false, "Destination")
	if not CrowdedLocation then
		return 0
	end
	-- TODO use this to come back to old position
	SetProperty("SIM", "OutdoorPos", CrowdedLocation)
			
	return 100
end

function Execute()
	thief_StartPickpocket("WorkBuilding", "SIM")
end

