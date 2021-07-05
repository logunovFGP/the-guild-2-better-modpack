function Init()
end

function Run()
	while true do
		Sleep(Rand(14))
		if Rand(2) == 0 then
			PlayAnimation("", "cogitate")
		else
			PlayAnimation("", "talk_positive")
		end
		Sleep(Rand(10))
		if Rand(2) == 0 then
			LoopAnimation("", "nod", 2)
		else
			PlayAnimation("", "talk")
		end
		Sleep(Rand(10))
		PlayAnimation("", "cogitate")
		if Rand(2) == 0 then
			PlayAnimation("", "shake_head")
		else
			PlayAnimation("", "talk_negative")
		end
		Sleep(Rand(20))
		if Rand(2) == 0 then
			PlayAnimation("", "talk2")
		else
			PlayAnimation("", "talk_short")
		end
	end
end