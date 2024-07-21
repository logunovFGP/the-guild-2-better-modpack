function Run()

	Sleep(0.5)
	MeasureSetNotRestartable()
	local	Member = GetData("Member")
	if not Member or Member == -1 then
		return
	end
	
	if not SquadGet("", "Squad") then
		return
	end
	
	if not SquadGetMeetingPlace("Squad", "Destination") then
		return
	end
	
	-- get the robber camp
	if not ai_GetWorkBuilding("", GL_BUILDING_TYPE_ROBBER, "MyRobbercamp") then
		if IsPartyMember("") then
			local NextBuilding = ai_GetNearestDynastyBuilding("", GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_ROBBER)
			if not NextBuilding then
				StopMeasure()
			end
			CopyAlias(NextBuilding, "MyRobbercamp")
		else
			return
		end
	end
		
	local ToDo, Success
	
    	SetData("Tarnung", 0)	
	
	while true do
		
		ToDo = ms_squadwaylaymember_WhatToDo()
		LogMessage("SWL: ("..GetName("")..") Result of WhatToDo is: " .. ToDo)
		Success = false
		
		if HasProperty("", "Plunder") then
			LogMessage("SWL: He has the 'Plunder' property.")
			local victim = GetProperty("", "Plunder")
			GetAliasByID(victim, "Victim")
			LogMessage("SWL: Victim is: " .. GetName("Victim"))
			if AliasExists("Victim") then
				ToDo = "plunder"
			end
		else
			LogMessage("SWL: He does not have the 'Plunder' property")
		end
		
		if ToDo == "return" then
			LogMessage("SWL: ReturnToBase()")
			Success = ms_squadwaylaymember_ReturnToBase()
		elseif ToDo == "wait" then
			LogMessage("SWL: Wait()")
			Success = ms_squadwaylaymember_Wait()
		elseif ToDo == "attack" then
			LogMessage("SWL: Attack()")
			Success = ms_squadwaylaymember_Attack()
		elseif ToDo == "plunder" then
			LogMessage("SWL: Plunder()")
			Success = ms_squadwaylaymember_Plunder()
		elseif ToDo == "rest" then
			LogMessage("SWL: Rest()")
			Success = ms_squadwaylaymember_Rest()
		end
		
		if not Success then
			Sleep(2)
		end
	end
end

function Wait()

	if HasProperty("Squad", "PrimaryTarget") then
		RemoveProperty("Squad", "PrimaryTarget")
	end
		
	-- normal wait behavior
	local	Distance = GetDistance("", "Destination")
	if Distance > 900 then
		local Range = Rand(300)
		if not f_MoveTo("", "Destination", GL_MOVESPEED_RUN, Range) then
			if not f_MoveTo("", "Destination", GL_MOVESPEED_RUN) then
				return
			end
		end	

		-- stroll a bit
		f_Stroll("", 300, 2)
	end
	
	-- spawn the bush
	if GetData("Tarnung") == 0 then
		Sleep(1)
		PlayAnimation("", "crouch_down")
		GetPosition("", "standPos")
		if Rand(2) == 0 then
			GfxAttachObject("tarn", "Outdoor/Bushes/bush_09_big.nif")
		else
			GfxAttachObject("tarn", "Outdoor/Bushes/bush_10_big.nif")
		end
		GfxSetPositionTo("tarn", "standPos")
		SetData("Tarnung", 1)
	end
	
	PlayAnimationNoWait("", "crouch_down")	
	SetState("", STATE_HIDDEN, true)
	SetProperty("", "WaylayReady", 1)
	ms_squadwaylaymember_IdleStuff()
	Sleep(2)
	RemoveProperty("", "WaylayReady")
end

