-- The ambush the workers raid sets. Not SquadWaylay: that one is the robber camp's own job
-- and stops dead without one (ms_SquadWaylayMember.lua line 19 wants a
-- GL_BUILDING_TYPE_ROBBER work building), so a party of thugs, beggars and the family's
-- rogues off a residence could never have run it.
--
-- The leader holds the meeting place - the spot the target works - and the squad waits
-- there for TWP_AMBUSH_HOURS. Nobody comes, everybody goes home: a mine nobody walks to
-- that morning is a wasted morning, not a reason to stand in a field all day.
function Run()
	SquadSetMeetingPlace("", "Destination")
	if not SquadGetLeader("", "Leader") then
		return
	end
	if not AliasExists("Destination") then
		return
	end
	SetProperty("", "Victim", GetID("Destination"))
	SetProperty("", "AmbushUntil", GetGametime() + TWP_AMBUSH_HOURS)
	while true do
		if GetGametime() > (GetProperty("", "AmbushUntil") or 0) then
			break
		end
		if (SquadGetMemberCount("", true) or 0) == 0 then
			break
		end
		Sleep(1)
	end
end

function CleanUp()
	SquadDestroy("")
end
