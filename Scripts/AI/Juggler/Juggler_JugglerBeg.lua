function Weight()
	
	if not GetSettlement("SIM", "City") then
		return 0
	end
	
	if not chr_CityFindCrowdedPlace("City", "SIM", "jugglerPlay") then
		return 0
	end
	
	if not SimGetWorkingPlace("SIM", "MyWork") then
	    return 0
	end
	
	local WorkerCount = BuildingGetWorkerCount("MyWork")
	-- worker #1 will always beg
	if BuildingGetWorkerCount("MyWork") > 0 and BuildingGetWorker("MyWork", 0, "Worker") and GetID("SIM") == GetID("Worker") then
		return 100
	end
	
	-- all other worker will do other things
	return 0
end

function Execute()
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", 14)
	MeasureStart("Measure", "SIM", "jugglerPlay", "JugglerBeg")
end

