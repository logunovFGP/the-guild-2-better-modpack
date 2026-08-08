function Run()
end

function OnLevelUp()
	joiner_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	joiner_SetupAI("")
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
	joiner_SetNeed("NeedSell", ItemId, Counter)
	joiner_SetNeed("NeedStd", ItemId, Stock)
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

	joiner_SetGood(GL_ITEM_OAKWOODRING, nil, nil)	-- Oak ring [79]
	joiner_SetGood(GL_ITEM_BUILDMATERIAL, nil, nil)	-- Construction material [80]
	joiner_SetGood(GL_ITEM_TORCH, nil, nil)	-- Torch [81]
	joiner_SetGood(GL_ITEM_WALKINGSTICK, nil, nil)	-- Walking stick [82]
	joiner_SetGood(GL_ITEM_HOLZZAPFEN, nil, 15)	-- Wood Pin [903]

	if Level >= 2 then
		joiner_SetGood(GL_ITEM_MACE, 2, nil)	-- Mace [83]
		joiner_SetGood(GL_ITEM_CROSSOFPROTECTION, nil, nil)	-- Protective cross [85]
		joiner_SetGood(GL_ITEM_CARTBOOSTER, nil, nil)	-- Light lubricant [138]
	end

	if Level >= 3 then
		joiner_SetGood(GL_ITEM_MACE, nil, nil)	-- Mace [83]
		joiner_SetGood(GL_ITEM_RUBINSTAFF, nil, nil)	-- Ruby staff [88]
		joiner_SetGood(GL_ITEM_AXE, nil, nil)	-- Battleaxe [89]
		joiner_SetGood(GL_ITEM_KAMM, nil, nil)	-- Comb [902]
	end
end
