function Run()
end

function OnLevelUp()
	smith_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	smith_SetupAI("")
	bld_HandleSetup("")
	-- create ambient animals
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
	smith_SetNeed("NeedSell", ItemId, Counter)
	smith_SetNeed("NeedStd", ItemId, Stock)
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

	smith_SetGood(GL_ITEM_TOOL, nil, nil)	-- Tool [60]
	smith_SetGood(GL_ITEM_DAGGER, nil, nil)	-- Dagger [61]
	smith_SetGood(GL_ITEM_BESCHLAG, -1, 10)	-- Fitting [904]

	if Level >= 2 then
		smith_SetGood(GL_ITEM_SILVERRING, nil, nil)	-- Silver ring [63]
		smith_SetGood(GL_ITEM_SHORTSWORD, nil, nil)	-- Shortsword [64]
		smith_SetGood(GL_ITEM_IRONBRACHELET, nil, nil)	-- Iron bracer [65]
		smith_SetGood(GL_ITEM_LONGSWORD, nil, nil)	-- Longsword [69]
		smith_SetGood(GL_ITEM_IRONCAP, nil, nil)	-- Iron cap [70]
		smith_SetGood(GL_ITEM_CHAINMAIL, nil, nil)	-- Chain mail [71]
	end

	if Level >= 3 then
		smith_SetGood(GL_ITEM_GEMRING, nil, nil)	-- Precious stone ring [66]
		smith_SetGood(GL_ITEM_BELTOFMETAPHYSIC, nil, nil)	-- Metaphysical belt [67]
		smith_SetGood(GL_ITEM_GOLDCHAIN, nil, nil)	-- Gold chain [68]
		smith_SetGood(GL_ITEM_FULLHELMET, nil, nil)	-- Full helm [73]
		smith_SetGood(GL_ITEM_PLATEMAIL, nil, nil)	-- Plate mail [74]
	end
end
