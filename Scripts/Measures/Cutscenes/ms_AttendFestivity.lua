function AIFunction()
	return "O"
end

function Run()
	SimSetProduceItemID("", -1, -1)
	
	if not f_SimIsValid("") then
		return
	end

	SetProperty("", "AccessAllAreas", 1)
	if HasProperty("", "InvitedBy") then
		local HostID = GetProperty("", "InvitedBy")
		if GetAliasByID(HostID, "PartyHost") then
			if not GetHomeBuilding("PartyHost", "PartyLocation") then
				StopMeasure()
			end
		end
	elseif not HasProperty("", "Host") then
		StopMeasure()
	end

	local PartyTime

	if HasProperty("", "Host") then
		if not GetHomeBuilding("", "PartyLocation") then
			StopMeasure()
		end
	end

	if AliasExists("PartyLocation") then
		PartyTime = GetProperty("PartyLocation", "PartyDate")
	end
	if not PartyTime then
		StopMeasure()
		return
	end
	PartyTime = PartyTime / 60

	if HasProperty("", "Host") then
		if not GetHomeBuilding("", "PartyLocation") then
			StopMeasure()
		end
		
		if GetInsideBuilding("","CurrentBuilding") then
			if not (GetID("CurrentBuilding") == GetID("Destination")) then
				f_ExitCurrentBuilding("")
				if not f_MoveTo("","Destination",GL_MOVESPEED_RUN) then
					StopMeasure()
				end
			end
			GetLocatorByName("PartyLocation", "HostWelcome", "HostWelcomePos")
			f_BeginUseLocator("", "HostWelcomePos", GL_STANCE_STAND, true)
			
		else
			if not f_MoveTo("", "Destination", GL_MOVESPEED_RUN) then
				StopMeasure()
			end

			GetLocatorByName("PartyLocation", "HostWelcome", "HostWelcomePos")
			f_BeginUseLocator("", "HostWelcomePos", GL_STANCE_STAND, true)
		end
	else
		if not HasProperty("", "InvitedBy") then
			StopMeasure()
		end

		local HostID = GetProperty("", "InvitedBy")

		if not GetAliasByID(HostID, "PartyHost") then
			StopMeasure()
		end

		if not GetHomeBuilding("PartyHost", "PartyLocation") then
			StopMeasure()
		end

		if not GetOutdoorMovePosition("", "PartyLocation", "MovePos") then
			StopMeasure()
		end

		if not f_MoveTo("", "MovePos", GL_MOVESPEED_RUN) then
			StopMeasure()
		end
		SetData("Arrived", 1)

		local FeastMaxGuests = GetProperty("PartyLocation", "FeastMaxGuests") or bld_GetFeastMaxGuests("PartyLocation")
		if FeastMaxGuests <= 0 then
			StopMeasure()
		end
		if not GetFreeLocatorByName("PartyLocation", "GuestArrive", 1, FeastMaxGuests, "GuestArrivePos") then
			StopMeasure()
		end

		while GetGametime() < PartyTime do	
			if not GetState("PartyLocation", STATE_FEAST) then
				StopMeasure()
			end

			if not f_BeginUseLocator("", "GuestArrivePos", GL_STANCE_STAND, true) then
				Sleep(5)
			else
				break
			end
		end
	end

	if not HasProperty("", "Host") then
		local InsidePartyLocation = false
		if GetInsideBuilding("", "CurrentBuilding") then
			InsidePartyLocation = (GetID("CurrentBuilding") == GetID("PartyLocation"))
		end
		if not InsidePartyLocation then
			if not f_MoveTo("", "PartyLocation", GL_MOVESPEED_RUN) then
				StopMeasure()
			end
		end
	end

	SetState("", STATE_LOCKED, true)
	
	while GetGametime() < PartyTime do
		Sleep(3)
		if Rand(100) < 50 then
			PlayAnimation("", "cogitate")
		else
			PlayAnimation("", "sentinel_idle")
		end
	end

	if not GetState("PartyLocation", STATE_FEAST) then
		StopMeasure()
	end
		
	if not SimSetBehavior("", "Feast") then
		StopMeasure()
	end

	SetData("Start", 1)
	StopMeasure()
end

function CleanUp()

	SetState("", STATE_LOCKED, false)
	RemoveProperty("", "AccessAllAreas")

	if not HasData("Start") and not HasData("Arrived") then
		if HasProperty("", "InvitedBy") then
			RemoveProperty("", "InvitedBy")
		end
		if AliasExists("PartyLocation") then
			local FeastMaxGuests = GetProperty("PartyLocation", "FeastMaxGuests") or bld_GetFeastMaxGuests("PartyLocation")
			for i=1, FeastMaxGuests do
				if HasProperty("PartyLocation", "Guest"..i) then
					if (GetProperty("PartyLocation","Guest"..i) == GetID("")) then
						RemoveProperty("PartyLocation", "Guest"..i)
					end
				end
			end
		end
	end
end

