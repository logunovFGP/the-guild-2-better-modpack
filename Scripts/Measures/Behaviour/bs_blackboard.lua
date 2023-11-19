function Run()
	if GetCurrentMeasureName("") == "AddPamphlet" then
		return ""
	end
	
	if SimGetAge("") < 12 then
		return ""
	end
	
	-- doesn't effect thugs
	if SimGetProfession("") == GL_PROFESSION_MYRMIDON then
		return ""
	end
	
	if GetImpactValue("", "BlackboardVisited") == 1 then
		return ""
	else
		AddImpact("", "BlackboardVisited", 1, 12)
	end
	
	if GetState("", STATE_IMPRISONED) or GetState("", STATE_CAPTURED) or GetState("", STATE_HIJACKED) then
		return ""
	end
	
	if GetState("", STATE_ROBBERGUARD) then
		return ""
	end
	
	if GetState("", STATE_WORKING) then
		return ""
	end

	return "CheerBlackBoard"
	
end

