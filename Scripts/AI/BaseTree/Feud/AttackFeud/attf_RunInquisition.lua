function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "inquisition") then
		return 0
	end
	if GetImpactValue("SIM", "CommandInquisitor")==0 then
		return 0
	end
	
	if SimGetReligion("SIM")==SimGetReligion("Victim") then
		return 0
	end
	
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("RunInquisition")) > 0 then
		return 0
	end

	if not GetSettlement("SIM", "Inq_CityAlias") then
		return 0
	end
	
	local NumServant = CityGetServantCount("Inq_CityAlias", GL_PROFESSION_INQUISITOR)
	if not CityGetServant("Inq_CityAlias", Rand(NumServant), GL_PROFESSION_INQUISITOR, "Inq_Servant") then
		return 0
	end

	return 10
end

function Execute()
	MeasureRun("Inq_Servant", "Victim", "RunInquisition")
end

