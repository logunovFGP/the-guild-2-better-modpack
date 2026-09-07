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
	-- scored: a weak victim, many free thugs, an aggressive house
	local Free = 0
	local Count = DynastyGetWorkerCount("dynasty", GL_PROFESSION_MYRMIDON)
	for i = 0, Count - 1 do
		if DynastyGetWorker("dynasty", GL_PROFESSION_MYRMIDON, i, "TWP_TA") and aitwp_IdleThug("TWP_TA") then
			Free = Free + 1
		end
	end
	RemoveAlias("TWP_TA")
	return utility_Score("dynasty", 120, {
		{ value = 1 - GetHPRelative("Victim"), curve = "linear", lo = 0.8 },
		{ value = utility_Norm(Free, 1, 3), curve = "sqrt" },
		utility_Priority("dynasty", "Agressive"),
	}, "bf_ThugAttack")
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
