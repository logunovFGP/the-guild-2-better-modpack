-- Take the evidence target to court as soon as a party member holds evidence that
-- carries. Evidence belongs to the sim who collected or forged it, so that member is
-- the accuser and carries the cooldown. Clearing AI_EvidenceTarget afterwards is what
-- "the target does not change until the trial" means. Ladder rung 3 ("charge").
function Weight()
	if not aitwp_Allowed("dynasty", "PlayerDyn", "charge") then
		return 0
	end
	if not aitwp_EvidenceTarget("dynasty", "PlayerDyn", "Victim") then
		return 0
	end
	if not SimCanBeCharged("Victim") then
		return 0
	end
	local Value = aitwp_FindAccuser("dynasty", "Victim", "Accuser")
	if Value < 1 then
		return 0
	end
	-- scored: the evidence in hand (a full case at 100) and the political priority
	-- siblings share the alias "Victim" and the engine runs every Weight() before the
	-- winner's Execute(); file it under this node so no sibling can take it
	aiboard_Stash("bf_Charge", "Victim")
	return utility_Score("dynasty", 100, {
		{ value = utility_Norm(Value, 0, 100), curve = "sqrt" },
		utility_Priority("dynasty", "Political"),
	}, "bf_Charge")
end

function Execute()
	utility_Picked("dynasty", "bf_Charge")
	if not aiboard_Claim("bf_Charge", "BF_ChargeVictim") then
		return
	end
	SetRepeatTimer("Accuser", "AI_ChargeCharacter", 48)
	RemoveProperty("dynasty", "AI_EvidenceTarget")
	aitwp_Log("charges " .. GetName("BF_ChargeVictim") .. " through " .. GetName("Accuser"), "dynasty")
	MeasureRun("Accuser", "BF_ChargeVictim", "ChargeCharacter")
	aiboard_Drop("BF_ChargeVictim")
end
