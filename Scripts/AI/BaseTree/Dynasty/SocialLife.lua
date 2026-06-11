function Weight()
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end

	local Hour = math.mod(GetGametime(), 24)
	if Hour < 6 then
		return 0
	end

	return 25
end

function Execute()
	aitwp_Log("Enter subtree SocialLife", "dynasty", true)
end