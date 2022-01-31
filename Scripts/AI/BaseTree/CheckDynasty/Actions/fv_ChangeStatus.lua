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
	
	if not GetDynasty("Target", "TargetDyn") then
		return 0
	end
	
	local BestState = ai_DynastyGetBestDiplomacyState("SIM", "Target")
	if BestState ~= "CurrentState" then
		if BestState == "ALLIANCE" then
			SetData("SetStatusTo", 3) -- to ALLIANCE
		elseif BestState == "NAP" then
			SetData("SetStatusTo", 2) -- to NAP
		elseif BestState == "NEUTRAL" then
			SetData("SetStatusTo", 1) -- to NEUTRAL
		elseif BestState == "FOE" then
			SetData("SetStatusTo", 0) -- to FOE
		end
		return 100
	end
	
	return 0
end

function Execute()
	SetRepeatTimer("dynasty", "DIP_"..GetDynastyID("Target"), 22)
	MeasureCreate("measure")
	MeasureAddData("Measure", "Choice", 1, false) -- change status
	MeasureAddData("Measure", "InitResult", GetData("SetStatusTo"), false) -- the new status
	MeasureStart("Measure", "SIM", "Target", "AdministrateDiplomacy")
end