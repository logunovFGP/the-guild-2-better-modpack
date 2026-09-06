function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "claim") then
		return 0
	end
	if not ReadyToRepeat("dynasty", "DIP_"..GetDynastyID("Victim")) then
		return 0
	end
	
	if DynastyGetDiplomacyState("dynasty", "Victim") == DIP_FOE then
		return 0
	end
	
	if Rand(5) > 0 then
		return 0
	end
	
	if GetMoney("Victim") < 5000 then 
		return 0
	end
	
	return 20
end

function Execute()
	MeasureCreate("measure")
	MeasureAddData("Measure", "Choice", 4, false)
	MeasureStart("Measure", "SIM", "Victim", "AdministrateDiplomacy")
end