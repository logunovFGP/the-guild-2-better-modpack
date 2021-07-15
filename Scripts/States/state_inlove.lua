function Init()

	SetStateImpact("no_hire")
end

function Run()

	while true do
		Sleep(120)
		if not HasProperty("", "courted") then
			break
		end
	end
		
	SetState("", STATE_INLOVE, false)
end

