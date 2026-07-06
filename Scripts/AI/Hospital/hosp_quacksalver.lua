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
	
	local qbase = "MActRule_" .. MeasureGetID("Quacksalver") .. "_"
	local qmaxw = 1
	if HasProperty("Hospital", qbase .. "enabled") and (GetProperty("Hospital", qbase .. "enabled") - 1) == 0 then
		return 0
	end
	if HasProperty("Hospital", qbase .. "maxw") then
		qmaxw = GetProperty("Hospital", qbase .. "maxw") - 1
	end
	if BuildingGetProducerCount("Hospital", PT_MEASURE, "Quacksalver") >= qmaxw then
		return 0
	end

	local qw = 100
	if HasProperty("Hospital", qbase .. "prio") then
		if (GetProperty("Hospital", qbase .. "prio") - 1) == 0 then
			qw = 20
		end
	end

	if GetItemCount("SIM", "MiracleCure") >= 1 then
		return qw
	elseif GetItemCount("Hospital", "MiracleCure", INVENTORY_STD) > 5 then
		return qw
	elseif GetItemCount("Hospital", "MiracleCure", INVENTORY_SELL) > 5 then
		return qw
	end

	return 0
end

function Execute()
	SetRepeatTimer("Hospital", "AI_QUACKSALVER", 4)
	SetProperty("SIM", "SpecialMeasureId", -MeasureGetID("Quacksalver"))
end
