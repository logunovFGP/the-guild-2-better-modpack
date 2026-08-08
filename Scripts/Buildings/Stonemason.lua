function Run()
end

function OnLevelUp()
	stonemason_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	stonemason_SetupAI("")
	bld_HandleSetup("")	-- create ambient animals
	if Rand(2) == 0 then
		worldambient_CreateAnimal("Cat", "", 1)
	else
		worldambient_CreateAnimal("Dog", "", 1)
	end
end

function PingHour()
	bld_HandlePingHour("", true)
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
	stonemason_SetNeed("NeedSell", ItemId, Counter)
	stonemason_SetNeed("NeedStd", ItemId, Stock)
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

	stonemason_SetGood(GL_ITEM_CLAY, -1, 20)	-- Clay [30]
	stonemason_SetGood(GL_ITEM_GRINDINGBRICK, nil, nil)	-- Grindingbrick [31]
	stonemason_SetGood(GL_ITEM_VASE, nil, nil)	-- Clay vase [32]

	if Level >= 2 then
		stonemason_SetGood(GL_ITEM_GRANITE, -1, 16)	-- Granite [39]
		stonemason_SetGood(GL_ITEM_STONEROTARY, nil, nil)	-- Stone Top [937]
		stonemason_SetGood(GL_ITEM_BUST, nil, nil)	-- Bust [938]
	end

	if Level >= 3 then
		stonemason_SetGood(GL_ITEM_STATUE, nil, nil)	-- Sculpture [939]
		stonemason_SetGood(GL_ITEM_BLISSSTONE, nil, nil)	-- Lucky Stone [946]
	end
end
