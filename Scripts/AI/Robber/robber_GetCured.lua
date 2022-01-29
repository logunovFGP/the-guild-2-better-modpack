function Weight()

	if GetHPRelative("SIM") >= 0.85 then
		return 0
	end
	
	if not SimGetWorkingPlace("SIM", "Robbernest") then
		return 0
	end
	
	if not BuildingHasUpgrade("Robbernest", "Campfire") then
		return 0
	end
	
	return 100
end

function Execute()
	SetProperty("SIM", "SpecialMeasureId", -MeasureGetID("GetCured"))
end

