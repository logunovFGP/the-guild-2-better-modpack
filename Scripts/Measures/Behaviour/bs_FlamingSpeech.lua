function Run()
	-- doesn't effect thugs
	if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
		return ""
	end
	
	if GetState("", STATE_ROBBERGUARD) then
		return ""
	end
	
	if not ReadyToRepeat("", "Listen2Preacher") then
		return ""
	end

	return "ListenFlamingSpeech"
end

