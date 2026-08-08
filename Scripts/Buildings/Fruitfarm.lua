function Run()
end

function OnLevelUp()
	fruitfarm_SetupAI("")
	bld_HandleOnLevelUp("")
	if BuildingGetOwner("", "FruitfarmBoss") and DynastyIsAI("FruitfarmBoss") then
		-- make sure the fruitfarm has fruit and honey resources
		bld_CheckResource("", 690, 2)
	end
end

function Setup()
	fruitfarm_SetupAI("")
	bld_HandleSetup("")
	-- create ambient animals
	if Rand(2)==0 then
		worldambient_CreateAnimal("Cat", "", 1)
	else
		worldambient_CreateAnimal("Dog", "", 1)
	end
	if BuildingGetOwner("", "FruitfarmBoss") and DynastyIsAI("FruitfarmBoss") then
		-- make sure the fruitfarm has fruit and honey resources
		bld_CheckResource("", 690, 2)
	end
end

function PingHour()
	bld_HandlePingHour("", true)
	-- Improve AI management
	if BuildingGetAISetting("", "Produce_Selection") > 0 then
	--	bld_SetupAI("")
	end
	
	if math.mod(GetGametime(), 24) == 6 and BuildingGetOwner("", "FruitfarmBoss") and DynastyIsAI("FruitfarmBoss") then
		-- make sure the fruitfarm has fruit and honey resources
		bld_CheckResource("", 690, 2)
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
	fruitfarm_SetNeed("NeedSell", ItemId, Counter)
	fruitfarm_SetNeed("NeedStd", ItemId, Stock)
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

	fruitfarm_SetGood(GL_ITEM_HONEY, 16, nil)	-- Honeycomb [940]
	fruitfarm_SetGood(GL_ITEM_FRUIT, 16, nil)	-- Fruit [941]
end
