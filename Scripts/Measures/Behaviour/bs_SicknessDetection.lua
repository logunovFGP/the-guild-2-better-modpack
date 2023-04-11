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

	-- check the disease of the actor
local Disease = ""
local list = {"Cold", "Influenza", "Pneumonia", "Pox", "Blackdeath"}

for i = 1, 5 do
    local disease = list[i]
    if GetImpactValue("Actor", disease) > 0 then
        Disease = disease
        break
    end
end
	
	-- check how contagious the disease is
	local Hazard = gameplayformulas_CalcIllnessHazard("", "Disease")
	
	if Hazard > Rand(100) then -- infected!
		-- get the correct illness
		
		if Disease == "Cold" then
			Disease.infectSim("","Cold")
		elseif Disease == "Influenza" then
			Disease.infectSim("","Influenza")
		elseif Disease == "Pneumonia" then
			Disease.infectSim("","Influenza")
		elseif Disease == "Pox" then
			Disease.infectSim("","Pox")
		elseif Disease == "Blackdeath" then
			if not HasState("", "BlackdeathImmunity") then
				local CurrentRound = GetRound()
				local StartingRound = GetProperty("MyHomeCity", "ActivePlague") or 0
				if CurrentRound < (StartingRound + 4) then
					Blackdeath.infectSim("")
				end
			end
			return "flee"
		end
	end
end

