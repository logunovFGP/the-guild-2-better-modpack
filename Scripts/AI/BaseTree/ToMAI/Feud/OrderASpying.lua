function Weight()
	if not dyn_GetIdleMyrmidon("dynasty", "MYRM") then
		return 0
	end

	
	-- SpiedByDyn causes crashes, do not use it!
	-- SetProperty("Destination", "TomAIBeingSpiedOn", 1)
	if(HasProperty("Victim", "TomAIBeingSpiedOn")) then
		-- someone is already spying on this one
		return 0
	end

	return 10
end

function Execute()
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", 8, false)
	MeasureStart("Measure", "MYRM", "Victim", "OrderASpying")
end

