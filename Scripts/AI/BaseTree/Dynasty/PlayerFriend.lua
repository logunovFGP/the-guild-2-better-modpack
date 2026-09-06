-- friend_for_now: a player this house likes (favour 70 and above) gets a small
-- courtesy now and then - a respectful letter. Never an alliance, whatever the favour
-- (aitwp_PlayerPolicy); the friendship lasts exactly as long as the favour does.
function Weight()
	if not ReadyToRepeat("dynasty", "AI_PlayerFriend") then
		return 0
	end
	if not dyn_GetIdleMember("dynasty", "SIM") then
		return 0
	end
	if not aitwp_FindFriendPlayer("dynasty", "FriendDyn") then
		return 0
	end
	if not aitwp_FindPlayerTarget("FriendDyn", "best", "FriendSim") then
		return 0
	end
	return utility_Trace("dynasty", "PlayerFriend", 5)
end

function Execute()
	utility_Picked("dynasty", "PlayerFriend")
	SetRepeatTimer("dynasty", "AI_PlayerFriend", 96)
	aitwp_Log("pays respect to " .. GetName("FriendSim"), "dynasty")
	MeasureCreate("Measure")
	MeasureAddData("Measure", "Choice", 2, false)
	MeasureAddData("Measure", "InitResult", 0, false)
	MeasureStart("Measure", "SIM", "FriendSim", "AdministrateDiplomacy")
end
