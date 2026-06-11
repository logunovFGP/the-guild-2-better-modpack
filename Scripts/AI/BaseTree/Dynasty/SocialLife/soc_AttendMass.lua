function Weight()
	if not ReadyToRepeat("dynasty", "AI_AttendMass") then
		return 0
	end

	if not GetSettlement("SIM", "SOC_City") then
		return 0
	end

	if CityGetNearestBuilding("SOC_City", "SIM", -1, GL_BUILDING_TYPE_CHURCH_CATH, -1, -1, FILTER_IGNORE, "SOC_Church") and GetImpactValue("SOC_Church", "MassInProgress") == 1 then
		return 30
	end

	if CityGetNearestBuilding("SOC_City", "SIM", -1, GL_BUILDING_TYPE_CHURCH_EV, -1, -1, FILTER_IGNORE, "SOC_Church") and GetImpactValue("SOC_Church", "MassInProgress") == 1 then
		return 30
	end

	return 0
end

function Execute()
	SetRepeatTimer("dynasty", "AI_AttendMass", 20)
	MeasureRun("SIM", "SOC_Church", "AttendMass", false)
end