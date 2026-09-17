-- A hideout for the feud: a thieves' guild - the base for kidnapping, burglary and
-- pickpocketing - whatever the house's class. Bought when one is for sale in the
-- home town, built otherwise (the engine picks the plot: ai_BuildNewWorkshop, with
-- the [AI] OverflowBuildOutside setting deciding whether it goes outside the walls).
-- From ladder rung 2, with 30k in the treasury.
function Weight()
	if aitwp_Rung("dynasty", "PlayerDyn") < 2 then
		return 0
	end
	if not ReadyToRepeat("dynasty", "AI_BF_Hideout") then
		return 0
	end
	if DynastyGetBuildingCount("dynasty", GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_THIEF) > 0 then
		return 0
	end
	if GetMoney("dynasty") < TWP_BF_HIDEOUT then
		return 0
	end
	if not aitwp_Residence("dynasty", "home") or not GetSettlement("home", "City") then
		return 0
	end
	-- scored: the treasury and how far up the ladder the feud already is
	return utility_Score("dynasty", 50, {
		{ value = utility_Norm(GetMoney("dynasty"), TWP_BF_HIDEOUT, 300000), curve = "sqrt" },
		{ value = utility_Norm(aitwp_Rung("dynasty", "PlayerDyn"), 2, 8), curve = "linear" },
	}, "bf_Hideout")
end

function Execute()
	utility_Picked("dynasty", "bf_Hideout")
	SetRepeatTimer("dynasty", "AI_BF_Hideout", 72)
	-- re-resolved: "City" was set in Weight(), before every sibling ran
	if aitwp_Residence("dynasty", "home") and GetSettlement("home", "City")
			and CityGetNearestBuilding("City", "SIM", GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_THIEF, -1, -1, FILTER_IS_BUYABLE, "ForSale") then
		aitwp_Log("buys a hideout: " .. GetName("ForSale"), "dynasty")
		MeasureRun("ForSale", "SIM", "BuyBuilding", true)
	else
		aitwp_Log("builds a hideout", "dynasty")
		ai_BuildNewWorkshop("SIM", GL_BUILDING_TYPE_THIEF)
	end
end
