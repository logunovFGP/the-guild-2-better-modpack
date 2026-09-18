function Weight()
	local Hour = math.mod(GetGametime(), 24)
	-- Business hours, unless the house keeps a night trade: a crypt, a thieves' guild, a
	-- divehouse, a tavern or a robber camp is open when the bakers are asleep, and a flat
	-- 06-18 gate on the whole subtree is what stopped its owner managing it.
	if ((Hour < 6) or (18 <= Hour)) and not aitwp_HasNightTrade("dynasty") then
		return 0
	end

	-- no child can act, so do not spend the tick finding that out four times over. The
	-- economy subtree converted 0 of 262 picks into a measure on 2026-09-18 and 0 of 637
	-- in September; 89% of its entries never got past the children's own cooldowns.
	if not aitwp_EconomyReady("dynasty") then
		return 0
	end

	return utility_Score("dynasty", 10, {
		utility_Trait("dynasty", "greed"),
	}, "ToMEconomy", "Economy")
end

function Execute()
	utility_Picked("dynasty", "ToMEconomy")
	aitwp_Log("Enter subtree ToMEconomy", "dynasty", true)
end
