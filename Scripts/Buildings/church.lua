function Run()
end

function OnLevelUp()
	if BuildingGetAISetting("", "Produce_Selection") > 0 then
	--	bld_SetupAI("")
	end
end

function Setup()
	-- create ambient animals
	if Rand(2) == 0 then
		worldambient_CreateAnimal("Cat", "", 1)
	else
		worldambient_CreateAnimal("Dog", "", 1)
	end
end

function PingHour()
	local currentGameTime = math.mod(GetGametime(), 24)
	if (currentGameTime == 12) then
		PlaySound3D("", "locations/bell_stroke_church_loop+0.wav", 2.0)
		Sleep(2)
		PlaySound3D("", "locations/bell_stroke_church_loop+0.wav", 2.0)
	elseif (currentGameTime == 18) then
		PlaySound3D("", "locations/bell_stroke_church_loop+0.wav", 2.0)
		Sleep(2)
		PlaySound3D("", "locations/bell_stroke_church_loop+0.wav", 2.0)
	end
	
	bld_HandlePingHour("")
end
