function Weight()

	return 0
end

function Execute()
	SetRepeatTimer("dynasty", "DIP_"..GetDynastyID("Target"), 22)
	MeasureCreate("measure")
	MeasureAddData("Measure", "Choice", 1, false) -- change status
	MeasureAddData("Measure", "InitResult", GetData("SetStatusTo"), false) -- the new status
	MeasureStart("Measure", "SIM", "Target", "AdministrateDiplomacy")
end