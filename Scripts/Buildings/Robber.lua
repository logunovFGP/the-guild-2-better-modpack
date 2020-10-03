function Run()
end

function OnLevelUp()
end


function Setup()
	worldambient_CreateAnimal("Wolf", "" , 2)
	
	if BuildingGetCartCount("") < 1 then
		GetOutdoorMovePosition(nil, "", "Pos")
		ScenarioCreateCart(EN_CT_MIDDLE, "", "Pos", "NewCart")
	end
end

function PingHour()
	bld_HandlePingHour("")
end
