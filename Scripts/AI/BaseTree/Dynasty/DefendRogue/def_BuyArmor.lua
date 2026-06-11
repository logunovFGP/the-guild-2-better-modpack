-- def_BuyArmor.lua -- Community Update: buy head and hand armor too, not only body.

function Weight()
	if not AliasExists("SIM") then
		return 0
	end

	local Difficulty = ScenarioGetDifficulty()
	if Difficulty < 2 then
		return 0
	end
	
	-- shadow dynasties need an office below difficulty 4
	if Difficulty <= 3 then
		if DynastyIsShadow("SIM") then
			if SimGetOfficeLevel("SIM") < 1 then
				return 0
			end
		end
	end
		
	local Rank = SimGetRank("SIM")
	if Rank < 3 then
		return 0
	end

	-- armor per slot, worst to best, with the minimum rank to buy.
	-- minrank 99 = never bought, only counts as already equipped.
	local Slots = {
		{ {"LeatherArmor", 3}, {"WarCuirass", 99}, {"Chainmail", 4}, {"Platemail", 5} },
		{ {"IronCap", 3}, {"FullHelmet", 4}, {"EpicHelmet", 99} },
		{ {"IronBrachelet", 99}, {"LeatherGloves", 3}, {"EpicBracers", 99} },
	}

	-- pick the first slot where the SIM lacks an adequate piece for its rank
	local Item
	local s = 1
	while Slots[s] and not Item do
		local slot = Slots[s]

		-- best index this rank allows
		local target = 0
		local i = 1
		while slot[i] do
			if slot[i][2] <= Rank then
				target = i
			end
			i = i + 1
		end
		
		if target > 0 then
			-- already owns the target piece or anything better in this slot?
			local goodEnough = false
			local j = target
			while slot[j] do
				local nm = slot[j][1]
				if GetItemCount("SIM", nm, INVENTORY_STD) > 0 or GetItemCount("SIM", nm, INVENTORY_EQUIPMENT) > 0 then
					goodEnough = true
				end
				j = j + 1
			end

			if not goodEnough then
				Item = slot[target][1]
			end
		end
		
		s = s + 1
	end
		
	if not Item then
		return 0
	end
	
	local Price = ai_CanBuyItem("SIM", Item)
	local money = GetMoney("SIM") / 4
	
	if Price < 0 then
		return 0
	elseif Price > money then
		return 0
	end

	SetProperty("SIM", "AIBuyArmor", Item)
	return 100
end

function Execute()
	MeasureRun("SIM", nil, "AIBuyArmor")
end
