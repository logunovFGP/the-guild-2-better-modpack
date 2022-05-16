function Run()

	if GetState("Owner", STATE_SICK) then
		return ""
	end

	SetData("Distance", 1000)
	return "SeeBlackDeath"
	
end

