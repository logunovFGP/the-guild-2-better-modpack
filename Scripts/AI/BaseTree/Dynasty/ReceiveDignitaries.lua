function Weight()
	if not ReadyToRepeat("dynasty", "AI_ReceiveDignitaries") then
		return 0
	end

	local WarChooserID = GetData("#WarChooser")
	if not WarChooserID or WarChooserID == 0 then
		return 0
	end
	if not GetAliasByID(WarChooserID, "DIP_WarChooser") then
		return 0
	end

	local WarRisk = GetProperty("DIP_WarChooser", "WarRisk") or 0
	if WarRisk < 25 then
		return 0
	end

	if not DynastyGetRandomBuilding("dynasty", -1, GL_BUILDING_TYPE_ESTATE, "DIP_Estate") then
		return 0
	end

	if not BuildingHasUpgrade("DIP_Estate", "ImperialSignet") then
		return 0
	end

	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end

	return 35
end

function Execute()
	SetRepeatTimer("dynasty", "AI_ReceiveDignitaries", 48)
	if ai_GoInsideBuilding("SIM", "SIM", -1, -1, "DIP_Estate") then
		MeasureRun("SIM", 0, "EmpfangeWuerden", false)
	end
end