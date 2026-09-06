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
	return utility_Trace("dynasty", "bf_Charge", 100 + Value)
end

function Execute()
	utility_Picked("dynasty", "bf_Charge")
	SetRepeatTimer("Accuser", "AI_ChargeCharacter", 48)
	RemoveProperty("dynasty", "AI_EvidenceTarget")
	aitwp_Log("charges " .. GetName("Victim") .. " through " .. GetName("Accuser"), "dynasty")
	MeasureRun("Accuser", "Victim", "ChargeCharacter")
end
