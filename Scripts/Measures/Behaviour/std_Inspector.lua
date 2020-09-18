function Run()

	local Name
	local	Settlement
	
	if not GetSettlement("", "Settlement") then
		Sleep(100)
		return
	end
	
	while true do
		CarryObject("", "Handheld_Device/Anim_Scroll.nif", false)

		if GetOfficeTypeHolder("Settlement", 6 ,"Office") then	-- 6 = EN_OFFICETYPE_GUILDMAN

			if DynastyIsPlayer("Office") then
				Sleep(30)
				return
			end
		end
		

		if not CityGetRandomBuilding("Settlement", -1, -1, -1, -1, FILTER_IGNORE, "PatrolMe") then
			Sleep(60)
			return
		end
		
		if GetOutdoorMovePosition("Owner", "PatrolMe", "MoveToPosition") then
			Name = GetName("MoveToPosition")
			local RandomOffset = 100 + Rand(400)
--			MsgMeasure("","Moving to ("..Name..")")
			f_MoveTo("", "MoveToPosition", GL_MOVESPEED_WALK, RandomOffset)
			Sleep(30)
			PlayAnimation("", "cogitate")
			Sleep(20)
			PlayAnimation("", "watch_for_guard")
			Sleep(20)
			PlayAnimation("", "cogitate")
			Sleep(30)
			CarryObject("", "", false)
			f_MoveTo("", "Settlement", GL_MOVESPEED_WALK)
		end

		Sleep(100)
	end
end

