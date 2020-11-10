function Weight()

	if IsDynastySim("SIM") then
		return 0
	end
	
	if not SimGetWorkingPlace("SIM", "Tavern") then
		return 0
	end
	
	local Producer = BuildingGetProducerCount("Tavern", PT_MEASURE, "AssignEmployeeToService")
	if Producer > 0 then
		return 0
	end

	if not SimCanWorkHere("SIM", "Tavern") then
		return 0
	end

	if HasProperty("Tavern", "ServiceActive") then
		return 0			
	end
	
	if HasProperty("Tavern", "GoToService") then
		return 0			
	end
	
	local Time = math.mod(GetGametime(), 24)
	
	if 2 < Time and Time < 10 then
		return 0
	end

	return 100
end

function Execute()
	SetProperty("Tavern","GoToService",1)
	MeasureCreate("Measure")
	MeasureStart("Measure", "SIM", "Tavern", "AssignEmployeeToService")
end

