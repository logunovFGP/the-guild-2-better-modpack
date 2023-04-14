function Weight()

	if not SimGetWorkingPlace("SIM", "PirateHarbor") then
		return 0
	end
	
	if not ReadyToRepeat("PirateHarbor", "ai_BuyPirateShip") then
		return 0
	end

	if GetMoney("PirateHarbor") < 3000 then
		return 0
	end
	
	-- be safe
	local Found = false
	if not HasProperty("PirateHarbor", "pirateship") then
	
		for i=0, BuildingGetCartCount("PirateHarbor")-1 do
			if BuildingGetCart("PirateHarbor", i, "Cart") then
				if CartGetType("Cart") == EN_CT_CORSAIR then
					Found = true
					break
				end
			end
		end
	end
	
	if Found then
		return 0
	end
	
	return 100
end

function Execute()
	SetRepeatTimer("PirateHarbor", "ai_BuyPirateShip", 24)
	BuildingBuyCart("PirateHarbor", EN_CT_CORSAIR, true, "PirateShip")
	SetProperty("PirateHarbor", "pirateship", 1)
end

