function Run()
end

function OnLevelUp()
	bld_HandleOnLevelUp("")
	if BuildingGetOwner("", "FruitfarmBoss") and DynastyIsAI("FruitfarmBoss") then
		-- make sure the fruitfarm has fruit and honey resources
		bld_CheckResource("", 690, 2)
	end
end

function Setup()
	bld_HandleSetup("")
	-- create ambient animals
	if Rand(2)==0 then
		worldambient_CreateAnimal("Cat", "", 1)
	else
		worldambient_CreateAnimal("Dog", "", 1)
	end
	if BuildingGetOwner("", "FruitfarmBoss") and DynastyIsAI("FruitfarmBoss") then
		-- make sure the fruitfarm has fruit and honey resources
		bld_CheckResource("", 690, 2)
	end
end

function PingHour()
	bld_HandlePingHour("", true)
	-- Improve AI management
	if BuildingGetAISetting("", "Produce_Selection") > 0 then
	--	bld_SetupAI("")
	end
	
	if math.mod(GetGametime(), 24) == 6 and BuildingGetOwner("", "FruitfarmBoss") and DynastyIsAI("FruitfarmBoss") then
		-- make sure the fruitfarm has fruit and honey resources
		bld_CheckResource("", 690, 2)
	end
end
