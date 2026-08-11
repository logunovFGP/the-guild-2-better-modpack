function OnLevelUp()
end

function Setup()

	if worldambient_CheckAmbient()==true then
		if BuildingGetLevel("") == 2 then
			worldambient_CreateKontorSim("", 2)
		elseif BuildingGetLevel("") == 3 then
			worldambient_CreateKontorSim("", 3)
		elseif BuildingGetLevel("") == 4 then
			worldambient_CreateKontorSim("", 1)
		end
	end
	
	SetProperty("", "kr_init_v2", 1)
	MeasureRun("", nil, "KontorMeasure")
end

function PingHour()
	if GetProperty("", "kr_init_v2") == nil then
		SetProperty("", "kr_init_v2", 1)
		RemoveProperty("", "kr_next_refresh")
		MeasureRun("", nil, "KontorMeasure", true)
		return
	end

	if GetCurrentMeasureName("") ~= "KontorMeasure" then
		MeasureRun("", nil, "KontorMeasure")
	end
end
