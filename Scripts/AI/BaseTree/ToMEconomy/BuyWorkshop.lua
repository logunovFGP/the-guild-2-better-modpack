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
	
	local simclass = SimGetClass("SIM")
	local simrel = SimGetReligion("SIM")
	
	local n = CityGetBuildingCountForCharacter("HomeCity", simclass, simrel, FILTER_IS_BUYABLE) or 0
	local m = CityGetBuildingCountForCharacter("HomeCity", simclass, simrel, FILTER_NO_DYNASTY) or 0
  
  if n > 0 or m > 0 then
  	return 8
  end
  return 0
end

function Execute()
	aitwp_Log("Execute ToMEconomy::BuyWorkshop", "SIM", true)
	local Difficulty = ScenarioGetDifficulty()
	local Timer = 96 - Difficulty * 12 -- easy: 4 days, medium: 3 days, hard: 2 days
	SetRepeatTimer("dynasty", "BasicAI_NewWorkshop", Timer)

	ai_BuyRandomWorkshop("SIM")
end