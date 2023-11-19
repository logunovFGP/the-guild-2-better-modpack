function Run()

	-- doesn't effect thugs
	if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
		return ""
	end
	
	if GetState("", STATE_ROBBERGUARD) then
		return ""
	end
	
	if GetState("", STATE_IMPRISONED) or GetState("", STATE_CAPTURED) then
		return ""
	end
	
	local	Favor = GetFavorToSim("", "Actor")
	if  Favor < 40 then
		return "Deride"
	end

	SetData("NoAutoFollow", 1)
	return "Gauntlet"
end

