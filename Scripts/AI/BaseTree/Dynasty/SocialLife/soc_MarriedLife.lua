function Weight()
	if not ReadyToRepeat("dynasty", "AI_MarriedLife") then
		return 0
	end

	if not SimGetSpouse("SIM", "SOC_Spouse") then
		return 0
	end

	if GetState("SOC_Spouse", STATE_DEAD) or GetStateImpact("SOC_Spouse", "no_control") then
		return 0
	end

	if DynastyIsPlayer("SOC_Spouse") then
		return 0
	end

	if GetMoney("dynasty") < 1000 then
		return 0
	end

	local Hour = math.mod(GetGametime(), 24)
	if Hour < 9 or Hour > 20 then
		return 0
	end

	return 12
end

function Execute()
	SetRepeatTimer("dynasty", "AI_MarriedLife", 36)
	if Rand(2) == 0 then
		MeasureRun("SIM", "SOC_Spouse", "TakeABath", false)
	else
		MeasureRun("SIM", "SOC_Spouse", "InviteToDance", false)
	end
end