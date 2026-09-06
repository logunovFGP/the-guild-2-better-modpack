function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "charge") then
		return 0
	end
	if not ReadyToRepeat("dynasty", "AI_ChargeCharacter") then
		return 0
	end

	if not AliasExists("Victim") then
		return 0
	end	
	
	if not SimCanBeCharged("Victim") then
		return 0
	end	
	
	return GetEvidenceValues("SIM", "Victim")
end

function Execute()
	if AliasExists("Victim") then
		SetRepeatTimer("dynasty", "AI_ChargeCharacter", 48)
		MeasureRun("SIM", "Victim", "ChargeCharacter")
	end
end