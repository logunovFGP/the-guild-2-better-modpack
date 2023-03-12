function Weight()

	if not GetSettlement("SIM", "City") then
		return 0
	end
	
	if not SimGetWorkingPlace("SIM", "WorkBuilding") then
		return 0
	end
	
	if not HasProperty("WorkBuilding", "ServiceActive") then
		return 0			
	end	
	
	local CrowdedLocation = chr_CityFindCrowdedPlace("City", "SIM", "Destination")
	if not CrowdedLocation then
		return 0
	end
	-- TODO use this to come back to old position
	SetProperty("SIM", "OutdoorPos", CrowdedLocation)

	if BuildingGetLevel("WorkBuilding") > 1 then
		if not HasProperty("WorkBuilding", "DanceShow") then
			return 33
		end	
	end

	return 100
end

function Execute()

	MeasureRun("SIM", "Destination", "AssignToLaborOfLove")
end

