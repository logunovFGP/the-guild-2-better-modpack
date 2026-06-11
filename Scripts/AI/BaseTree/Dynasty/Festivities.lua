function Weight()
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end

	if not GetHomeBuilding("SIM", "FST_Home") then
		return 0
	end

	local Left = GetProperty("FST_Home", "InvitationsLeft") or 0
	if Left > 0 then
		return 70
	end

	if BuildingHasUpgrade("FST_Home", "Saloon") and not GetState("FST_Home", STATE_FEAST) then
		return 15
	end

	return 0
end

function Execute()
	aitwp_Log("Enter subtree Festivities", "dynasty", true)
end
