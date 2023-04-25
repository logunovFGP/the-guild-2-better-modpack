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
	elseif TierArt == 76 then
		state_animal_PflegeVieh("Goat")
	end
end
	
function PflegeVieh(Animal)
	
	local range = 600
	local AniChange = false
	if Animal == "Goat" then
		AniChange = "Sheep"
	end
	
	GetPosition("", "StartPos")
	
	while true do
		Sleep(0.1)
		
		-- too far from home?
		if GetDistance("", "StartPos") > range*2 then
			CopyAlias("StartPos", "NewPos")
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
			
		if CurrentDistance > 100 then 
			f_MoveToNoWait("", "NewPos", GL_MOVESPEED_SNEAK, 30)
			local StuckCheck = 0
			local StuckCounter = 0
			while true do
				if StuckCounter == 1 then
					StuckCheck = CurrentDistance
				else
					StuckCounter = StuckCounter + 1
				end
					
				LoopAnimation("", ""..Animal.."_walk", 0.75, 1)
				CurrentDistance = GetDistance("", "NewPos")
				if CurrentDistance <= 100 or CurrentDistance == StuckCheck then
					break
				end
			end
		end
			
		-- is there someone nearby?
		local Interest = Find("","__F( (Object.GetObjectsByRadius(Sim) == 600))", "Interest", -1)
		local InterestID = Rand(Interest)
			
		if AliasExists("Interest"..InterestID) then
			AlignTo("", "Interest"..InterestID)
		end
			
		local idle = Rand(4)
		local idleTime = Rand(30) + 30
		
		if AniChange ~= false then
			Animal = AniChange
		end
		
		if idle == 0 then
			-- no idle, run!
		elseif idle == 1 then
			LoopAnimation("", ""..Animal.."_idle_01", idleTime, 1)
			if not AniChange then
				PlayAnimation("", ""..Animal.."_idle_02", 1)
			end
		elseif idle == 2 then
			LoopAnimation("", ""..Animal.."_idle_01", idleTime, 1)
		elseif idle == 3 then
			if not AniChange then
				PlayAnimation("", ""..Animal.."_idle_02", 1)
			else
				LoopAnimation("", ""..Animal.."_idle_01", idleTime, 1)
			end
		end
				
		if Rand(10) == 4 then
			if Animal == "Sheep" then
				if not AniChange then
					PlaySound3DVariation("", "Locations/sheep_baa", 1.0)
				else
					PlaySound3DVariation("", "Animals/Goat", 1.0)
				end
			elseif Animal == "Pig" then
				PlaySound3DVariation("", "Locations/pigs_grunt", 1.0)
			elseif Animal == "Cow" then
				PlaySound3DVariation("", "Locations/cow_low", 1.0)
			end
		end
		
		RemoveAlias("NewPos")
	end
	
	Sleep(2)
end

function WaldVieh(Animal)
	local range = 2000
	
	GetPosition("", "StartPos")
	
	while true do
		Sleep(0.1)
		
		-- too far from home?
		if GetDistance("", "StartPos") > range*2 then
			CopyAlias("StartPos", "NewPos")
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
			
		if CurrentDistance > 200 then
			
			local MovementType = Rand(3)
			local MoveSpeed = GL_MOVESPEED_WALK
			local Animation = "_walk"
			
			if CurrentDistance > 500 and MovementType == 0 then
				MoveSpeed = GL_MOVESPEED_RUN
				Animation = "_run"
			end
			
			f_MoveToNoWait("", "NewPos", MoveSpeed, 30)
			local StuckCheck = 0
			local StuckCounter = 0
			while true do
				if StuckCounter == 1 then
					StuckCheck = CurrentDistance
				else
					StuckCounter = StuckCounter + 1
				end
					
				LoopAnimation("", ""..Animal..""..Animation, 0.75, 1)
				CurrentDistance = GetDistance("", "NewPos")
				if CurrentDistance <= 100 or CurrentDistance == StuckCheck then
					break
				end
			end
		end
			
		-- is there someone nearby?
		local Interest = Find("","__F( (Object.GetObjectsByRadius(Sim) == 600))", "Interest", -1)
		local InterestID = Rand(Interest)
			
		if AliasExists("Interest"..InterestID) then
			AlignTo("", "Interest"..InterestID)
		end
			
		local idle = Rand(4)
		local idleTime = Rand(15) + 15
		local HowlingTime = math.mod(GetGametime(), 24)
		
		if Animal == "wolf" then
			if HowlingTime > 22 and HowlingTime < 24 or (HowlingTime > 0 and HowlingTime < 3) then
				if Rand(3) == 0 then
					PlaySound3DVariation("", "ambient/wolf_howl", 1.0)
				end
			end
		end
		
		if idle == 0 then
			-- no idle, run!
		elseif idle == 1 then
			LoopAnimation("", ""..Animal.."_idle_01", idleTime, 1)
			if not AniChange then
				PlayAnimation("", ""..Animal.."_idle_02", 1)
			end
		elseif idle == 2 then
			LoopAnimation("", ""..Animal.."_idle_01", idleTime, 1)
		elseif idle == 3 then
			PlayAnimation("", ""..Animal.."_idle_02", 1)
			LoopAnimation("", ""..Animal.."_idle_01", (math.ceil(idleTime/2)), 1)
		end
		
		RemoveAlias("NewPos")
	end
	
	Sleep(2)
