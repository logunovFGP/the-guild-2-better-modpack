function Weight()
	if not AliasExists("SIM") then
		return 0
	end
	if GetState("SIM", STATE_DEAD) or GetState("SIM", STATE_CUTSCENE) then
		return 0
	end

	local Item = "CrossOfProtection"
	if ScenarioGetDifficulty() < 2 then
		return 0
	end
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Use"..Item)) > 0 then
		return 0
	end

	local bThreat = false
	local NumDynasties = ScenarioGetObjects("cl_Dynasty", 99, "ThreatDyn")
	local i
	for i = 0, NumDynasties - 1 do
		if DynastyGetDiplomacyState("dynasty", "ThreatDyn"..i) == DIP_FOE then
			bThreat = true
			break
		end
	end
	if not bThreat then
		return 0
	end

	if GetItemCount("", Item, INVENTORY_STD) > 0 then
		return 35
	end

	local Price = ai_CanBuyItem("SIM", Item)
	if not Price or Price < 0 then
		return 0
	end
	if ItemGetBasePrice(Item) > GetMoney("SIM") * 0.10 then
		return 0
	end
	return 8
end

function Execute()
	MeasureRun("SIM", "SIM", "UseCrossOfProtection")
end
