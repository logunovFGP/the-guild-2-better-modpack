function Weight()

	return 0
end

function Execute()
	local TargetID = GetID("Target")
	SetRepeatTimer("dynasty", "AI_Worship", 12)
	if AliasExists("Church") then
		SetProperty("Church", "PraiseSomeone", TargetID)
	end
end
