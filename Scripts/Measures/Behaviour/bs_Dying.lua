function Run()
	-- doesn't effect thugs
	if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
		return ""
	end
	
	if GetState("", STATE_ROBBERGUARD) then
		return ""
	end
	
	if GetState("", STATE_IMPRISONED) or GetState("" ,STATE_CAPTURED) then
		return ""
	end
	
	if GetCurrentMeasurePriority("") >= 50 then
		return ""
	end
	
	local	Favor = GetFavorToSim("", "Actor")
	if  Favor < 20 then
		return "Deride"
	else
		return "Cry"
	end
end

