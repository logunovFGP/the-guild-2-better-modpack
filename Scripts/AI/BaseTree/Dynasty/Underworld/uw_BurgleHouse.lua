function Weight()
	local Hour = math.mod(GetGametime(), 24)
	if Hour >= 5 and Hour < 21 then
		return 0
	end

	if not ReadyToRepeat("dynasty", "AI_Burgle") then
		return 0
	end

	if not GetSettlement("SIM", "UW_City") then
		return 0
	end

	for i = 1, 5 do
		if CityGetRandomBuilding("UW_City", GL_BUILDING_CLASS_LIVINGROOM, GL_BUILDING_TYPE_RESIDENCE, -1, -1, FILTER_HAS_DYNASTY, "UW_House") then
			if GetDynastyID("UW_House") > 0 and GetDynastyID("UW_House") ~= GetID("dynasty") then
				if not BuildingGetOwner("UW_House", "UW_Victim") or DynastyGetDiplomacyState("SIM", "UW_Victim") ~= DIP_ALLIANCE then
					return 15
				end
			end
		end
	end

	return 0
end

function Execute()
	SetRepeatTimer("dynasty", "AI_Burgle", 30)
	MeasureRun("SIM", "UW_House", "BurgleAHouse", false)
end