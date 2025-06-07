function Run()
	LogMessage("@TAVERN aaaaaaa")

	if not GetInsideBuilding("", "Tavern") then
		StopMeasure()
	end

	if not HasProperty("", "AssignedBed") then
		StopMeasure()
	end

	local AssignedBed = GetProperty("", "AssignedBed")

	BuildingGetRoom("Tavern", "RentRoom", "Room")

	if not f_MoveTo("", "Room", GL_MOVESPEED_WALK) then
		LogMessage("@TAVERN #E Critical error! Cannot move to the Lodge...")
	end

	Sleep(1)

	if not GetLocatorByName("Tavern", "bed"..AssignedBed, "SleepingPos") then
		LogMessage("@TAVERN #E Critical error! Locator not found (bed)...")
	end

	f_BeginUseLocator("", "SleepingPos", GL_STANCE_LAY, true)

	Sleep(60*(Rand(3)+1))

	f_EndUseLocator("", "SleepingPos", GL_STANCE_LAY, true)

	SetProperty("", "WaitsForCheckout")

	f_MoveTo("", "Tavern", GL_MOVESPEED_WALK)

	if GetFreeLocatorByName("Tavern", "WaitLodge", 1, 8, "SitPos") then
		f_BeginUseLocator("", "SitPos", GL_STANCE_SIT, true)
	end

	local WaitTime = GetGametime() + 1.5

	while GetGametime() < WaitTime do
		Sleep(5)
	end

	LogMessage("@TAVERN #E (" .. GetName("") .. ") Leaves without tip. Reason: Too Long to Check Out.")	
	f_EndUseLocator("", "SitPos", GL_STANCE_STAND)

	StopMeasure()
end

function CleanUp()
	if GetInsideBuilding("", "Tavern") then
		if AliasExists("Tavern") then
			BuildingRemoveLodgeSim("Tavern", "")
			GetDynasty("Tavern", "Dynasty")
			if DynastyIsPlayer("Dynasty") then
				LogMessage("@TAVERN #W (" .. GetName("") .. ") ends the SleepTavern().")
			end
			if HasProperty("", "WaitsForCheckout") then
				RemoveProperty("", "WaitsForCheckout")
			end
			if HasProperty("", "AssignedBed") then
				local Slot = GetProperty("", "AssignedBed")
				local BedStatus = GetProperty("Tavern", "StatusBed"..Slot)
				RemoveProperty("", "AssignedBed")
				SetProperty("Tavern", "StatusBed"..Slot, "Vacant")
			end
			if HasProperty("Tavern", "GuestLodge"..GetID("").."Waiter") then
				local Waiter = GetProperty("Tavern", "GuestLodge"..GetID("").."Waiter")
				GetAliasByID(Waiter, "Waiter")
				RemoveProperty("Tavern", "GuestLodge"..GetID("").."Waiter")
				MeasureRun("Waiter", nil, "AssignEmployeeToService")
			end
		end
	end
	f_ExitCurrentBuilding("")
	SimResetBehavior("")
end