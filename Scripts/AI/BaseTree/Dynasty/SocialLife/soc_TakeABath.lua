function Weight()
	if GetMoney("dynasty") < 2500 then
		return 0
	end

	if GetImpactValue("SIM", "perfume") > 0 then
		return 0
	end

	if not ReadyToRepeat("dynasty", "AI_SocialBath") then
		return 0
	end

	if not GetSettlement("SIM", "SOC_City") then
		return 0
	end

	if not DynastyGetRandomBuilding("SIM", -1, GL_BUILDING_TYPE_TAVERN, "SOC_Bath") then
		if not CityGetNearestBuilding("SOC_City", "SIM", -1, GL_BUILDING_TYPE_TAVERN, 2, -1, FILTER_HAS_DYNASTY, "SOC_Bath") then
			if not CityGetNearestBuilding("SOC_City", "SIM", -1, GL_BUILDING_TYPE_TAVERN, 3, -1, FILTER_HAS_DYNASTY, "SOC_Bath") then
				return 0
			end
		end
	end

	if not AliasExists("SOC_Bath") then
		return 0
	end

	return 8
end

function Execute()
	SetRepeatTimer("dynasty", "AI_SocialBath", 24)
	MeasureRun("SIM", "SOC_Bath", "TakeABathAlone", false)
end