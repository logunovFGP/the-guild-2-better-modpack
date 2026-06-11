function Weight()
	if not ReadyToRepeat("dynasty", "AI_PrayBlessing") then
		return 0
	end

	if not DynastyGetRandomBuilding("dynasty", GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_CHURCH_CATH, "SOC_OwnChurch") and not DynastyGetRandomBuilding("dynasty", GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_CHURCH_EV, "SOC_OwnChurch") then
		return 0
	end

	return 10
end

function Execute()
	SetRepeatTimer("dynasty", "AI_PrayBlessing", 36)
	MeasureRun("SIM", "SOC_OwnChurch", "PrayForGodsBlessing", false)
end