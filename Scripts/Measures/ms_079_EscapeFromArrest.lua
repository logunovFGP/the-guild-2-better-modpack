function Run()
	MeasureSetNotRestartable()

	if GetInsideBuilding("", "Building") then
		return
	end

	SetState("", STATE_CAPTURED, false)
	AddImpact("", "REVOLT", 1, 6)
	SetState("", STATE_REVOLT, true)
end

function CleanUp()
end
