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
	
	if (GetDynastyID("Destination") ~= GetID("dynasty")) then
		local Costs = 0
		if GetImpactValue("", "Sprain") == 1 then
			Costs = Sprain:getCost()
		elseif GetImpactValue("", "Cold") == 1 then
			Costs = Cold:getCost()
		elseif GetImpactValue("", "Influenza") == 1 then
			Costs = Influenza:getCost()
		elseif GetImpactValue("", "BurnWound") == 1 then
			Costs = BurnWound:getCost()
		elseif GetImpactValue("", "Pox") == 1 then
			Costs = Pox:getCost()
		elseif GetImpactValue("", "Pneumonia") == 1 then
			Costs = Pneumonia:getCost()
		elseif GetImpactValue("", "Blackdeath") == 1 then
			Costs = Blackdeath:getCost()
		elseif GetImpactValue("", "Fracture") == 1 then
			Costs = Fracture:getCost()
		elseif GetImpactValue("", "Caries") == 1 then
			Costs = Caries:getCost()
		elseif GetHPRelative("") < 0.99 then
			Costs = GetMaxHP("") -GetHP("")
		else
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
	if GetImpactValue("", "Sprain") == 1 then
		Costs = Sprain:getCost()
	elseif GetImpactValue("", "Cold") == 1 then
		Costs = Cold:getCost()
	elseif GetImpactValue("", "Influenza") == 1 then
		Costs = Influenza:getCost()
	elseif GetImpactValue("", "BurnWound") == 1 then
		Costs = BurnWound:getCost()
	elseif GetImpactValue("", "Pox") == 1 then
		Costs = Pox:getCost()
	elseif GetImpactValue("", "Pneumonia") == 1 then
		Costs = Pneumonia:getCost()
	elseif GetImpactValue("", "Blackdeath") == 1 then
		Costs = Blackdeath:getCost()
	elseif GetImpactValue("", "Fracture") == 1 then
		Costs = Fracture:getCost()
	elseif GetImpactValue("", "Caries") == 1 then
		Costs = Caries:getCost()
	elseif GetHPRelative("") < 0.99 then
		Costs = GetMaxHP("")-GetHP("")
	end
	OSHSetMeasureCost("@L_INTERFACE_HEADER_+6", Costs)
end


