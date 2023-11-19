function Run()

	if not AliasExists("Destination") then
		return
	end

	local TimeOut = -1
	if SimGetProfession("") == GL_PROFESSION_CITYGUARD then
		TimeOut = 5
		SetData("Endtime"..GetID("Destination"), math.mod(GetGametime(),24) + 5)
	end

	local fDistance = 300
	if IsType("Destination", "Cart") then
		fDistance = 500
	elseif IsType("Destination", "Ship") then
		fDistance = 1000
	end
	
	local DataValue, Temp
	
	for l=0, 4 do
		Temp = "EscortedBy_"..l
		if not HasProperty("Destination", Temp) then
			DataValue = Temp
			break
		end
	end
	
	if not DataValue then
		return
	end
	
	SetData("Property", DataValue)
	SetProperty("Destination", DataValue, GetID(""))

	if TimeOut < 0 then
		while true do
			
			if not AliasExists("Destination") then
				break
			end
			
			if GetInsideBuilding("Destination", "InsideTarget") then -- don't follow inside!
				if HasProperty("", "CityBodyguard") or HasProperty("", "KIbodyguard") then
					break
				end
				
				local InsideType = BuildingGetType("InsideTarget")
				if InsideType == GL_BUILDING_TYPE_TOWNHALL then -- stay out
					local LocArray = {"walledge2", "bomb2", "entry1", "bomb1", "walledge1"}
					local randomChoice = Rand(5) + 1
					if GetLocatorByName("InsideTarget", LocArray[randomChoice], "WaitHere") then
						f_MoveTo("", "WaitHere", GL_MOVESPEED_RUN, fDistance)
						f_Stroll("", 400, 4)
					else
						f_MoveTo("", "InsideTarget")
						f_Stroll("", 400, 4)
					end
					
					while GetInsideBuilding("Destination", "InsideTarget") do
						Sleep(10)
					end
					
				elseif InsideType == GL_BUILDING_TYPE_TAVERN then
					local LocArray = {"walledge2", "bomb4", "entry1", "bomb1", "walledge1"}
					local randomChoice = Rand(5) + 1
					if GetLocatorByName("InsideTarget", LocArray[randomChoice], "WaitHere") then
						f_MoveTo("", "WaitHere", GL_MOVESPEED_RUN, fDistance)
						f_Stroll("", 400, 4)
					else
						f_MoveTo("", "InsideTarget")
						f_Stroll("", 400, 4)
					end
					
					while GetInsideBuilding("Destination", "InsideTarget") do
						Sleep(10)
					end
					
				elseif InsideType == GL_BUILDING_TYPE_RESIDENCE then
					local LocArray = {"walledge2", "bomb3", "entry1", "walledge1"}
					local randomChoice = Rand(4) + 1
					if GetLocatorByName("InsideTarget", LocArray[randomChoice], "WaitHere") then
						f_MoveTo("", "WaitHere", GL_MOVESPEED_RUN, fDistance)
						f_Stroll("", 400, 4)
					else
						f_MoveTo("", "InsideTarget")
						f_Stroll("", 400, 4)
					end
					
					while GetInsideBuilding("Destination", "InsideTarget") do
						Sleep(10)
					end
					
				elseif InsideType == GL_BUILDING_TYPE_CHURCH_EV or GL_BUILDING_TYPE_CHURCH_CATH then
					local LocArray = {"walledge1", "entry1", "walledge2"}
					local randomChoice = Rand(3) + 1
					if GetLocatorByName("InsideTarget", LocArray[randomChoice], "WaitHere") then
						f_MoveTo("", "WaitHere", GL_MOVESPEED_RUN, fDistance)
						f_Stroll("", 400, 4)
					else
						f_MoveTo("", "InsideTarget")
						f_Stroll("", 400, 4)
					end
					
					while GetInsideBuilding("Destination", "InsideTarget") do
						Sleep(10)
					end
			
				else -- default inside
					if GetLocatorByName("InsideTarget", "entry1", "WaitHere") then
						f_MoveTo("", "WaitHere", GL_MOVESPEED_RUN, fDistance)
						f_Stroll("", 400, 4)
					else
						f_MoveTo("", "InsideTarget")
						f_Stroll("", 400, 4)
					end
					
					while GetInsideBuilding("Destination", "InsideTarget") do
						Sleep(10)
					end
				end
			else
				-- speed me up
				if GetImpactValue("", "MoveSpeed") < 1.2 then
					AddImpact("", "MoveSpeed", 1.2, 4)
				end
				
				local CurrentDistance = GetDistance("", "Destination")
				if CurrentDistance > 200 and CurrentDistance < 750 then
					if not f_Follow("", "Destination", GL_MOVESPEED_WALK, fDistance, true) then
						f_MoveTo("", "InsideTarget", GL_MOVESPEED_WALK, fDistance)
					end
				elseif CurrentDistance >= 750 then
					if not f_Follow("", "Destination", GL_MOVESPEED_RUN, fDistance, true) then
						f_MoveTo("", "InsideTarget", GL_MOVESPEED_RUN, fDistance)
					end
				end
				
				Sleep(2)
			end
		end
		StopMeasure()
	end
	
--	Sleep(Gametime2Realtime(TimeOut))
	if TimeOut == 5 then
		f_FollowNoWait("", "Destination", GL_MOVESPEED_RUN, fDistance)
		if math.mod(GetGametime(), 24) > GetData("Endtime"..GetID("Destination")) then
			StopMeasure()
		end
	end
end

function CleanUp()
	local DataValue = GetData("Property")

	if AliasExists("Destination") and HasProperty("Destination", "KIbodyguard") then
	
		if DataValue then
			RemoveProperty("Destination", DataValue)
		end
		
		if GetProperty("Destination", "KIbodyguard") > 1 then
			SetProperty("Destination", "KIbodyguard", 1)
		else
			RemoveProperty("Destination", "KIbodyguard")
		end
	end

	if HasProperty("", "CityBodyguard") then
		RemoveProperty("", "CityBodyguard")
	end
end

