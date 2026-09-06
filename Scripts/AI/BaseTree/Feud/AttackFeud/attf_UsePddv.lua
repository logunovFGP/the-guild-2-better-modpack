function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "pddv") then
		return 0
	end
	local	Item = "Pddv"
	if not ReadyToRepeat("dynasty", "AIUse_Pddv") then
		return 0
	end
	
	if ScenarioGetDifficulty() < 2 then
		return 0
	end
	
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Usepddv")) > 0 then
		return 0
	end
	
	if GetItemCount("", Item, INVENTORY_STD)>0 then
		return 100
	end

	local Price = ai_CanBuyItem("SIM", Item)
	
	if Price < 0 then
		return 0
	end
	
	if GetMoney("SIM")<3000 then
		return 0
	end
	
	if GetInsideBuilding("Victim","Inside") then
		return 0
	end

	return 5
end

function Execute()
	SetRepeatTimer("dynasty", "AIUse_Pddv", 24)
	MeasureRun("SIM", "Victim", "Usepddv")
end
