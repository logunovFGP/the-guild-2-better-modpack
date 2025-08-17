function Weight()
	local Hour = math.mod(GetGametime(), 24)
	if (Hour < 6) or (18 <= Hour) then
		return 0
	end

	return 10
end

function Execute()
	aitwp_Log("Enter subtree ToMEconomy", "dynasty", true)
end
