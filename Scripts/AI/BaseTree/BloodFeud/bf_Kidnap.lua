-- kidnap. The house takes a player character off the street and holds them in its own
-- thieves' guild. Thugs, robbers, thieves and beggars all help with the snatch - it wants
-- hands, not swordsmen - and the family's rogues come along.
--
-- Two numbers have to clear, not one. The fight is aitwp_WinChance as before, because the
-- escort still has to be dealt with. The snatch is aitwp_KidnapChance, which asks a
-- different question: getting the body away through a town is where a kidnapping actually
-- fails, and a party that wins the brawl and loses the victim in the crowd has failed.
--
-- Inside the walls only when the house commands the watch. aitwp_FindReachableTarget goes
-- through aitwp_MayAttackHere, which says yes in town only to a house holding an office
-- with CommandCityGuard - so an office is what turns this from a roadside crime into
-- something the rival can do on the market square.
--
-- Needs a thieves' guild of its own for the cell: ms_SquadHijackMember.lua stops dead
-- without one, and bf_Hideout is the node that buys it.
--
-- Opens earlier than the raids - Buerger, or five rounds in - then a day's cooldown.
function Weight()
	if not aitwp_RaidAllowed("PlayerDyn", "kidnap") then
		return 0
	end
	if not aitwp_Allowed("dynasty", "PlayerDyn", "thug_attack") then
		return 0
	end
	if not ReadyToRepeat("dynasty", "AI_BF_Kidnap") then
		return 0
	end
	-- nowhere to hold them is no kidnapping, whatever the odds
	if not aitwp_HasThievesDen("dynasty", "TWP_KDen") then
		return 0
	end
	RemoveAlias("TWP_KDen")
	if not aitwp_FindReachableTarget("dynasty", "PlayerDyn", "adult", "Victim") then
		return 0
	end
	local Defence = {}
	aitwp_DefenceOf("PlayerDyn", "Victim", Defence)
	local Candidates = aitwp_WarCandidates("dynasty", "TWP_KD")
	local Side = {}
	local Sent, Chance = aitwp_WarCommit("TWP_KD", Candidates, Defence, TWP_ATTACK_WIN_CHANCE, Side)
	aitwp_ClearFighters("TWP_KD", Candidates)
	if Sent < 1 then
		return 0
	end
	-- the second number: winning the brawl is not the same as getting the body away
	local Odds = aitwp_KidnapChance("dynasty", "Victim", Sent)
	if Odds < TWP_KIDNAP_BAR then
		return 0
	end
	aiboard_Stash("bf_Kidnap", "Victim")
	SetData("WarChance", Chance)
	SetData("KidnapOdds", Odds)

	return utility_Score("dynasty", 110, {
		{ value = utility_Norm(Odds, TWP_KIDNAP_BAR, 1), curve = "linear", lo = 0.8 },
		utility_Priority("dynasty", "Agressive"),
	}, "bf_Kidnap")
end

function Execute()
	utility_Picked("dynasty", "bf_Kidnap")
	if not aiboard_Claim("bf_Kidnap", "TWP_KDV") then
		return
	end
	SetRepeatTimer("dynasty", "AI_BF_Kidnap", TWP_WAR_COOLDOWN)
	local Defence = {}
	aitwp_DefenceOf("PlayerDyn", "TWP_KDV", Defence)
	local Candidates = aitwp_WarCandidates("dynasty", "War")
	local Side = {}
	local Sent, Chance = aitwp_WarCommit("War", Candidates, Defence, TWP_ATTACK_WIN_CHANCE, Side)
	local Leader = false
	if Sent >= 1 and aitwp_WarLeader("dynasty", Chance, "War" .. (Sent + 1)) then
		Sent, Leader = Sent + 1, true
	end
	local Ok = aitwp_SquadAttack("War", Sent, "TWP_KDV", "SquadHijackCharacter", "SquadHijackMember")
	aitwp_LogWar("dynasty", "kidnap", "TWP_KDV", Sent, Leader, Chance, Ok,
		aitwp_KidnapChance("dynasty", "TWP_KDV", Sent))
	if Candidates > Sent then
		Sent = Candidates
	end
	aitwp_ClearFighters("War", Sent)
	aiboard_Drop("TWP_KDV")
end
