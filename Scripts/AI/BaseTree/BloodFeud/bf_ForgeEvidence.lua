-- Forged evidence against the player's most valuable character. The target is
-- fixed in AI_EvidenceTarget until it has been charged (bf_Charge). The forgery is
-- a Sorcerer Document (II before I, each behind its own ladder rung: 6 and 5); the
-- artefact measure buys it at the market when the dynasty does not hold one, so
-- "needs to purchase the papers" is enforced by aitwp_ForgeryDocument, which only
-- returns a document that is owned or for sale.
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
	aitwp_Log("forges evidence against " .. GetName("Victim") .. " with " .. GetData("ForgeItem"), "dynasty")
	MeasureRun("SIM", "Victim", "Use" .. GetData("ForgeItem"))
end
