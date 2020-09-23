function Run()
end

function OnLevelUp()
	if BuildingGetAISetting("", "Produce_Selection") > 0 then
	--	bld_SetupAI("")
	end
end

function Setup()
	-- create ambient animals
	if Rand(2)==0 then
		worldambient_CreateAnimal("Cat", "", 1)
	else
		worldambient_CreateAnimal("Dog", "", 1)
	end
end

function UpdateBalance(Alias)
	local RoundIncome
	local LastIncome
	local MedicalIncome
	local QuackIncome
	local SoapIncome
	
	if HasProperty(Alias, "RoundIncome") then
		RoundIncome = GetProperty(Alias, "RoundIncome")
	end
	
	if HasProperty(Alias, "MedicalIncome") then
		MedicalIncome = GetProperty(Alias, "MedicalIncome")
	end
	
	if HasProperty(Alias, "QuackIncome") then
		QuackIncome = GetProperty(Alias, "QuackIncome")
	end
	
	if HasProperty(Alias, "SoapIncome") then
		SoapIncome = GetProperty(Alias, "SoapIncome")
	end
	
	SetProperty(Alias, "LastIncome", RoundIncome)
	SetProperty(Alias, "RoundIncome", 0)
	SetProperty(Alias, "LastMedicalIncome",MedicalIncome)
	SetProperty(Alias, "MedicalIncome", 0)
	SetProperty(Alias, "LastQuackIncome",QuackIncome)
	SetProperty(Alias, "QuackIncome", 0)
	SetProperty(Alias, "LastSoapIncome", SoapIncome)
	SetProperty(Alias, "SoapIncome", 0)
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
	
	-- Check every worker (only once) for illness and equipment 
	if not HasProperty("", "CheckDefaultWorkers") then
		bld_ResetWorkers("")
		SetProperty("", "CheckDefaultWorkers", 1)
	end
	
	-- Improve AI management
	if BuildingGetAISetting("", "Produce_Selection") > 0 then
	--	bld_SetupAI("")
	--	MeasureRun("", nil, "MedicineChest", false)
	end
	
	-- Only for AI-dynasties
	
	if BuildingGetOwner("", "MyBoss") then
		if GetHomeBuilding("MyBoss", "MyHome") then
			if DynastyIsShadow("MyHome") then -- shadows shall only have 1 cart
				bld_RemoveCart("")
			end
			
			if DynastyIsAI("MyHome") then
				bld_CheckRivals("")
				bld_ForceLevelUp("")
				bld_CheckRepairs("")
			end
		end
	end
end
