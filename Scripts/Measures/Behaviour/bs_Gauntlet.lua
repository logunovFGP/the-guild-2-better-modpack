function Run()
	local Profession = SimGetProfession("")

	local Forbidden = {GL_PROFESSION_PRISONGUARD, GL_PROFESSION_CITYGUARD, GL_PROFESSION_TOWNHALLGUARD, GL_PROFESSION_ELITEGUARD, GL_PROFESSION_PRIVATEGUARD, GL_PROFESSION_EXECUTIONER, GL_PROFESSION_MYRMIDON}

	for k, v in helpfuncs_myipairs(Forbidden) do
		if Profession == v then
			return ""
		end
	end
	
	if GetState("", STATE_ROBBERGUARD) then
		return ""
	end
	
	if GetState("", STATE_IMPRISONED) or GetState("", STATE_CAPTURED) then
		return ""
	end
	
	local Favor = GetFavorToSim("", "Actor")
	if  Favor < 40 then
		return "Deride"
	end

	SetData("NoAutoFollow", 1)
	return "Gauntlet"
end

