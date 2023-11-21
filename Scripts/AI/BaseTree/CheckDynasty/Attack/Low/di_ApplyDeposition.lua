function Weight()
	
	return 0
end

function Execute()
	SetRepeatTimer("SIM", "AI_DepositOffice", 4)
	MeasureRun("SIM", "Victim", "RunForAnOffice")
end
