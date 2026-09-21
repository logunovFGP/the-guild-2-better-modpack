-- One member of the ambush: walk out to the meeting place, lie up, and take the victim if
-- they come within TWP_AMBUSH_RADIUS before the squad's hour runs out. Otherwise go home.
--
-- The victim id is on the squad, not on the member: everyone has to strike the same person
-- or it is a brawl, not an ambush.
function Run()
	Sleep(0.5)
	MeasureSetNotRestartable()
	if not SquadGet("", "Squad") then
		aitwp_LogRaid("", "member", "nosquad")
		return
	end
	if not SquadGetMeetingPlace("Squad", "Destination") then
		aitwp_LogRaid("", "member", "nomeeting")
		return
	end
	f_MoveTo("", "Destination", GL_MOVESPEED_RUN, TWP_AMBUSH_RADIUS)
	local VictimID = GetProperty("Squad", "Victim") or 0
	while true do
		if GetGametime() > (GetProperty("Squad", "AmbushUntil") or 0) then
			break
		end
		if VictimID > 0 and GetAliasByID(VictimID, "Victim") and AliasExists("Victim")
				and not GetState("Victim", STATE_DEAD)
				and GetDistance("", "Victim") <= TWP_AMBUSH_RADIUS then
			aitwp_LogRaid("", "member", "struck")
			MeasureRun("", "Victim", "AttackEnemy", true)
			return
		end
		Sleep(0.5)
	end
	-- nobody came
	aitwp_LogRaid("", "member", "nobodycame")
	if GetHomeBuilding("", "AmbushHome") then
		f_MoveTo("", "AmbushHome", GL_MOVESPEED_RUN, 300)
	end
end
