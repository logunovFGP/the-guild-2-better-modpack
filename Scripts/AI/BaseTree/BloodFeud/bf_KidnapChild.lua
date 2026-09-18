-- kidnap_child. The same snatch, aimed at a player child: no escort worth the name, and
-- worth far more to the family than a grown cousin. Everything else is bf_Kidnap - the war
-- party, the two numbers, the cell in the thieves' guild, the watch that has to be the
-- house's own before this happens inside the walls.
--
-- Waits for Patron, and only Patron: taking a child is not something a house does to a
-- burgher it is merely ahead of, and there is no round that opens it instead.
function Weight()
	if not aitwp_RaidAllowed("PlayerDyn", "kidnap_child") then
		return 0
	end
	if not aitwp_Allowed("dynasty", "PlayerDyn", "thug_attack") then
		return 0
	end
	if not ReadyToRepeat("dynasty", "AI_BF_KidnapChild") then
		return 0
	end
	-- nowhere to hold them is no kidnapping, whatever the odds
	if not aitwp_HasThievesDen("dynasty", "TWP_KDen") then
		return 0
	end
	RemoveAlias("TWP_KDen")
	if not aitwp_FindReachableTarget("dynasty", "PlayerDyn", "child", "Victim") then
		return 0
	end
	local Defence = {}
	aitwp_DefenceOf("PlayerDyn", "Victim", Defence)
	local Candidates = aitwp_WarCandidates("dynasty", "TWP_KC2")
	local Side = {}
	local Sent, Chance = aitwp_WarCommit("TWP_KC2", Candidates, Defence, TWP_ATTACK_WIN_CHANCE, Side)
	aitwp_ClearFighters("TWP_KC2", Candidates)
	if Sent < 1 then
		return 0
	end
	-- the second number: winning the brawl is not the same as getting the body away
	local Odds = aitwp_KidnapChance("dynasty", "Victim", Sent)
	if Odds < TWP_KIDNAP_BAR then
		return 0
	end
	aiboard_Stash("bf_KidnapChild", "Victim")
	SetData("WarChance", Chance)
	SetData("KidnapOdds", Odds)

	return utility_Score("dynasty", 130, {
		{ value = utility_Norm(Odds, TWP_KIDNAP_BAR, 1), curve = "linear", lo = 0.8 },
		utility_Priority("dynasty", "Agressive"),
	}, "bf_KidnapChild")
end

function Execute()
	utility_Picked("dynasty", "bf_KidnapChild")
	if not aiboard_Claim("bf_KidnapChild", "TWP_KCV") then
		return
	end
	SetRepeatTimer("dynasty", "AI_BF_KidnapChild", TWP_WAR_COOLDOWN)
	local Defence = {}
	aitwp_DefenceOf("PlayerDyn", "TWP_KCV", Defence)
	local Candidates = aitwp_WarCandidates("dynasty", "War")
	local Side = {}
	local Sent, Chance = aitwp_WarCommit("War", Candidates, Defence, TWP_ATTACK_WIN_CHANCE, Side)
	local Leader = false
	if Sent >= 1 and aitwp_WarLeader("dynasty", Chance, "War" .. (Sent + 1)) then
		Sent, Leader = Sent + 1, true
	end
	local Ok = aitwp_SquadAttack("War", Sent, "TWP_KCV", "SquadHijackCharacter", "SquadHijackMember")
	aitwp_LogWar("dynasty", "kidnap_child", "TWP_KCV", Sent, Leader, Chance, Ok,
		aitwp_KidnapChance("dynasty", "TWP_KCV", Sent))
	if Candidates > Sent then
		Sent = Candidates
	end
	aitwp_ClearFighters("War", Sent)
	aiboard_Drop("TWP_KCV")
end
