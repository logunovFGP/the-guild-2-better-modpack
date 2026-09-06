function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "pamphlet") then
		return 0
	end
	
	if ScenarioGetDifficulty() < 2 then
		return 0
	end
	
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("AddPamphlet")) > 0 then
		return 0
	end
			
	return 100
end

function Execute()
	MeasureRun("SIM","VICTIM","AddPamphlet")
end

