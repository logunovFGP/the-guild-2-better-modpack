function Weight()

	if SimGetWorkingPlace("SIM", "WorkBuilding") then
		-- alles ok
	elseif IsPartyMember("SIM") then
			local NextBuilding = ai_GetNearestDynastyBuilding("SIM",GL_BUILDING_CLASS_WORKSHOP,GL_BUILDING_TYPE_FRUITFARM)
			if not NextBuilding then
				return 0
			end
			CopyAlias(NextBuilding,"WorkBuilding")
	else
	    return 0
	end
	
	if not BuildingGetOwner("WorkBuilding", "BuildOwner") then
		return 0
	end
	
	if not BuildingGetCity("WorkBuilding", "BuildCity") then
		return 0
	end
	
	if not ReadyToRepeat("WorkBuilding", "AI_CR") then
		return 0
	end
	
	-- TODO add timer for resource check (separate timers for fields and animals)
	if ReadyToRepeat("WorkBuilding", "AI_CR_Meadows") then
		if GetRound() > 0 then
			SetRepeatTimer("WorkBuilding", "AI_CR_Meadows", 20)
		else
			SetRepeatTimer("WorkBuilding", "AI_CR_Meadows", 0.5)
		end
		local	CheckFieldResources = { "Honey", "Fruit" }
		local FieldProto = 690
		
		local MissingResources, MissingResourceCount = {}, 0
		for i=1, 2 do
			local Item = CheckFieldResources[i]
			if BuildingCanProduce("WorkBuilding", Item) and not bld_IsResourceAvailable("WorkBuilding", Item) then
				MissingResourceCount = MissingResourceCount + 1
				MissingResources[MissingResourceCount] = Item
			end
		end
		
		if MissingResourceCount > 0 then
			-- TODO replace random by proper logic
			SetData("MeasureName", "SowWiese")
			SetData("ResourceToSow", MissingResources[Rand(MissingResourceCount) + 1])
			return 100
		end
	end
	
	return 0
end

function Execute()
	local ItemName = GetData("ResourceToSow")
	local ItemID = ItemGetID(ItemName)
	local MeasureName = GetData("MeasureName")
	
	-- TODO find available field (empty first, otherwise other)
	local ResourceAlias = "ResourceAlias"
	local Radius = 4000
	local IgnoreOwnership = (GL_BUILDING_TYPE_FRUITFARM == BuildingGetType("WorkBuilding") and DynastyIsAI("WorkBuilding"))
	local DynFilter = "AND(Object.CanBeControlled())"
	if IgnoreOwnership then
		DynFilter = ""
	end
	
	local FilterByItem = string.format("__F((Object.GetObjectsByRadius(Building)==%d)AND(Object.IsClass(6))AND(Object.IsType(33))%s)", Radius, DynFilter)
	local Count = Find("WorkBuilding", FilterByItem, "ResourceSearchResult", 20)
	for i=0, Count - 1 do
		if AliasExists("ResourceSearchResult"..i) -- safety check
				and ResourceCanBeChanged("ResourceSearchResult"..i) -- it's a changeable resource like a field or meadow
				and ResourceGetEntry("ResourceSearchResult"..i, ItemID) >= 0 then
			local ResItemId = GetProperty("ResourceSearchResult"..i, "ResourceItemID") or -1
			if ResItemId <= 0 or not AliasExists(ResourceAlias) then
				CopyAlias("ResourceSearchResult"..i, ResourceAlias)
			end
		end
	end

	if not AliasExists(ResourceAlias) then
		-- no resource available, abort
		return
	end

	MeasureName = MeasureName or ResourceGetMeasureID(ResourceAlias, ItemID)
	MeasureCreate("Measure")
	local	Entry = ResourceGetEntry(ResourceAlias, ItemID)
	MeasureAddData("Measure", "Selection", Entry)
	MeasureStart("Measure", "SIM", ResourceAlias, MeasureName)
end

