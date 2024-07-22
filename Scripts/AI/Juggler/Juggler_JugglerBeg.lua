function Weight()
	
	if not GetSettlement("SIM", "City") then
		return 0
	end
	
	if not chr_CityFindCrowdedPlace("City", "SIM", false, "jugglerPlay") then
		return 0
	end
	
	if not SimGetWorkingPlace("SIM", "MyWork") then
	    return 0
	end
	
	return 100
end

function Execute()
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", Rand(3)+3)
	MeasureStart("Measure", "SIM", "jugglerPlay", "JugglerBeg")
end

