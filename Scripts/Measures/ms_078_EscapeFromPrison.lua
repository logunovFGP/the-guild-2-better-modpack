function Run()
	--if DynastyIsPlayer("") then
	--	SetRichPresence("state", "InPrison")
	--end
	MeasureSetNotRestartable()

	if not GetInsideBuilding("", "Prison") then
		return
	end

	if not GetSettlement("Prison", "CityAlias") then
		return
	end
	
	SetState("", STATE_IMPRISONED, false)
	CitySimBreakout("CityAlias", "")
	
	if GetHomeBuilding("", "Home") then
		f_MoveTo("", "Home", GL_MOVESPEED_RUN)
	end
end

function CleanUp()
	--if DynastyIsPlayer("") then
	--	SetRichPresence("state", "")
	--end
end
