function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "VictimDynasty", "disappropriate") then
		return 0
	end
	if GetImpactValue("SIM", "Disappropriate") == 0 then
		return 0
	end
	
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Disappropriate")) > 0 then
		return 0
	end
	
	if not aitwp_FindTargetBuilding("Victim", GL_BUILDING_CLASS_WORKSHOP, "strongest", "VictimWorkshop") then
		return 0
	end
	
	if AliasExists("RivalBuild") then
		CopyAlias("RivalBuild", "VictimWorkshop")
	end
	
	if GetRound() < 3 then
		return 0
	end

	return 10
end

function Execute()
	MeasureRun("SIM", "VictimWorkshop", "Disappropriate")
end

