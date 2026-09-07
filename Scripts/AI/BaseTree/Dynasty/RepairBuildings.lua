function Weight()
	if not ReadyToRepeat("dynasty", "AI_Repair") then
		return 0
	end

	if DynastyGetBuildingCount("dynasty", -1, -1) < 1 then
		return 0
	end

	-- the most damaged of all our buildings, not the worst of five dice rolls
	local Worst = aitwp_MostDamagedBuilding("dynasty", "REP_Target")

	if Worst > 0.85 or not AliasExists("REP_Target") then
		return 0
	end

	local Cost = BuildingGetRepairPrice("REP_Target")
	if GetMoney("dynasty") < Cost * 2 then
		return 0
	end

	if Worst < 0.5 then
		return utility_Trace("dynasty", "RepairBuildings", 60)
	end
	return utility_Trace("dynasty", "RepairBuildings", 25)
end

function Execute()
	utility_Picked("dynasty", "RepairBuildings")
	SetRepeatTimer("dynasty", "AI_Repair", 6)
	MeasureRun("REP_Target", 0, "RenovateBuilding", false)
end