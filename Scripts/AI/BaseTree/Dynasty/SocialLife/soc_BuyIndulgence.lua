function Weight()
	if not ReadyToRepeat("SIM", "AI_Indulgence") then
		return 0
	end

	SimGetCrimeList("SIM", "SOC_CrimeList")
	if ListSize("SOC_CrimeList") < 1 then
		return 0
	end

	if GetItemCount("SIM", "LetterOfIndulgence", INVENTORY_STD) > 0 then
		if not GetSettlement("SIM", "SOC_City") then
			return 0
		end

		if not CityGetNearestBuilding("SOC_City", "SIM", -1, GL_BUILDING_TYPE_CHURCH_CATH, -1, -1, FILTER_IGNORE, "SOC_CathChurch") then
			return 0
		end

		SetData("SOC_IndulgenceMode", 1)
		return 30
	end

	if GetMoney("dynasty") < 3000 then
		return 0
	end

	SetData("SOC_IndulgenceMode", 0)
	return 15
end

function Execute()
	SetRepeatTimer("SIM", "AI_Indulgence", 12)

	if GetData("SOC_IndulgenceMode") == 1 then
		if ai_GoInsideBuilding("SIM", "SIM", -1, -1, "SOC_CathChurch") then
			MeasureRun("SIM", nil, "BuyHolyIndulgence", false)
		end
	else
		MeasureCreate("SOC_IndulgenceBuy")
		MeasureAddData("SOC_IndulgenceBuy", "ItemToBuy", "LetterOfIndulgence")
		MeasureStart("SOC_IndulgenceBuy", "SIM", nil, "AIBuyItem")
	end
end