end

function KleinVieh(Animal)
	local range = 900
	
	GetPosition("", "StartPos")
	
	while true do
		Sleep(0.1)
		
		-- too far from home?
		if GetDistance("", "StartPos") > range*2 then
			CopyAlias("StartPos", "NewPos")
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
			
		if CurrentDistance > 200 then
			
			local MoveSpeed = GL_MOVESPEED_SNEAK
			local Animation = "_walk"
			
			f_MoveToNoWait("", "NewPos", MoveSpeed, 30)
			local StuckCheck = 0
			local StuckCounter = 0
			
			while true do
				if StuckCounter == 1 then
					StuckCheck = CurrentDistance
				else
					StuckCounter = StuckCounter + 1
				end
					
				LoopAnimation("", ""..Animal..""..Animation, 0.75, 1)
				CurrentDistance = GetDistance("", "NewPos")
				if CurrentDistance <= 100 or CurrentDistance == StuckCheck then
					break
				end
			end
		end
			
		-- is there someone nearby?
		local Interest = Find("","__F( (Object.GetObjectsByRadius(Sim) == 600))", "Interest", -1)
		local InterestID = Rand(Interest)
			
		if AliasExists("Interest"..InterestID) then
			AlignTo("", "Interest"..InterestID)
		end
			
		local idle = Rand(3)
		local idleTime = Rand(30) + 30
		
		if idleArt == 0 then
			-- no idle, run!
		else
			LoopAnimation("", ""..Animal.."_idle_01", idleTime, 1)
		end
				
		if Rand(5) == 4 then
			if Animal == "duck" then
				PlaySound3DVariation("", "Animals/duck", 1.0)
			elseif Animal == "chicken" then
				PlaySound3DVariation("", "Animals/hen", 1.0)
			elseif Animal == "cock" then
				local MorningTime = math.mod(GetGametime(), 24)
		      		if MorningTime >= 4 and MorningTime <= 9 then
		      			PlaySound3DVariation("", "Animals/rooster", 1.0)
		      		end
			end
		end
		
		RemoveAlias("NewPos")
	end
	
	Sleep(2)
end

function HausVieh(Animal)
	local range = 1600
	
	if HasProperty("", "Pet") then
		range = 500
	end
	
	GetPosition("", "StartPos")
	
	while true do
		Sleep(0.1)
		
		-- too far from home?
		if GetDistance("", "StartPos") > range*2 then
			CopyAlias("StartPos", "NewPos")
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
			
		if CurrentDistance > 200 then
			
			local MovementType = Rand(3)
			local MoveSpeed = GL_MOVESPEED_WALK
			if Animal == "cat" then 
				MoveSpeed = GL_MOVESPEED_SNEAK
			end
			
			local Animation = "_walk"
			
			if CurrentDistance > 500 and MovementType == 0 then
				MoveSpeed = GL_MOVESPEED_RUN
				if Animal == "cat" then
					MoveSpeed = GL_MOVESPEED_WALK
				end
				Animation = "_run"
			end
			
			f_MoveToNoWait("", "NewPos", MoveSpeed, 30)
			local StuckCheck = 0
			local StuckCounter = 0
			while true do
				if StuckCounter == 1 then
					StuckCheck = CurrentDistance
				else
					StuckCounter = StuckCounter + 1
				end
					
				LoopAnimation("", ""..Animal..""..Animation, 0.75, 1)
				CurrentDistance = GetDistance("", "NewPos")
				if CurrentDistance <= 100 or CurrentDistance == StuckCheck then
					break
				end
			end
		end
			
		-- is there someone nearby?
		local Interest = Find("","__F( (Object.GetObjectsByRadius(Sim) == 600))", "Interest", -1)
		local InterestID = Rand(Interest)
			
		if AliasExists("Interest"..InterestID) then
			AlignTo("", "Interest"..InterestID)
		end
			
		local idle = Rand(4)
		local idleTime = Rand(30) + 30
		
		if idle == 0 then
			-- no idle, run!
		elseif idle == 1 then
			LoopAnimation("", ""..Animal.."_idle_01", idleTime, 1)
			PlayAnimation("", ""..Animal.."_idle_02", 1)
		elseif idle == 2 then
			LoopAnimation("", ""..Animal.."_idle_01", idleTime, 1)
		elseif idle == 3 then
			PlayAnimation("", ""..Animal.."_idle_02", 1)
			LoopAnimation("", ""..Animal.."_idle_01", (math.ceil(idleTime/2)), 1)
		end
				
		if Rand(5) == 4 then
			if Animal == "dog" then
				PlaySound3DVariation("", "ambient/dog_bark", 1.0)
			elseif Animal == "cat" then
				PlaySound3DVariation("", "Animals/cat", 1.0)
			end
		end
		
		RemoveAlias("NewPos")
	end
	
	Sleep(2)
end

function CleanUp()

	if AliasExists("NewPos") then
		RemoveAlias("NewPos")
		RemoveAlias("StartPos")
	end
	
	InternalDie("")
	InternalRemove("")
end
