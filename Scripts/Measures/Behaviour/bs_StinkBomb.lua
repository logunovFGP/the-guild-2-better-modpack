function Run()
	
	if GetCurrentMeasureName("") == "UseStinkBomb" then
		return ""
	end
	
	if GetCurrentMeasurePriority("")>55 then
		return ""
	end
	
	SetData("Distance", 2000)
	return "Flee"
end
