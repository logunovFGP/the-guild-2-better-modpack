function Run()
end

function OnLevelUp()
	baker_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	baker_SetupAI("")
	bld_HandleSetup("")
	-- create ambient animals
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
	baker_SetNeed("NeedSell", ItemId, Counter)
	baker_SetNeed("NeedStd", ItemId, Stock)
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

	baker_SetGood(GL_ITEM_BARLEYBREAD, 8, nil)	-- Barley bread [20]
	baker_SetGood(GL_ITEM_COOKIE, 12, nil)	-- Biscuit [21]

	if Level >= 2 then
		baker_SetGood(GL_ITEM_WHEATBREAD, 8, nil)	-- Wheat bread [22]
		baker_SetGood(GL_ITEM_CAKE, nil, nil)	-- Tart [23]
	end

	if Level >= 3 then
		baker_SetGood(GL_ITEM_BREADROLL, 2, nil)	-- Wheat roll [25]
		baker_SetGood(GL_ITEM_CREAMPIE, 2, nil)	-- Cream pie [26]
		baker_SetGood(GL_ITEM_CANDY, nil, nil)	-- Sweetmeat [27]
	end
end
