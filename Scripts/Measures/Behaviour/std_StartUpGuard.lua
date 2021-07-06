function Init()
end

function Run()
	while true do
		Sleep(Rand(14))
		LoopAnimation("", "guard_object", 15)
		Sleep(Rand(10))
		PlayAnimation("", "watch_for_guard")
	end
end