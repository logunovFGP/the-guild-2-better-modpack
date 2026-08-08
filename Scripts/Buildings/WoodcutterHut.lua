function Run()
end

function OnLevelUp()
	woodcutterhut_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	woodcutterhut_SetupAI("")
	bld_HandleSetup("")	-- create ambient animals
	if Rand(2)==0 then
		worldambient_CreateAnimal("Stag", "", 2)
	else
		worldambient_CreateAnimal("Deer", "", 2)
	end
end

function PingHour()
	bld_HandlePingHour("")
		
	-- Improve AI management
	if BuildingGetAISetting("", "Produce_Selection") > 0 then
	--	bld_SetupAI("")
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
	woodcutterhut_SetNeed("NeedSell", ItemId, Counter)
	woodcutterhut_SetNeed("NeedStd", ItemId, Stock)
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

	woodcutterhut_SetGood(GL_ITEM_PINEWOOD, nil, 12)	-- Pine wood [201]
	woodcutterhut_SetGood(GL_ITEM_OAKWOOD, nil, 8)	-- Oak wood [202]
	woodcutterhut_SetGood(GL_ITEM_CHARCOAL, nil, 8)	-- Charcoal [203]
	woodcutterhut_SetGood(GL_ITEM_FUNGI, nil, 8)	-- Mushroom Basket [204]
end
