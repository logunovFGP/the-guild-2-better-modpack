function Run()
	
	if GetProperty("Actor", "PollutedWell") == 1 then
		if IsType("", "Sim") then
			if GetImpactValue("", "Sickness") == 0 and GetImpactValue("", "Resist") == 0 and SimGetProfession("") ~= 9 then
				local zuf = Rand(100) +1
				
				if zuf>90 then
					diseases_Influenza("", true)
				else
					diseases_Cold("", true)
				end
			end
		end
	end

	return ""
end

function CleanUp()
	
end
