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
		return utility_Trace("dynasty", "bf_Provoke", 100)
	end
	if (GetProperty("dynasty", "AI_BF_DuelRogues") or 0) == 1
			and aitwp_FindPlayerTarget("PlayerDyn", "rogue", "Victim") and ReadyToRepeat("Victim", "Get_Insult") then
		return utility_Trace("dynasty", "bf_Provoke", 100)
	end
	return 0
end

function Execute()
	utility_Picked("dynasty", "bf_Provoke")
	SetRepeatTimer("Victim", "Get_Insult", 72)
	SetRepeatTimer("Duelist", "AI_Insult", 24)
	aitwp_Log("provokes " .. GetName("Victim") .. " with " .. GetName("Duelist"), "dynasty")
	MeasureRun("Duelist", "Victim", "InsultCharacter", false)
end
