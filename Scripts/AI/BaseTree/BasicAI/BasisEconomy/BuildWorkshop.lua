function Weight()
	if not ReadyToRepeat("dynasty", "BasicAI_NewWorkshop") then
		return 0
	end

	-- shadow dynasties don't build new workshops
	if DynastyIsShadow("dynasty") then
		return 0
	end
	
	-- Missing a title? Then the new workshop will have to wait.
	if not CanBuildWorkshop("dynasty") then
		return 0
	end
	
	if not (dyn_GetIdleMember("dynasty", "SIM") or DynastyGetMemberRandom("dynasty", "SIM")) then
		return 0
	end
	
	if not AliasExists("SIM") then
		return 0
	end
	
	if not GetHomeBuilding("SIM", "home") then
		return 0
	end
	
	if not BuildingGetCity("home", "HomeCity") then
		return 0
	end
	
	local Wealth = SimGetWealth("SIM")
	local Money = GetMoney("SIM")
	
	local ratio = math.floor(Money*100 / Wealth)
	if math.min(5, ratio) then
		return ratio
	end
	
	return 5
end

function Execute()
	local Difficulty = ScenarioGetDifficulty()
	local Timer = 48 - Difficulty * 6 -- easy: 2 days, medium: 3 days, hard: 1 days
	SetRepeatTimer("dynasty", "BasicAI_NewWorkshop", Timer)
end