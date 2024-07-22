function Weight()

	if not GetSettlement("SIM", "City") then
		return 0
	end
	
	if IsDynastySim("SIM") or SimGetGender("SIM", GL_GENDER_MALE) then
		return 0
	end
	
	if not SimGetWorkingPlace("SIM", "WorkBuilding") then
		return 0
	end
	
	if not HasProperty("WorkBuilding", "ServiceActive") then
		return 0			
	end	
	
	local CrowdedLocation = chr_CityFindCrowdedPlace("City", "SIM", false, "Destination")
	if not AliasExists("Destination") then
		return 0
	end

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

