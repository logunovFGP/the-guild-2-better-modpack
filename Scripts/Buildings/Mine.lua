function Run()
end

function OnLevelUp()
	mine_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	mine_SetupAI("")
	bld_HandleSetup("")
	-- create ambient animals
	if Rand(2) == 0 then
		worldambient_CreateAnimal("Stag", "", 2)
	else
		worldambient_CreateAnimal("Deer", "", 2)
	end
end

function PingHour()
	bld_HandlePingHour("", true)	
	
	-- Improve AI management
	if BuildingGetAISetting("", "Produce_Selection") > 0 then
	--	bld_SetupAI("")
		-- economy_CalcProductionPriorities("")
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
	mine_SetNeed("NeedSell", ItemId, Counter)
	mine_SetNeed("NeedStd", ItemId, Stock)
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

	mine_SetGood(GL_ITEM_IRON, nil, 12)	-- Iron [241]
	mine_SetGood(GL_ITEM_SILVER, nil, 8)	-- Silver [242]
	mine_SetGood(GL_ITEM_GOLD, nil, 4)	-- Gold [243]
	mine_SetGood(GL_ITEM_GEMSTONE, nil, 4)	-- Precious stone [244]
end
