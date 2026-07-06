function Run()

	local Error = SimCanBeHired("", "Destination")
	if Error ~= "" then
		chr_OutputHireError("", "Destination", Error)
		return
	end
	
	-- Courtlovers cannot be hired anymore
	if HasProperty("", "courted") or GetState("", STATE_INLOVE) then
		MsgQuick("Destination", "@L_HIRE_ERROR_COURTED", GetID(""))
		AddImpact("", "NoRandomHire", 1, 12)
		StopMeasure()
	end

	if GetDynastyID("") > 0 then
		chr_OutputHireError("", "Destination", "NoWorker")
		return
	end

	-- check for maximum of 10 thugs for dynasty
	if BuildingGetType("Destination") == GL_BUILDING_TYPE_RESIDENCE and DynastyGetWorkerCount("Destination", GL_PROFESSION_MYRMIDON) >= 10 then
		MsgBoxNoWait("Destination","", "@L_GENERAL_ERROR_HEAD_+0", "@L_MEASURES_HIRERANDOM_NOTHUGS_+0")
		StopMeasure()
	end

	local Handsel = SimGetHandsel("", "Destination")
	local Level = SimGetLevel("")
	local Salary = SimGetWage("")
	local XP = GetDatabaseValue("CharLevels", Level-1, "xp")  -- XP which was needed for the current level

	if BuildingHasUpgrade("Destination", "CrossedAxes") == true then
		Handsel = Handsel + 4900
	elseif BuildingHasUpgrade("Destination", "HarkingHorn") == true then
		Handsel = Handsel + 2400
	end
	
	if BuildingGetType("Destination") == 111 then
		Handsel = Handsel + 4900
	end
	
	local LableGender = ""
	local LableRand = Rand(3) + 1
		
	if SimGetGender("") == GL_GENDER_FEMALE then
		LableGender = "F"
	else
		LableGender = "M"
	end

	local result = MsgNews("Destination","","@P"..
					"@B[O,@LJa_+0]"..
					"@B[C,@LNein_+0]",
					nil,
					"intrigue",
					-1,
					"@L_GENERAL_MEASURES_HIRE_HEAD_+0",
					"@L_GENERAL_MEASURES_HIRE_SPEECH_HEAD_"..LableGender..LableRand,
					GetID(""), Handsel, Level, Salary)
					
	if result == "C" then
		AddImpact("", "NoRandomHire", 1, 4)
		return
	end
	
	if BuildingGetOwner("Destination", "BOwner") then
		if GetMoney("BOwner") < Handsel then
			MsgQuick("Destination", "@L_GENERAL_MEASURES_FAILURES_+14", Handsel, GetID("RandWorker"))
			StopMeasure()
		end
	end

	if BuildingGetType("Destination") == GL_BUILDING_TYPE_RESIDENCE then
		ms_048_hireemployee_CheckSoeldner()
	elseif BuildingGetType("Destination") == GL_BUILDING_TYPE_ESTATE then
		ms_048_hireemployee_CheckLeibwache()
	end	
	
	MoveSetActivity("")
	chr_CalculateBuildingBonus("", "Destination", "hire")
	CreateScriptcall( "GiveBack", 0.001, "Measures/ms_048_HireEmployee.lua", "GiveXPBack", "", "Destination", XP) -- use scriptcall, because Destination is lost after SimHire	

	economy_UpdateBalance("Destination", "Wages", 0-Handsel)
	local	Error = SimHire("", "Destination")
	if Error~="" then
		chr_OutputHireError("", "Destination", Error)
		return
	else
	  PlaySound3D("Destination", "Effects/moneybag_to_hand+0.wav", 1.0)
	end
end

function CheckSoeldner()
	if BuildingHasUpgrade("Destination", "CrossedAxes") then
		RemoveItems("", "Dagger", 1, INVENTORY_EQUIPMENT)
		AddItems("", "FullHelmet", 1, INVENTORY_EQUIPMENT)
		AddItems("", "Platemail", 1, INVENTORY_EQUIPMENT)
		AddItems("", "Axe", 1, INVENTORY_EQUIPMENT)	
	elseif BuildingHasUpgrade("Destination", "HarkingHorn") then
		RemoveItems("", "Dagger", 1, INVENTORY_EQUIPMENT)
		AddItems("", "IronCap", 1, INVENTORY_EQUIPMENT)
		AddItems("", "Chainmail", 1, INVENTORY_EQUIPMENT)
		AddItems("", "Longsword", 1, INVENTORY_EQUIPMENT)
	end
end

function CheckLeibwache()
	RemoveItems("", "Dagger", 1, INVENTORY_EQUIPMENT)
	AddItems("", "FullHelmet", 1, INVENTORY_EQUIPMENT)
	AddItems("", "Platemail", 1, INVENTORY_EQUIPMENT)
	AddItems("", "Longsword", 1, INVENTORY_EQUIPMENT)	
end

function GiveXPBack(params)
	if SimGetLevel("") == 1 then  -- sometimes the level is not reduced to 1
		IncrementXPQuiet("", params) -- after hiring, the sim looses all his XP, so we give it back
	end
	
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
