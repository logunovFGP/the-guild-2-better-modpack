function Run()
end

function OnLevelUp()
	farm_SetupAI("")
	bld_HandleOnLevelUp("")
	if BuildingGetOwner("", "FarmBoss") and DynastyIsAI("FarmBoss") then
		-- make sure the fruitfarm has fruit and honey resources
		bld_CheckResource("", 635, 2)
		bld_CheckResource("", 618, 3)
	end
end

function Setup()
	farm_SetupAI("")
	bld_HandleSetup("")
	if BuildingGetOwner("", "FarmBoss") and DynastyIsAI("FarmBoss") then
		-- make sure the fruitfarm has fruit and honey resources
		bld_CheckResource("", 635, 2)
		bld_CheckResource("", 618, 3)
	end
	-- create ambient animals
	--worldambient_CreateAnimal("Cock", "", 1)
	--worldambient_CreateAnimal("Chicken", "", 3)
end

function PingHour()
	bld_HandlePingHour("", true)
	
	if BuildingGetAISetting("", "Produce_Selection") > 0 then
		-- economy_CalcProductionPriorities("")
	end
	
	if math.mod(GetGametime(), 24) == 6 and BuildingGetOwner("", "FarmBoss") and DynastyIsAI("FarmBoss") then
		-- make sure the farm has resources
		bld_CheckResource("", 635, 2)
		bld_CheckResource("", 618, 3)
	end
end

function SetNeed(InvAlias, ItemId, Value)
	if (GetProperty(InvAlias, "NeedLock_"..ItemId) or 0) ~= 0 then
		return
	end
	if Value then
		SetProperty(InvAlias, "Need_"..ItemId, Value)
	else
		RemoveProperty(InvAlias, "Need_"..ItemId)
	end
end

function SetGood(ItemId, Counter, Stock)
	farm_SetNeed("NeedSell", ItemId, Counter)
	farm_SetNeed("NeedStd", ItemId, Stock)
end

function SetupAI(Alias)
	local Level = BuildingGetLevel(Alias)
	if Level < 1 then
		return
	end
	if not GetInventory(Alias, INVENTORY_STD, "NeedStd") then
		return
	end
	if not GetInventory(Alias, INVENTORY_SELL, "NeedSell") then
		return
	end

	farm_SetGood(GL_ITEM_WHEAT, nil, 4)	-- Grain [2]
	farm_SetGood(GL_ITEM_BARLEY, nil, 4)	-- Barley [3]
	farm_SetGood(GL_ITEM_WOOL, nil, 4)	-- Wool [8]
	farm_SetGood(GL_ITEM_BEEF, nil, 4)	-- Beef [10]

	if Level >= 2 then
		farm_SetGood(GL_ITEM_LEATHER, nil, 4)	-- Leather [11]
	end
end
