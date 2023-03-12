function Weight()
	if GetImpactValue("SIM", "FlamingSpeech")==0 then
		return 0
	end
	
	if GetMeasureRepeat("SIM", "FlamingSpeech")>0 then
		return 0
	end
	
	if not GetNearestSettlement("SIM", "privfs_city") then
		return 0
	end
	
	if not chr_CityFindCrowdedPlace("privfs_city", "SIM", "privfs_dest") then
		return 0
	end

	return 100
end

function Execute()
	MeasureRun("SIM", "privfs_dest", "FlamingSpeech")
end
