function Weight()

	if not GetSettlement("SIM", "City") then
		return 0
	end
	
	if not chr_CityFindCrowdedPlace("City", "SIM", "pos") then
		return 0
	end
	
	return 0 -- 80
end

function Execute()
    MeasureRun("SIM", "pos", "HushMoney")
end
