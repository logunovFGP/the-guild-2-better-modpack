-- What buying a workshop on the market is worth against its siblings. Workshop, the
-- routine visit, is a constant 60; raising this makes the AI shop more and manage less.
TOM_BUY_WORKSHOP_BASE = 45

-- Game hours between purchases, before the difficulty scaling below (easy 4 days, hard
-- 2). The shipping value is 96; at difficulty 4 that is 48 hours, so a one-day test run
-- evaluates this node once and proves nothing about the weight - session 5 logged exactly
-- one and so did session 6. Lowered to 13 on 2026-09-18 for the test runs: at difficulty
-- 4 the timer below then comes out negative, so the node is ready on every ToMEconomy
-- entry and one game day shows how often the AI really buys. Put it back to 96 before
-- shipping - it is a balance number, not a knob.
TOM_BUY_WORKSHOP_HOURS = 13

-- Which gate stopped it, as one ::TWP::WHY line. Lowering TOM_BUY_WORKSHOP_HOURS to 13 on
-- 2026-09-18 made the cooldown negative at difficulty 4 - always ready - and the node was
-- still scored exactly once in 28 evaluations, so the cooldown was never what held it back.
-- Eight early returns and no way to tell them apart is how that went unnoticed for a month.
local function Blocked(Gate)
	utility_Why("dynasty", "buyworkshop " .. Gate)
	return 0
end

function Weight()
	-- its own timer: this shared BasicAI_NewWorkshop with BuildWorkshop, so whichever
	-- fired first locked the other out for the whole cooldown
	if not ReadyToRepeat("dynasty", "AI_BuyWorkshop") then
		return Blocked("cooldown")
	end

	-- shadow dynasties don't build new workshops
	if DynastyIsShadow("dynasty") then
		return Blocked("shadow")
	end
	
	-- Missing a title? Then the new workshop will have to wait.
	if not CanBuildWorkshop("dynasty") then
		return Blocked("title")
	end

	if not (dyn_GetIdleMember("dynasty", "SIM") or DynastyGetMemberRandom("dynasty", "SIM")) then
		return Blocked("nomember")
	end
	
	if not AliasExists("SIM") then
		return Blocked("nomember")
	end
	
	if not GetHomeBuilding("SIM", "home") then
		return Blocked("nohome")
	end
	
	if not BuildingGetCity("home", "HomeCity") then
		return Blocked("nocity")
	end
	
	local simclass = SimGetClass("SIM")
	local simrel = SimGetReligion("SIM")
	
	local n = CityGetBuildingCountForCharacter("HomeCity", simclass, simrel, FILTER_IS_BUYABLE) or 0
	local m = CityGetBuildingCountForCharacter("HomeCity", simclass, simrel, FILTER_NO_DYNASTY) or 0
	local OnSale = n + m
	if OnSale < 1 then
		return Blocked("noneonsale")
	end
	-- scored: the more there are on the market and the fuller the treasury, the more
	-- worth buying one. It was a flat 8 against Workshop's constant 60, which is ~11%
	-- of the level when eligible and measured 1 pick in 34 (session 4, 2026-09-17) -
	-- "builds workshops but very rarely buys the ones on sale", the maintainer's report.
	return utility_Score("dynasty", TOM_BUY_WORKSHOP_BASE, {
		{ value = utility_Norm(OnSale, 1, 5), curve = "sqrt" },
		utility_Money("dynasty", 50000),
		-- no goal argument: ToMEconomy.lua already carries the Economy x3 at the root, and
		-- naming it here too would apply x0.3 to this leaf alone under any other goal - 20
		-- of the 25 dynasties in session 4 - which is most of what it is trying to fix
	}, "BuyWorkshop")
end

function Execute()
	utility_Picked("dynasty", "BuyWorkshop")
	aitwp_Log("Execute ToMEconomy::BuyWorkshop", "SIM", true)
	local Difficulty = ScenarioGetDifficulty()
	local Timer = TOM_BUY_WORKSHOP_HOURS - Difficulty * 12 -- easy: 4 days, hard: 2 days
	SetRepeatTimer("dynasty", "AI_BuyWorkshop", Timer)

	ai_BuyRandomWorkshop("SIM")
end