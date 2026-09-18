-- raid_building. The war party against a player building standing outside the walls - the
-- mines, huts and farms no watch patrols - to take it or wreck it. SquadRazzia is the
-- engine's own raid on a building, the same one the myrmidon razzia rides out on.
--
-- The defence is whoever works there (aitwp_BuildingDefence); a building has no sheet of
-- its own, so aitwp_DefenceOf cannot be pointed at one.
--
-- The loudest thing the feud does, so the highest gate: the player a high noble (Baron)
-- AND ten rounds in - both, not either. Then a day's cooldown.
function Weight()
	if not aitwp_RaidAllowed("PlayerDyn", "raid_building") then
		return 0
	end
	if not aitwp_Allowed("dynasty", "PlayerDyn", "thug_attack") then
		return 0
	end
	if not ReadyToRepeat("dynasty", "AI_BF_RaidBuilding") then
		return 0
	end
	if not aitwp_FindOutsideBuilding("PlayerDyn", "VicBld") then
		return 0
	end
	local Defence = {}
	aitwp_BuildingDefence("VicBld", Defence)
	local Candidates = aitwp_WarCandidates("dynasty", "TWP_RB")
	local Side = {}
	local Sent, Chance = aitwp_WarCommit("TWP_RB", Candidates, Defence, TWP_ATTACK_WIN_CHANCE, Side)
	aitwp_ClearFighters("TWP_RB", Candidates)
	if Sent < 1 then
		return 0
	end
	aiboard_Stash("bf_RaidBuilding", "VicBld")
	SetData("WarChance", Chance)

	-- scored between the two: a mine is worth more than a gatherer and less than an heir
	return utility_Score("dynasty", 100, {
		{ value = utility_Norm(Chance, TWP_ATTACK_WIN_CHANCE, 1), curve = "linear", lo = 0.8 },
		utility_Priority("dynasty", "Agressive"),
	}, "bf_RaidBuilding")
end

function Execute()
	utility_Picked("dynasty", "bf_RaidBuilding")
	if not aiboard_Claim("bf_RaidBuilding", "TWP_RBV") then
		return
	end
	SetRepeatTimer("dynasty", "AI_BF_RaidBuilding", TWP_WAR_COOLDOWN)
	local Defence = {}
	aitwp_BuildingDefence("TWP_RBV", Defence)
	local Candidates = aitwp_WarCandidates("dynasty", "War")
	local Side = {}
	local Sent, Chance = aitwp_WarCommit("War", Candidates, Defence, TWP_ATTACK_WIN_CHANCE, Side)
	local Leader = false
	if Sent >= 1 and aitwp_WarLeader("dynasty", Chance, "War" .. (Sent + 1)) then
		Sent, Leader = Sent + 1, true
	end
	local Ok = aitwp_SquadAttack("War", Sent, "TWP_RBV", "SquadRazzia", "SquadRazziaMember")
	aitwp_LogWar("dynasty", "raid_building", "TWP_RBV", Sent, Leader, Chance, Ok)
	if Candidates > Sent then
		Sent = Candidates
	end
	aitwp_ClearFighters("War", Sent)
	aiboard_Drop("TWP_RBV")
end
