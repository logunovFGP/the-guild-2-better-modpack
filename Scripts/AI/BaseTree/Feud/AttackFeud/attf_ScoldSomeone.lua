function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "scold") then
		return 0
	end
	if not DynastyGetRandomBuilding("SIM", 2, GL_BUILDING_TYPE_CHURCH_EV, "Church") then
		if not DynastyGetRandomBuilding("SIM", 2, GL_BUILDING_TYPE_CHURCH_CATH, "Church") then
			return 0
		end
	end
		
	if not ReadyToRepeat("dynasty", "AI_Worship") then
		return 0
	end
	
	return 20
end

function Execute()
	local TargetID = GetID("Victim")
	SetRepeatTimer("dynasty", "AI_Worship", 12)
	if AliasExists("Church") then
		SetProperty("Church", "ScoldSomeone", TargetID)
	end
end
