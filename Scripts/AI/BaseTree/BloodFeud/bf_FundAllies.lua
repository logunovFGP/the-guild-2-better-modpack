-- Money to an AI ally (AdministrateDiplomacy gift, the smallest tier = 15% of cash)
-- so it stands with the house against the player. Ladder rung 4 ("fund_allies"),
-- blood rival only - it recruits others. Needs 200k in the treasury.
function Weight()
	if not aitwp_Allowed("dynasty", "PlayerDyn", "fund_allies") then
		return 0
	end
	if not ReadyToRepeat("dynasty", "AI_BF_Fund") then
		return 0
	end
	if GetMoney("dynasty") < 200000 then
		return 0
	end
	if not aitwp_FindAllyMember("dynasty", "AllyMember") then
		return 0
	end
	return utility_Trace("dynasty", "bf_FundAllies", 20)
end

function Execute()
	utility_Picked("dynasty", "bf_FundAllies")
	SetRepeatTimer("dynasty", "AI_BF_Fund", 120)
	aitwp_Log("funds its ally " .. GetName("AllyMember"), "dynasty")
	MeasureCreate("Measure")
	MeasureAddData("Measure", "Choice", 3, false)
	MeasureAddData("Measure", "InitResult", 0, false)
	MeasureStart("Measure", "SIM", "AllyMember", "AdministrateDiplomacy")
end
