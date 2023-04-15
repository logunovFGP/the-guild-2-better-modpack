function Run()
   	
	if not GetState("", STATE_IDLE) then
		return ""
	end
	
	if GetState("",STATE_ROBBERGUARD) then
		return ""
	end

	-- doesn't effect thugs
	if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
		return ""
	end
	
	if SimGetProfession("")== GL_PROFESSION_JUGGLER then
		return ""
	end

	if not ReadyToRepeat("", "SimGetKurios") then
		return ""
	end

	if IsPartyMember("") then
		return ""
	end
	
    return "SimGetKurios"
end
