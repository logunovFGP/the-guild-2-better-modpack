function Weight()
	if not ReadyToRepeat("SIM", "AI_VisitDoctor") then
		return 0
	end

	-- The house's coffers were the wrong purse. The bill falls on whoever goes, and both
	-- ms_AttendDoctor and the hospital counter charge GetMoney("SIM"), so a rich house
	-- kept sending members who arrived with empty pockets, were refused at the bedside
	-- and walked back an hour later. Ask exactly what the counter will ask - it is one
	-- predicate now, gameplayformulas_PaysForTreatment, and this is the first gate that
	-- consults it.
	if gameplayformulas_CheckMoneyForTreatment("SIM") == 0 then
		return 0
	end

	if GetHPRelative("SIM") < 0.7 then
		return 40
	end

	local Diseases = { "Sprain", "Cold", "Influenza", "BurnWound", "Pox", "Pneumonia", "Blackdeath", "Fracture", "Caries" }
	for _, Name in helpfuncs_myipairs(Diseases) do
		if GetImpactValue("SIM", Name) == 1 then
			return 40
		end
	end

	return 0
end

function Execute()
	SetRepeatTimer("SIM", "AI_VisitDoctor", 8)
	MeasureRun("SIM", 0, "AttendDoctor", false)
end