function IdleStuff()
	local RandomAni = Rand(5)
	if RandomAni == 0 then
		PlayAnimationNoWait("", "sentinel_idle")
	elseif RandomAni == 1 then
		CarryObject("", "Handheld_Device/ANIM_telescope.nif", false)
		PlayAnimation("", "scout_object")
		CarryObject("", "", false)
	elseif RandomAni == 2 or RandomAni == 3 then
		PlayAnimation("", "cogitate")
	else
		Sleep(1)
	end
	
	GfxSetRotation("", 0, Rand(360), 0, false)
	Sleep(2)
end

function WhatToDo()

	-- Check the inventory for stuff
	local Items = 0
	local Count = InventoryGetSlotCount("", INVENTORY_STD)
	
	for i=0, Count-1 do
		local ItemId
		local ItemCount 
			
		ItemId, ItemCount = InventoryGetSlotInfo("", i, INVENTORY_STD)
		if ItemId and ItemID ~= 999 and ItemCount > 0 then
			Items = ItemCount
			break
		end
	end
	
	if Items > 0 then
		-- Check the building's inventory to add new stuff - no need to waylay if it is full. We use a dummy item
		if not CanAddItems("MyRobbercamp", "PoisonedCake", 1, INVENTORY_STD) then
			return "wait"
		else
			return "return"
		end
	end
	
	if not HasProperty("Squad", "PrimaryTarget") then
		
		-- are we already plundering a cart?
		local BootyFilterCart = "__F((Object.GetObjectsByRadius(Cart) == 2500)AND NOT(Object.BelongsToMe()))"
		local NumVictimCarts = Find("", BootyFilterCart, "VictimCart", -1)
		local ToDo = false
		if NumVictimCarts >0 then
			for i=0, NumVictimCarts-1 do
				if CartGetOperator("VictimCart"..i, "Operator"..i) then
					if GetState("Operator"..i, STATE_DRIVERATTACKED) then
						CopyAlias("VictimCart"..i, "Victim")
						SetProperty("Squad", "PrimaryTarget", GetID("Victim"))
						ToDo = true
						break
					end
				end
			end
		end
		
		if ToDo then
			return "plunder"
		else  
			if GetHPRelative("") < 0.76 then
				return "rest"
			end
		end
	
		local Target = ms_squadwaylaymember_Scan("")

		if Target then -- only surprise attacks
			LogMessage("SWL: Result of scan is: 'attack' with Target = true.")
			return "attack"
		end
		
		LogMessage("SWL: Result of scan is: 'wait' with Target = false.")
		return "wait"
	end
	
	local TargetID = GetProperty("Squad", "PrimaryTarget") or 0
	if TargetID < 1 then
		RemoveProperty("Squad", "PrimaryTarget")
		return "wait"
	end	
	
	if not GetAliasByID(TargetID, "Victim") then
		RemoveProperty("Squad", "PrimaryTarget")
		return "wait"
	end
	
	if chr_GetBootyCount("Victim", INVENTORY_STD) <= 200 then
		RemoveProperty("Squad", "PrimaryTarget")
		return "wait"
	end
	
	if GetState("Victim", STATE_ACTIVE_ESCORT) then
		return "attack"
	end
	
	if CartGetOperator("Victim", "Operator") then
		if not GetState("Operator", STATE_DRIVERATTACKED) then
			RemoveProperty("Squad", "PrimaryTarget")
			return "wait"
		end
	end
	
	return "plunder"
end

