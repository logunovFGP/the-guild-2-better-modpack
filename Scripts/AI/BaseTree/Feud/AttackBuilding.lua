function Weight()
	
	local Difficulty = ScenarioGetDifficulty()
	
	if Difficulty < 2 then
		return 0
	end
	
	if Difficulty < 3 then
		if GetRound() < (4 - Difficulty) then
			return 0
		end
	end
	
	if not ReadyToRepeat("SIM", "AI_AttackRival") then
		return 0
	end
	
	if DynastyIsShadow("SIM") and DynastyIsShadow("Victim") then
		return 0
	end
	
	
	if not AliasExists("RivalBuild") then
		if not aitwp_FindTargetBuilding("VictimDynasty", -1, "strongest", "RivalBuild") then
			return 0
		end
	end
	
	if BuildingGetClass("RivalBuild") == GL_BUILDING_CLASS_RESOURCE then
		return 0
	end
	
	if DynastyIsShadow("SIM") then
		-- reduces aggressiveness of shadow dynasties. Traced, not bare: this returns a real
		-- weight and used to emit no ::TWP::W at all, so every shadow house scoring here
		-- counted as "no child scored" and inflated subtree-barren. 18 of 26 dynasties are
		-- shadow, which is most of the 87% that number reported on 2026-09-21.
		return utility_Trace("dynasty", "AttackBuilding", 3)
	end
	
	return utility_Trace("dynasty", "AttackBuilding", 20)
end

function Execute()
	utility_Picked("dynasty", "AttackBuilding")
	local Difficulty = ScenarioGetDifficulty()
	local Timer = 24 - Difficulty*4
	SetRepeatTimer("SIM", "AI_AttackRival", Timer)	
end