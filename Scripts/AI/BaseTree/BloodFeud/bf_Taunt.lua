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
	return utility_Trace("dynasty", "bf_Taunt", 30)
end

function Execute()
	utility_Picked("dynasty", "bf_Taunt")
	SetRepeatTimer("SIM", "AI_BF_Taunt", 48)
	aitwp_Log("sends a taunting letter to " .. GetName("Victim"), "dynasty")
	MeasureCreate("Measure")
	MeasureAddData("Measure", "Choice", 2, false)
	MeasureAddData("Measure", "InitResult", 1, false)
	MeasureStart("Measure", "SIM", "Victim", "AdministrateDiplomacy")
end
