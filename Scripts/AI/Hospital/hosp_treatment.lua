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

	if bld_CalcTreatmentNeed("Hospital", "SIM") > 0 then
		return 100
	end
	
	return 0
end

function Execute()
	MeasureRun("SIM", "Hospital", "MedicalTreatment", true)
end

