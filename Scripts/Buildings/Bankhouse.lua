function Run()
end

function OnLevelUp()
	bankhouse_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	bankhouse_SetupAI("")
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
	bankhouse_SetNeed("NeedSell", ItemId, Counter)
	bankhouse_SetNeed("NeedStd", ItemId, Stock)
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

	bankhouse_SetGood(GL_ITEM_OPTIEISEN, -1, nil)	-- Optieisen [954]
	bankhouse_SetGood(GL_ITEM_GOLDLOWMED, nil, nil)	-- Goldlowmed [959]
	bankhouse_SetGood(GL_ITEM_PERGAMENT, -1, 12)	-- Pergament [963]

	if Level >= 2 then
		bankhouse_SetGood(GL_ITEM_OPTISILBER, -1, nil)	-- Optisilber [953]
		bankhouse_SetGood(GL_ITEM_GOLDMEDHIGH, nil, nil)	-- Goldmedhigh [957]
		bankhouse_SetGood(GL_ITEM_SCHULDENBRIEF, nil, nil)	-- Obligation [962]
	end

	if Level >= 3 then
		bankhouse_SetGood(GL_ITEM_OPTIGOLD, -1, nil)	-- Optigold [952]
		bankhouse_SetGood(GL_ITEM_GOLDVERYHIGH, nil, nil)	-- Goldveryhigh [955]
		bankhouse_SetGood(GL_ITEM_URKUNDE, nil, nil)	-- Certificate [961]
	end
end
