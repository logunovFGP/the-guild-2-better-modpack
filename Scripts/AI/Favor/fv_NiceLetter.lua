function Weight()
	return 0
end

function Execute()
	MeasureCreate("measure")
	MeasureAddData("Measure", "Choice", 2, false)
	MeasureStart("Measure", "SIM", "Target", "AdministrateDiplomacy")
end