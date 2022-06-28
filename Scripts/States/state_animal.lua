function Init()
	SetStateImpact("no_idle")
	SetStateImpact("no_hire")
	SetStateImpact("no_control")
	SetStateImpact("no_attackable")
	SetStateImpact("no_measure_start")
	SetStateImpact("no_measure_attach")
	SetStateImpact("no_action")
	SetStateImpact("no_cancel_button")
	SetStateImpact("NoCameraJump")
	SimSetMortal("", false)
end

function Run()
	while true do
		local TierArt = SimGetProfession("")
		if TierArt == 43 then
			state_animal_HausVieh("dog")
		elseif TierArt == 44 then
			state_animal_HausVieh("cat")
		elseif TierArt == 45 then
			state_animal_KleinVieh("chicken")
		elseif TierArt == 46 then
			state_animal_KleinVieh("cock")
		elseif TierArt == 47 then
			state_animal_KleinVieh("duck")
		elseif TierArt == 48 then
			state_animal_KleinVieh("goose")
		elseif TierArt == 49 then
			state_animal_WaldVieh("wolf")
		elseif TierArt == 50 then
			state_animal_WaldVieh("deer")
		elseif TierArt == 51 then
			state_animal_WaldVieh("Stag")
		elseif TierArt == 55 then
			state_animal_PflegeVieh("Sheep")
		elseif TierArt == 57 then
			state_animal_PflegeVieh("Cow")
		elseif TierArt == 58 then
			state_animal_PflegeVieh("Pig")
		elseif TierArt == 76 then -- goat
			state_animal_PflegeVieh("Sheep")
			LogMessage("Goati Time")
		end
	end
end
	
function PflegeVieh(Animal)
	local range = 500
	local AniChange = false
	if Animal == "Goat" then
		AniChange = "Sheep"
	end
	
	-- get starting pos
	GetPosition("", "StartPos")
	LogMessage("StartPos")
	
	-- too far from home?
	if GetHomeBuilding("", "MyHome") and GetDistance("", "MyHome") > 1000 then
		CopyAlias("MyHome", "NewPos")
		LogMessage("Let's go Home")
	end
	
	-- create a new position nearby
	if not AliasExists("NewPos") then
		GetPosition("", "NewPos")
		
		local x = 0
		local y = 0
		local z = 0
		
		local RandomChangeX = Rand(3)
		if RandomChangeX == 0 then
			x = 0 + Rand(range) + 100
		elseif RandomChangeX == 1 then
			x = 0 - Rand(range) - 100
		end
		
		if Rand(2) == 0 then
			z = 0 + Rand(range) + 100
		else
			z = 0 - Rand(range) - 100
		end
		
		PositionModify("NewPos", x, y, z)
	end
	
	local CurrentDistance = GetDistance("", "NewPos")
	LogMessage("Distance is "..CurrentDistance)
	
	if CurrentDistance > 100 then 
		f_MoveToNoWait("", "NewPos", GL_MOVESPEED_SNEAK, 30)
		LogMessage("Let's go now")
		local StuckCheck = 0
		local StuckCounter = 0
		while true do
			if StuckCounter > 2 then
				StuckCheck = CurrentDistance
			else
				StuckCounter = StuckCounter + 1
			end
			
			LoopAnimation("", ""..Animal.."_walk", 1, 1)
			CurrentDistance = GetDistance("", "NewPos")
			if CurrentDistance <= 50 or CurrentDistance == StuckCheck then
				LogMessage("Reached")
				break
			end
			LogMessage("AnotherRound")
		end
	end
	
	-- is there someone nearby?
	local Interest = Find("","__F( (Object.GetObjectsByRadius(Sim) == 500))", "Interest", -1)
	local InterestID = Rand(Interest)
	
	if AliasExists("Interest"..InterestID) then
		AlignTo("", "Interest"..InterestID)
	end
	
	local idleArt = Rand(4)
	local idleWart = Rand(30) + 30
	if idleArt == 0 then
		-- weiter gehts
	elseif idleArt == 1 then
		LoopAnimation("", ""..Animal.."_idle_01", idleWart, 1)
		if not AniChange then
			PlayAnimation("", ""..Animal.."_idle_02", 1)
		end
		LogMessage("IdleArt1")
	elseif idleArt == 2 then
		LoopAnimation("", ""..Animal.."_idle_01", idleWart, 1)
		LogMessage("IdleArt2")
	elseif idleArt == 3 then
		if not AniChange then
			PlayAnimation("", ""..Animal.."_idle_02", 1)
		else
			LoopAnimation("", ""..Animal.."_idle_01", idleWart, 1)
		end
		LogMessage("IdleArt3")
	end
		
	if Rand(10) == 4 then
		LogMessage("Sound")
		if Animal == "Sheep" then
			if not AniChange then
				PlaySound3DVariation("","Locations/sheep_baa", 1.0)
			else
				PlaySound3DVariation("","Animals/Goat", 1.0)
			end
		elseif Animal == "Pig" then
			PlaySound3DVariation("","Locations/pigs_grunt", 1.0)
		elseif Animal == "Cow" then
			PlaySound3DVariation("","Locations/cow_low", 1.0)
		end
	end
	
	RemoveAlias("NewPos")
	RemoveAlias("StartPos")