function ReturnToBase()

	if GetDistance("", "MyRobbercamp") > 500 then

		Sleep(2)
		CarryObject("", "Handheld_Device/ANIM_Bag.nif", false)
		MoveSetActivity("", "carry")
		Sleep(1)

		GetOutdoorMovePosition("", "MyRobbercamp", "MovePos")

		if not f_MoveTo("", "MovePos") then
			return
		end
	end

	local ItemId, Found, RemainingSpace, Removed
	local Booty = false
	local MessageItem, MessageCount

	local Count = InventoryGetSlotCount("", INVENTORY_STD)
	for i=0, Count-1 do
		ItemId, Found = InventoryGetSlotInfo("", i, INVENTORY_STD)
		if ItemId and ItemId > 0 and ItemId ~= 999 and Found > 0 then
			RemainingSpace = GetRemainingInventorySpace("MyRobbercamp", ItemId)
			while Found > RemainingSpace do
				MsgQuick("MyRobbercamp", "@L_GENERAL_INFORMATION_INVENTORY_INVENTORY_FULL_+1", GetID("MyRobbercamp"), ItemGetLabel(ItemId, false))
				Sleep(15)
			end
			
			if CanAddItems("MyRobbercamp", ItemId, Found, INVENTORY_STD) then 
				Removed = RemoveItems("", ItemId, Found)
				local Added = AddItems("MyRobbercamp", ItemId, Removed)
				MessageItem = ItemId
				MessageCount = Removed
				if Added > 0 then
					Booty = true
					IncrementXPQuiet("", 15) 
				end
			end
		end
	end
	
	-- send a message to the player (only 1 message every 2 hours)
	if Booty and GetImpactValue("MyRobbercamp", "BootyMsg") < 1 then
		
		local Label = ItemGetLabel(MessageItem, false)
		if Found == 1 then
			Label = ItemGetLabel(MessageItem, true)
		end
		
		MsgNewsNoWait("MyRobbercamp", "MyRobbercamp", "", "building", -1, "@L_ROBBER_135_WAYLAYFORBOOTY_BOOTY_HEAD_+0", "@L_ROBBER_135_WAYLAYFORBOOTY_BOOTY_BODY_+0", GetID("MyRobbercamp"), MessageCount, Label)
		AddImpact("MyRobbercamp", "BootyMsg", 1, 2)
	end
	
	Sleep(2)
	CarryObject("", "", false)
	MoveSetActivity("")
	Sleep(1)
	
	-- normal wait behavior
	local	Distance = GetDistance("", "Destination")
	if Distance > 900 then
		local Range = Rand(400)
		if not f_MoveTo("", "Destination", GL_MOVESPEED_RUN, Range) then
			if not f_MoveTo("", "Destination", GL_MOVESPEED_RUN) then
				return
			end
		end		
	end
	return true
end


function Attack()

	GfxDetachAllObjects()
	SetData("Tarnung", 0)
	SetState("", STATE_HIDDEN, false)
	
	SetProperty("Squad", "PrimaryTarget", GetID("Victim"))
	SetProperty("", "Plunder", GetID("Victim"))
	
	-- check if Victim has no dynasty (= worldtrader). Select the local politician for evidence then
	if GetDynastyID("Victim") < 1 then
		f_GetLocalPolitician("", false, "Mayor") -- false means: not from my own dynasty
	end
	
	if IsType("Victim", "Cart") then
		-- spawn escorts if they have any, if not, nothing will happen by setting the state true
		SetState("Victim", STATE_ACTIVE_ESCORT, true)
		if GetImpactValue("Victim", "messagesent") == 0 then
			GetPosition("Victim", "ParticleSpawnPos")
			PlaySound3D("Victim", "fire/Explosion_01.wav", 1.0)
			StartSingleShotParticle("particles/Explosion.nif", "ParticleSpawnPos", 1, 5)
			AddImpact("Victim", "messagesent", 1, 3)
			
			if AliasExists("Mayor") then
				CommitAction("attackcart", "", "Mayor", "") 
				GetSettlement("Mayor", "MayorTown")
				MsgNewsNoWait("Mayor", "", "", "military", -1, 
									"@L_ROBBER_135_WAYLAYFORBOOTY_VICTIM_HEAD_+0",
									"@L_ROBBER_135_WAYLAYFORBOOTY_VICTIM_BODY_+1", GetID("Mayor"), GetID("MayorTown"))
			else
				CommitAction("attackcart", "", "Victim", "Victim")
				feedback_MessageMilitary("Victim",
									"@L_ROBBER_135_WAYLAYFORBOOTY_VICTIM_HEAD_+0",
									"@L_ROBBER_135_WAYLAYFORBOOTY_VICTIM_BODY_+0")
			end
		end

		if CartGetOperator("Victim", "Operator") then
			SetState("Operator", STATE_DRIVERATTACKED, true)
		end
		
		return true
	end
