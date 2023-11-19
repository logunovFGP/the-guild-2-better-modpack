function Weight()
	if not ReadyToRepeat("SIM", "AI_CheckOutfit") then
		return 0
	end	
	
	if math.mod(GetGametime(), 24) >= 8 then
		return 100
	else
		return 0
	end
end

function Execute()
	local Random = Rand(12)
	SetRepeatTimer("SIM", "AI_CheckOutfit", (24+Random))
	MeasureRun("SIM", nil, "CheckOutfit")
end

