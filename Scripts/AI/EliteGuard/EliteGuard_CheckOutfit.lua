function Weight()
	if not ReadyToRepeat("SIM", "_AI_CheckOutfit") then
		return 0
	end

	if math.mod(GetGametime(), 24) > 18 then
		return 100
	else
		return 0
	end

	return 100
end

function Execute()
	local Random = Rand(8)
	SetRepeatTimer("SIM", "AI_CheckOutfit", (16+Random))
	MeasureRun("SIM", nil, "CheckOutfit")
end

