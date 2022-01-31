function Weight()
	if not ReadyToRepeat("dynasty", "DIP_"..GetDynastyID("Victim")) then
		return 0
	end
	
	if Rand(5) > 0 then
		return 0
	end
	
	if GetMoney("Victim") < 5000 or GetMoney("SIM") > 20000 then 
		return 0
	end
	
	return 100
end

function Execute()
	MeasureCreate("measure")
	MeasureAddData("Measure", "Choice", 5, false)
	MeasureStart("Measure", "SIM", "Victim", "AdministrateDiplomacy")
end