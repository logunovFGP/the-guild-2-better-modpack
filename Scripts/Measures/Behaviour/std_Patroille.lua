function Run()

	local		Number = 1
	local		Point
	
	while true do
	
		Point = "Point"..Number
		
		if HasProperty("", Point) then
			local PositionName = GetProperty("", Point)

			if GetOutdoorLocator(PositionName, 1, "Position") == 1 then
				f_MoveTo("", "Position")
			end
			
			Sleep(Rand(12)+1)
			Number = Number + 1
			
		else
			Number = 1
		end
		
		if Rand(3) == 0 then
			if Rand(6) == 0 then
				PlayAnimation("", "watch_for_guard")
			else
				if Rand(2) == 0 then
					PlayAnimation("", "cogitate")
				else
					PlayAnimation("", "talk_short")
				end
			end
		end
		Sleep(1+Rand(5))
	end
end

