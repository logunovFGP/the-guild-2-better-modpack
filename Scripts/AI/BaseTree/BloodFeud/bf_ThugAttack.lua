-- Thug attack: the house's hired thugs run the plain Attack order (AttackEnemy) on a
-- player character or employee caught outdoors away from town. Every thug that is
-- idle or on its rounds goes (aitwp_IdleThug), forced past patrol and escort
-- priorities. Not the Marauders' waylay: that is the robber camp's, on carts.
-- Ladder rung 4 ("thug_attack"); the cooldown is the thug's.
function Weight()
	if not AliasExists("MYRM") then
		return 0
	end
	if not aitwp_Allowed("dynasty", "PlayerDyn", "thug_attack") then
		return 0
	end
	if not ReadyToRepeat("MYRM", "AI_BF_Attack") then
		return 0
	end
	if not aitwp_FindPlayerTarget("PlayerDyn", "outside", "Victim") then
		return 0
	end
	return utility_Trace("dynasty", "bf_ThugAttack", 120)
end

function Execute()
	utility_Picked("dynasty", "bf_ThugAttack")
	SetRepeatTimer("MYRM", "AI_BF_Attack", 3)
	local Sent, Results = 0, ""
	local Count = DynastyGetWorkerCount("dynasty", GL_PROFESSION_MYRMIDON)
	for i = 0, Count - 1 do
		if DynastyGetWorker("dynasty", GL_PROFESSION_MYRMIDON, i, "Thug") and aitwp_IdleThug("Thug") then
			Results = Results .. tostring(MeasureRun("Thug", "Victim", "AttackEnemy", true)) .. ";"
			Sent = Sent + 1
		end
	end
	RemoveAlias("Thug")
	aitwp_Log("sends " .. Sent .. " thugs at " .. GetName("Victim") .. " (" .. Results .. ")", "dynasty")
end
