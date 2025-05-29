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
	local hasFinished = false

	while GetGametime() < WaitTime do
		
		if HasProperty("", "WaitsForCheckout") then
			hasFinished = true
			break
		end
	end

	if not hasFinished then 		
		f_EndUseLocator("", "SitPos", GL_STANCE_STAND)

		SetProperty("Tavern", "StatusBed"..AssignedBed, "Vacant")

		if HasProperty("", "WaitsForCheckout") then
			RemoveProperty("", "WaitsForCheckout")
		end

		if HasProperty("", "AssignedBed") then
			RemoveProperty("", "AssignedBed")
		end
			
		f_ExitCurrentBuilding("")
		SimResetBehavior("")
	end
end

function CleanUp()

end