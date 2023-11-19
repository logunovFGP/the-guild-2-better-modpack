function Init()

	SetStateImpact("no_hire")
end

function Run()

	while true do
		Sleep(200)
		if not HasProperty("", "courted") then
			break
		end
	end
		
	SetState("", STATE_INLOVE, false)
end

