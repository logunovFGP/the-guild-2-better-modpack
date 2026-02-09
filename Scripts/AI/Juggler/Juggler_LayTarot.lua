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

  if BuildingGetLevel("MyWork") < 2 then
      return 0
	end
	
	-- worker #4 will always do tarot
	if BuildingGetWorkerCount("MyWork") > 3 and BuildingGetWorker("MyWork", 3, "Worker") and GetID("SIM") == GetID("Worker") then
		return 100
	end
	
	-- all other worker will do other things
	return 0
end

function Execute()
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", Rand(3)+3)
	MeasureStart("Measure", "SIM", "jugglerPlay", "LayTarot")
end

