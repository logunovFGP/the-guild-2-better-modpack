function Run()
end

function OnLevelUp()
	juggler_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	juggler_SetupAI("")
	bld_HandleSetup("")
	-- create ambient animals
	if Rand(2)==0 then
		worldambient_CreateAnimal("Cat", "", 1)
	else
		worldambient_CreateAnimal("Dog", "", 1)
	end
end

function PingHour()
	
	if not GetState("", STATE_MOVING_BUILDING) and not GetState("", STATE_BUILDING) and not GetState("", STATE_LEVELINGUP) then
		SetState("", STATE_MOVING_BUILDING, true)
	end

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
	juggler_SetNeed("NeedSell", ItemId, Counter)
	juggler_SetNeed("NeedStd", ItemId, Stock)
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

	juggler_SetGood(GL_ITEM_WILLOWROT, -1, 20)	-- Willow withe [569]
	juggler_SetGood(GL_ITEM_AMULET, nil, nil)	-- Protective charm [571]
	juggler_SetGood(GL_ITEM_SPINDEL, nil, nil)	-- Spindel [975]

	if Level >= 2 then
		juggler_SetGood(GL_ITEM_CLAY, nil, 20)	-- Clay [30]
		juggler_SetGood(GL_ITEM_PENDEL, nil, nil)	-- Pendel [974]
	end

	if Level >= 3 then
		juggler_SetGood(GL_ITEM_VOODO, nil, nil)	-- Voodoo Doll [976]
	end
end
