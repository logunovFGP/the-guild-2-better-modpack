function Run()

	if GetInsideBuilding("", "CurrentBuilding") then
		GetSettlement("CurrentBuilding", "City")
		if BuildingGetType("CurrentBuilding") == GL_BUILDING_TYPE_HOSPITAL then
			CopyAlias("CurrentBuilding", "Destination")
		end
	end

	if not AliasExists("City") then
		if not GetNearestSettlement("", "City") then
			return
		end
	end
	
	if GetState("", STATE_TOWNNPC) or GetState("", STATE_NPC) then
		return
	end
	
	MeasureSetNotRestartable()
	
	if not AliasExists("Destination") then
		-- level of hospital could be included to make sure the current disease is curable
		economy_GetRandomBuildingByRanking("City", "Destination", 0, GL_BUILDING_TYPE_HOSPITAL)
		if not AliasExists("Destination") then
			MsgQuick("", "@L_MEDICUS_FAILURES_+1")
			return
		end
	end
	
	local Costs = 0
	if (GetDynastyID("Destination") ~= GetID("dynasty")) then
		for k, Illness in diseases_GetDiseaseIterator() do
			if GetImpactValue("", Illness:getName()) == 1 then
				Costs = Illness:getCost()
				break
			end
		end

		if Costs == 0 and GetHPRelative("") < 0.99 then
			Costs = GetMaxHP("") -GetHP("")
		elseif Costs == 0 then
			return
		end
		
		local Money = GetMoney("")
		if Costs > Money then
			MsgQuick("", "@L_MEDICUS_FAILURES_+2", GetID(""))
			StopMeasure()
		end
	end
	local HospitalID = GetID("Destination")
	idlelib_VisitDoc(HospitalID)
end

function AIDecide()
	return "O"
end

function CleanUp()
	if HasProperty("", "WaitingForTreatment") then
		RemoveProperty("", "WaitingForTreatment")
	end
end

-- -----------------------
-- GetOSHData
-- -----------------------
function GetOSHData(MeasureID)
local Costs = 0
	for k, Illness in diseases_GetDiseaseIterator() do
		if GetImpactValue("", Illness:getName()) == 1 then
			Costs = Illness:getCost()
			break
		end
	end

	if Costs == 0 and GetHPRelative("") < 0.99 then
		Costs = GetMaxHP("")-GetHP("")
	end
	OSHSetMeasureCost("@L_INTERFACE_HEADER_+6", Costs)
end


