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
local Sickness = ""
local list = {"Cold", "Influenza", "Pneumonia", "Pox", "Blackdeath"}

for i = 1, 5 do
    local index = list[i]
    if GetImpactValue("Actor", index) > 0 then
        Sickness = index
        break
    end
end
	
	-- check how contagious the disease is
	local Hazard = gameplayformulas_CalcIllnessHazard("", "Disease")
	
	if Hazard > Rand(100) then -- infected!
		-- get the correct illness
		
		if Sickness == "Cold" then
			Disease.Cold:infectSim("")
		elseif Sickness == "Influenza" then
			Disease.Influenza:infectSim("")
		elseif Sickness == "Pneumonia" then
			Disease.Influenza:infectSim("")
		elseif Sickness == "Pox" then
			Disease.Pox:infectSim("")
		elseif Sickness == "Blackdeath" then
			if not HasState("", "BlackdeathImmunity") then
				local CurrentRound = GetRound()
				local StartingRound = GetProperty("MyHomeCity", "ActivePlague") or 0
				if CurrentRound < (StartingRound + 4) then
					Disease.Blackdeath:infectSim("")
				end
			end
			return "flee"
		end
	end
end

