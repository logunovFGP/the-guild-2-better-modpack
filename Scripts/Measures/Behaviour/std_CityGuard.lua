-- Community Update: with a player captain the guard plan was skipped and the
-- guards idled. They now follow a route set by the captain, or patrol normally.
function Run()

	local Player = false
	if GetSettlement("","Settlement") then	
		if GetOfficeTypeHolder("Settlement", 2 ,"Office") then		-- 2 = sheriff
			Player = DynastyIsPlayer("Office")
		end
		
		if not Player then
			AIExecutePlan("", "CityGuard", "SIM", "", "dynasty", "ServantDynasty")
			return
		else
			-- follow a route set by the captain, else patrol normally
			if HasProperty("", "CU_PatrolActive") then
				MeasureRun("", nil, "PatrolTheTown")
				return
			end
			AIExecutePlan("", "CityGuard", "SIM", "", "dynasty", "ServantDynasty")
			return
		end
	else
		PlayAnimation("","cogitate")
	end
	
	Sleep(Rand(20)+10)
end
