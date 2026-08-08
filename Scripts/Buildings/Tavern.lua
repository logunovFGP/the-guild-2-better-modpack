function Run()
end

function OnLevelUp()
	tavern_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	tavern_SetupAI("")
	bld_HandleSetup("")	-- create ambient animals
	if Rand(2)==0 then
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
	tavern_SetNeed("NeedSell", ItemId, Counter)
	tavern_SetNeed("NeedStd", ItemId, Stock)
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

	tavern_SetGood(GL_ITEM_ALCOHOL, 8, 16)	-- Alcohol [40]
	tavern_SetGood(GL_ITEM_GRAINPAP, 8, 16)	-- Grain porridge [41]
	tavern_SetGood(GL_ITEM_SMALLBEER, 12, 18)	-- Weak beer [42]

	if Level >= 2 then
		tavern_SetGood(GL_ITEM_SMALLBEER, 12, 24)	-- Weak beer [42]
		tavern_SetGood(GL_ITEM_SALMONFILET, 4, 8)	-- Salmon fillet [43]
		tavern_SetGood(GL_ITEM_WHEATBEER, 9, 15)	-- Wheat beer [44]
		tavern_SetGood(GL_ITEM_MEAD, nil, nil)	-- Mead [45]
	end

	if Level >= 3 then
		tavern_SetGood(GL_ITEM_ROASTBEEF, nil, nil)	-- Roast beef [46]
		tavern_SetGood(GL_ITEM_BOOZYBREATHBEER, nil, nil)	-- Drunkard Brew beer [47]
		tavern_SetGood(GL_ITEM_GHOSTLYFOG, nil, nil)	-- Ghostly fog [48]
	end
end
