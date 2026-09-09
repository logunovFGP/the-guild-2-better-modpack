-- Duel by provocation: insult a player character so it must accept or lose face.
-- Rules: never with a duelist whose martial arts and dexterity are both under 5 or
-- who is under 80% health (aitwp_IsFitToDuel); always against the player's
-- non-rogues; against a rogue only on the daily 1-in-4 roll kept in AI_BF_DuelRogues.
-- Ladder rung 3 (aitwp_Allowed "duel"). Cooldowns are per duelist (AI_Insult) and
-- per victim (Get_Insult), not per house.
function Weight()
	if not aitwp_Allowed("dynasty", "PlayerDyn", "duel") then
		return 0
	end
	if not aitwp_FindFitDuelist("dynasty", "Duelist") then
		return 0
	end
	if aitwp_FindPlayerTarget("PlayerDyn", "duel", "Victim") and ReadyToRepeat("Victim", "Get_Insult") then
		return bf_provoke_Scored()
	end
	if (GetProperty("dynasty", "AI_BF_DuelRogues") or 0) == 1
			and aitwp_FindPlayerTarget("PlayerDyn", "rogue", "Victim") and ReadyToRepeat("Victim", "Get_Insult") then
		return bf_provoke_Scored()
	end
	return 0
end

-- Scored: the duelist's edge in martial arts and dexterity over the victim (-5 to
-- +10 talent points spans the whole factor) and an aggressive house.
function Scored()
	local Edge = GetSkillValue("Duelist", FIGHTING) + GetSkillValue("Duelist", DEXTERITY) / 2
		- GetSkillValue("Victim", FIGHTING) - GetSkillValue("Victim", DEXTERITY) / 2
	-- siblings share the alias "Victim" and the engine runs every Weight() before the
	-- winner's Execute(); file it under this node so no sibling can take it
	blackboard_Stash("bf_Provoke", "Victim")
	return utility_Score("dynasty", 100, {
		{ value = utility_Norm(Edge, -5, 10), curve = "linear" },
		utility_Priority("dynasty", "Agressive"),
	}, "bf_Provoke")
end

function Execute()
	utility_Picked("dynasty", "bf_Provoke")
	if not blackboard_Claim("bf_Provoke", "BF_DuelVictim") then
		return
	end
	SetRepeatTimer("BF_DuelVictim", "Get_Insult", 72)
	SetRepeatTimer("Duelist", "AI_Insult", 24)
	aitwp_Log("provokes " .. GetName("BF_DuelVictim") .. " with " .. GetName("Duelist"), "dynasty")
	MeasureRun("Duelist", "BF_DuelVictim", "InsultCharacter", false)
	blackboard_Drop("BF_DuelVictim")
end
