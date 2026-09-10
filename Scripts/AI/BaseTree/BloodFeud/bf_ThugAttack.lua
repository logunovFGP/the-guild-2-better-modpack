-- Thug attack: the house sends every hired hand it can spare - thugs off the residence,
-- and the marauders, thieves and mercenaries of any camp it owns - at a player character
-- or employee, on the plain Attack order. It goes only when the party reckons it wins
-- three fights in four (aitwp_WinChance, which counts the victim's escort and everyone of
-- their house standing close enough to join in), so a lone thug no longer walks into a
-- party of six. Where the fight may happen is aitwp_MayAttackHere's call, and the measure
-- asks again on arrival: the victim can be back on the market by then.
-- Not the Marauders' waylay: that is the robber camp's, on carts.
-- Ladder rung 4 ("thug_attack"); the cooldown is the house's.
function Weight()
	if not aitwp_Allowed("dynasty", "PlayerDyn", "thug_attack") then
		return 0
	end
	if not ReadyToRepeat("dynasty", "AI_BF_Attack") then
		return 0
	end
	if not aitwp_FindPlayerTarget("PlayerDyn", "outside", "Victim") then
		return 0
	end

	local Party = {}
	local Sent = aitwp_GatherFighters("dynasty", "TWP_TA", Party, TWP_ATTACK_PARTY_MAX)
	aitwp_ClearFighters("TWP_TA", Sent)
	if Sent < 1 then
		return 0
	end

	local Defence = {}
	aitwp_DefenceOf("PlayerDyn", "Victim", Defence)
	local Chance = aitwp_WinChance(Party, Defence)
	if Chance < TWP_ATTACK_WIN_CHANCE then
		aitwp_Log("holds back " .. Sent .. " v " .. (Defence.n or 0) .. " on "
			.. GetName("Victim") .. " (win " .. string.format("%.2f", Chance) .. ")", "dynasty")
		return 0
	end
	-- siblings share the alias "Victim" and the engine runs every Weight() before the
	-- winner's Execute(); file the target the win chance was measured against
	aiboard_Stash("bf_ThugAttack", "Victim")
	SetData("ThugWinChance", Chance)

	-- scored: the surer the fight, the bigger the party, the more aggressive the house
	return utility_Score("dynasty", 120, {
		{ value = utility_Norm(Chance, TWP_ATTACK_WIN_CHANCE, 1), curve = "linear", lo = 0.8 },
		{ value = utility_Norm(Sent, 1, 3), curve = "sqrt" },
		utility_Priority("dynasty", "Agressive"),
	}, "bf_ThugAttack")
end

function Execute()
	utility_Picked("dynasty", "bf_ThugAttack")
	if not aiboard_Claim("bf_ThugAttack", "TWP_TAV") then
		return
	end
	SetRepeatTimer("dynasty", "AI_BF_Attack", 3)
	local Party = {}
	local Sent = aitwp_GatherFighters("dynasty", "Thug", Party, TWP_ATTACK_PARTY_MAX)
	local Results = ""
	for i = 1, Sent do
		Results = Results .. tostring(MeasureRun("Thug" .. i, "TWP_TAV", "AttackEnemy", true)) .. ";"
	end
	aitwp_ClearFighters("Thug", Sent)
	aitwp_Log("sends " .. Sent .. " at " .. GetName("TWP_TAV") .. " (win "
		.. string.format("%.2f", GetData("ThugWinChance") or 0) .. "; " .. Results .. ")", "dynasty")
	aiboard_Drop("TWP_TAV")
end
