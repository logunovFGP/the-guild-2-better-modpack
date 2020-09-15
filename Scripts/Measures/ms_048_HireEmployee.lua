function Run()

	local Error = SimCanBeHired("", "Destination")
	if Error ~= "" then
		chr_OutputHireError("", "Destination", Error)
		return
	end
	
	-- Courtlovers cannot be hired anymore
	if HasProperty("", "courted") then
		MsgQuick("Destination", "@L_HIRE_ERROR_COURTED", GetID(""))
		AddImpact("", "NoRandomHire", 1, 12)
		StopMeasure()
	end

	if GetDynastyID("")>0 then
		chr_OutputHireError("", "Destination", "NoWorker")
		return
	end

	local Handsel = SimGetHandsel("", "Destination")
	local Level	= SimGetLevel("")
	local Salary = SimGetWage("")

	local result = MsgNews("Destination","","@P"..
					"@B[O,@LJa_+0]"..
					"@B[C,@LNein_+0]",
					nil,
					"intrigue",
					-1,
					"@L_GENERAL_MEASURES_HIRE_HEAD_+0",
					"@L_GENERAL_MEASURES_HIRE_BODY_+0",
					GetID(""), Handsel, Level, Salary)
					
	if result == "C" then
		AddImpact("", "NoRandomHire", 1, 4)
		return
	end

	if BuildingGetType("Destination") == 2 then
		ms_048_hireemployee_CheckSoeldner()
	elseif BuildingGetType("Destination") == 111 then
		ms_048_hireemployee_CheckLeibwache()
	end	
	
	MoveSetActivity("", "")
	chr_CalculateBuildingBonus("", "Destination", "hire")
	
	local	Error = SimHire("", "Destination")
	if Error~="" then
		chr_OutputHireError("", "Destination", Error)
		return
	else
		PlaySound("Effects/moneybag_to_hand+0.wav", 1)
	end
	
end

function CheckSoeldner()
	if BuildingHasUpgrade("Destination", 716) then
		RemoveItems("", "Dagger", 1, INVENTORY_EQUIPMENT)
		AddItems("", "FullHelmet", 1, INVENTORY_EQUIPMENT)
		AddItems("", "Platemail", 1, INVENTORY_EQUIPMENT)
		AddItems("", "Axe", 1, INVENTORY_EQUIPMENT)	
	elseif BuildingHasUpgrade("Destination", 604) then
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
