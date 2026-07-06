function Weight()
	
	if IsDynastySim("SIM") then
		if not ai_GetWorkBuilding("SIM", GL_BUILDING_TYPE_HOSPITAL, "Hospital") then
			return 0
		end
		
		if IsDynastySim("SIM") then
			if SimGetClass("SIM")~=3 then
				return 0
			end
		end
	else
		if not SimGetWorkingPlace("SIM", "Hospital") then
			return 0
		end
	end

	local need = bld_CalcTreatmentNeed("Hospital", "SIM")
	if need <= 0 then
		return 0
	end

	local rbase = "MActRule_" .. MeasureGetID("MedicalTreatment") .. "_"
	local hasRules = HasProperty("Hospital", rbase .. "enabled") or HasProperty("Hospital", rbase .. "maxw") or HasProperty("Hospital", rbase .. "minp") or HasProperty("Hospital", rbase .. "prio")
	if hasRules then
		if HasProperty("Hospital", rbase .. "enabled") and (GetProperty("Hospital", rbase .. "enabled") - 1) == 0 then
			return 0
		end
		local minp = 1
		if HasProperty("Hospital", rbase .. "minp") then
			minp = GetProperty("Hospital", rbase .. "minp") - 1
		end
		if need < minp then
			return 0
		end
		local maxw = 99
		if HasProperty("Hospital", rbase .. "maxw") then
			maxw = GetProperty("Hospital", rbase .. "maxw") - 1
		end
		if BuildingGetProducerCount("Hospital", PT_MEASURE, "MedicalTreatment") >= maxw then
			return 0
		end
		local prio = 1
		if HasProperty("Hospital", rbase .. "prio") then
			prio = GetProperty("Hospital", rbase .. "prio") - 1
		end
		if prio == 0 then
			return 20
		end
	end

	return 100
end

function Execute()
	SetProperty("SIM", "SpecialMeasureId", -MeasureGetID("MedicalTreatment"))
end

