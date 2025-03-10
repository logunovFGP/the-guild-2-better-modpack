function Run()
end

function OnLevelUp()
	bld_HandleOnLevelUp("")
	if BuildingGetOwner("", "FarmBoss") and DynastyIsAI("FarmBoss") then
		-- make sure the fruitfarm has fruit and honey resources
		bld_CheckResource("", 635, 2)
		bld_CheckResource("", 618, 3)
	end
end

function Setup()
	bld_HandleSetup("")
	if BuildingGetOwner("", "FarmBoss") and DynastyIsAI("FarmBoss") then
		-- make sure the fruitfarm has fruit and honey resources
		bld_CheckResource("", 635, 2)
		bld_CheckResource("", 618, 3)
	end
	-- create ambient animals
	--worldambient_CreateAnimal("Cock", "", 1)
	--worldambient_CreateAnimal("Chicken", "", 3)
end

function PingHour()
	bld_HandlePingHour("", true)
	
	if BuildingGetAISetting("", "Produce_Selection") > 0 then
		economy_CalcProductionPriorities("")
	end
	
	if math.mod(GetGametime(), 24) == 6 and BuildingGetOwner("", "FarmBoss") and DynastyIsAI("FarmBoss") then
		-- make sure the farm has resources
		bld_CheckResource("", 635, 2)
		bld_CheckResource("", 618, 3)
	end
end
