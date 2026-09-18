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
	
	-- or 0: utility_Trace concatenates the weight into its log line, so a nil from the
	-- native would error in Weight() and the node would weigh 0 with nothing said. It also
	-- returned that nil straight to the selector before this was traced, which is
	-- undefined for the roulette. No evidence is a weight of nothing either way.
	return utility_Trace("dynasty", "ChargeCharacter", GetEvidenceValues("SIM", "Victim") or 0)
end

function Execute()
	utility_Picked("dynasty", "ChargeCharacter")
	if AliasExists("Victim") then
		SetRepeatTimer("dynasty", "AI_ChargeCharacter", 48)
		MeasureRun("SIM", "Victim", "ChargeCharacter")
	end
end