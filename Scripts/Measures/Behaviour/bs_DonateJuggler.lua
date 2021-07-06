function Run()
	
	if SimGetClass("") == 4 then --rogues are not affected by this
		return ""
	end
	
	if not GetState("", STATE_IDLE) then
		return ""
	end

	if not ReadyToRepeat("", "DonateJuggler") then
		return ""
	end

	if GetImpactValue("", "HaveBeenPickpocketed") > 0 then
		return ""
	end	

	if IsPartyMember("") then
		if Rand(2) == 0 then
			return ""
		end
	end
	
	return "DonateJuggler"
end

