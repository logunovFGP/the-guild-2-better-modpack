function Run()
	
	-- doesn't effect thugs
	if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
		return ""
	end
	
	if GetState("", STATE_IMPRISONED) or GetState("", STATE_CAPTURED) then
		return ""
	end
	
	if GetCurrentMeasurePriority("") >= 40 then
		return ""
	end
	
	chr_ModifyFavor("", "Actor", -GL_FAVOR_MOD_VERYSMALL)
	
	local	Favor = GetFavorToSim("", "Actor")
	if  Favor < 60 then
		return "Deride"
	else
		return ""
	end
end

