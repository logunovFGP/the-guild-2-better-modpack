function Weight()
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end
	
	if ScenarioGetTimePlayed() < 24 then
		return 0
	end
	
	if SimGetAge("SIM") < 16 then
		return 0
	end
	
	if not ReadyToRepeat("SIM", "AI_Privilege") then
		return 0
	end
	
	if not f_SimIsValid("SIM") then
		return 0
	end
	
	-- TODO:  Check impacts for all relevant privileges
	local	Privilege = { "AbsolveSinner", "EmbezzlePublicMoney", "PropitiateEnemies", "Set_ChurchTithe", 
				   "Set_SeverityOfLaw", "Set_TurnoverTax", "LevelUpCity", "CurryFavor" }
	local PCount = 8
	local HasPrivilege = false
	
	for i=1, PCount do
		if GetImpactValue("SIM", Privilege[i])==1 then
			HasPrivilege = true
			break
		end
	end
	
	if not HasPrivilege then
		return 0
	end
	
	return utility_Score("dynasty", 3, {
		utility_Priority("dynasty", "Political"),
		utility_Trait("dynasty", "ambition"),
	}, "Privilege", "Politics")
end

function Execute()
	utility_Picked("dynasty", "Privilege")
	local Difficulty = ScenarioGetDifficulty()
	local Timer = 12 - Difficulty * 2
	SetRepeatTimer("SIM", "AI_Privilege", Timer)
end