function Weight()
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end

	local CurrentEnemy = aitwp_GetBestEnemy("dynasty")
	aitwp_Log("AI::Feud Current enemy ID = "..CurrentEnemy, "dynasty")
	if not CurrentEnemy or CurrentEnemy <= 0 then
		return 0
	end

	GetAliasByID(CurrentEnemy, "VictimDynasty")
	if not AliasExists("") then
		return 0
	end
	local SimID = dyn_GetValidMember("VictimDynasty")
	if SimID and SimID > 0 and GetAliasByID(SimID, "Victim") and AliasExists("Victim") then
		return utility_Score("dynasty", 30, {
			utility_Priority("dynasty", "Agressive"),
		}, "Feud", "Conflict") * aitwp_AttitudeFactor("dynasty", "VictimDynasty")
	end
	
	return 0
end

function Execute()
	utility_Picked("dynasty", "Feud")
end