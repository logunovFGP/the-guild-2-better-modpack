function Weight()
	if not AliasExists("Victim") then
		return 0
	end
	if GetState("SIM", STATE_DEAD) or GetState("SIM", STATE_UNCONSCIOUS) or GetState("SIM", STATE_CUTSCENE) then
		return 0
	end
	if GetState("Victim", STATE_DEAD) or GetState("Victim", STATE_CUTSCENE) then
		return 0
	end
	if GetDistance("SIM", "Victim") > 4000 then
		return 0
	end
	return 20
end

function Execute()
	MeasureRun("SIM", "Victim", "Rob")
end
