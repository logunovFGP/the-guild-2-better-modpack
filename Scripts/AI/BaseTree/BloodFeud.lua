-- The blood feud. One coloured AI dynasty per human player is that player's blood
-- enemy (aitwp_EnsureBloodEnemies, chosen daily in Priorities) and runs this
-- subtree with everything it has: provoked duels, forged evidence and charges,
-- raids, ambushes on the road, a standing gang, and equipment for the whole house.
-- Aliases for the children: PlayerDyn (the player), SIM (an idle party member),
-- MYRM (an idle thug when there is one).
function Weight()
	local PlayerID = GetProperty("dynasty", "AI_BloodEnemyOf") or 0
	if PlayerID <= 0 then
		return 0
	end
	if not GetAliasByID(PlayerID, "PlayerDyn") or not AliasExists("PlayerDyn") or DynastyIsDead("PlayerDyn") then
		return 0
	end
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end
	RemoveAlias("MYRM")
	dyn_GetIdleMyrmidon("dynasty", "MYRM")
	return utility_Score("dynasty", 60, {}, "BloodFeud")
end

function Execute()
	utility_Picked("dynasty", "BloodFeud")
	aitwp_Log("Enter subtree BloodFeud", "dynasty")
end
