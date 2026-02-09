function Weight()
	local time = math.mod(GetGametime(),24)
	
	if time >= 16 then
		return 0
	end
	
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end

	if not ReadyToRepeat("SIM", "AI_ApplyForOffice") then
		return 0
	end
	
		-- application running already
		-- this would also return true if SIM is defending current office!
--		local MyOfficeLevel = SimGetOfficeLevel("SIM")
--		-- compare with application
--	if SimIsAppliedForOffice("SIM") then
--		return 0
--	end
	
	-- nobility check
	local MyTitle = GetNobilityTitle("SIM")
	if MyTitle < 4 then
		return false
	end
	
	return 20
end

function Execute()
	SetRepeatTimer("SIM", "AI_ApplyForOffice", 3)
	if aitwp_FindOfficeForApplication("SIM", "APPLY_OFFICE") then
		--LogMessage("::TWP::AI::"..GetName("SIM").." ".. " applying for vacant office seat.")
		MeasureRun("SIM", "APPLY_OFFICE", "RunForAnOffice")
	else
		--LogMessage("::TWP::AI::"..GetName("SIM").." ".. " couldn't find vacant office seat.")
	end
end
