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
	
	if not ReadyToRepeat("dynasty", "DIP_"..GetDynastyID("Target")) then
		return 0
	end
	
	if Rand(3) > 0 then
		return 0
	end
	
	return 100
end

function Execute()
	MeasureCreate("measure")
	MeasureAddData("Measure", "Choice", 2, false)
	MeasureStart("Measure", "SIM", "Target", "AdministrateDiplomacy")
end