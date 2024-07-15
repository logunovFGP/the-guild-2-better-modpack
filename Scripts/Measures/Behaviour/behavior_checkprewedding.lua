function Run()
	LogMessage(GetName("") .. " is in CheckPreWedding.lua")
	MeasureSetNotRestartable()
	MeasureRun("", nil, "Prewedding", true)
end