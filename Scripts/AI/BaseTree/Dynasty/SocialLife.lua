function Weight()
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end

	local Hour = math.mod(GetGametime(), 24)
	if Hour < 6 then
		return 0
	end

	-- scored: flirting, gifts, bribes and feasts follow the political priority and
	-- need money; serves the Politics goal
	return utility_Score("dynasty", 25, {
		utility_Priority("dynasty", "Political"),
		{ value = utility_Money("dynasty", 20000), curve = "sqrt" },
	}, "SocialLife", "Politics")
end

function Execute()
	utility_Picked("dynasty", "SocialLife")
	aitwp_Log("Enter subtree SocialLife", "dynasty", true)
end