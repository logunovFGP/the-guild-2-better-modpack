function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "VictimDynasty", "inspection") then
		return 0
	end

	local Hour = math.mod(GetGametime(), 24)
	if Hour < 8 or Hour > 16 then
		return 0
	end

	if GetImpactValue("SIM", "InspectBusiness")==0 then
		return 0
	end
	
	if GetImpactValue("dynasty","BeeingInspected")==1 then
		return 0
	end	

	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("InspectBusiness")) > 0 then
		return 0
	end

	if not GetSettlement("SIM", "CityAlias") then
		return 0
	end

	local NumServant = CityGetServantCount("CityAlias", GL_PROFESSION_INSPECTOR)
	if not CityGetServant("CityAlias", Rand(NumServant), GL_PROFESSION_INSPECTOR, "ib_Servant") then
		return 0
	end

	if not GetState("ib_Servant", STATE_IDLE) then
		return 0
	end
	
	if AliasExists("RivalBuild") then
		CopyAlias("RivalBuild", "ib_Target")
		return 50
	end
	-- the victim's strongest workshop in this town, not a random one that may be elsewhere
	if aitwp_FindTargetBuilding("VictimDynasty", 2, "strongest", "ib_Target", "SIM") then
		return 50
	end

	return 0
end

function Execute()
	MeasureRun("ib_Servant","ib_Target","InspectBusiness")
end

