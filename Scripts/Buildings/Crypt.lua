function Run()
end

function OnLevelUp()
	crypt_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	crypt_SetupAI("")
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
	crypt_SetNeed("NeedSell", ItemId, Counter)
	crypt_SetNeed("NeedStd", ItemId, Stock)
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

	crypt_SetGood(GL_ITEM_SCHADELKERZE, nil, nil)	-- Skull Candle [966]
	crypt_SetGood(GL_ITEM_EKTOPLASMA, -1, 20)	-- Ectoplasm [968]
	crypt_SetGood(GL_ITEM_KNOCHENARMREIF, nil, nil)	-- Bone Bangle [969]
	crypt_SetGood(GL_ITEM_SCHADEL, -1, 40)	-- Skull [972]
	crypt_SetGood(GL_ITEM_KNOCHEN, -1, 40)	-- Knochen [973]

	if Level >= 2 then
		crypt_SetGood(GL_ITEM_HEXERDOKUMENTI, nil, nil)	-- Sorcerer Document I [965]
		crypt_SetGood(GL_ITEM_LEICHENHEMD, -1, 20)	-- Burial Gown [971]
		crypt_SetGood(GL_ITEM_PDDV, nil, nil)	-- Pddv [979]
	end

	if Level >= 3 then
		crypt_SetGood(GL_ITEM_HEXERDOKUMENTII, nil, nil)	-- Sorcerer Document II [964]
		crypt_SetGood(GL_ITEM_ROBE, nil, nil)	-- Sorcerer Robe [977]
	end
end
