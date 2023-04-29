function Run()

	SetProperty("", "StartWorkingTime", 1)
	
	while true do
		-- boost the productivity of employees. Check stats every 30 seconds.
		if not IsDynastySim("") then
			if SimGetWorkingPlace("", "WorkingPlace") then
				local ProdSkillBonus = 0
				
				-- remove old boost
				RemoveImpact("", "Productivity")
			
				-- get Boss' stats
				if BuildingGetOwner("WorkingPlace", "Boss") then	
					ProdSkillBonus = (GetSkillValue("Boss", CRAFTSMANSHIP) - 1)*0.1
				end
				
				-- get own stats
				ProdSkillBonus = ProdSkillBonus + (GetSkillValue("", CRAFTSMANSHIP) - 1)*0.05
				
				-- add the boost
				AddImpact("", "Productivity", ProdSkillBonus, -1)
			end
		end	
		Sleep(30)
	end
end

function CleanUp()

	if HasProperty("", "StartWorkingTime") then
		RemoveProperty("", "StartWorkingTime")
	end
	
	if not IsDynastySim("") then
		-- remove boost when work is over
		RemoveImpact("", "Productivity")
	end
end
