function GetWorld()
	local WorldName
	WorldName = GetSettingString("NETWORK", "World", "")
	-- LogMessage("@NAO Messages: " .. GetProperty("World", "messages", 999))
	-- LogMessage("@NAO Ambient: " .. GetProperty("World", "ambient", 999))
	return WorldName
end

function CreatePlayerDynasty(ID, SpawnPoint, PeerID, PlayerDesc)
	LogMessage("@NAO #W ID: " .. ID .. ", SpawnPoint: " .. SpawnPoint .. ", " .. PeerID .. ", PlayerDesc: " .. PlayerDesc)
	local Error = defaultcampaign_CreateDynasty(ID, SpawnPoint, true, PeerID, PlayerDesc)
	if Error ~= "" then
		return Error
	end
end