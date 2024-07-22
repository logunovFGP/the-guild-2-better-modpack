-------------------------------------------------------------------------------
----
----	OVERVIEW "behavior_childness.lua"
----
----	Behavior of a child from 0 to 4 years of age.
----	The child cannot be controlled by the player and will stay
----	inside the residence playing.
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()
	
	chr_CheckHome("") -- make sure we have a home
	
	-- Check if the sim is old enough for the school
	if SimGetAge("") >= GL_AGE_FOR_SCHOOL then
	
		local Money = GL_SCHOOLMONEY
		feedback_MessageSchedule("", "@L_FAMILY_149_ATTENDSCHOOL_INTRO_HEAD", "@L_FAMILY_149_ATTENDSCHOOL_INTRO_BODY", GetID(""), Money)
		SimSetBehavior("", "Schooldays") -- school days is the time the child can be sent to school
		return
	end

	-- Check if the sim is at the residence. If not, let him move to it.
	if GetInsideBuilding("", "InsideBuilding") then
		if not GetID("Residence") == GetID("InsideBuilding") then
			f_MoveTo("", "Residence", GL_MOVESPEED_RUN)
		end
	else
		f_MoveTo("", "Residence", GL_MOVESPEED_RUN)
	end
		
	--idle behaviours
	local Action = Rand(5)
	if BuildingGetType("Residence") == GL_BUILDING_TYPE_RESIDENCE then -- residence, all normal
	
		if Action == 0 then	
			if GetFreeLocatorByName("Residence", "Play", 1, 3, "PlayPos") then
				if f_BeginUseLocator("", "PlayPos", GL_STANCE_STAND, true) then
					PlayAnimation("", "child_play_02_in")
					LoopAnimation("", "child_play_02_loop", 16)
					PlayAnimation("", "child_play_02_out")
					f_EndUseLocator("", "PlayPos", GL_STANCE_STAND)
					Sleep(Rand(20)+1)
				end
			end
		
		elseif Action == 1 then	
			if GetLocatorByName("Residence", "Apples", "PlayPos") then
				if f_BeginUseLocator("", "PlayPos", GL_STANCE_STAND, true) then
					if Rand(100) > 50 then
						PlayAnimation("", "manipulate_middle_low_r")
						PlayAnimation("", "eat_standing")
					else
						PlayAnimation("", "cogitate")
					end
					Sleep(Rand(20)+1)
				end
			end
		
		elseif Action == 2 then
			if GetFreeLocatorByName("Residence", "ChildStroll", 1, 1, "PlayPos") then
				if f_MoveTo("", "PlayPos") then
					Sleep(2+Rand(5))
				end
			end
			if GetFreeLocatorByName("Residence", "ChildStroll", 2, 2, "PlayPos") then
				if f_MoveTo("", "PlayPos") then
					Sleep(2+Rand(5))
				end
			end
			if GetFreeLocatorByName("Residence", "ChildStroll", 3, 3, "PlayPos") then
				if f_MoveTo("", "PlayPos") then
					Sleep(3)
				end
			end
			if GetFreeLocatorByName("Residence", "ChildStroll", 4, 4, "PlayPos") then
				if f_MoveTo("", "PlayPos") then
					Sleep(1+Rand(6))
				end
			end
		
		elseif Action == 3 then
			PlayAnimation("", "cogitate")
			Sleep(1+Rand(10))
			PlayAnimation("", "watch_for_guard")
		
		else
			if GetLocatorByName("Residence", "BearRug", "PlayPos") then
				if f_BeginUseLocator("", "PlayPos", GL_STANCE_SITGROUND, true) then
					Sleep(Rand(20)+12)
					f_EndUseLocator("", "PlayPos", GL_STANCE_STAND)
				end
			end
		end
	else -- not normal, probably worker hut
		Sleep(180)
	end
end
