function Weight()
	if not ReadyToRepeat("dynasty", "AI_CollectDebts") then
		return 0
	end

	if not aitwp_OwnBuildingByTurn("dynasty", GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_BANKHOUSE, "CD_Bank", "Bank") then
		return 0
	end

	local StolenCount = GetProperty("CD_Bank", "StolenCount") or 0
	if StolenCount < 1 then
		return 0
	end

	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end

	return utility_Score("dynasty", 40, {
		utility_Trait("dynasty", "greed"),
	}, "CollectBankDebts", "Economy")
end

function Execute()
	utility_Picked("dynasty", "CollectBankDebts")
	SetRepeatTimer("dynasty", "AI_CollectDebts", 8)

	local BankID = GetID("CD_Bank")
	local Count = ScenarioGetObjects("cl_Sim", 9999, "CD_Sim")
	for i = 0, Count - 1 do
		local Alias = "CD_Sim"..i
		if HasProperty(Alias, "StolenSum") and HasProperty(Alias, "CreditBank") and GetProperty(Alias, "CreditBank") == BankID and not GetState(Alias, STATE_DEAD) then
			LogMessage("@BANK AICollect bank=" .. BankID .. " target=" .. GetName(Alias) ..
					" stolen=" .. GetProperty(Alias, "StolenSum"))
			MeasureRun("SIM", Alias, "CollectDebts", false)
			return
		end
	end

	-- StolenCount claimed a defaulter and the sweep found none: the count has drifted
	-- away from the sims, which is what the CollectDebts "more time" branch used to do
	LogMessage("@BANK AICollect bank=" .. BankID .. " no debtor found, StolenCount=" ..
			tostring(GetProperty("CD_Bank", "StolenCount")))
end