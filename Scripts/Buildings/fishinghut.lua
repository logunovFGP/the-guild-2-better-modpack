--
-- CheckPosition is called everytime a new position is checked for a building of this kind
-- the only alias defined here is "Position", that represents the wanted position
-- return nil if the position ok else return the label of the error message
-- attention: this function call is unscheduled
--
function CheckPosition()

	--direct Line check 
	if (BuildingFindWaterPos("Position", "PositionEntry", "WaterPos")) then
		return nil
	end

	-- deeper pos check
	if not ScenarioFindPosition("Position", 2000, EN_POSTYPE_WATER, 300, 750, EN_POSTYPE_GROUND, 100, "PosWater", "PosGround") then
		-- no water found, this is a big problem
		return "@L_GENERAL_BUILDING_NEED_WATER"
	end
	return nil
end

function OnLevelUp()
	fishinghut_SetupAI("")
	bld_HandleOnLevelUp("")
	
	GetPosition("", "Position")
	GetLocatorByName("", "Entry1", "PositionEntry")	
	if (BuildingFindWaterPos("Position", "PositionEntry", "PosWater")) then
		if (GetOutdoorMovePosition(nil, "", "PosGround")) then
			BuildingSetWaterPos("", "PosWater", "PosGround")
			return true
		end
	end
	
	if ScenarioFindPosition("", 2250, EN_POSTYPE_WATER, 300, 750, EN_POSTYPE_GROUND, 100, "PosWater", "PosGround") then
		BuildingSetWaterPos("", "PosWater", "PosGround")
		return true
	end	
	
	-- no water found, this is a big problem
	return false
end

function Setup()
	fishinghut_SetupAI("")
	bld_HandleSetup("")
end

function PingHour()
	bld_HandlePingHour("", true)
	
	-- carts are spawned in HandlePingHour if necessary
	-- raw fish sales are handled by economy cart measures 
end

--
-- Run is called directly after the building is complete initialized.
-- this is a scheduled call, so you can loop an sleep
--
function Run()
	if BuildingGetWaterPos("", true, "PosWater") then
		local Found = false
		
		for i=0, BuildingGetCartCount("")-1 do
			if BuildingGetCart("", i, "Cart") then
				if CartGetType("Cart") == EN_CT_FISHERBOOT then
					Found = true
					break
				end
			end
		end
		
		if not Found then
			if BuildingGetWaterPos("", true, "PosWater") then
				ScenarioCreateCart(EN_CT_FISHERBOOT, "", "PosWater", "fishingboat")
			end
		end
	
		if (GetOutdoorMovePosition("fishingboat", "", "GoodPos")) then
			SimBeamMeUp("fishingboat", "GoodPos")
		end	
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

function SetKeep(ItemId, Value)
	if (GetProperty("NeedStd", "NeedLock_"..ItemId) or 0) ~= 0 then
		return
	end
	if Value then
		SetProperty("NeedStd", "Keep_"..ItemId, Value)
	else
		RemoveProperty("NeedStd", "Keep_"..ItemId)
	end
end

function SetGood(ItemId, Counter, Stock)
	fishinghut_SetNeed("NeedSell", ItemId, Counter)
	fishinghut_SetNeed("NeedStd", ItemId, Stock)
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

	fishinghut_SetGood(GL_ITEM_HERRING, -1, nil)	-- Herring [310]
	fishinghut_SetKeep(GL_ITEM_HERRING, 40)
	fishinghut_SetGood(GL_ITEM_SALMON, -1, nil)	-- Salmon [311]
	fishinghut_SetKeep(GL_ITEM_SALMON, 40)

	fishinghut_SetGood(GL_ITEM_FRIEDHERRING, nil, nil)	-- Fried herring [312]
	fishinghut_SetGood(GL_ITEM_SMOKEDSALMON, nil, nil)	-- Smoked salmon [315]

	if Level >= 2 then
		fishinghut_SetGood(GL_ITEM_SHELLCHAIN, nil, nil)	-- Mussel necklace [309]
		fishinghut_SetGood(GL_ITEM_SHELL, -1, 8)	-- Mussel [313]
		fishinghut_SetGood(GL_ITEM_SHELLSOUP, nil, nil)	-- Mussel soup [314]
	end

	if Level >= 3 then
		fishinghut_SetGood(GL_ITEM_SHELL, -1, 12)	-- Mussel [313]
		fishinghut_SetGood(GL_ITEM_STINKBOMB, nil, nil)	-- Stink bomb [318]
		fishinghut_SetGood(GL_ITEM_PEARLCHAIN, nil, nil)	-- Pearl necklace [321]
	end
end
