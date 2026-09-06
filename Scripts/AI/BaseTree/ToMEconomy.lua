function Weight()
	local Hour = math.mod(GetGametime(), 24)
	if (Hour < 6) or (18 <= Hour) then
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
