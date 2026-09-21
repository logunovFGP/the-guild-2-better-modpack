function Weight()
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end

	local CurrentEnemy = aitwp_GetBestEnemy("dynasty")
	aitwp_Log("AI::Feud Current enemy ID = "..CurrentEnemy, "dynasty")
	if not CurrentEnemy or CurrentEnemy <= 0 then
		return 0
	end

	-- An aitwp_FeudReady gate stood here for one session and was removed on 2026-09-21 as a
	-- measured no-op: ::TWP::WHY feud allcooldown fired 0 times across 385 picks. It asked
	-- whether all five children were on cooldown, but a child only SETS its repeat timer when
	-- it executes, and in a subtree this quiet they almost never do - so the timers stayed
	-- unset, an unset timer reads ready, and the gate always passed. Safe direction, useless
	-- gate: the other half of the EconomyReady bug rather than the opposite of it.
	--
	-- It was also built on a number that was wrong. The 83-87% "barren" was mostly shadow
	-- houses scoring 3 and 5 in AttackBuilding and AttackFeud through a bare return that
	-- emitted no ::TWP::W. Those are traced now; read the real figure before gating anything.

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