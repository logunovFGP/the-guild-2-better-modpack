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
	return utility_Trace("dynasty", "bf_ForgeEvidence", 150)
end

function Execute()
	utility_Picked("dynasty", "bf_ForgeEvidence")
	local Item = GetData("ForgeItem")
	if GetItemCount("SIM", Item, INVENTORY_STD) == 0 and not aitwp_DrawFromStock("SIM", Item, 1) then
		return
	end
	aitwp_Log("forges evidence against " .. GetName("Victim") .. " with " .. Item, "dynasty")
	MeasureRun("SIM", "Victim", "Use" .. Item)
end
