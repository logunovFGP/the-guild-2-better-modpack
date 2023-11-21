function Weight()
	if not ReadyToRepeat("dynasty", "AI_Expand") then
		return 0
	end

	if not dyn_GetIdleMember("dynasty", "SIM") or not AliasExists("SIM") then
		return 0
	end
	
	return 10
end

function Execute()
	local Difficulty = ScenarioGetDifficulty()
	local Timer = 48 - Difficulty * 6 -- easy: 2 days, medium: 3 days, hard: 1 days
	SetRepeatTimer("dynasty", "AI_Expand", Timer)
end
