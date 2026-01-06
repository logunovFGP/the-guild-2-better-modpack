-- returns 30 on active contracts for SIM
function Weight()
	if not ReadyToRepeat("SIM", "AI_ContractGuildHouse") then
		return 0
	end

	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end
	
	if not GetSettlement("SIM", "City") then
		return 0
	end
	
	if (gameplayformulas_CheckPublicBuilding("City", GL_BUILDING_TYPE_GUILDHOUSE)[1] <= 0) then
		return 0
	end
	
	if not CityGetRandomBuilding("City", -1, GL_BUILDING_TYPE_GUILDHOUSE, -1, -1, FILTER_IGNORE, "Guildhouse") then
		return 0
	end

	if HasProperty("Guildhouse", "ContractCount") and (GetProperty("Guildhouse", "ContractCount")>0) then
		if HasProperty("Guildhouse", "Contract") and GetProperty("Guildhouse", "Contract") == 1 then
			-- TODO AI will currently not manufacture special guild items, ignore these contracts
			return 0
		end
		if HasProperty("Guildhouse", "ContractClass") then
			if (SimGetClass("SIM")==GetProperty("Guildhouse", "ContractClass")) then
				if chr_GetAlderman()==GetID("SIM") then
					return 30
				elseif chr_CheckGuildMaster("SIM","Guildhouse") then
					return 30
				else
					return 20
				end
			end
		end
	end

	return 0
end

function Execute()
	SetRepeatTimer("dynasty", "AI_ContractGuildHouse", 4)
	MeasureCreate("Measure")
	MeasureRun("SIM", "Guildhouse", "ContractGuildHouse")
end
