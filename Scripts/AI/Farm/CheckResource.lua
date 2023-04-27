function Weight()
	return 0
end

function Execute()

	local	Proto
	local MinDistance
	local Done
	local checkTown = GetData("daTown")
	local ItemID = GetData("ItemID")

	local	ToDo = GetData("ToDo")
	
	if ToDo == "BuildNew" then

		Proto = GetData("Proto")
		if not CityBuildNewBuilding("BuildCity", Proto, "BuildOwner", "ResourceAlias", "WorkBuilding") then
			if not AliasExists("ResourceAlias") then
				return
			end
			if not BuildingBuy("ResourceAlias", "BuildOwner", BM_NORMAL) then
				return
			end
		else
			local x = 1
		end
        if Proto == 618 then
		    ToDo = "RaiseCattle"
		else
		    ToDo = "SowField"
		end
	elseif ToDo == "Buy" then

		Proto	= GetData("Proto")
		Done 	= false
		MinDistance = GetDistance("ResourceAlias", "WorkBuilding")
		
		if MinDistance>0 then
			if CityBuildNewBuilding("BuildCity", Proto, "BuildOwner", "ResourceAlias", "WorkBuilding", MinDistance-1000) then
				Done = true
			end
		end
		
		if not Done then
			if not BuildingBuy("ResourceAlias", "BuildOwner", BM_NORMAL) then
				return
			end
		end
        if Proto == 618 then
			ToDo = "RaiseCattle"
		else
		    ToDo = "SowField"
		end
	end
	
	if ToDo == "SowField" then
		MeasureCreate("Measure")
		local	Entry = ResourceGetEntry("ResourceAlias", ItemID)
		local MeasureName = ResourceGetMeasureID("ResourceAlias", ItemID)
		if not MeasureName then
			MeasureName = "SowField"
		end
		MeasureAddData("Measure", "Selection", Entry)
		MeasureStart("Measure", "SIM", "ResourceAlias", MeasureName)
		return
	elseif ToDo == "RaiseCattle" then
	    if HasProperty("ResourceAlias","ToBeSowed") then
		    return
		else
		    SetProperty("ResourceAlias","ToBeSowed",1)
		end
	    MeasureCreate("Measure")
		local Entry = ResourceGetEntry("ResourceAlias", ItemID)
		local MeasureName = ResourceGetMeasureID("ResourceAlias", ItemID)
		if not MeasureName then
		    MeasureName = "RaiseCattle"
		end
		MeasureAddData("Measure", "Selection", Entry)
		MeasureStart("Measure", "SIM", "ResourceAlias", MeasureName)
		return
	end
	
end

