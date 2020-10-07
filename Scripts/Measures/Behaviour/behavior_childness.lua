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
	
	if not GetSettlement("", "City") then
		GetNearestSettlement("", "City")
	end	

	-- Check if the sim is old enough for the school
	if SimGetAge("") >= GL_AGE_FOR_SCHOOL then
	
		local Money = GL_SCHOOLMONEY
		feedback_MessageSchedule("", "@L_FAMILY_149_ATTENDSCHOOL_INTRO_HEAD", "@L_FAMILY_149_ATTENDSCHOOL_INTRO_BODY", GetID(""), Money)
		SimSetBehavior("", "Schooldays") -- school days is the time the child can be sent to school
		return
		
	end

	-- Check if the sim is at the residence. If not let him move to.
	if not AliasExists("Residence") then
		if SimGetMother("","MyMother") == false or GetHomeBuilding("MyMother", "Residence")==false then
			if SimGetFather("","MyFather") == false or GetHomeBuilding("MyFather", "Residence")==false then
				GetHomeBuilding("", "Residence")
			end
		end
	end	
	
	if not AliasExists("Residence") then
		Sleep(120)
		return
	end
	
	-- move home if you are not there
	local BuildType = BuildingGetType("Residence")
	if BuildType == 2 or BuildType == 1  then
		if GetInsideBuilding("", "InsideBuilding") then
			if not GetID("Residence") == GetID("InsideBuilding") then
				f_MoveTo("", "Residence")
			end
		else
			f_MoveTo("", "Residence")
		end
	else
		CityGetNearestBuilding("City", "", -1, 1, -1, -1, FILTER_IGNORE, "NewHome")
		SetHomeBuilding("", "NewHome")
		CopyAlias("NewHome", "Residence")
	end
	
	--idle behaviours
	local Action = Rand(5)
	if BuildingGetType("Residence")== 2 then -- residence, all normal
		if Action == 0 then	
			if GetFreeLocatorByName("Residence", "Play",1,3, "PlayPos") then
				if f_BeginUseLocator("","PlayPos",GL_STANCE_STAND,true) then
					PlayAnimation("","child_play_02_in")
					LoopAnimation("","child_play_02_loop",12)
					PlayAnimation("","child_play_02_out")
					f_EndUseLocator("","PlayPos",GL_STANCE_STAND)
					Sleep(Rand(12)+1)
				end
			end
		elseif Action == 1 then	
			if GetLocatorByName("Residence", "Apples", "PlayPos") then
				if f_BeginUseLocator("","PlayPos",GL_STANCE_STAND,true) then
					if Rand(100)>50 then
						PlayAnimation("","manipulate_middle_low_r")
						PlayAnimation("","eat_standing")
					else
						PlayAnimation("","cogitate")
					end
					Sleep(Rand(12)+1)
				end
			end
		elseif Action == 2 then
			if GetFreeLocatorByName("Residence", "ChildStroll",1,1, "PlayPos") then
				if f_MoveTo("","PlayPos") then
					Sleep(3+Rand(5))
				end
			end
			if GetFreeLocatorByName("Residence", "ChildStroll",2,2, "PlayPos") then
				if f_MoveTo("","PlayPos") then
					Sleep(3+Rand(3))
				end
			end
			if GetFreeLocatorByName("Residence", "ChildStroll",3,3, "PlayPos") then
				if f_MoveTo("","PlayPos") then
					Sleep(2)
				end
			end
			if GetFreeLocatorByName("Residence", "ChildStroll",4,4, "PlayPos") then
				if f_MoveTo("","PlayPos") then
					Sleep(1+Rand(6))
				end
			end
		elseif Action == 3 then
			PlayAnimation("", "cogitate")
			Sleep(1+Rand(3))
			PlayAnimation("", "watch_for_guard")
		else
			if GetLocatorByName("Residence", "BearRug", "PlayPos") then
				if f_BeginUseLocator("","PlayPos",GL_STANCE_SITGROUND,true) then
					Sleep(Rand(20)+12)
					f_EndUseLocator("","PlayPos",GL_STANCE_STAND)
				end
			end
		end
	
		Sleep(10)
	else
		Sleep(60)
	end	
end
