function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "break_will") then
		return 0
	end

	if GetImpactValue("SIM", "OrderABrainwash")==0 then
		return 0
	end

	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("OrderABrainwash")) > 0 then
		return 0
	end
	
	if DynastyIsShadow("Victim") then
		return 0
	end
	
	if not GetSettlement("SIM", "CityAlias") then
		return 0
	end
	
	local NumServant = CityGetServantCount("CityAlias", GL_PROFESSION_PRISONGUARD)
	if not CityGetServant("CityAlias", Rand(NumServant), GL_PROFESSION_PRISONGUARD, "oab_Servant") then
		return 0
	end
	
	return 20
end

function Execute()
	MeasureRun("oab_Servant", "Victim", "OrderABrainwash")
end
