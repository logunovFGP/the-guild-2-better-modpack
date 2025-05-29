function Run()
	MsgDebugMeasure("Enjoying time at the tavern.")
	LogMessage("@IDLE #W ("..GetName("")..") I am enjoying time at the tavern.")

	if GetSettlement("", "City") then
		local Stage = GetData("#MusicStage")
		if (Stage ~= nil) and GetAliasByID(Stage, "StageObject") then
			BuildingGetCity("StageObject", "StageCity")
			if GetID("City") == GetID("StageCity") and (Rand(100)>39) then
				if (BuildingGetType("StageObject") == GL_BUILDING_TYPE_DIVEHOUSE) then
					idlelib_GoToDivehouse()
					return
				end
			end
		end
		
		-- TODO calculation of attractivity needs to be increased when versengold is giving a concert
		economy_GetRandomBuildingByRanking("City", "Destination", 0, GL_BUILDING_TYPE_TAVERN)

		if not AliasExists("Destination") or not f_MoveTo("", "Destination") then
			return
		end

		CopyAlias("Destination", "Tavern")

		if Rand(4) == 0 then
			if HasProperty("Destination", "Versengold") then
				MeasureRun("", nil, "CheerMusicians")
			else
				idlelib_KissMeHonza()
			end
		end
		
		local NumSims = Find("", "__F((Object.GetObjectsByRadius(Sim) == 10000))", "Sim", -1)

		if NumSims > 30 then
			f_ExitCurrentBuilding("")
			idlelib_GoToRandomPosition()
			return
		end

		local hasFoundSeat = 0

		if IsDynastySim("") then
			for i = 1, 6 do
				if GetFreeLocatorByName("Destination", "SitRich", i, i, "SitPos") then
					hasFoundSeat = i + 15
					break					
				end
			end
		else
			for i = 1, 15 do
				if GetFreeLocatorByName("Destination", "SitInn", i, i, "SitPos") then
					hasFoundSeat = i
					break					
				end
			end
		end

		if not (hasFoundSeat == 0) then 
			f_Stroll("", 150, 2)
		end

		if (hasFoundSeat > 0) and not f_BeginUseLocator("", "SitPos", GL_STANCE_SIT, true) then 
			return
		end

		local Time = {Remaining=GetGametime()+2, Current=math.mod(GetGametime(), 24)}

		local IncrementTime = function(Value)
			Time.Remaining = Time.Remaining + Value
		end

		if (Time.Current > 6) and (Time.Current < 20) then
			IncrementTime(Rand(3)+2)
		else
			IncrementTime(Rand(6)+2)
		end

		if HasProperty("Destination", "DanceShow") then
			IncrementTime(3)
		end

		if HasProperty("Destination", "ServiceActive") then
			IncrementTime(2)
		end

		GetDynasty("Destination", "Dynasty")
		
		while (GetGametime() < Time.Remaining) do

			if HasProperty("Destination", "Versengold") and (Rand(10)>7) then
				f_EndUseLocator("", "SitPos", GL_STANCE_STAND)
				MeasureRun("", nil, "CheerMusicians")
			end	

			local Purchases = 
			{ 
				["Drink"]	= {Items = {"SmallBeer", "WheatBeer"}, Needo=8},
				["Food"]	= {Items = {"GrainPap",  "RoastBeef"}, Needo=1},
				Decision = {Type="Drink", Amount=1}
			}

			if HasProperty("Destination", "DanceShow") then
				Purchases.Decision.Amount = 2
			end

			if Rand(2) == 0 then
				Purchases.Decision.Type = "Food"
			end

			SetProperty("Tavern", "Guest"..GetID("").."WantsType", Purchases[Purchases.Decision.Type].Items[Rand(2)+1])
			SetProperty("Tavern", "Guest"..GetID("").."WantsAmount", Purchases.Decision.Amount)

			if HasProperty("Tavern", "GuestServed#"..GetID("")) then
				PlaySound3DVariation("", "Locations/tavern_people", 1)

				local AnimType = Rand(2)

				if AnimType == 0 then
					PlayAnimation("", "sit_talk")
				else
					PlayAnimationNoWait("", "sit_laugh")
					Sleep(2)
					if (Rand(2) == 0) then
						PlaySound3D("", "Locations/tavern/laugh_01.wav", 1)
					else
						PlaySound3D("", "Locations/tavern/laugh_02.wav", 1)
					end
					Sleep(5)
				end

				if HasProperty("Tavern", "Guest"..GetID("").."Has") then
					local Type = GetProperty("Tavern", "Guest"..GetID("").."Has")

					if Type == "Food" then

						if not AliasExists("Bowl_Stew"..GetID("")) then
							local Data =
							{
								-- Poor
								{525,80,184}, {521,80,270}, {615,80,181}, {626,80,300}, {550,80,-165}, {457,80,-179}, {515,80,-81}, {407,80,-88}, {93,80,-76}, {91,80,32}, {50,80,70}, {-1,80,-5}, {0,80,390}, {0,80,300}, {110,80,390},
								-- Rich
								{473,155,-810}, {382,155,-878}, {771,155,-817}, {769,155,-719}, {785,155,-817}, {380,155,-760}
							}

							GfxAttachObject("Bowl_Stew"..GetID(""), "Locations/Tavern/Bowl_Stew_fixed.nif")
							GfxSetPosition("Bowl_Stew"..GetID(""), Data[hasFoundSeat][1], Data[hasFoundSeat][2], Data[hasFoundSeat][3], true)

							GetDynasty("Tavern", "Dynasty")
							if DynastyIsPlayer("Dynasty") then
								LogMessage("@TAVERN_TABLE #W Spawning bowl of soup (" .. GetName("") ..")")
							end
						end

						for i = 1, Rand(4) + 1 do
							PlayAnimation("", "sit_eat")
						end

						GfxDetachObject("Bowl_Stew"..GetID(""))
					end

					if Type == "Drink" then
						local AnimTime
						if Rand(2) == 0 then
							AnimTime = PlayAnimationNoWait("", "sit_cheer")
							Sleep(1)
							PlaySound3D("", "Locations/tavern/cheers_01.wav", 1)
							CarryObject("", "Handheld_Device/ANIM_beaker_sit_drink.nif", false)
							Sleep(1)
							PlaySound3DVariation("", "CharacterFX/drinking", 1)
							Sleep(AnimTime-1.5)
							CarryObject("", "", false)
							Sleep(1.5)
						else
							AnimTime = PlayAnimationNoWait("", "sit_drink")
							Sleep(1)
							CarryObject("", "Handheld_Device/ANIM_beaker_sit_drink.nif", false)
							Sleep(1)
							PlaySound3DVariation("", "CharacterFX/drinking", 1)
							Sleep(AnimTime-1.5)
							CarryObject("", "", false)				
							if SimGetGender("") == GL_GENDER_MALE then
								PlaySound3DVariation("", "CharacterFX/male_belch", 1)
							else
								PlaySound3DVariation("", "CharacterFX/female_belch", 1)
							end
							Sleep(1.5)
						end
					end
				end
			end

			Sleep(5)
		end

		Time.Current = math.mod(GetGametime(), 24)
		if (Time.Current > 21) or (Time.Current < 4) then
			if Rand(100) > 80 then
				--LoopAnimation("","idle_drunk",10)
				AddImpact("", "totallydrunk", 1, 6)
				AddImpact("", "MoveSpeed", 0.7, 6)
				SetState("", STATE_TOTALLYDRUNK, true)
				StopMeasure()
			end
		end
	end
end

function CleanUp()
	f_EndUseLocator("", "SitPos", GL_STANCE_STAND)
	if GetInsideBuilding("", "Tavern") then
		if AliasExists("Tavern") then
			if AliasExists("Bowl_Stew"..GetID("")) then
				GfxDetachObject("Bowl_Stew"..GetID(""))
			end
			GetDynasty("Tavern", "Dynasty")
			if DynastyIsPlayer("Dynasty") then
				LogMessage("@TAVERN #W (" .. GetName("") .. ") ends the GoTavern() action.")
			end
			local Guest = GetID("")
			local Clear = {"GuestServed#"..Guest, "Guest"..GetID("").."WantsType", "Guest"..GetID("").."WantsAmount", "Guest"..GetID("").."Has"}
			for k, v in helpfuncs_myipairs(Clear) do
				if HasProperty("Tavern", k) then
					RemoveProperty("Tavern", k)
				end
			end
			if HasProperty("Tavern", "Guest"..GetID("").."Waiter") then
				local Waiter = GetProperty("Tavern", "Guest"..GetID("").."Waiter")
				GetAliasByID(Waiter, "Waiter")
				MeasureRun("Waiter", nil, "AssignEmployeeToService")
			end
		end
	end
end