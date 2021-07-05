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
			
			Sleep(Rand(12)+4)
			Number = Number + 1
			
		else
			Number = 1
		end
		
		if Rand(3) == 0 then
			if Rand(6) == 0 then
				PlayAnimation("", "guard_object")
			else
				PlayAnimation("", "cogitate")
			end
		end
		Sleep(3+Rand(5))
	end
end

