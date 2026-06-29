function Run()
	local aSet = GetProperty("", "DbgRoadAset")
	local bSet = GetProperty("", "DbgRoadBset")
	if not aSet then aSet = 0 end
	if not bSet then bSet = 0 end

	local choice = MsgBox("", "", "@P"..
		"@B[1,@L_ROADDBG_MARKA_+0]"..
		"@B[2,@L_ROADDBG_MARKB_+0]"..
		"@B[3,@L_ROADDBG_BUILD_+0]"..
		"@B[4,@L_ROADDBG_CLEAR_+0]",
		"@L_ROADDBG_MENU_HEAD_+0", "@L_ROADDBG_MENU_BODY_+0")

	if choice == 1 then
		local x, y, z = GetWorldPositionXYZ("")
		if x then
			SetProperty("", "DbgRoadAx", x)
			SetProperty("", "DbgRoadAz", z)
			SetProperty("", "DbgRoadAset", 1)
			MsgBoxNoWait("", "", "@L_ROADDBG_SETA_HEAD_+0", "@L_ROADDBG_SETA_BODY_+0")
		end
	elseif choice == 2 then
		local x, y, z = GetWorldPositionXYZ("")
		if x then
			SetProperty("", "DbgRoadBx", x)
			SetProperty("", "DbgRoadBz", z)
			SetProperty("", "DbgRoadBset", 1)
			MsgBoxNoWait("", "", "@L_ROADDBG_SETB_HEAD_+0", "@L_ROADDBG_SETB_BODY_+0")
		end
	elseif choice == 3 then
		if aSet ~= 1 or bSet ~= 1 then
			MsgBoxNoWait("", "", "@L_ROADDBG_NEED_HEAD_+0", "@L_ROADDBG_NEED_BODY_+0")
			StopMeasure(); return
		end

		local t = MsgBox("", "", "@P"..
			"@B[1,@L_ROADDBG_TYPE_DIRT_+0]"..
			"@B[2,@L_ROADDBG_TYPE_PAVED_+0]"..
			"@B[3,@L_ROADDBG_TYPE_STONE_+0]",
			"@L_ROADDBG_TYPE_HEAD_+0", "@L_ROADDBG_TYPE_BODY_+0")
		local roadType
		if t == 1 then roadType = 0
		elseif t == 2 then roadType = 1
		elseif t == 3 then roadType = 2
		else StopMeasure(); return end

		local ax = GetProperty("", "DbgRoadAx")
		local az = GetProperty("", "DbgRoadAz")
		local bx = GetProperty("", "DbgRoadBx")
		local bz = GetProperty("", "DbgRoadBz")

		if CreateRoad(ax, az, bx, bz, roadType) then
			MsgBoxNoWait("", "", "@L_ROADDBG_DONE_HEAD_+0", "@L_ROADDBG_DONE_BODY_+0")
		else
			MsgBoxNoWait("", "", "@L_ROADDBG_FAIL_HEAD_+0", "@L_ROADDBG_FAIL_BODY_+0")
		end
	elseif choice == 4 then
		RemoveProperty("", "DbgRoadAset")
		RemoveProperty("", "DbgRoadBset")
		RemoveProperty("", "DbgRoadAx")
		RemoveProperty("", "DbgRoadAz")
		RemoveProperty("", "DbgRoadBx")
		RemoveProperty("", "DbgRoadBz")
		MsgBoxNoWait("", "", "@L_ROADDBG_CLEARED_HEAD_+0", "@L_ROADDBG_CLEARED_BODY_+0")
	end

	StopMeasure()
end

function CleanUp()
end