end

function WaldVieh(Animal)
	GetPosition("", "StartPlatz")
	local range = 1000		
  
  	while true do
	 	GetPosition("StartPlatz", "GehHin")
		local x,y,z = PositionGetVector("GehHin")
		x = x + ((Rand(range)*2)-range)
		z = z + ((Rand(range)*2)-range)
		PositionModify("GehHin", x, y, z)
	  	SetPosition("GehHin", x, y, z)
		local moveArt = Rand(3)
   		local abstand = GetDistance("Owner", "GehHin")
		local abstand2
			
		if moveArt == 1 then
			if f_MoveToNoWait("","GehHin",GL_MOVESPEED_RUN) then
				while abstand > 100 do
					abstand2 = GetDistance("Owner", "GehHin")
					LoopAnimation("", ""..Animal.."_run", 1, 1)
					abstand = GetDistance("Owner", "GehHin")
					if abstand == abstand2 then
						break
					end
				end
			end
		else
		 	if f_MoveToNoWait("", "GehHin", GL_MOVESPEED_WALK) then
				while abstand > 100 do
					abstand2 = GetDistance("Owner", "GehHin")
					LoopAnimation("", ""..Animal.."_walk", 1, 1)
					abstand = GetDistance("Owner", "GehHin")
					if abstand == abstand2 then
						break
					end
				end
			end
		end

		local idleArt = Rand(4)
		local idleWart = Rand(19)+12
		local heulZeit = math.mod(GetGametime(), 24)

		if heulZeit > 22 and heulZeit < 24 or heulZeit > 0 and heulZeit < 4 then
			if Rand(3) == 0 then
		 		PlaySound3DVariation("", "ambient/wolf_howl",1.0)
			end
		end

   		if idleArt == 0 then
			-- weiter gehts
		elseif idleArt == 1 then
			LoopAnimation("", ""..Animal.."_idle_01", idleWart, 1)
			PlayAnimation("", ""..Animal.."_idle_02", 1)
   		elseif idleArt == 2 then
			LoopAnimation("", ""..Animal.."_idle_01", idleWart, 1)
		elseif idleArt == 3 then
			PlayAnimation("", ""..Animal.."_idle_02", 1)
		end

		RemoveAlias("GehHin")
		Sleep(30+Rand(20))
	end
end

function KleinVieh(Animal)
	local range = 500
	if Animal == "duck" then
		range = 200
	elseif Animal == "goose" then
		range = 400
  	end
	
	GetPosition("", "TierPosX")
	GetPosition("", "TierPosY")	
	
	while true do	
		GetPosition("TierPosY", "TierPosX")
   		local x,y,z = PositionGetVector("TierPosX")
		x = x + ((Rand(range)*2)-range)
		z = z + ((Rand(range)*2)-range)
		PositionModify("TierPosX", x, y, z)
   		SetPosition("TierPosX", x, y, z)

    	local abstand = GetDistance("Owner", "TierPosX")
    	local abstand2

    	if f_MoveToNoWait("", "TierPosX", GL_MOVESPEED_SNEAK) then
		while abstand > 100 do
			abstand2 = GetDistance("Owner", "TierPosX")
			LoopAnimation("", ""..Animal.."_walk", 1, 1)
			abstand = GetDistance("Owner", "TierPosX")
			if abstand == abstand2 then
				break
			end
		end
	
	    	local idleArt = Rand(3)
	    	local idleWart = Rand(10)+11
	
	    	if idleArt == 0 then
	     		-- weiter gehts
	    	elseif idleArt == 1 then
	     		LoopAnimation("", ""..Animal.."_idle_01", idleWart, 1)
	    	elseif idleArt == 2 then
	     		LoopAnimation("", ""..Animal.."_idle_01", idleWart, 1)
	    	end
	
	    	if Rand(5) == 4 then
		   		if Animal == "duck" then
		    	   PlaySound3DVariation("", "Animals/duck", 1.0)
		    	elseif Animal == "chicken" then
		   	    	PlaySound3DVariation("", "Animals/hen", 1.0)
		   		elseif Animal == "cock" then
		     		local morgen = math.mod(GetGametime(), 24)
		      		if morgen >= 5 and morgen <= 9 then
		      			PlaySound3DVariation("", "Animals/rooster", 1.0)
		      		end
	      		end
	    	end

		  	RemoveAlias("GehHin")
			Sleep(15+Rand(15))
		end
	end
