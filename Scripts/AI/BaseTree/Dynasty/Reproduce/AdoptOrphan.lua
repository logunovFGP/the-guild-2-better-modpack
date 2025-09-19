function Weight()
	if not AliasExists("SIM") then
		return 0
	end

	local time = math.mod(GetGametime(),24)
	if time < 8 then
		adoptorphan_SetFailTimersExact(8-time)
		return 0
	end
	
	if ai_GetUsefulChildCount("SIM") > 2 then
		-- I've got enough children to survive
		adoptorphan_SetFailTimers()
		return 0
	end

	if not FindNearestBuilding("SIM", -1, GL_BUILDING_TYPE_WEDDINGCHAPEL, -1, false, "WeddingChapel") then
		adoptorphan_SetFailTimers()
		return 0
	end
	
	if not GetHomeBuilding("SIM", "Home") then
		adoptorphan_SetFailTimers()
		return 0
	end

	if BuildingGetType("Home")==GL_BUILDING_TYPE_RESIDENCE then
		if SimGetAge("SIM") < 40 and SimGetAge("Spouse") < 40 then
			-- I have a residence home, so I can make my own children.
			adoptorphan_SetFailTimers()
			return 0
		end
	end
	

	
	
	
	return 5
end

function Execute()
	SetRepeatTimer("dynasty", "AI_Reproduce", 24)
	MeasureRun("SIM", "WeddingChapel", "AdoptOrphan", false)
end


function SetFailTimers()
	adoptorphan_SetFailTimersExact(24)
end

function SetFailTimersExact(Hours)
	SetRepeatTimer("SIM", "AI_FailedReproduction_Adopt", Hours)
	SetRepeatTimer("Spouse", "AI_FailedReproduction_Adopt", Hours)
end