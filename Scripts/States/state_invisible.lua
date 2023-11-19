function Init()
	SetStateImpact("no_idle")
	SetStateImpact("no_control")
	SetStateImpact("no_hire")
	SetStateImpact("no_enter")
	SetStateImpact("no_measure_attach")
	SetStateImpact("no_measure_start")
	SetStateImpact("NoCameraJump")
end

function Run()
	if GetNearestSettlement("", "City") then
		if not CityGetRandomBuilding("City", -1, GL_BUILDING_TYPE_WORKER_HOUSING, -1, -1, FILTER_IGNORE, "InvisContainer") then
			return
		end
	end
	
	SimBeamMeUp("", "InvisContainer", false)
	while true do
		Sleep(30)
	end
	
end

function CleanUp()
	
end

