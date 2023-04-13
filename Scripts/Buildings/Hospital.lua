function Run()
end

function OnLevelUp()
	bld_HandleOnLevelUp("")
end

function Setup()
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

		if not i == 1 then
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