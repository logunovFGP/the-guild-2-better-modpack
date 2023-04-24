function Run()
	
	-- find the building
	local Counter = DynastyGetBuildingCount2("")
	local BestDistance = 0
	
	for i=0, Counter-1 do
		if DynastyGetBuilding2("", i, "Building") then
			if GetState("Building", STATE_BUILDING) or GetState("Building", STATE_LEVELINGUP) then
				local Distance = GetDistance("", "Building")
				if BestDistance == 0 or Distance < BestDistance then
					CopyAlias("Building", "Destination")
					BestDistance = Distance
				end
			end
		end
	end
	
	LogMessage("BuildingSite is "..Counter)
	
	if not AliasExists("Destination") then
		LogMessage("SelberBauen no Destination")
		return
	end
	
        if GetImpactValue("Destination", "BauArbeiter") >= 5 then
	        local k = 3
		
		if GetImpactValue("Destination", "BauArbeiter") >= 8 then
			k = 4
		end
		
		MsgNewsNoWait("Owner", "Destination", "", "default", -1, "@L_HPFZ_STATE_GEBBAU_FEHLER_+2",
					"@L_HPFZ_STATE_GEBBAU_FEHLER_+"..k)
	else
		MeasureRun("Owner", "Destination", "BauArbeitMeasure", true)
	end
end
