function Weight()
	if not ReadyToRepeat("dynasty", "AI_Repair") then
		return 0
	end

	if DynastyGetBuildingCount("dynasty", -1, -1) < 1 then
		return 0
	end

	local Worst = 1.0
	for i = 1, 5 do
		if DynastyGetRandomBuilding("dynasty", -1, -1, "REP_Try") then
			local HP = GetHPRelative("REP_Try")
			if HP and HP < Worst then
				Worst = HP
				CopyAlias("REP_Try", "REP_Target")
			end
		end
	end

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