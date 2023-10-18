function MehlMahlen()

	f_MoveTo("", "WorkBuilding")
	StartProduction("", "WorkBuilding")
--	SetProperty("WorkBuilding", "Active", 1)
    
	while true do
		
		PlaySound3D("WorkBuilding", "Cart/CartRumbling_r_01.wav", 1.0)
		Sleep(15)
		
--		if not HasProperty("WorkBuilding", "Active") or GetProperty("WorkBuilding", "Active")~= 1 then
--			SetProperty("WorkBuilding", "Active", 1)
--		end
	end

	return --true
end

function CleanUp()

  --  SetProperty("WorkBuilding", "Active", 0)
	SetData("muehle", 0)
end
