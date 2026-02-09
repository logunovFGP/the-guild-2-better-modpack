function Run()

	if GetMoney("") < 400 then
		MsgBoxNoWait("dynasty","", "@L_GENERAL_ERROR_HEAD_+0","@L_MEASURES_HIRERANDOM_NOMONEY_+0")
		StopMeasure()
	end

	-- check for maximum of 10 thugs for dynasty
	if BuildingGetType("") == 2 and DynastyGetWorkerCount("dynasty", GL_PROFESSION_MYRMIDON) >= 10 then
		MsgBoxNoWait("dynasty","", "@L_GENERAL_ERROR_HEAD_+0", "@L_MEASURES_HIRERANDOM_NOTHUGS_+0")
		StopMeasure()
	end
	
	local Button1 = "@B[B,@L_HPFZ_EINSTELLEN_+0]"
	local Button2 = "@B[N,@L_HPFZ_EINSTELLEN_+1]"
	local Button3 = "@B[M,@L_HPFZ_EINSTELLEN_+2]"
	
	local Worker2Exists = FindWorker("", "worker", 3)
	if Worker2Exists ~= "" then
		Button2 = ""
	end
	
	local Worker3Exists = FindWorker("", "worker", 5)
	if Worker3Exists ~= "" then
		Button3 = ""
	end		

	local auswahl = MsgNews("","","@P"..
					Button1..
					Button2..
					Button3,
					ms_048_hireemployeebuildingrandom_DecideFirst,
					"intrigue",
					-1,
					"@L_GENERAL_MEASURES_HIRE_HEAD_+0",
					"@L_HPFZ_MEASURES_HIRE_ZUSATZ_+0")

	-- added by FH:
	-- prevents game from freezing
	if auswahl == "C" then
		return
	end
	
	local DesiredLevel = 1
	if auswahl == "N" then
		DesiredLevel = 3
	elseif auswahl == "M" then
		DesiredLevel = 5
	end
		
	local arbeiter = FindWorker("", "RandWorker", DesiredLevel)
	if arbeiter ~= "" then
		chr_OutputHireError("RandWorker", "", arbeiter)
		StopMeasure()
	end
	
	if not AliasExists("RandWorker") then
		StopMeasure()
	end
	
	local Handsel = SimGetHandsel("RandWorker", "")
	if BuildingHasUpgrade("", "CrossedAxes") == true then
		Handsel = Handsel + 4900
	elseif BuildingHasUpgrade("", "HarkingHorn") == true then
		Handsel = Handsel + 2400
	end
	
	if BuildingGetType("") == 111 then
		Handsel = Handsel + 4900
	end
	
	SetData("Hands", Handsel)
	local Level	= SimGetLevel("RandWorker")
	SetData("Lvl", Level)
	local Salary = SimGetWage("RandWorker")
	SetData("Saly", Salary)
	local XP = GetDatabaseValue("CharLevels", Level-1, "xp")  -- XP which was needed for the current level
	SetData("XPP", XP)	
	
	ms_048_hireemployeebuildingrandom_DecideYou()
	
	if BuildingGetType("") == GL_BUILDING_TYPE_RESIDENCE then
		ms_048_hireemployeebuildingrandom_CheckSoeldner("", "RandWorker")
	elseif BuildingGetType("") == GL_BUILDING_TYPE_ESTATE then
		ms_048_hireemployeebuildingrandom_CheckLeibwache("RandWorker")
	end	
end
		
