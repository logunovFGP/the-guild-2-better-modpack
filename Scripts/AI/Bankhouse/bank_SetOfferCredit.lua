function Weight()

	if IsDynastySim("SIM") then
		return 0
	end
	
	if not SimGetWorkingPlace("SIM", "MyBank") then
		return 0
	end
	
	-- the bank's Actions tab: on/off, how many clerks at once (one when never set, as it
	-- always was), how many customers must wait, and whether it outranks goods
	if gameplayformulas_MActRule("MyBank", "OfferCredit", "enabled", 1) == 0 then
		return 0
	end
	if BuildingGetProducerCount("MyBank", PT_MEASURE, "OfferCredit") >= gameplayformulas_MActRule("MyBank", "OfferCredit", "maxw", 1) then
		return 0
	end
	
	if GetCurrentMeasureName("SIM") == "CollectDebts" then
		return 0
	end

	if GetInsideBuildingID("SIM") ~= GetID("MyBank") then
		return 0
	end
	
	if not HasProperty("MyBank", "BankAccount") then
		return 0
	end
	
	if GetProperty("MyBank", "BankAccount") < 100 then
		return 0
	end

	local Hour = math.mod(GetGametime(), 24)
	if (Hour < 6) or (Hour >= 22) then
		return 0
	end
	
	local CreditSimFilter = "__F((Object.GetObjectsByRadius(Sim) == 10000) AND (Object.HasProperty(WaitForCredit)))"
	local NumCreditSims = Find("SIM", CreditSimFilter,"CreditSim", -1)
	if NumCreditSims < math.max(1, gameplayformulas_MActRule("MyBank", "OfferCredit", "minp", 1)) then
		return 0
	end
	
	if gameplayformulas_MActRule("MyBank", "OfferCredit", "prio", 1) == 0 then
		return 20
	end
	return 100
end

function Execute()
	MeasureRun("SIM", "MyBank", "OfferCredit", false)
end
