function Weight()

	local trys = 0
	while not AliasExists("Target") do
		trys = trys + 1
		local TargetID = gameplayformulas_GetRandomPlayer()
		if GetAliasByID(TargetID, "CheckMe") then
			if ReadyToRepeat("dynasty", "DIP_"..TargetID) then
				CopyAlias("CheckMe", "Target")
				break
			end
		end
		
		TargetID = gameplayformulas_GetRandomImportantDynasty()
		if GetAliasByID(TargetID, "CheckMe") then
			if ReadyToRepeat("dynasty", "DIP_"..TargetID) then
				CopyAlias("CheckMe", "Target")
				break
			end
		end
		
		if trys > 10 then
			break
		end
	end
	
	if not AliasExists("Target") then
		return 0
	end
	
	if not DynastyGetRandomBuilding("SIM", 2, GL_BUILDING_TYPE_CHURCH_EV, "Church") then
		if not DynastyGetRandomBuilding("SIM", 2, GL_BUILDING_TYPE_CHURCH_CATH, "Church") then
			return 0
		end
	end
		
	if not ReadyToRepeat("dynasty", "AI_Worship") then
		return 0
	end
	
	return 100
end

function Execute()
	local TargetID = GetID("Target")
	SetRepeatTimer("dynasty", "AI_Worship", 12)
	if AliasExists("Church") then
		SetProperty("Church", "PraiseSomeone", TargetID)
	end
end
