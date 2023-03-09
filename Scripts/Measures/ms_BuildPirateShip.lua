function Init()
	
	local Found = false
	
	if not HasProperty("", "pirateship") then
	
		for i=0, BuildingGetCartCount("")-1 do
			if BuildingGetCart("", i, "Cart") then
				if CartGetType("Cart") == EN_CT_CORSAIR then
					Found = true
				end
			end
		end
	end
	
	if Found then
		if not HasProperty("", "pirateship") then
			SetProperty("", "pirateship", 1)
		end
		
		MsgQuick("", "@L_FAILURE_BUILD_PIRATESHIP_+0", GetID(""))
		StopMeasure()
	end
end 

function Run()
	BuildingBuyCart("", EN_CT_CORSAIR, true, "PirateShip")
	SetProperty("", "pirateship", 1)
end

function CleanUp()
end
