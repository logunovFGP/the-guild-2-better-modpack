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
	-- no HTN method applies, so every child weighs 0 and the tick is not worth
	-- spending; the ::TWP::HTN line names the precondition that fell first
	if aihtn_Step("dynasty") == "-" then
		return 0
	end
	-- The W = 15 dampener that used to sit here is gone (2026-09-18). It weighed the
	-- subtree down for three hours after an entry that fired no leaf, back when 85 of 110
	-- entries were barren. The planner gate above ended that: 0 of 17 on 2026-09-18. What
	-- the dampener still caught was the ordinary window between entering the subtree and
	-- the leaf firing, when AI_BF_Entered is newer than AI_BF_Fired by construction - 26
	-- of 101 evaluations, each one cutting a healthy subtree from ~41 to ~11 against a
	-- level totalling ~166. A guard whose every remaining trigger is a false positive is
	-- not a guard. The gate decides now, on whether a method applies, which is the
	-- question the dampener was always a proxy for.
	return utility_Score("dynasty", 60, {
		utility_Priority("dynasty", "Agressive"),
	}, "BloodFeud")
end

function Execute()
	utility_Picked("dynasty", "BloodFeud")
	aitwp_Log("Enter subtree BloodFeud", "dynasty")
end
