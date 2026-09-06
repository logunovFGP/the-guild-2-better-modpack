function Weight()
	if not AliasExists("SIM") then
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
			-- a young couple in a residence gets 30 days for a child of their own first;
			-- the house wants three children and adopts when they do not come
			local Until = GetProperty("SIM", "AI_NaturalTryUntil")
			if not Until then
				Until = GetGametime() + 720
				SetProperty("SIM", "AI_NaturalTryUntil", Until)
			end
			if GetGametime() < Until then
				adoptorphan_SetFailTimers()
				return 0
			end
		end
	end
	
	
	local time = math.mod(GetGametime(),24)
	if time < 8 then
		adoptorphan_SetFailTimersExact(8 - time)
		return 0
	end
	
	-- we're probably not gonna get there in time, so don't waste any
	if time >= 21 then
		adoptorphan_SetFailTimersExact(8+ (24-time))
		return 0
	end
	
	local Title = GetNobilityTitle("SIM")
	if mdata_GetPrice("AdoptOrphan", Title) > GetMoney("SIM") then
		adoptorphan_SetFailTimersExact(6)
		return 0
	end
	
	
	
	return 5
end

function Execute()
	SetRepeatTimer("dynasty", "AI_Reproduce", 24)
	MeasureRun("SIM", "WeddingChapel", "AdoptOrphan", false)
	SetProperty("SIM", "AI_NaturalTryUntil", GetGametime() + 720) -- another 30 days of trying before the next adoption
end


function SetFailTimers()
	adoptorphan_SetFailTimersExact(24)
end

function SetFailTimersExact(Hours)
	SetRepeatTimer("SIM", "AI_FailedReproduction_Adopt", Hours)
	SetRepeatTimer("Spouse", "AI_FailedReproduction_Adopt", Hours)
end