function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "banish") then
		return 0
	end
	
	if ScenarioGetDifficulty() < 2 then
		return 0
	end
	
	local Difficulty = ScenarioGetDifficulty()
	if GetRound() < (6 - Difficulty) then -- no early bans
		return 0
	end
	
	if GetImpactValue("SIM", "BanCharacter")==0 then
		return 0
	end
	
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("BanCharacter")) > 0 then
		return 0
	end
	
	if SimGetOffice("Victim","Office") then
		if OfficeGetLevel("Office")>=6 then
			return 0
		end
	end
	
	if DynastyIsShadow("Victim") then
		return 0
	end
	
	if GetDistance("SIM", "Victim") > 7000 then
		return 0
	end
	
	return 5
end

function Execute()
	MeasureRun("SIM", "Victim", "BanCharacter")
end

