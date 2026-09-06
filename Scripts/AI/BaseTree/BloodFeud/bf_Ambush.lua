-- Ambush: attack a player character or employee caught outdoors away from town -
-- on the road, in the fields, at the mine - with every idle thug at once. Ladder
-- rung 4 ("ambush"); the cooldown is the thug's.
function Weight()
	if not AliasExists("MYRM") then
		return 0
	end
	if not aitwp_Allowed("dynasty", "PlayerDyn", "ambush") then
		return 0
	end
	if not ReadyToRepeat("MYRM", "AI_BF_Ambush") then
		return 0
	end
	if not aitwp_FindPlayerTarget("PlayerDyn", "outside", "Victim") then
		return 0
	end
	return utility_Trace("dynasty", "bf_Ambush", 120)
end

function Execute()
	utility_Picked("dynasty", "bf_Ambush")
	SetRepeatTimer("MYRM", "AI_BF_Ambush", 3)
	aitwp_Log("ambushes " .. GetName("Victim"), "dynasty")
	local Count = DynastyGetWorkerCount("dynasty", GL_PROFESSION_MYRMIDON)
	for i = 0, Count - 1 do
		if DynastyGetWorker("dynasty", GL_PROFESSION_MYRMIDON, i, "Thug") and GetState("Thug", STATE_IDLE) then
			MeasureRun("Thug", "Victim", "AttackEnemy", false)
		end
	end
end
