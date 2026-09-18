-- assassination_attempt. The house finds a player character caught outdoors, works out how
-- few of its people it needs to be sure of the fight, groups them into one squad and sends
-- them together.
--
-- Half the thugs and at most a third of any other pool (aitwp_WarCandidates: marauders,
-- mercenaries, thieves, beggars and the family's own rogues - all of them carry a dagger),
-- committed one at a time until the estimate clears three fights in four and not one more.
-- The head of the house rides out 30% of the time, and never when the party wins outright.
--
-- Replaces bf_ThugAttack, which sent everything it had on N separate Attack orders and so
-- arrived in ones and twos. One squad arrives once.
--
-- Ladder rung 4 ("thug_attack"), the player at Patron or round 10, then a day's cooldown.
function Weight()
	if not aitwp_RaidAllowed("PlayerDyn", "assassination_attempt") then
		return 0
	end
	if not aitwp_Allowed("dynasty", "PlayerDyn", "thug_attack") then
		return 0
	end
	if not ReadyToRepeat("dynasty", "AI_BF_Assassinate") then
		return 0
	end
	if not aitwp_FindPlayerTarget("PlayerDyn", "outside", "Victim") then
		return 0
	end
	local Defence = {}
	aitwp_DefenceOf("PlayerDyn", "Victim", Defence)
	local Candidates = aitwp_WarCandidates("dynasty", "TWP_AS")
	local Side = {}
	local Sent, Chance = aitwp_WarCommit("TWP_AS", Candidates, Defence, TWP_ATTACK_WIN_CHANCE, Side)
	aitwp_ClearFighters("TWP_AS", Candidates)
	if Sent < 1 then
		aitwp_Log("holds back " .. Candidates .. " v " .. (Defence.n or 0) .. " on "
			.. GetName("Victim") .. " (win " .. string.format("%.2f", Chance) .. ")", "dynasty")
		return 0
	end
	-- siblings share "Victim" and every Weight() runs before the winner's Execute(); file
	-- the target the estimate was made against
	aiboard_Stash("bf_Assassinate", "Victim")
	SetData("WarChance", Chance)

	-- scored: the surer the fight and the bigger the party it took, the more worth doing
	return utility_Score("dynasty", 120, {
		{ value = utility_Norm(Chance, TWP_ATTACK_WIN_CHANCE, 1), curve = "linear", lo = 0.8 },
		{ value = utility_Norm(Sent, 1, 4), curve = "sqrt" },
		utility_Priority("dynasty", "Agressive"),
	}, "bf_Assassinate")
end

function Execute()
	utility_Picked("dynasty", "bf_Assassinate")
	if not aiboard_Claim("bf_Assassinate", "TWP_ASV") then
		return
	end
	-- the cooldown is set before anything can fail: a raid that falls over is still a raid
	-- attempted, and retrying it every tick is how the cart purchase wasted a whole day
	SetRepeatTimer("dynasty", "AI_BF_Assassinate", TWP_WAR_COOLDOWN)
	local Defence = {}
	aitwp_DefenceOf("PlayerDyn", "TWP_ASV", Defence)
	local Candidates = aitwp_WarCandidates("dynasty", "War")
	local Side = {}
	local Sent, Chance = aitwp_WarCommit("War", Candidates, Defence, TWP_ATTACK_WIN_CHANCE, Side)
	local Leader = false
	if Sent >= 1 and aitwp_WarLeader("dynasty", Chance, "War" .. (Sent + 1)) then
		Sent, Leader = Sent + 1, true
	end
	local Ok = aitwp_SquadAttack("War", Sent, "TWP_ASV", "SquadWar", "SquadWarMember")
	aitwp_LogWar("dynasty", "assassination_attempt", "TWP_ASV", Sent, Leader, Chance, Ok)
	if Candidates > Sent then
		Sent = Candidates
	end
	aitwp_ClearFighters("War", Sent)
	aiboard_Drop("TWP_ASV")
end
