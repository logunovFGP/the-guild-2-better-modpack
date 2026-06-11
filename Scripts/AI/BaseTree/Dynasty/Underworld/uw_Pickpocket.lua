function Weight()
	local Hour = math.mod(GetGametime(), 24)
	if Hour < 8 or Hour >= 22 then
		return 0
	end

	if not ReadyToRepeat("SIM", "AI_Pickpocket") then
		return 0
	end

	if not GetSettlement("SIM", "UW_City") then
		return 0
	end

	if not CityGetRandomBuilding("UW_City", GL_BUILDING_CLASS_MARKET, -1, -1, -1, FILTER_IGNORE, "UW_Spot") then
		return 0
	end

	return 20
end

function Execute()
	SetRepeatTimer("SIM", "AI_Pickpocket", 14)
	MeasureRun("SIM", "UW_Spot", "PickpocketPeople", false)
end