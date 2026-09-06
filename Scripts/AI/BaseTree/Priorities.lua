function Weight()
	utility_Tick("dynasty") -- counts root evaluations for the daily snapshot
	if not ReadyToRepeat("dynasty", "AI_Priorities") then
		return 0
	end
	return utility_Trace("dynasty", "Priorities", 50)
end

function Execute()
	utility_Picked("dynasty", "Priorities")
	SetRepeatTimer("dynasty", "AI_Priorities", 24)
	aitwp_CalculatePriorities("dynasty")
	-- blood enemies and relation-based enemy lists, then the goal blackboard
	-- (AI_Goal / AI_GoalTarget / AI_GoalUntil), then the daily telemetry line
	aitwp_EnsureBloodEnemies()
	aitwp_RefreshEnemies("dynasty")
	aitwp_PlayerPolicy("dynasty")
	aitwp_BloodDaily("dynasty")
	utility_ChooseGoal("dynasty")
	aitwp_Snapshot("dynasty")
end
