function Weight()

	local Time = math.mod(GetGametime(), 24)
	if Time > 6 and Time < 20 then
		return 0
	end

	if IsDynastySim("SIM") then
		return 0
	end
	
	if not SimGetWorkingPlace("SIM", "Thiefshut") then
		return 0
	end
	
	if not BuildingHasUpgrade("Thiefshut", "PrisonDoor") then
		return 0
	end
	
	if BuildingGetPrisoner("Thiefshut", "Victim") then
		return 0
	end
	
	if GetMeasureRepeat("SIM", "Hijack") > 0 then
		return 0
	end
		
	for trys=0, 9 do
		if thief_hijack_Check() then
			return 100
		end
	end
	return 0
end

function Check()
	
	if not (aitwp_PreferPlayerDynasty("dynasty", "kidnap", "HIJ_VICTIM") or DynastyGetRandomVictim("SIM", 50, "HIJ_VICTIM")) then
		return false
	end
	if not aitwp_Allowed("dynasty", "HIJ_VICTIM", "kidnap") then
		return false
	end
	
	if GetInsideBuilding("HIJ_VICTIM", "Inside") then
		return false
	end
	
	if DynastyGetDiplomacyState("SIM", "HIJ_VICTIM") > DIP_NEUTRAL then
		return false
	end
	
	local Count = DynastyGetMemberCount("HIJ_VICTIM")
	if Count < 1 then
		return false
	end
	
	if not DynastyGetMember("HIJ_VICTIM", Rand(Count), "HIJ_SIM") then
		return false
	end
	
	if not CanBeControlled("HIJ_SIM", "HIJ_VICTIM") then
		return false
	end
	
	return true
end

function Execute()
	SquadCreate("SIM", "SquadHijackCharacter", "HIJ_SIM", "SquadHijackMember", "SquadHijackMember")
end

