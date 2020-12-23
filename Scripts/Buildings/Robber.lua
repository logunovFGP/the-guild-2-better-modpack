function Run()
	if BuildingGetOwner("", "MyBoss") and BuildingGetCartCount("") < 1 then
		GetOutdoorMovePosition(nil, "", "Pos")
		ScenarioCreateCart(EN_CT_MIDDLE, "", "Pos", "NewCart")
	end
end

function OnLevelUp()
	bld_HandleOnLevelUp("")
end

function Setup()
	bld_HandleSetup("")
	worldambient_CreateAnimal("Wolf", "" , 2)
end

function PingHour()
	bld_HandlePingHour("", true)
end