end


function Plunder()
	GfxDetachAllObjects()
	SetData("Tarnung", 0)
	SetState("", STATE_HIDDEN, false)
	
	if CartGetOperator("Victim", "Operator") then
		if not GetState("Operator", STATE_DRIVERATTACKED) then
			if HasProperty("Squad", "PrimaryTarget") and GetID("Victim") == GetProperty("Squad", "PrimaryTarget") then
				RemoveProperty("Squad", "PrimaryTarget")
			end
			return
		end
	end
	
	if not f_MoveTo("", "Victim", GL_MOVESPEED_RUN, 75) then
		return
	end

	SetProperty("", "DontLeave", 1)
	StopAction("attackcart", "")
	CommitAction("plunder", "", "Victim", "Victim")
	Sleep(2)
	
	ItemValue = chr_Plunder("", "Victim") 
	local XPValue = math.floor((25 + ItemValue*0.2)/25)
	chr_GainXP("", XPValue)
	if ItemValue > 0 then
		--for the mission
		mission_ScoreCrime("dynasty", ItemValue)
	end
	
	StopAction("plunder", "")
	RemoveProperty("", "DontLeave")
	RemoveProperty("", "Plunder")
	LogMessage("SWL: Plunder() end with return true.")
	return true
end

function Scan(Member)
	
	-- constants
	local MinBooty = 200
	local BootyRadius = 1500
	
	local Count
	local BootyFilterCart = "__F((Object.GetObjectsByRadius(Cart) == "..BootyRadius..")AND NOT(Object.BelongsToMe())AND(Object.ActionAdmissible()))"

	local NumVictimCarts = Find(Member, BootyFilterCart, "VictimCart", -1)
	local NumOwnRobbers = SquadGetMemberCount("")
	local Attack = true
	
	if NumVictimCarts <= 0 then
		LogMessage("SWL: No Carts")
		return
	end

	local MaxTargetValue = 0
	
	if not SquadGet(Member, "Squad") then
		LogMessage("No Squad")
		return
	end
	
	local SquadMemberCount = SquadGetMemberCount("Squad")
	local RandomMember = 0
	
	if SquadMemberCount > 1 then
		RandomMember = Rand(SquadMemberCount)
	end
	
	SquadGetMember("Squad", RandomMember, "Robber")
	
	LogMessage("SWL: Scanning")
	if GetState(Member, STATE_HIDDEN) then
		LogMessage("SWL: Hidden")
		for FoundObject =0, NumVictimCarts-1 do -- found the best cart to attack
			
			local VictimDyn = GetDynastyID("VictimCart"..FoundObject)
			local CurrentTargetValue = chr_GetBootyCount("VictimCart"..FoundObject, INVENTORY_STD)
			
			if CurrentTargetValue >= MaxTargetValue then
				LogMessage("SWL: Loot detected")
				if VictimDyn < 1 then
					f_GetLocalPolitician(Member, false, "Mayor") -- false means: not from my own dynasty
					LogMessage("SWL: Mayor found")
				end
				
				if AliasExists("Mayor") then
					VictimDyn = GetDynastyID("Mayor")
				end
				
				if GetDynastyID(Member) ~= VictimDyn then
					if DynastyGetDiplomacyState("dynasty","VictimCart"..FoundObject) < DIP_NAP then -- check diplomatic state
						LogMessage("SWL: Scan: no NAP+")
						if GetFavorToDynasty("VictimCart"..FoundObject, "dynasty") < 85 then -- don't attack friends 
							LogMessage("SWL: No friend")
							CopyAlias("VictimCart"..FoundObject, "Victim")
							MaxTargetValue = CurrentTargetValue
						else
							if GetID(Member) == GetID("Robber") then
								AlignTo(Member, "VictimCart")
								MsgSay(Member, "@L_MEASURE_ROBBER_WAYLAYFORBOOTY_SCAN_DONT_ATTACK_FRIENDS")
							end
						end
					else
						if GetID(Member) == GetID("Robber") then
							AlignTo(Member, "VictimCart")
							MsgSay(Member, "@L_MEASURE_ROBBER_WAYLAYFORBOOTY_SCAN_DONT_ATTACK_FRIENDS")
						end
					end
				end
			end
		end
	else
		LogMessage("Not hidden")
		PlayAnimation(Member, "cheer_01")
	end
	
	if not AliasExists("Victim") then
		LogMessage("SWL: No victim found")
		return
	end
		
	--check if booty is enough
	if MaxTargetValue < MinBooty then
		if GetID(Member) == GetID("Robber") then
			AlignTo(Member, "Victim")
			MsgSay(Member, "@L_MEASURE_ROBBER_WAYLAYFORBOOTY_SCAN_NOBOOTY")
		end
		LogMessage("SWL: No booty")
		return
	end
		
	--start attack

	AlignTo(Member, "Victim")
	Sleep(0.5)
	LogMessage("SWL: Attack!")
	return "Victim"
