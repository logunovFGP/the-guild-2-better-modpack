function Run()

	if GetMoney("") < 400 then
		MsgBoxNoWait("dynasty","", "@L_GENERAL_ERROR_HEAD_+0","@L_MEASURES_HIRERANDOM_NOMONEY_+0")
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
	
	if HasProperty("RandWorker", "courted") then
		MsgQuick("","@L_HIRE_ERROR_COURTED", GetID("RandWorker"))
		AddImpact("RandWorker", "NoRandomHire", 1, 12)
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
	SetData("Lvl",Level)
	local Salary = SimGetWage("RandWorker")
	SetData("Saly",Salary)
	local XP = GetDatabaseValue("CharLevels", Level-1, "xp")  -- XP which was needed for the current level
	SetData("XPP",XP)	
	
	ms_048_hireemployeebuildingrandom_DecideYou()
	
	if BuildingGetType("") == 2 then
		ms_048_hireemployeebuildingrandom_CheckSoeldner("", "RandWorker")
	elseif BuildingGetType("") == 111 then
		ms_048_hireemployeebuildingrandom_CheckLeibwache("RandWorker")
	end	
end
		
function DecideYou()

	SetData("Entscheid",0)
	local handsels = GetData("Hands")
	local levels = GetData("Lvl")
	local salarys = GetData("Saly")
	local xp = GetData("XPP")
	
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

	local Error = SimHire("RandWorker", "", true)
	chr_OutputHireError("RandWorker", "", Error)
	if SimGetLevel("RandWorker") == 1 then  -- sometimes the level is not reduced to 1 (I guess because he already had the right clothes)
		IncrementXPQuiet("RandWorker",xp)	      -- XP back to previous value
	end		
	if Error == "" then
		-- stop courting
		if SimGetCourtLover("RandWorker", "WorkerLover") then
			SimReleaseCourtLover("RandWorker")
			if HasProperty("RandWorker", "courted") then
				RemoveProperty("", "courted")
			end
	
			if HasProperty("WorkerLover", "courted") then
				RemoveProperty("WorkerLover", "courted")
			end
		end	
		
		if BuildingHasUpgrade("", "CrossedAxes") == true then
			chr_SpendMoney("BOwner", 4900, "LaborHansel")
		elseif BuildingHasUpgrade("", "HarkingHorn") then
			chr_SpendMoney("BOwner", 2400, "LaborHansel")
		elseif BuildingGetType("") == GL_BUILDING_TYPE_ESTATE then
			chr_SpendMoney("BOwner", 4900, "LaborHansel")
		else
			PlaySound("Effects/moneybag_to_hand+0.wav", 1)
		end
		
		SetData("Entscheid", 1)
		
		if DynastyIsAI("") then
			if BuildingGetLevel("") == 1 then
				local lvlset = (Rand(2)+1)
				SetProperty("RandWorker","Level", lvlset)
			elseif BuildingGetLevel("") == 2 then
				local lvlset = (Rand(2)+3)
				SetProperty("RandWorker", "Level", lvlset)
			else
				local lvlset = (Rand(2)+5)
				SetProperty("RandWorker", "Level", lvlset)
			end
		end
	end
	
	MoveSetActivity("RandWorker")
	SimGetWorkingPlace("RandWorker", "workbuilding")
	chr_CalculateBuildingBonus("RandWorker", "", "hire")

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
	if BuildingHasUpgrade(Alias, "CrossedAxes") == true then
		RemoveItems(Worker, "Dagger",1,INVENTORY_EQUIPMENT)
		AddItems(Worker, "FullHelmet",1,INVENTORY_EQUIPMENT)
		AddItems(Worker, "Platemail",1,INVENTORY_EQUIPMENT)
		AddItems(Worker, "Axe",1,INVENTORY_EQUIPMENT)	
	elseif BuildingHasUpgrade(Alias, "HarkingHorn") == true then
		RemoveItems(Worker, "Dagger",1,INVENTORY_EQUIPMENT)
		AddItems(Worker, "IronCap",1,INVENTORY_EQUIPMENT)
		AddItems(Worker, "Chainmail",1,INVENTORY_EQUIPMENT)
		AddItems(Worker, "Longsword",1,INVENTORY_EQUIPMENT)
	end
end

function CheckLeibwache(Alias)
	RemoveItems(Alias, "Dagger",1,INVENTORY_EQUIPMENT)
	AddItems(Alias, "FullHelmet",1,INVENTORY_EQUIPMENT)
	AddItems(Alias, "Platemail",1,INVENTORY_EQUIPMENT)
	AddItems(Alias, "Longsword",1,INVENTORY_EQUIPMENT)	
end
