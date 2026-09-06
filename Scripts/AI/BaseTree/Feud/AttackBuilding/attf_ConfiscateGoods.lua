function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "VictimDynasty", "confiscate") then
		return 0
	end
	if GetImpactValue("SIM", "ConfiscateGoods") == 0 then
		return 0
	end
	
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("ConfiscateGoods")) > 0 then
		return 0
	end
	
	if not aitwp_FindTargetBuilding("Victim", GL_BUILDING_CLASS_WORKSHOP, "strongest", "VictimWorkshop") then
		return 0
	end
	
	if AliasExists("RivalBuild") then
		CopyAlias("RivalBuild", "VictimWorkshop")
	end
		
	return 20
end

function Execute()
	MeasureRun("SIM", "VictimWorkshop", "ConfiscateGoods")
end

