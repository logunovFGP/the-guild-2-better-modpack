function Run()
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
