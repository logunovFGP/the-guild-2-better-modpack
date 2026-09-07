function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "VictimDynasty", "demolish") then
		return 0
	end
	
	if ScenarioGetDifficulty() < 3 then
		return 0
	end
	
	if GetImpactValue("SIM", "DemolishBuilding")==0 then
		return 0
	end
	
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("DemolishBuilding")) > 0 then
		return 0
	end

	-- the victim's most damaged building (or the building already under attack)
	RemoveAlias("db_House")
	if AliasExists("RivalBuild") then
		CopyAlias("RivalBuild", "db_House")
	else
		aitwp_MostDamagedBuilding("Victim", "db_House")
	end
	if AliasExists("db_House") and GetHPRelative("db_House") < 0.3 then
		return 20
	end
	return 0
	
end

function Execute()
	MeasureRun("SIM", "db_House", "DemolishBuilding")
end
