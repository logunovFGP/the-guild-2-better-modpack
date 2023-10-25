function Run()
	
	if SimGetClass("") == 4 then --rogues are barely affected by this
		if Rand(8) > 0 then
			return ""
		end
	end
	
	if not GetState("", STATE_IDLE) then
		return ""
	end

	if not ReadyToRepeat("", "DonateJuggler") then
		return ""
	end
	
	if IsPartyMember("") then
		return ""
	end

	return "DonateJuggler"
end

