function Run()
end

function OnLevelUp()
	tailor_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	tailor_SetupAI("")
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
	tailor_SetNeed("NeedSell", ItemId, Counter)
	tailor_SetNeed("NeedStd", ItemId, Stock)
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

	tailor_SetGood(GL_ITEM_CLOTH, nil, 10)	-- Linen [100]
	tailor_SetGood(GL_ITEM_MONEYBAG, nil, nil)	-- Purse [101]
	tailor_SetGood(GL_ITEM_BLANKET, nil, 8)	-- Woollen blanket [102]
	tailor_SetGood(GL_ITEM_FARMERSCLOTHES, nil, nil)	-- Peasant clothes [103]

	if Level >= 2 then
		tailor_SetGood(GL_ITEM_LEATHERARMOR, nil, nil)	-- Leather doublet [104]
		tailor_SetGood(GL_ITEM_CITIZENSCLOTHES, nil, nil)	-- Citizen's clothes [105]
		tailor_SetGood(GL_ITEM_GLOVESOFDEXTERITY, nil, nil)	-- Duelling gloves [106]
	end

	if Level >= 3 then
		tailor_SetGood(GL_ITEM_NOBLESCLOTHES, nil, nil)	-- Noble's clothes [107]
		tailor_SetGood(GL_ITEM_CAMOUFLAGECLOAK, nil, nil)	-- Camouflage cloak [108]
		tailor_SetGood(GL_ITEM_LEATHERGLOVES, nil, nil)	-- Leather gloves [109]
	end
end
