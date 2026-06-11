function Weight()
	local Hour = math.mod(GetGametime(), 24)
	if Hour < 18 then
		return 0
	end

	if SimGetAge("SIM") < 18 then
		return 0
	end

	if GetMoney("dynasty") < 300 then
		return 0
	end

	if not ReadyToRepeat("dynasty", "AI_TavernNight") then
		return 0
	end

	if GetSeason() == EN_SEASON_WINTER then
		return 15
	end

	return 10
end

function Execute()
	SetRepeatTimer("dynasty", "AI_TavernNight", 16)
	if ai_GoInsideBuilding("SIM", "SIM", -1, GL_BUILDING_TYPE_TAVERN) then
		MeasureRun("SIM", nil, "RPGSitAround", false)
	end
end