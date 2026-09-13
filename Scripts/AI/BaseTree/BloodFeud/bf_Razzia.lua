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
	if GetDynastyEvidenceValues("dynasty", "PlayerDyn") < TWP_BF_RAZZIA_EVIDENCE then
		return 0
	end
	if not aitwp_FindTargetBuilding("PlayerDyn", -1, "strongest", "RaidTarget") then
		return 0
	end
	-- scored: how far past the 35 threshold the evidence is, and an aggressive house
	-- bf_Razzia and bf_UseBuildingArtefact both resolve "RaidTarget", with different
	-- filters, so the winner would raid the other one's building; file it per node
	aiboard_Stash("bf_Razzia", "RaidTarget")
	return utility_Score("dynasty", 150, {
		{ value = utility_Norm(GetDynastyEvidenceValues("dynasty", "PlayerDyn"), TWP_BF_RAZZIA_EVIDENCE, 100), curve = "linear" },
		utility_Priority("dynasty", "Agressive"),
	}, "bf_Razzia")
end

function Execute()
	utility_Picked("dynasty", "bf_Razzia")
	if not aiboard_Claim("bf_Razzia", "BF_RazziaTarget") then
		return
	end
	SetRepeatTimer("MYRM", "AI_BF_Razzia", 24)
	aitwp_Log("raids " .. GetName("BF_RazziaTarget"), "dynasty")
	MeasureCreate("Measure")
	MeasureStart("Measure", "MYRM", "BF_RazziaTarget", "Razzia")
	aiboard_Drop("BF_RazziaTarget")
end
