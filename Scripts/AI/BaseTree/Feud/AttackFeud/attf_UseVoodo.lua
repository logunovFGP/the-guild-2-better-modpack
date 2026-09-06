function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "voodoo") then
		return 0
	end
	local	Item = "Voodo"
	if not ReadyToRepeat("dynasty", "AIUse_Voodoo") then
		return 0
	end
	
	if ScenarioGetDifficulty() < 2 then
		return 0
	end
		
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Use"..Item)) > 0 then
		return 0
	end
	
	if GetImpactValue("Victim", "Sickness") > 0 then
		return 0
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

	return 10
end

function Execute()
	SetRepeatTimer("dynasty", "AIUse_Voodoo", 24)
	MeasureRun("SIM", "Victim", "UseVoodo", false)
end