end

function Rest()

	GfxDetachAllObjects()
	SetData("Tarnung", 0)
	SetState("", STATE_HIDDEN, false)
	
	local duration = 4
	local CurrentHP = GetHP("")
	local MaxHP = (GetMaxHP(""))*0.96
	local ToHeal = (MaxHP - CurrentHP)
	local HealPerTic = ToHeal / (duration * 12)
	local UseLocator = false

	local Offset = 50+Rand(150)
	MsgMeasure("", "@L_MEASURE_ROBBER_WAYLAYFORBOOTY_MSGMEASURE_REST_+0")
	if not f_MoveTo("", "MyRobbercamp", GL_MOVESPEED_RUN, (150+Offset)) then
		return
	end
	
	local CurrentTime = GetGametime()
	local EndTime = CurrentTime + duration
	local Time = MoveSetStance("",GL_STANCE_SITGROUND)
	Sleep(Time)

	while GetGametime() < EndTime do
		Sleep(5)
		if GetHP("") < MaxHP then
			ModifyHP("", HealPerTic,false)
		else
			break
		end
	end

	MsgMeasure("","")
	Time = MoveSetStance("", GL_STANCE_STAND)
	Sleep(Time)
	return true
end

function CleanUp()

	MsgMeasure("", "")
	StopAction("plunder", "")
	CarryObject("", "", false)
	RemoveProperty("", "WaylayReady")
	GfxDetachAllObjects()
	SetState("", STATE_HIDDEN, false)
	StopAnimation("")
	MoveSetActivity("")
	if not HasProperty("", "DontLeave") then
		SquadRemoveMember("", true)
		if AliasExists("Squad") then
			if SquadGetMemberCount("Squad", true) < 1 then
				SquadDestroy("Squad")
			end
		end
	else
		RemoveProperty("", "DontLeave")
	end

	if not GetState("", STATE_FIGHTING) then
		if HasProperty("", "Plunder") then
			local victim = GetProperty("", "Plunder")
			GetAliasByID(victim, "Victim")
			if AliasExists("Victim") then
				if not IsType("Victim","Sim") then
					if CartGetOperator("Victim", "Operator") then
						if GetState("Operator",STATE_DRIVERATTACKED) then
							SetState("Operator", STATE_DRIVERATTACKED, false)
						end
					end
				end
			end
			RemoveProperty("", "Plunder")
		end
	end
end

