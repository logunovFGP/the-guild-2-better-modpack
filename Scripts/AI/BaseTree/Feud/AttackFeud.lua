function Weight()
	
	local Difficulty = ScenarioGetDifficulty()
	
	if Difficulty < 3 then
		if GetRound() < (4 - Difficulty) then
			return 0
		end
	end
	
	-- only important shadows attack enemies
	if DynastyIsShadow("SIM") then
		if SimGetOfficeLevel("SIM")<0 then
			if DynastyGetBuildingCount2("SIM") == 0 then
				return 0
			end
		end
	end
	
	if not ReadyToRepeat("SIM", "AI_AttackFeud") then
		return 0
	end
	
	-- don't attack shadow enemies
	if DynastyIsShadow("Victim") then
		return 0
	end
	
	-- don't attack characters who are inside a building
	if GetInsideBuilding("Victim","Inside") then
		return 0
	end
	
	if GetDistance("SIM", "Victim") > 10000 then
		return 0
	end
	
	if DynastyIsShadow("SIM") and DynastyIsShadow("Victim") then
		return 0
	end
	
	if DynastyIsShadow("SIM") then
		-- reduces aggressiveness of shadow dynasties. Traced, not bare: this returns a real
		-- weight and used to emit no ::TWP::W at all, so every shadow house scoring here
		-- counted as "no child scored" and inflated subtree-barren. 18 of 26 dynasties are
		-- shadow, which is most of the 87% that number reported on 2026-09-21.
		return utility_Trace("dynasty", "AttackFeud", 5)
	end
	
	return utility_Trace("dynasty", "AttackFeud", 30)
end

function Execute()
	utility_Picked("dynasty", "AttackFeud")
	local Difficulty = ScenarioGetDifficulty()
	local Timer = 13 - Difficulty*3
	SetRepeatTimer("SIM", "AI_AttackFeud", Timer)	
end