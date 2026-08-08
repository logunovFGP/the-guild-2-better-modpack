function Run()
end

function OnLevelUp()
	windmill_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	windmill_SetupAI("")
	bld_HandleSetup("")	-- create ambient animals
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
	windmill_SetNeed("NeedSell", ItemId, Counter)
	windmill_SetNeed("NeedStd", ItemId, Stock)
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

	windmill_SetGood(GL_ITEM_BARLEYFLOUR, 20, nil)	-- BarleyFlour [943]
	windmill_SetGood(GL_ITEM_WHEATFLOUR, 16, nil)	-- WheatFlour [944]
end