function DecideYou()

	local handsels = GetData("Hands")
	local levels = GetData("Lvl")
	local salarys = GetData("Saly")
	local XP = GetData("XPP")
	
	if BuildingGetOwner("", "BOwner") then
		if GetMoney("BOwner") < handsels then
			MsgQuick("", "@L_GENERAL_MEASURES_FAILURES_+14", handsels, GetID("RandWorker"))
			StopMeasure()
		end
	end
	
	local result = "O"
	
	if IsGUIDriven() then
		local LableGender = ""
		local LableRand = Rand(3) + 1
		
		if SimGetGender("RandWorker") == GL_GENDER_FEMALE then
			LableGender = "F"
		else
			LableGender = "M"
		end
		
		result = MsgBox("","RandWorker","@P"..
					"@B[O,@LJa_+0]"..
					"@B[C,@LNein_+0]",
					"@L_GENERAL_MEASURES_HIRE_HEAD_+0",
					"@L_GENERAL_MEASURES_HIRE_SPEECH_HEAD_"..LableGender..LableRand,
					GetID("RandWorker"), handsels, levels, salarys)
	end
					
	if result == "C" then
		AddImpact("RandWorker", "NoRandomHire", 1, 4)
		return
	end

	chr_CalculateBuildingBonus("", "RandWorker", "hire")
	CreateScriptcall( "GiveBack", 0.001, "Measures/ms_048_HireEmployee.lua", "GiveXPBack", "RandWorker", "", XP) -- use scriptcall, because Destination is lost after SimHire	

	local	Error = SimHire("RandWorker", "", true)
	if Error~="" then
		chr_OutputHireError("RandWorker", "", Error)
		return
	else
		economy_UpdateBalance("", "Wages", 0-handsels)
	  PlaySound3D("", "Effects/moneybag_to_hand+0.wav", 1.0)
	end
end

function DecideFirst()
	if BuildingGetLevel("") == 1 then
		return "B"
	elseif BuildingGetLevel("") == 2 then
		return "N"
	else
		return "M"
	end
end

function CheckSoeldner(Alias, Worker)
	AddItems(Worker, "Dagger", 1, INVENTORY_EQUIPMENT)
	if BuildingHasUpgrade(Alias, "CrossedAxes") then
		RemoveItems(Worker, "Dagger", 1, INVENTORY_EQUIPMENT)
		AddItems(Worker, "FullHelmet", 1, INVENTORY_EQUIPMENT)
		AddItems(Worker, "Platemail", 1, INVENTORY_EQUIPMENT)
		AddItems(Worker, "Axe", 1, INVENTORY_EQUIPMENT)	
	elseif BuildingHasUpgrade(Alias, "HarkingHorn") then
		RemoveItems(Worker, "Dagger", 1, INVENTORY_EQUIPMENT)
		AddItems(Worker, "IronCap", 1, INVENTORY_EQUIPMENT)
		AddItems(Worker, "Chainmail", 1, INVENTORY_EQUIPMENT)
		AddItems(Worker, "Longsword", 1, INVENTORY_EQUIPMENT)
	end
end

function CheckLeibwache(Alias)
	RemoveItems(Alias, "Dagger", 1, INVENTORY_EQUIPMENT)
	AddItems(Alias, "FullHelmet", 1, INVENTORY_EQUIPMENT)
	AddItems(Alias, "Platemail", 1, INVENTORY_EQUIPMENT)
	AddItems(Alias, "Longsword", 1, INVENTORY_EQUIPMENT)	
end

function GiveXPBack(params)
	if SimGetLevel("") == 1 then  -- sometimes the level is not reduced to 1
		IncrementXPQuiet("", params) -- after hiring, the sim looses all his XP, so we give it back
	end
	
	-- stop courting
	if SimGetCourtLover("", "WorkerLover") then
		SimReleaseCourtLover("")
		if HasProperty("", "courted") then
			RemoveProperty("", "courted")
		end
		
		if HasProperty("WorkerLover", "courted") then
			RemoveProperty("WorkerLover", "courted")
		end
	end	
	
	MoveSetActivity("")
	
	-- pay extra money if needed
	if AliasExists("Destination") and IsType("Destination", "Building") then
		if BuildingGetOwner("Destination", "BOwner") then
			
			if BuildingHasUpgrade("Destination", "CrossedAxes") == true then
				chr_SpendMoney("BOwner", 4900, "LaborHansel")
			elseif BuildingHasUpgrade("Destination", "HarkingHorn") then
				chr_SpendMoney("BOwner", 2400, "LaborHansel")
			end
				
			if BuildingGetType("Destination") == GL_BUILDING_TYPE_ESTATE then
				chr_SpendMoney("BOwner", 4900, "LaborHansel")
			end
		end
	end
end

