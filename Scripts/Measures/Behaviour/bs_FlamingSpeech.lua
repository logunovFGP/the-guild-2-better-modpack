function Run()

	if not f_SimIsValid("") then
		return ""
	end	

	-- doesn't effect thugs
	if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
		return ""
	end
	
	if GetState("", STATE_ROBBERGUARD) then
		return ""
	end

	if GetState("", STATE_GUARDING) then
		return ""
	end
	
	if not ReadyToRepeat("", "Listen2Preacher") then
		return ""
	end

	return "ListenFlamingSpeech"
end

