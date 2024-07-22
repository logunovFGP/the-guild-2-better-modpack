function Weight()
	
	if not SimGetWorkingPlace("SIM", "Tavern") then
		return 0
	end
	
	local Time = math.mod(GetGametime(), 24)
	
	if Time > 2 and Time < 10 then
		return 0
	end

	if bld_CalcServiceNeed("Tavern", "SIM") > 0 then
		return 100
	else
		return 0
	end
end

function Execute()
	MeasureCreate("Measure")
	MeasureStart("Measure", "SIM", "Tavern", "AssignEmployeeToService")
end

