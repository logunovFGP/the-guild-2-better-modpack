function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "declare_foe") then
		return 0
	end
	
	if not ReadyToRepeat("dynasty", "DIP_"..GetDynastyID("Victim")) then
		return 0
	end
	
	if not GetDynasty("Victim", "VictimDyn") then
		return 0
	end
	
	local BestState = ai_DynastyGetBestDiplomacyState("dynasty", "VictimDyn")
	if BestState ~= "CurrentState" then
		if BestState == "NAP" then
			SetData("SetStatusTo",2) -- to NAP
		elseif BestState == "NEUTRAL" then
			SetData("SetStatusTo",1) -- to NEUTRAL
		else
			SetData("SetStatusTo",0) -- to FOE
		end
		return 100
	end
	
	return 0
end

function Execute()
	SetRepeatTimer("dynasty", "DIP_"..GetDynastyID("Victim"), 22)
	MeasureCreate("measure")
	MeasureAddData("Measure", "Choice", 1, false) -- change status
	MeasureAddData("Measure", "InitResult", GetData("SetStatusTo"), false) -- the new status
	MeasureStart("Measure", "SIM", "Victim", "AdministrateDiplomacy")
end