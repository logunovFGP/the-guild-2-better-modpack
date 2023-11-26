function Weight()

	if not ReadyToRepeat("SIM", "AI_CheckOutfit") then
		return 0
	end

	if not SimGetWorkingPlace("SIM", "Place") then
		return 0
	end
	
	if not BuildingGetOwner("Place", "RobberBoss") then
		return 0
	end

	if GetMoney("RobberBoss") < 3000 then
		return 0
	end

	return 100
end

function Execute()
	SetRepeatTimer("SIM", "AI_CheckOutfit", 12)
	SetProperty("SIM", "SpecialMeasureId", -MeasureGetID("CheckOutfit"))
end

