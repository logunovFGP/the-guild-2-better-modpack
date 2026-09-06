function Weight()
	if not ReadyToRepeat("dynasty", "AI_DefendRogue") then
		return 0
	end
	
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end
	-- TODO: Check for dangerous rogues in town
	
	return utility_Score("dynasty", 5, {}, "DefendRogue", "Conflict")
end

function Execute()
	utility_Picked("dynasty", "DefendRogue")
	SetRepeatTimer("dynasty", "AI_DefendRogue", 6)
end