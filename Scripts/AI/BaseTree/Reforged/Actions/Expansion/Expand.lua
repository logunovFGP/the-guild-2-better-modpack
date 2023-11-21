---- Decides, whether a new workshop will be build. 
function Weight()
--	local Difficulty = ScenarioGetDifficulty()
--	local FirstRound = 5 - Difficulty -- wait 5 rounds on easy, 1 round on hard
--	if GetRound() < FirstRound then
--		return 0
--	end
	
	if DynastyIsShadow("dynasty") then
		return 0
	end

	if not CanBuildWorkshop("dynasty") then
		-- Missing a title, the new workshop will have to wait.
		return 0
	end
	
	local Wealth = SimGetWealth("SIM")
	local Money = GetMoney("SIM")
	
	local ratio = math.floor(Money*100 / Wealth)
	if math.min(5, ratio) then
		return ratio
	end
	return 0
end

function Execute()
end
