-- workers_raid. The same war party, pointed at the people the player sends out of town: the
-- miners, lumberjacks and gatherers who walk to a resource and back with nobody near them.
--
-- The squad lies in wait at the spot rather than chasing, on our own ambush measures
-- (Squad/ms_bf_Ambush.lua). Not SquadWaylay: that is the robber camp's own job and stops
-- dead without one, so a party of thugs, beggars and rogues off a residence could never
-- have run it. The ambush holds for TWP_AMBUSH_HOURS and then goes home, which is what
-- should happen in the hours the mine is idle.
--
-- Weaker target, same arithmetic: the estimate still has to clear three fights in four,
-- because a gatherer with two guards is not the soft touch it looks like.
--
-- Ladder rung 4 ("thug_attack"), the player at Patron or round 10, then a day's cooldown.
function Weight()
	if not aitwp_RaidAllowed("PlayerDyn", "workers_raid") then
		return 0
	end
	if not aitwp_Allowed("dynasty", "PlayerDyn", "thug_attack") then
		return 0
	end
	if not ReadyToRepeat("dynasty", "AI_BF_WorkersRaid") then
		return 0
	end
	if not aitwp_FindWorkerTarget("PlayerDyn", "Victim") then
		return 0
	end
	local Defence = {}
	aitwp_DefenceOf("PlayerDyn", "Victim", Defence)
	local Candidates = aitwp_WarCandidates("dynasty", "TWP_WR")
	local Side = {}
	local Sent, Chance = aitwp_WarCommit("TWP_WR", Candidates, Defence, TWP_ATTACK_WIN_CHANCE, Side)
	aitwp_ClearFighters("TWP_WR", Candidates)
	if Sent < 1 then
		return 0
	end
	aiboard_Stash("bf_WorkersRaid", "Victim")
	SetData("WarChance", Chance)

	-- scored below the assassination: it costs the player a purse, not an heir
	return utility_Score("dynasty", 80, {
		{ value = utility_Norm(Chance, TWP_ATTACK_WIN_CHANCE, 1), curve = "linear", lo = 0.8 },
		utility_Priority("dynasty", "Agressive"),
	}, "bf_WorkersRaid")
end

function Execute()
	utility_Picked("dynasty", "bf_WorkersRaid")
	if not aiboard_Claim("bf_WorkersRaid", "TWP_WRV") then
		return
	end
	SetRepeatTimer("dynasty", "AI_BF_WorkersRaid", TWP_WAR_COOLDOWN)
	local Defence = {}
	aitwp_DefenceOf("PlayerDyn", "TWP_WRV", Defence)
	local Candidates = aitwp_WarCandidates("dynasty", "War")
	local Side = {}
	local Sent, Chance = aitwp_WarCommit("War", Candidates, Defence, TWP_ATTACK_WIN_CHANCE, Side)
	local Leader = false
	if Sent >= 1 and aitwp_WarLeader("dynasty", Chance, "War" .. (Sent + 1)) then
		Sent, Leader = Sent + 1, true
	end
	local Ok = aitwp_SquadAttack("War", Sent, "TWP_WRV", "bf_Ambush", "bf_AmbushMember")
	aitwp_LogWar("dynasty", "workers_raid", "TWP_WRV", Sent, Leader, Chance, Ok)
	if Candidates > Sent then
		Sent = Candidates
	end
	aitwp_ClearFighters("War", Sent)
	aiboard_Drop("TWP_WRV")
end
