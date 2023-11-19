-------------------------------------------------------------------------------
----
----	OVERVIEW "behavior_apprenticeship.lua"
----
----	Behavior of a child from 8 to 12 years of age.
----	The child can be sent to apprenticeship to change the class.
----	Since the child can not be directly controlled by the player
----	it must be sent back to the residence if it is not already there
----	and not in another workshop.
----	
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()
	
	if not GetSettlement("", "City") then
		GetNearestSettlement("", "City")
	end

	-- Check if the sim is old enough for the university
	local Age = SimGetAge("")
	if Age >= GL_AGE_FOR_UNIVERSITY then
		if SimGetClass("") == GL_CLASS_SCHOLAR then
			-- Check the education
			if GetProperty("", "EduLevel") > EDULEVEL_NONE then			
				local Money = GL_UNIVERSITYMONEY
				feedback_MessageSchedule("", "@L_FAMILY_151_ATTENDUNIVERSITY_1ST_INTRO_HEAD", "@L_FAMILY_151_ATTENDUNIVERSITY_1ST_INTRO_BODY", GetID(""), Money)
			else
				feedback_MessageSchedule("", "@L_FAMILY_151_ATTENDUNIVERSITY_MISSING_EDUCATION_HEAD", "@L_FAMILY_151_ATTENDUNIVERSITY_MISSING_EDUCATION_BODY", GetID(""))
			end
		end
		SimSetBehavior("", "University")
		return
	end
	
	-- Check if the sim is at the residence. If not let him move to.
	if not AliasExists("Residence") then
		if SimGetMother("","MyMother")==false or GetHomeBuilding("MyMother", "Residence")==false then
			if SimGetFather("","MyFather")==false or GetHomeBuilding("MyFather", "Residence")==false then
				GetHomeBuilding("", "Residence")
			end
		end
	end	
	
	if not AliasExists("Residence") then
		Sleep(120)
		return
	end
	
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
	local Hour = math.mod(GetGametime(), 24)
	local Action = Rand(6)
	if BuildingGetType("Residence") == GL_BUILDING_TYPE_RESIDENCE then -- residence, all normal
		if Hour < 8 or Hour > 20 then -- it's late go home or stay there
			if GetInsideBuildingID("")~=GetID("Residence") then
				f_MoveTo("", "Residence", GL_MOVESPEED_RUN)
			end
			
			if Action == 0 then	
				if GetFreeLocatorByName("Residence", "Play",1,3, "PlayPos") then
					if f_BeginUseLocator("","PlayPos",GL_STANCE_STAND,true) then
						PlayAnimation("","child_play_02_in")
						LoopAnimation("","child_play_02_loop",12)
						PlayAnimation("","child_play_02_out")
						f_EndUseLocator("","PlayPos",GL_STANCE_STAND)
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
					end
				end
			elseif Action == 2 then
				if GetFreeLocatorByName("Residence", "ChildStroll",1,1, "PlayPos") then
					f_MoveTo("","PlayPos",GL_MOVESPEED_RUN,100)
				end
				if GetFreeLocatorByName("Residence", "ChildStroll",2,2, "PlayPos") then
					f_MoveTo("","PlayPos",GL_MOVESPEED_RUN,100)
				end
				if GetFreeLocatorByName("Residence", "ChildStroll",3,3, "PlayPos") then
					f_MoveTo("","PlayPos",GL_MOVESPEED_RUN,100)
				end
				if GetFreeLocatorByName("Residence", "ChildStroll",4,4, "PlayPos") then
					f_MoveTo("","PlayPos",GL_MOVESPEED_RUN,100)
				end
			elseif Action == 3 then
				if GetLocatorByName("Residence", "BearRug", "PlayPos") then
					if f_BeginUseLocator("","PlayPos",GL_STANCE_SITGROUND,true) then
						Sleep(Rand(20)+10)
						f_EndUseLocator("","PlayPos",GL_STANCE_STAND)
					end
				end
			elseif Action == 4 then
				f_Stroll("", 500, 4)
				PlayAnimation("", "dance_female_1")
				Sleep(3)
				f_Stroll("", 350, 3)
				PlayAnimation("", "dance_male_1")
				PlayAnimation("", "giggle")
			elseif Action == 5 then
				f_Stroll("", 750, 5)
				PlayAnimation("", "point_at")
				PlayAnimation("", "lay_down")
				PlayAnimation("", "get_up")
				PlayAnimation("", "nod")
				Sleep(6)
			end
		else -- its daytime!
			if Action == 0 then
				if GetInsideBuildingID("") >= 0 then -- go outside!
					f_ExitCurrentBuilding("")
					f_Stroll("", 1500, 15)
					Sleep(2+Rand(10))
				else
					Sleep(3)
				end
			elseif Action == 1 then
				f_Stroll("", 500, 4)
				PlayAnimation("", "dance_female_1")
				Sleep(5)
				f_Stroll("", 350, 3)
				PlayAnimation("", "dance_male_1")
				PlayAnimation("", "giggle")
			elseif Action == 2 then
				f_Stroll("", 750, 5)
				PlayAnimation("", "point_at")
				PlayAnimation("", "lay_down")
				PlayAnimation("", "get_up")
				PlayAnimation("", "nod")
				Sleep(4)
			elseif Action == 3 then
				if CityGetRandomBuilding("City", -1, GL_BUILDING_TYPE_LINGERPLACE, -1, -1, FILTER_IGNORE, "Market") then
					GetFleePosition("", "Market", 300,"MovePos")
					f_MoveTo("", "MovePos", GL_MOVESPEED_WALK)
			
					PlayAnimationNoWait("", "child_play_02_in")
					LoopAnimation("", "child_play_02_loop", 12)
					PlayAnimationNoWait("", "child_play_02_out")
				end
			elseif Action == 4 then
				if CityGetRandomBuilding("City", 2, -1, -1, -1, FILTER_IGNORE, "Shop") then
					GetFleePosition("", "Shop", 500,"MovePos")
					f_MoveTo("", "MovePos", GL_MOVESPEED_WALK)
					PlayAnimation("", "point_at")
					f_MoveTo("", "Shop", GL_MOVESPEED_RUN, 100)
					PlayAnimation("", "manipulate_bottom_r")
					PlayAnimation("", "manipulate_bottom_l")
					f_Stroll("", 1000, 10)
					Sleep(7)
				end
			else
				if GetInsideBuildingID("")>=0 then
					f_ExitCurrentBuilding("")
				end
				f_Stroll("", 2000, 20)
				local season = GetSeason()
				if season == EN_SEASON_WINTER then
					local FightPartners = Find("", "__F((Object.GetObjectsByRadius(Sim)==2000)AND NOT(Object.HasDynasty()))","FightPartner", -1)
					if FightPartners > 0 then
						idlelib_SnowballBattle("FightPartner0")
						return
					end
				end
			end
		end
	else
		Sleep(60)
	end
	Sleep(7)
end
