function Weight()
	
	if IsDynastySim("SIM") then
		if not ai_GetWorkBuilding("SIM", GL_BUILDING_TYPE_DIVEHOUSE, "Divehouse") then
			return 0
		end
	else
		if not SimGetWorkingPlace("SIM", "Divehouse") then
			return 0
		end
	end

	if HasProperty("Divehouse", "ServiceActive") then
		return 0			
	end

	if HasProperty("Divehouse", "GoToService") then
		return 0			
	end

	local Time = math.mod(GetGametime(), 24)
	local TryTime

	if Time > 2 and Time < 10 then
		return 0
	end

	if HasProperty("Divehouse", "ServiceStartTime") then
		TryTime = GetProperty("Divehouse", "ServiceStartTime") + 4
		if TryTime < Time then
			return 0
		end
	end

	return 100
end

function Execute()
	SetProperty("Divehouse", "GoToService", 1)
	MeasureRun("SIM", "Divehouse", "AssignToServiceDivehouse", true)
end

