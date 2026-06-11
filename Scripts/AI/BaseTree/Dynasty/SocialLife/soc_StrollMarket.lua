function Weight()
	if GetSeason() == EN_SEASON_WINTER then
		return 0
	end

	local Hour = math.mod(GetGametime(), 24)
	if Hour < 8 or Hour > 18 then
		return 0
	end

	if not ReadyToRepeat("SIM", "AI_Stroll") then
		return 0
	end

	if not GetSettlement("SIM", "SOC_City") then
		return 0
	end

	if not CityGetRandomBuilding("SOC_City", GL_BUILDING_CLASS_MARKET, -1, -1, -1, FILTER_IGNORE, "SOC_Market") then
		return 0
	end

	if GetSeason() == EN_SEASON_SUMMER then
		return 8
	end
	return 5
end

function Execute()
	SetRepeatTimer("SIM", "AI_Stroll", 10)
	f_MoveToNoWait("SIM", "SOC_Market")
end