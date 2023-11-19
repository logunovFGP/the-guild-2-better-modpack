function Weight()
	
	if DynastyIsAI("SIM") then
		if not ai_GetWorkBuilding("SIM", GL_BUILDING_TYPE_HOSPITAL, "Hospital") then
			return 0
		end
	else
		if not SimGetWorkingPlace("SIM", "Hospital") then
			return 0
		end
	end
	
	if not ReadyToRepeat("Hospital", "AI_QUACKSALVER") then
		return 0
	end

	if not BuildingHasUpgrade("Hospital", "MiracleCure") then
		return 0
	end
	
	if not ai_HasAccessToItem("SIM", "MiracleCure") then
		return 0
	end
	
	if not SimGetWorkingPlace("SIM", "Hospital") then
		return 0
	end
	
	if BuildingGetProducerCount("Hospital", PT_MEASURE, "Quacksalver") > 0 then
		return 0
	end

	if GetItemCount("SIM", "MiracleCure") >= 1 then
		return 100
	elseif GetItemCount("Hospital", "MiracleCure", INVENTORY_STD) > 5 then
		return 100
	elseif GetItemCount("Hospital", "MiracleCure", INVENTORY_SELL) > 5 then
		return 100
	end

	return 0
end

function Execute()
	SetRepeatTimer("Hospital", "AI_QUACKSALVER", 4)
	SetProperty("SIM", "SpecialMeasureId", -MeasureGetID("Quacksalver"))
end
