function Init()
	SetStateImpact("no_hire")
	SetStateImpact("no_fire")	
	SetStateImpact("no_control")
	SetStateImpact("no_attackable")
	SetStateImpact("no_measure_start")
	SetStateImpact("no_measure_attach")
	SetStateImpact("no_charge")
	SetStateImpact("no_arrestable")
	SetStateImpact("no_action")
	SetStateImpact("no_cancel_button")
end

function Run()
	local TimeOut = GetGametime() + 24
	while GetGametime() < TimeOut do
		Sleep(100)
	end
end

function CleanUp()
	if HasProperty("Destination", "NoEscape") then
		RemoveProperty("Destination", "NoEscape")
	end
	MoveSetActivity("")
	StopAnimation("")
end

