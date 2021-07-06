function Run()
	-- doesn't effect thugs
	if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
		return ""
	end
	
	if GetCurrentMeasureName("") == "UseStinkBomb" then
		return ""
	end
	
	if GetCurrentMeasurePriority("")>55 then
		return ""
	end
	
	SetData("Distance", 2000)
	return "Flee"
end
