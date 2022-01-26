function Weight()
	return 0
end

function Execute()
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", Rand(2)+3)
	MeasureStart("Measure", "SIM", "StartHier", "AssignToPoisonEnemy")
end

