function Weight()
	if not ReadyToRepeat("dynasty", "AI_CollectDebts") then
		return 0
	end

	if not DynastyGetRandomBuilding("dynasty", GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_BANKHOUSE, "CD_Bank") then
		return 0
	end

	local StolenCount = GetProperty("CD_Bank", "StolenCount") or 0
	if StolenCount < 1 then
		return 0
	end

	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end

	return 40
end

function Execute()
	SetRepeatTimer("dynasty", "AI_CollectDebts", 8)

	local BankID = GetID("CD_Bank")
	local Count = ScenarioGetObjects("cl_Sim", 9999, "CD_Sim")
	for i = 0, Count - 1 do
		local Alias = "CD_Sim"..i
		if HasProperty(Alias, "StolenSum") and HasProperty(Alias, "CreditBank") and GetProperty(Alias, "CreditBank") == BankID and not GetState(Alias, STATE_DEAD) then
			MeasureRun("SIM", Alias, "CollectDebts", false)
			return
		end
	end
end