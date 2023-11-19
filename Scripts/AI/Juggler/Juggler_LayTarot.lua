function Weight()
	
	if not GetSettlement("SIM", "City") then
		return 0
	end
	
	if not chr_CityFindCrowdedPlace("City", "SIM", "jugglerPlay") then
		return 0
	end
	
	if SimGetWorkingPlace("SIM", "MyWork") then
	    if BuildingGetLevel("MyWork") < 2 then
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
	MeasureStart("Measure", "SIM", "jugglerPlay", "LayTarot")
end

