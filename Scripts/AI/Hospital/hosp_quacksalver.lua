function Weight()

	--LogMessage("CheckQuacksalver")
	
	if not SimGetWorkingPlace("SIM", "Hospital") then
		if not ai_GetWorkBuilding("SIM", GL_BUILDING_TYPE_HOSPITAL, "Hospital") then
			return 0
		end
	end
	
	if not GetSettlement("Hospital", "City") then
		return 0
	end
	
	if not ReadyToRepeat("Hospital", "AI_QUACKSALVER") then
--		LogMessage("CheckQuacksalver Not ready")
		return 0
	end

	if not BuildingCanProduce("Hospital", "MiracleCure") then
		--LogMessage("Can not produce MiracleCure")
		return 0
	end
	
	if BuildingGetProducerCount("Hospital", PT_MEASURE, "Quacksalver") > 0 then
		--LogMessage("Too many quacksalver")
		return 0
	end
	
	chr_CityFindCrowdedPlace("City", "SIM", false, "Destination")
	if not AliasExists("Destination") then
		return 0
	end

	if GetItemCount("SIM", "MiracleCure") >= 1 then
		return 100
	elseif GetItemCount("Hospital", "MiracleCure", INVENTORY_STD) >= 5 then
		LogMessage("CheckQuacksalver enough miraclecure")
		return 100
	elseif GetItemCount("Hospital", "MiracleCure", INVENTORY_SELL) >= 5 then
		return 100
	end

	return 0
end

function Execute()
	--LogMessage("SetRepeat to 3")
	SetRepeatTimer("Hospital", "AI_QUACKSALVER", 3)
	SetProperty("SIM", "SpecialMeasureId", -MeasureGetID("Quacksalver"))
end
