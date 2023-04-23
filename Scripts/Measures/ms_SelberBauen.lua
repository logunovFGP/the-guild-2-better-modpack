function Run()
	
	-- find the building
	local MyBuildingSites =  "__F((Object.BelongsToMe())AND(Object.CanBeControlled())AND(Object.GetObjectsByRadius(Building)==6000)AND(Object.BelongsToMe())AND(Object.GetState(building))OR(Object.GetState(levelingup)))"
	local BuildingSite = Find("", MyBuildingSites, "Building", 5)
	local BestDistance = 0
	
	-- get nearest
	for i=0, BuildingSite-1 do
		local Alias = "Building"..i
		if AliasExists(Alias) then
			local Distance = GetDistance("Owner", Alias)
			if BestDistance == 0 or Distance < BestDistance then
				BestDistance = Distance
				CopyAlias(Alias, "Destination")
			end
		end
	end
	
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
