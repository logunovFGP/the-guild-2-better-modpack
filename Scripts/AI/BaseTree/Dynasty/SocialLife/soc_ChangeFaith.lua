function Weight()
	if not ReadyToRepeat("dynasty", "AI_ChangeFaith") then
		return 0
	end

	if GetMoney("dynasty") < 1000 then
		return 0
	end

	if not GetSettlement("SIM", "SOC_City") then
		return 0
	end

	local CathCount = CityGetBuildingCount("SOC_City", GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_CHURCH_CATH)
	local EvCount = CityGetBuildingCount("SOC_City", GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_CHURCH_EV)

	-- religion 0 = catholic, 1 = protestant
	local Religion = SimGetReligion("SIM")

	if Religion == 0 and CathCount < 1 and EvCount > 0 then
		SetData("SOC_FaithTarget", GL_BUILDING_TYPE_CHURCH_EV)
		return 15
	elseif Religion == 1 and EvCount < 1 and CathCount > 0 then
		SetData("SOC_FaithTarget", GL_BUILDING_TYPE_CHURCH_CATH)
		return 15
	end

	return 0
end

function Execute()
	SetRepeatTimer("dynasty", "AI_ChangeFaith", 72)
	if ai_GoInsideBuilding("SIM", "SIM", -1, GetData("SOC_FaithTarget")) then
		MeasureRun("SIM", nil, "ChangeFaith", false)
	end
end