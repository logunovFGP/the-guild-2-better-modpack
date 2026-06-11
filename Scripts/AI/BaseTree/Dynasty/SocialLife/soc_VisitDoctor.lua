function Weight()
	if GetMoney("dynasty") < 500 then
		return 0
	end

	if not ReadyToRepeat("SIM", "AI_VisitDoctor") then
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