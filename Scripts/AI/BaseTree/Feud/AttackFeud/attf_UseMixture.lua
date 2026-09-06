function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "mixture") then
		return 0
	end
	local	Item = "Mixture"
	
	if not ReadyToRepeat("dynasty", "AIUse_Mixture") then
		return 0
	end
	
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Use"..Item)) > 0 then
		return 0
	end
	
	if GetItemCount("", Item, INVENTORY_STD)>0 then
		return 100
	end

	local Price = ai_CanBuyItem("SIM", Item)
	
	if Price < 0 then
		return 0
	end
	
	if GetMoney("SIM") < 5000 then
		return 0
	end
	
	if GetInsideBuilding("Victim","Inside") then
		return 0
	end

	return 5
end

function Execute()
	SetRepeatTimer("dynasty", "AIUse_Mixture", 24)
	MeasureRun("SIM", "Victim", "UseMixture", false)
end
