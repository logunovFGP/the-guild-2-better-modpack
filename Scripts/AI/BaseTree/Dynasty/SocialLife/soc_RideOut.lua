function Weight()
	if not ReadyToRepeat("SIM", "AI_RideOut") then
		return 0
	end

	if GetNobilityTitle("SIM") < 8 then
		return 0
	end

	if GetMoney("dynasty") < 5000 then
		return 0
	end

	if not GetSettlement("SIM", "RIDE_Home") then
		return 0
	end

	local CityCount = ScenarioGetObjects("cl_Settlement", 20, "RIDE_City")
	if CityCount < 2 then
		return 0
	end

	local HomeID = GetID("RIDE_Home")
	for i = 1, CityCount do
		local Alias = "RIDE_City"..Rand(CityCount)
		if AliasExists(Alias) and GetID(Alias) ~= HomeID then
			if CityGetRandomBuilding(Alias, GL_BUILDING_CLASS_MARKET, -1, -1, -1, FILTER_IGNORE, "RIDE_Spot") then
				if GetDistance("SIM", "RIDE_Spot") >= 16000 then
					return 5
				end
			end
		end
	end

	return 0
end

function Execute()
	SetRepeatTimer("SIM", "AI_RideOut", 96)
	MeasureRun("SIM", "RIDE_Spot", "UseHorse", false)
end