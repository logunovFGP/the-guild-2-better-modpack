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
