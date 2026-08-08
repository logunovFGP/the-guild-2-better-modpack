function Run()
end

function OnLevelUp()
	hospital_SetupAI("")
	bld_HandleOnLevelUp("")
end

function Setup()
	hospital_SetupAI("")
	bld_HandleSetup("")
	local list = {"Cat","Dog"}
	worldambient_CreateAnimal(list[Rand(2)+1], "", 1)
end

function UpdateBalance(Alias)
	local list = {"RoundIncome","MedicalIncome","QuackIncome","SoapIncome",0,0,0,0}

	for i = 1, 4 do 
		if HasProperty(Alias, list[i]) then
			list[i+4] = GetProperty(Alias, list[i])
		end

		if i ~= 1 then
			SetProperty(Alias, "Last"..list[i], list[i+4])
		else
			SetProperty(Alias, "LastIncome", list[5])
		end

		SetProperty(Alias, list[i], 0)
	end

end

function CheckForStuckedMedics(Alias)

	if BuildingGetProducerCount(Alias, PT_MEASURE, "MedicalTreatment") > 1 then 
		BuildingGetInsideSimList(Alias, "InsideList")
		local ListSize = ListSize("InsideList")
		local Found = 0	
		
		-- check for waiting patients
		if ListSize > 0 then
			for i=0, ListSize-1 do
				ListGetElement("InsideList", i, "SimToCheck")
				if HasProperty("SimToCheck", "WaitingForTreatment") then
					Found = 1
					break
				end
			end
			
			-- if none available, stop treatment-measure
			if Found == 0 then
				for i=0, ListSize-1 do
					ListGetElement("InsideList", i, "SimToCheck")
					if GetCurrentMeasureName("SimToCheck") == "MedicalTreatment" then
						if not DynastyIsPlayer("SimToCheck") then
							SimStopMeasure("SimToCheck")
						end
					end
				end
			end
		end
	end
end

function PingHour()

	local Hour = math.mod(GetGametime(), 24)
	if Hour == 0 then
	--	hospital_UpdateBalance("")
	elseif Hour == 3 then
		hospital_CheckForStuckedMedics("")
	end

	bld_HandlePingHour("", true)
end

function SetNeed(InvAlias, ItemId, Value)
	if (GetProperty(InvAlias, "NeedLock_"..ItemId) or 0) ~= 0 then
		return
	end
	if Value then
		SetProperty(InvAlias, "Need_"..ItemId, Value)
	else
		RemoveProperty(InvAlias, "Need_"..ItemId)
	end
end

function SetGood(ItemId, Counter, Stock)
	hospital_SetNeed("NeedSell", ItemId, Counter)
	hospital_SetNeed("NeedStd", ItemId, Stock)
end

function SetupAI(Alias)
	local Level = BuildingGetLevel(Alias)
	if Level < 1 then
		return
	end
	if not GetInventory(Alias, INVENTORY_STD, "NeedStd") then
		return
	end
	if not GetInventory(Alias, INVENTORY_SELL, "NeedSell") then
		return
	end

	hospital_SetGood(GL_ITEM_LAVENDER, -1, 20)	-- Lavender [120]
	hospital_SetGood(GL_ITEM_BANDAGE, -1, 20)	-- Bandage [360]
	hospital_SetGood(GL_ITEM_SOAP, nil, 8)	-- Soap [361]
	hospital_SetGood(GL_ITEM_MIRACLECURE, -1, 15)	-- Miracle cure [362]

	if Level >= 2 then
		hospital_SetGood(GL_ITEM_SALVE, -1, 10)	-- Ointment [364]
		hospital_SetGood(GL_ITEM_MEDICINE, -1, 8)	-- Medicine bottle [365]
		hospital_SetGood(GL_ITEM_STAFFOFAESCULAP, nil, nil)	-- Caduceus [366]
	end

	if Level >= 3 then
		hospital_SetGood(GL_ITEM_MIXTURE, nil, nil)	-- Secret Mixture [369]
		hospital_SetGood(GL_ITEM_MEDIPACK, nil, nil)	-- Healer's pouch [370]
		hospital_SetGood(GL_ITEM_PAINKILLER, -1, 8)	-- Pain medication [371]
	end
end
