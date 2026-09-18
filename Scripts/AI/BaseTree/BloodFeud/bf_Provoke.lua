-- Duel by provocation: insult a player character so it must accept or lose face.
--
-- The victim is chosen first and the duellist second, because fitness is relative: what
-- makes someone a champion is whether their FIGHTING can put *this* target down inside
-- the three rounds a duel has (aitwp_IsFitToDuel). The house then asks for the odds and
-- refuses below TWP_DUEL_BAR - it used to score the talent gap and never gate on it, so
-- on 2026-09-19 it insulted with a duellist five talent points *worse* than the target
-- and still weighed 102.
--
-- Rules otherwise unchanged: always against the player's non-rogues; against a rogue only
-- on the daily 1-in-4 roll kept in AI_BF_DuelRogues. Ladder rung 3 (aitwp_Allowed "duel").
-- Cooldowns are per duelist (AI_Insult) and per victim (Get_Insult), not per house.
local function FindVictim()
	if aitwp_FindPlayerTarget("PlayerDyn", "duel", "Victim") and ReadyToRepeat("Victim", "Get_Insult") then
		return true
	end
	if (GetProperty("dynasty", "AI_BF_DuelRogues") or 0) == 1
			and aitwp_FindPlayerTarget("PlayerDyn", "rogue", "Victim") and ReadyToRepeat("Victim", "Get_Insult") then
		return true
	end
	return false
end

function Weight()
	if not aitwp_Allowed("dynasty", "PlayerDyn", "duel") then
		return 0
	end
	if not FindVictim() then
		return 0
	end
	if not aitwp_FindFitDuelist("dynasty", "Victim", "Duelist") then
		return 0
	end
	local Win, Lose = aitwp_DuelOdds("Duelist", "Victim")
	if Win < TWP_DUEL_BAR then
		return 0
	end
	-- siblings share the alias "Victim" and the engine runs every Weight() before the
	-- winner's Execute(); file it under this node so no sibling can take it
	aiboard_Stash("bf_Provoke", "Victim")
	-- scored: the margin the odds give, and an aggressive house
	return utility_Score("dynasty", 100, {
		{ value = utility_Norm(Win - Lose, 0, 1), curve = "linear" },
		utility_Priority("dynasty", "Agressive"),
	}, "bf_Provoke")
end

function Execute()
	utility_Picked("dynasty", "bf_Provoke")
	if not aiboard_Claim("bf_Provoke", "BF_DuelVictim") then
		return
	end
	-- re-resolved: "Duelist" is a shared alias and every sibling's Weight() ran between
	-- the stash above and this line
	if not aitwp_FindFitDuelist("dynasty", "BF_DuelVictim", "Duelist") then
		aiboard_Drop("BF_DuelVictim")
		return
	end
	local Win, Lose, Draw = aitwp_DuelOdds("Duelist", "BF_DuelVictim")
	SetRepeatTimer("BF_DuelVictim", "Get_Insult", 72)
	SetRepeatTimer("Duelist", "AI_Insult", 24)
	aitwp_Log("provokes " .. GetName("BF_DuelVictim") .. " with " .. GetName("Duelist")
		.. " (win " .. string.format("%.2f", Win) .. " lose " .. string.format("%.2f", Lose)
		.. " draw " .. string.format("%.2f", Draw) .. ")", "dynasty")
	MeasureRun("Duelist", "BF_DuelVictim", "InsultCharacter", false)
	aiboard_Drop("BF_DuelVictim")
end
