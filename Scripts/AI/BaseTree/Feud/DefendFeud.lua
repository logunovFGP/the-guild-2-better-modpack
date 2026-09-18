function Weight()

	if not ReadyToRepeat("SIM", "AI_DefendFeud") then
		return 0
	end
	
	local EnemyCount = aitwp_DynastyGetNumOfEnemies("SIM")
	if EnemyCount < 1 then
		return 0
	end
	
	return utility_Trace("dynasty", "DefendFeud", 20)
end

function Execute()
	utility_Picked("dynasty", "DefendFeud")
	SetRepeatTimer("SIM", "AI_DefendFeud", 3)
end