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
	-- scored: how far past the 35 threshold the evidence is, and an aggressive house
	return utility_Score("dynasty", 150, {
		{ value = utility_Norm(GetDynastyEvidenceValues("dynasty", "PlayerDyn"), 35, 100), curve = "linear" },
		utility_Priority("dynasty", "Agressive"),
	}, "bf_Razzia")
end

function Execute()
	utility_Picked("dynasty", "bf_Razzia")
	SetRepeatTimer("MYRM", "AI_BF_Razzia", 24)
	aitwp_Log("raids " .. GetName("RaidTarget"), "dynasty")
	MeasureCreate("Measure")
	MeasureStart("Measure", "MYRM", "RaidTarget", "Razzia")
end
