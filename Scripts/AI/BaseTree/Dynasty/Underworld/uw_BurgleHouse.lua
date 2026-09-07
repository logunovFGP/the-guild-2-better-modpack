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

	-- the highest-level house in town that is not ours or an ally's; a player's only
	-- when the ladder allows burglary against that player
	local Best, BestLevel = -1, -1
	local Count = CityGetBuildings("UW_City", GL_BUILDING_CLASS_LIVINGROOM, GL_BUILDING_TYPE_RESIDENCE, -1, -1, FILTER_HAS_DYNASTY, "UW_H")
	for i = 0, Count - 1 do
		local H = "UW_H" .. i
		if GetDynastyID(H) > 0 and GetDynastyID(H) ~= GetID("dynasty")
				and (not BuildingGetOwner(H, "UW_Victim") or DynastyGetDiplomacyState("SIM", "UW_Victim") ~= DIP_ALLIANCE)
				and aitwp_Allowed("dynasty", H, "burglary") then
			local Level = BuildingGetLevel(H) or 0
			if Level > BestLevel then
				Best, BestLevel = i, Level
			end
		end
	end
	if Best >= 0 then
		CopyAlias("UW_H" .. Best, "UW_House")
	end
	for i = 0, Count - 1 do
		RemoveAlias("UW_H" .. i)
	end
	RemoveAlias("UW_Victim")
	if Best >= 0 then
		return 15
	end

	return 0
end

function Execute()
	SetRepeatTimer("dynasty", "AI_Burgle", 30)
	MeasureRun("SIM", "UW_House", "BurgleAHouse", false)
end