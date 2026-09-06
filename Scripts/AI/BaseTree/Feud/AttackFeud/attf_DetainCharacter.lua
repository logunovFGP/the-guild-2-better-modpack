function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "arrest") then
		return 0
	end

	if GetImpactValue("SIM", "DetainCharacter")==0 then
		return 0
	end
	
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("DetainCharacter")) > 0 then
		return 0
	end

	if not GetSettlement("SIM", "CityAlias") then
		return 0
	end
	
	if GetEvidenceAlignmentSum("SIM","Victim") <= 0 then
		return 0
	end
	
	if not ai_CheckMutex("CityAlias", "DetainCharacter") then
		return 0
	end

	local NumServant = CityGetServantCount("CityAlias", GL_PROFESSION_CITYGUARD)
	if not CityGetServant("CityAlias", Rand(NumServant), GL_PROFESSION_CITYGUARD, "dc_Servant") then
		return 0
	end

	return 20
end

function Execute()
	MeasureRun("dc_Servant", "Victim", "DetainCharacter")
end
