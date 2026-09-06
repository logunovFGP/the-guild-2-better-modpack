function Weight()
	if not AliasExists("SIM") then
		return 0
	end
	if GetState("SIM", STATE_DEAD) or GetState("SIM", STATE_CUTSCENE) then
		return 0
	end

	local Quote = GetHPRelative("SIM")
	if not Quote or Quote > 0.5 then
		return 0
	end

	local Item = "MediPack"
	if GetItemCount("", Item, INVENTORY_STD) > 0 then
		return utility_Trace("dynasty", "SelfHeal", 90)
	end

	local Price = ai_CanBuyItem("SIM", Item)
	if not Price or Price < 0 then
		return 0
	end
	if Price > GetMoney("SIM") * 0.25 then
		return 0
	end
	return utility_Trace("dynasty", "SelfHeal", 60)
end

function Execute()
	utility_Picked("dynasty", "SelfHeal")
	MeasureRun("SIM", "SIM", "UseMediPack")
end
