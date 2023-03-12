function Weight()
	
	if not GetSettlement("SIM", "City") then
		return 0
	end
	
	if not CityFindCrowdedPlace("City", "SIM", "jugglerPlay") then
		return 0
	end
	
	if SimGetWorkingPlace("SIM", "MyWork") then
	    if BuildingGetLevel("MyWork") < 3 then
		    return 0
		end
	else
	    return 0
	end
	
	return 100
end

function Execute()
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", Rand(3)+3)
	MeasureStart("Measure", "SIM", "jugglerPlay", "TellFortune")
end

