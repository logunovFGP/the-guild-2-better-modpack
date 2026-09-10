-- Forged evidence against the player's most valuable character. The target is fixed
-- in AI_EvidenceTarget until it has been charged (bf_Charge). The forgery is a
-- Sorcerer Document (II before I, each behind its own ladder rung: 6 and 5) that the
-- SIM holds or the residence store hands over just in time (aitwp_ForgeryDocument,
-- aitwp_DrawFromStock); the feud cart buys or collects the papers, nobody walks.
function Weight()
	if not aitwp_EvidenceTarget("dynasty", "PlayerDyn", "Victim") then
		return 0
	end
	local Item = aitwp_ForgeryDocument("SIM", "dynasty", "PlayerDyn")
	if not Item then
		return 0
	end
	SetData("ForgeItem", Item)
	-- scored: the more valuable the victim and the heavier the paper (II forges two
	-- pieces), the more it is worth; an intriguing house forges more readily
	local Heavy = 0.5
	if Item == "HexerdokumentII" then
		Heavy = 1
	end
	-- siblings share the alias "Victim" and the engine runs every Weight() before the
	-- winner's Execute(); file it under this node so no sibling can take it
	aiboard_Stash("bf_ForgeEvidence", "Victim")
	return utility_Score("dynasty", 150, {
		{ value = utility_Norm(aitwp_PlayerTargetScore("Victim", "best") or 0, 20, 200), curve = "linear" },
		{ value = Heavy, curve = "linear" },
		utility_Priority("dynasty", "Intrigue"),
	}, "bf_ForgeEvidence")
end

function Execute()
	utility_Picked("dynasty", "bf_ForgeEvidence")
	if not aiboard_Claim("bf_ForgeEvidence", "BF_ForgeVictim") then
		return
	end
	local Item = GetData("ForgeItem")
	if GetItemCount("SIM", Item, INVENTORY_STD) == 0 and not aitwp_DrawFromStock("SIM", Item, 1) then
		return
	end
	aitwp_Log("forges evidence against " .. GetName("BF_ForgeVictim") .. " with " .. Item, "dynasty")
	MeasureRun("SIM", "BF_ForgeVictim", "Use" .. Item)
	aiboard_Drop("BF_ForgeVictim")
end
