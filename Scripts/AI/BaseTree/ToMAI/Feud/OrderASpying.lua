function Weight()
	if not dyn_GetIdleMyrmidon("dynasty", "MYRM") then
		return 0
	end

	if GetFavorToDynasty("dynasty", "VictimDynasty") > gameplayformulas_GetMaxFavByDiffForAttack() then
		return 0
	end
	
	if(HasProperty("Victim", "SpiedByDyn"..GetDynastyID("dynasty"))) then
		-- we are already spying on this one
		return 0
	end

	return 10
end

function Execute()
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", 8, false)
	MeasureStart("Measure", "MYRM", "Victim", "OrderASpying")
end

