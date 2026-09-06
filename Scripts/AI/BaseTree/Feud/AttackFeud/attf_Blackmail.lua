function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "blackmail") then
		return 0
	end
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("BlackmailCharacter")) > 0 then
		return 0
	end

	if not ReadyToRepeat("dynasty", "Do_Blackmail") then
		return 0
	end

	if GetState("Victim", STATE_DEAD) or GetState("Victim", STATE_UNCONSCIOUS) then
		return 0
	end

	if GetEvidenceAlignmentSum("SIM", "Victim") < 3 then
		return 0
	end

	if GetInsideBuildingID("Victim") ~= -1 then
		return 0
	end

	return 25
end

function Execute()
	SetRepeatTimer("dynasty", "Do_Blackmail", 48)
	MeasureRun("SIM", "Victim", "BlackmailCharacter", false)
end