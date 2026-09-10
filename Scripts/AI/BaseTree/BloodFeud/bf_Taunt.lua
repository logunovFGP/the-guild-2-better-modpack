-- A taunting letter (AdministrateDiplomacy, "Taunt them"): favour lost, scaled by
-- the writer's rhetoric. Ladder rung 1 ("taunt_letter"), blood rival only - it is a
-- reputation tool. Not while a feud is declared: the engine burns letters to foes.
function Weight()
	if not aitwp_Allowed("dynasty", "PlayerDyn", "taunt_letter") then
		return 0
	end
	if DynastyGetDiplomacyState("dynasty", "PlayerDyn") == DIP_FOE then
		return 0
	end
	if not ReadyToRepeat("SIM", "AI_BF_Taunt") then
		return 0
	end
	if not aitwp_FindPlayerTarget("PlayerDyn", "best", "Victim") then
		return 0
	end
	-- scored: the letter bites as hard as the writer's rhetoric
	-- siblings share the alias "Victim" and the engine runs every Weight() before the
	-- winner's Execute(); file it under this node so no sibling can take it
	aiboard_Stash("bf_Taunt", "Victim")
	return utility_Score("dynasty", 30, {
		{ value = utility_Norm(GetSkillValue("SIM", RHETORIC), 0, 10), curve = "linear" },
	}, "bf_Taunt")
end

function Execute()
	utility_Picked("dynasty", "bf_Taunt")
	if not aiboard_Claim("bf_Taunt", "BF_TauntVictim") then
		return
	end
	SetRepeatTimer("SIM", "AI_BF_Taunt", 48)
	aitwp_Log("sends a taunting letter to " .. GetName("BF_TauntVictim"), "dynasty")
	MeasureCreate("Measure")
	MeasureAddData("Measure", "Choice", 2, false)
	MeasureAddData("Measure", "InitResult", 1, false)
	MeasureStart("Measure", "SIM", "BF_TauntVictim", "AdministrateDiplomacy")
	aiboard_Drop("BF_TauntVictim")
end
