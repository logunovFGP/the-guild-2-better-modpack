function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "collect_evidence") then
		return 0
	end
	if not dyn_GetIdleMyrmidon("dynasty", "MYRM") then
		return 0
	end

	
	-- SpiedByDyn causes crashes, do not use it!
	-- SetProperty("Destination", "TomAIBeingSpiedOn", 1)
--	if(HasProperty("Victim", "TomAIBeingSpiedOn")) then
--		-- someone is already spying on this one
--		return 0
--	end

	return 0 -- disabled for now since spying tends to lead to crashes in some cases
end

function Execute()
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", 8, false)
	MeasureStart("Measure", "MYRM", "Victim", "OrderASpying")
end

