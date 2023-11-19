function Run()

	if not GetState("", STATE_IDLE) then
		return ""
	end

	-- doesn't effect thugs
	if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
		return ""
	end
	
	if GetID("dynasty") == GetDynastyID("Actor") then
		return ""
	end
	
	if GetState("", STATE_ROBBERGUARD) then
		return ""
	end

	if IsPartyMember("") then
		return ""
	end	
	
	return "SimHandel"
end

