function Weight()
	if not AliasExists("SIM") then
		return 0
	end

	if not GetHomeBuilding("SIM", "home") then
		cohabitwithcharacter_SetFailTimers()
		return 0
	end
	
	if DynastyGetBuildingCount("SIM", 1, 2) < 1 then
		cohabitwithcharacter_SetFailTimers()
		return 0
	end

	if GetStateImpact("Spouse", "no_control") then
		cohabitwithcharacter_SetFailTimers()
		return 0
	end
	
	if not f_SimIsValid("Spouse") then
		cohabitwithcharacter_SetFailTimers()
		return 0
	end
	
	if SimGetBehavior("Spouse")=="CheckPresession" or SimGetBehavior("Spouse")=="CheckTrial" then
		cohabitwithcharacter_SetFailTimersExact(5)
		return 0
	end
	
	if   (SimGetGender("SIM") == GL_GENDER_MALE and SimGetAge("Spouse")>=47) 
	  or (SimGetGender("Spouse") == GL_GENDER_MALE and SimGetAge("SIM")>=47) 
	  then
		cohabitwithcharacter_SetFailTimers()
		return 0
	end

	return 50
end

function Execute()
	if not AliasExists("Spouse") then
		if not SimGetSpouse("SIM", "Spouse") then
			cohabitwithcharacter_SetFailTimers()
			return
		end
	end
	SetRepeatTimer("dynasty", "AI_Reproduce", 24)
	MeasureRun("SIM", "Spouse", "CohabitWithCharacter")
end


function SetFailTimers()
	cohabitwithcharacter_SetFailTimersExact(24)
end

function SetFailTimersExact(Hours)
	SetRepeatTimer("SIM", "AI_FailedReproduction_Cohabit", Hours)
	SetRepeatTimer("Spouse", "AI_FailedReproduction_Cohabit", Hours)
end
