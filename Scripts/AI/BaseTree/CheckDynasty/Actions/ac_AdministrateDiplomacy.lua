function Weight()
	return 0
end

function Execute()
	SetRepeatTimer("dynasty", "ai_AdministrateDiplomacy", 8)
	MeasureCreate("measure")
	MeasureAddData("Measure", "InitResult", GetData("SetStatusTo"), false)
	MeasureStart("Measure", "SIM", "Victim", "AdministrateDiplomacy")
end
