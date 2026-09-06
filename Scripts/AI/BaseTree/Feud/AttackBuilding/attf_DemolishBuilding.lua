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

	local NumVictimBuildings = DynastyGetBuildingCount("Victim",-1,-1)
	for i=0,NumVictimBuildings do
		if not DynastyGetRandomBuilding("Victim",-1,-1,"db_House") then
			return 0
		end
		
		if AliasExists("RivalBuild") then
			CopyAlias("RivalBuild", "db_House")
		end
		
		if GetHPRelative("db_House") < 0.3 then
			return 20
		end
	end
	return 0
	
end

function Execute()
	MeasureRun("SIM", "db_House", "DemolishBuilding")
end
