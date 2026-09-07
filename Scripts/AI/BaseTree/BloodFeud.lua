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
	-- an entry that found every child at 0 wastes the tick (session 2: 85 of 110). After
	-- one, weigh 15 for up to three hours or until a child fires (utility_Picked keeps
	-- AI_BF_Fired for every bf_ node).
	local W = 60
	local Entered, Fired = GetProperty("dynasty", "AI_BF_Entered") or 0, GetProperty("dynasty", "AI_BF_Fired") or 0
	if Entered > Fired and GetGametime() - Entered < 3 then
		W = 15
	end
	return utility_Score("dynasty", W, {
		utility_Priority("dynasty", "Agressive"),
	}, "BloodFeud")
end

function Execute()
	utility_Picked("dynasty", "BloodFeud")
	SetProperty("dynasty", "AI_BF_Entered", GetGametime())
	aitwp_Log("Enter subtree BloodFeud", "dynasty")
end
