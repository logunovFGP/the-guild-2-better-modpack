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
	
	if not aitwp_FindBuilder("dynasty", "SIM") then
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
	
	local Money = GetMoney("SIM")

	-- the richer the dynasty, the more eager it is to expand
	if Money > 20000 then
		return utility_Trace("dynasty", "BuildWorkshop", 8)
	elseif Money > 5000 then
		return utility_Trace("dynasty", "BuildWorkshop", 3)
	end
	return 0
end

function Execute()
	utility_Picked("dynasty", "BuildWorkshop")
	aitwp_Log("Enter subtree ToMEconomy::BuildWorkshop", "SIM", true)
	local Difficulty = ScenarioGetDifficulty()
	local Timer = 96 - Difficulty * 12 -- easy: 4 days, medium: 3 days, hard: 2 days
	SetRepeatTimer("dynasty", "BasicAI_NewWorkshop", Timer)
end