end

function HausVieh(Animal)
 	local firstTime = 1
	GetSettlement("", "AnimalTown")

	while true do
  		local offset = math.mod(GetID("Owner"), 30) * 0.1
	 	local class
	  	if GetNearestSettlement("", "AnimalTown") then
	    	local	RandVal = Rand(7)
	    	if RandVal < 2 then
	      		if firstTime == 2 then
		      		class = GL_BUILDING_CLASS_MARKET
		    	else
		      		class = GL_BUILDING_CLASS_WORKSHOP
		      		firstTime = 2
		    	end
	    	elseif RandVal < 4 then
		    	class = GL_BUILDING_CLASS_PUBLIC
	    	else
		    	class = GL_BUILDING_CLASS_WORKSHOP
	    	end
		
		 	if CityGetRandomBuilding("AnimalTown", class, -1, -1, -1, FILTER_IGNORE, "Destination") then
				if GetOutdoorMovePosition("", "Destination", "MoveToPosition") then
			  		local moveArt = Rand(5)
				  	local abstand = GetDistance("Owner", "MoveToPosition")
					local abstand2

				 	if moveArt <= 3 then -- slow
						if Animal == "cat" then -- Katzen Extra
							f_MoveToNoWait("", "MoveToPosition", GL_MOVESPEED_SNEAK, 400+offset*15) -- Katzen Extra
					  	else -- Katzen Extra
							f_MoveToNoWait("", "MoveToPosition", GL_MOVESPEED_WALK, 400+offset*15)
					  	end -- Katzen Extra
					  
					 	while abstand > 400+offset*15+100 do
							abstand2 = GetDistance("Owner", "MoveToPosition")
				   	 		LoopAnimation("", ""..Animal.."_walk", 1, 1)
					    	abstand = GetDistance("Owner", "MoveToPosition")
							if abstand == abstand2 then
				      			break
				     		end
					  	end
				  	else -- fast
				    	if Animal == "cat" then -- Katzen Extra
				    		f_MoveToNoWait("", "MoveToPosition", GL_MOVESPEED_WALK, 400+offset*15) -- Katzen Extra
				    	else -- Katzen Extra
			        		f_MoveToNoWait("", "MoveToPosition", GL_MOVESPEED_RUN, 400+offset*15)
				    	end -- Katzen Extra
				    
				    	while abstand > 400+offset*15+100 do
					    	abstand2 = GetDistance("Owner", "MoveToPosition")
			   	    		LoopAnimation("",""..Animal.."_run", 1, 1)
					    	abstand = GetDistance("Owner", "MoveToPosition")
							if abstand == abstand2 then
			        			break
			        		end
				    	end
			    	end
			 	end
		 	end

	   		local idleArt = Rand(4)
	    	local idleWart = Rand(10)+12
	    	if idleArt == 0 then
	   			-- weiter gehts
	    	elseif idleArt == 1 then
		    	LoopAnimation("", ""..Animal.."_idle_01", idleWart, 1)
		    	PlayAnimation("", ""..Animal.."_idle_02", 1)
	    	elseif idleArt == 2 then
	      		LoopAnimation("", ""..Animal.."_idle_01", idleWart, 1)
	    	elseif idleArt == 3 then
	     		PlayAnimation("", ""..Animal.."_idle_02", 1)
	   		end
	    
	    	if Animal == "dog" then
				PlaySound3DVariation("", "ambient/dog_bark", 1.0)
	    	end
         
      		if Animal == "cat" and Rand(3) == 1 then
 				PlaySound3DVariation("", "Animals/cat",1.0)
			end
	  	end
		Sleep(12+Rand(10))
  	end
end

function CleanUp()
	InternalDie("")
	InternalRemove("")
end
