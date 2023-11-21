function Weight()
	
	if SimGetSpouse("SIM", "Spouse") then
		return 0
	end
	
	if not ReadyToRepeat("dynasty", "AI_CourtLover") then
		return 0
	end

	if SimGetCourtLover("SIM", "Beloved") then
		if GetStateImpact("Beloved", "no_control") then
			return 0
		end
	end
	
	if not AliasExists("Beloved") then
		SetData("aicl_todo", "Start")
		return 100
	end
	
	if SimGetBehavior("Beloved") == "CheckPresession" or SimGetBehavior("Beloved") == "CheckTrial" then
		return 0
	end
	
	if not f_SimIsValid("Beloved") then
		return 0
	end
	
	local	Progress = SimGetProgress("SIM")
	
	if Progress >= 99 then
		SetData("aicl_todo", "Marry")
		return 500
	end
	
	-- Do Courting
	SetData("aicl_todo", "Court")
	return 100
end

function Execute()
	
	local	ToDo = GetData("aicl_todo")
	
	if ToDo == "Start" then
		MeasureRun("SIM", nil, "CourtLover")
		return
	elseif ToDo == "Marry" then
		MeasureRun("SIM", "Beloved", "Marry")
		return
	elseif ToDo == "Court" then
		local MeasureName = gameplayformulas_FindCourtingMeasure("SIM", "Beloved") -- find a good courting measure
		
		if MeasureName == "none" then
			SetRepeatTimer("dynasty", "AI_CourtLover", 2)
			return
		else
			MeasureRun("SIM", "Beloved", MeasureName) -- start measure
			return
		end
	else
		return
	end
end
