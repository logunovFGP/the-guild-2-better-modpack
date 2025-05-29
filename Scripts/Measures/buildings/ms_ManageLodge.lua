function Run()

	if not GetInsideBuilding("", "Tavern") then
		StopMeasure()
	end

	SetProperty("Tavern", "ServingLodge", -1)

end

function CleanUp()

end