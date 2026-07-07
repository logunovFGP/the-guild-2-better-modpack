function Weight()
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Slander")) > 0 then
		return 0
	end

	if not ReadyToRepeat("dynasty", "Do_Slander") then
		return 0
	end

	if GetState("Victim", STATE_DEAD) or GetState("Victim", STATE_UNCONSCIOUS) then
		return 0
	end

	local Price = 200 * SimGetLevel("Victim") * GetNobilityTitle("Victim", false)
	if GetMoney("dynasty") < Price * 2 then
		return 0
	end

	local BardFilter = "__F((Object.GetObjectsByRadius(Sim)==3000)AND(Object.Property.IsBard == 1)AND(Object.Property.BardIsFree == 1))"
	if Find("SIM", BardFilter, "SLN_Bard", -1) < 1 then
		return 0
	end

	return 5
end

function Execute()
	SetRepeatTimer("dynasty", "Do_Slander", 168)
	MeasureRun("SIM", "Victim", "Slander", false)
end