function Run()
	
	if GetImpactValue("Actor", "polluted") == 1 then
		if IsType("", "Sim") then
			if GetImpactValue("", "Sickness") == 0 then
				if IsDynastySim("") and DynastyGetRandomBuilding("", -1, GL_BUILDING_TYPE_ALCHEMIST) then
					return ""
				elseif SimGetProfession("") == 9 then
					return ""
				end
				
				local ResistingChance = 0
				ResistingChance = math.ceil(GetImpactValue("", "Resist") + ImpactGetMaxTimeleft("", "Resist"))
				local SickChance = Rand(6)
				LogMessage("SickChance liegt bei "..SickChance.." und ResistingChance bei "..ResistingChance)
				if SickChance > ResistingChance then
					local zuf = Rand(100) +1
					
					if zuf>90 then
						Disease.Influenza:infectSim("")
					else
						Disease.Cold:infectSim("")
					end
				end
			end
		end
	end

	return ""
end

function CleanUp()
end
