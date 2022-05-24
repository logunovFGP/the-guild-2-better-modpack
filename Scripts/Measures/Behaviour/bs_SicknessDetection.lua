function Run()
	
	-- check state impact
	if GetStateImpact("", "no_control") or GetStateImpact("", "no_hire") then
		return
	end
	
	if not GetSettlement("", "MyHomeCity") then
		return
	end
	
	-- Resist prevents infection spams on the same Sim
	if GetImpactValue("", "Resist") > 0 then
		return
	else
		AddImpact("", "Resist", 1, 2)
	end
	
	-- no infection spam in certain areas
	if GetInsideBuilding("", "CurrentBuilding") then
		if BuildingGetType("CurrentBuilding") == GL_BUILDING_TYPE_HOSPITAL then
			return
		end
		
		if BuildingGetType("CurrentBuilding") == GL_BUILDING_TYPE_WORKER_HOUSING then
			return
		end
	end
	
	-- check how contagious the disease is
	local Hazard = 50 -- 50% base chance
	
	if GetImpactValue("Actor", "Influenza") then
		Hazard = Hazard + 10 -- more contagious
	elseif GetImpactValue("Actor", "Blackdeath") then
		Hazard = Hazard + 30 -- highly contagious
	end
	
	local Constitution = GetSkillValue("", CONSTITUTION) * 5 -- high consti protects you from infections
	Hazard = Hazard - Constitution
	
	local SimAge = SimGetAge("") 
	
	if SimAge > 30 then -- old people have higher chances for infections
		Hazard = Hazard + 5
	end
	
	if SimAge > 40 then 
		Hazard = Hazard + 5
	end
	
	if SimAge > 50 then
		Hazard = Hazard + 5
	end
	
	if SimAge > 60 then
		Hazard = Hazard + 5
	end
	
	if Hazard > Rand(100) then -- infected!
		-- get the correct illness
		
		if GetImpactValue("Actor", "Cold") > 0 then
			diseases_Cold("", true)
		elseif GetImpactValue("Actor", "Influenza") > 0 then
			diseases_Influenza("", true)
		elseif GetImpactValue("Actor", "Pneumonia") > 0 then
			diseases_Influenza("", true)
		elseif GetImpactValue("Actor", "Blackdeath") > 0 then
			if not HasState("", "BlackdeathImmunity") then
				local CurrentRound = GetRound()
				local StartingRound = GetProperty("MyHomeCity", "ActivePlague") or 0
				if CurrentRound < StartingRound + 4 then
					diseases_Blackdeath("", true)
				end
			end
			return "flee"
		end
	end
end

