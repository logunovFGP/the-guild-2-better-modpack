-- Raid a player building with a thug once the dynasty's evidence against the player
-- reaches the razzia measure's own threshold of 35. Ladder rung 5 ("razzia"); the
-- cooldown is the thug's.
function Weight()
	if not AliasExists("MYRM") then
		return 0
	end
	if not aitwp_Allowed("dynasty", "PlayerDyn", "razzia") then
		return 0
	end
	if not ReadyToRepeat("MYRM", "AI_BF_Razzia") then
		return 0
	end
	if GetDynastyEvidenceValues("dynasty", "PlayerDyn") < 35 then
		return 0
	end
	if not aitwp_FindTargetBuilding("PlayerDyn", -1, "strongest", "RaidTarget") then
		return 0
	end
	return utility_Trace("dynasty", "bf_Razzia", 150)
end

function Execute()
	utility_Picked("dynasty", "bf_Razzia")
	SetRepeatTimer("MYRM", "AI_BF_Razzia", 24)
	aitwp_Log("raids " .. GetName("RaidTarget"), "dynasty")
	MeasureCreate("Measure")
	MeasureStart("Measure", "MYRM", "RaidTarget", "Razzia")
end
