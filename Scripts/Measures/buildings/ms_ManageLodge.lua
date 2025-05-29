function Run()
	if not GetInsideBuilding("", "Tavern") then
		LogMessage("@TAVERN #E Critical error in Lodge.")
		StopMeasure()
	end

	if not BuildingGetOwner("Tavern", "MyBoss") then
		LogMessage("@TAVERN #E Critical error in Lodge.")
		StopMeasure()
	end

	if not HasProperty("Tavern", "AmountBeds") then
		SetProperty("Tavern", "AmountBeds", 3)
	end

	for i = 1, 3 do
		if not HasProperty("Tavern", "StatusBed"..i) then
			SetProperty("Tavern", "StatusBed"..i, "Vacant")
		end
		if not HasProperty("Tavern", "BedMoney"..i) then
			SetProperty("Tavern", "BedMoney"..i, 0)
		end
	end

	GetLocatorByName("Tavern", "GiveRoom", "LodgeManager")
	f_BeginUseLocator("", "LodgeManager", GL_STANCE_STAND, true)
	
	SetData("IsProductionMeasure", 0)
	SimSetProduceItemID("", -GetCurrentMeasureID(""), -1)
	SetData("IsProductionMeasure", 1)
	Sleep(1)

	local function ReturnPrice(Slot)
		local Element 	= FindNode("\\GUI\\HudRoot")
		local Bed 		= Element:FindChildDepth("Bed0"..Slot)
		local Price		= Bed:FindChildDepth("Price")
		return ( 25* (Price:GetValueInt("Price") ) )
	end

	while true do
		local CheckOutSimFilter = "__F((Object.GetObjectsByRadius(Sim) == 10000) AND (Object.HasProperty(WaitsForCheckout)))"
		local NumCheckOutSims = Find("", CheckOutSimFilter, "CheckOutSim", -1)

		if NumCheckOutSims < 1 then
			Sleep(1)
		end

		if NumCheckOutSims > 0 then
			SetState("CheckOutSim0", STATE_DUEL, true)
			GetLocatorByName("Tavern", "GetRoom", "CheckOut")
			f_BeginUseLocator("CheckOutSim0", "CheckOut", GL_STANCE_STAND, true)
			MeasureSetNotRestartable()
			SetState("", STATE_DUEL, true)

			PlayAnimationNoWait("CheckOutSim0", "talk_short")
			MsgSay("CheckOutSim0", "@L_LODGE_TIP_+"..Rand(4))

			local Slot = GetProperty("CheckOutSim0", "AssignedBed")
			local Tip = ReturnPrice(Slot) * ( (Rand(9)+1) / 10)

			SetProperty("Tavern", "StatusBed"..Slot, "Vacant")
			
			CreditMoney("", Tip, "Lodge (Tips)")

			ShowOverheadSymbol("", false, false, 0, "@L%1t", Tip)

			Sleep(0.7)
			chr_ModifyFavor("CheckOutSim0", "MyBoss", 5)

			Sleep(0.3)
			chr_ModifyFavor("MyBoss", "CheckOutSim0", 5)

			Sleep(0.3)
			chr_GainXP("CheckOutSim0", 5)

			Sleep(0.3)
			chr_GainXP("", 5)

			f_EndUseLocator("CheckOutSim0", "GetRoom", GL_STANCE_STAND)

			Sleep(1)

			SetState("", STATE_DUEL, false)
			SetState("CheckOutSim0", STATE_DUEL, false)

			if HasProperty("CheckOutSim0", "WaitsForCheckout") then
				RemoveProperty("CheckOutSim0", "WaitsForCheckout")
			end

			if HasProperty("CheckOutSim0", "AssignedBed") then
				RemoveProperty("CheckOutSim0", "AssignedBed")
				f_ExitCurrentBuilding("CheckOutSim0")
				SimResetBehavior("CheckOutSim0")
			end

			Sleep(1)
		end

		local LodgeSimFilter = "__F((Object.GetObjectsByRadius(Sim) == 10000) AND (Object.HasProperty(WaitForLodge)))"
		local NumLodgeSims = Find("", LodgeSimFilter, "LodgeSim", -1)

		if NumLodgeSims < 1 then
			if Rand(10) == 0 then
				PlayAnimation("", "cogitate")
			end
			Sleep(5)
		else
			LogMessage("@TAVERN Lodge -> Waiting for guest " .. GetName("LodgeSim0"))

			SetState("LodgeSim0", STATE_DUEL, true)

			GetLocatorByName("Tavern", "GetRoom", "AskForBed")
			f_BeginUseLocator("LodgeSim0", "AskForBed", GL_STANCE_STAND, true)
			MeasureSetNotRestartable()
			SetState("", STATE_DUEL, true)

			PlayAnimationNoWait("LodgeSim0", "talk_short")

			MsgSay("LodgeSim0", "@L_LODGE_ASK_FOR_BED_+"..Rand(8))
			
			local isSelectedBed = nil

			for i = 1, 3 do
				if HasProperty("Tavern", "StatusBed"..i) then
					local isBedAvailable = GetProperty("Tavern", "StatusBed"..i)
					if (isBedAvailable == "Vacant") then
						local Price = ReturnPrice(i)
						local Favor = GetFavorToSim("", "LodgeSim0")
						local Label = nil

						if (Favor >= 65) then
							Label = "LODGE_PRICE_INFO_POLITE"
						end

						if (Label == nil) and (Favor >= 40) then
							Label = "LODGE_PRICE_INFO_NORMAL"
						end

						if (Label == nil) and (Favor <= 35) then
							Label = "LODGE_PRICE_INFO_RUDE"
						end

						MsgSay("", "@L_"..Label.."_+0", Price)
						local temp = Rand(1)

						if temp == 0 then
							PlayAnimationNoWait("LodgeSim0", "nod")
							MsgSay("LodgeSim0", "@L_LODGE_ACCEPT_PRICE_+"..Rand(1), Price)
							isSelectedBed = i
							SetProperty("Tavern", "StatusBed"..i, GetID("LodgeSim0"))
						else
							PlayAnimationNoWait("LodgeSim0", "shakehead")
							MsgSay("LodgeSim0", "@L_LODGE_REJECT_PRICE_+"..Rand(1), Price)
							isSelectedBed = nil
						end

						break
					end
				end
			end

			PlayAnimationNoWait("", "talk_short")

			if (isSelectedBed == nil) then
				local Favor = GetFavorToSim("", "LodgeSim0")
				local Label = nil

				if (Favor >= 65) then
					Label = "_LODGE_NO_BED_POLITE_"
				end

				if (Label == nil) and (Favor >= 40) then
					Label = "_LODGE_NO_BED_CASUAL_"
				end

				if (Label == nil) and (Favor <= 35) then
					Label = "_LODGE_NO_BED_GRUMPY_"
				end

				MsgSay("", "@L"..Label.."+"..Rand(4))
			end

			if (isSelectedBed ~= nil) then
				local Favor = GetFavorToSim("", "LodgeSim0")
				local Label = nil

				if (Favor >= 65) then
					Label = "L_LODGE_ROOM_AVAILABLE_POLITE_"
				end

				if (Label == nil) and (Favor >= 40) then
					Label = "L_LODGE_ROOM_AVAILABLE_CASUAL_"
				end

				if (Label == nil) and (Favor <= 35) then
					Label = "L_LODGE_ROOM_AVAILABLE_GRUMPY_"
				end

				MsgSay("", "@"..Label.."+"..Rand(4))

				local Price = ReturnPrice(isSelectedBed)

				SetProperty("Tavern", "BedMoney"..isSelectedBed, GetProperty("Tavern", "BedMoney"..isSelectedBed) + Price)

				CreditMoney("", Price, "Lodge")
				ShowOverheadSymbol("", false, false, 0, "@L%1t", Price)

				Sleep(0.7)
				chr_ModifyFavor("LodgeSim0", "MyBoss", 5)

				Sleep(0.3)
				chr_ModifyFavor("MyBoss", "LodgeSim0", 5)

				Sleep(0.3)
				chr_GainXP("LodgeSim0", 15)

				Sleep(0.3)
				chr_GainXP("", 5)

				SetProperty("LodgeSim0", "AssignedBed", isSelectedBed)
				MeasureRun("LodgeSim0", nil, "SleepTavern", true)
			end

			f_EndUseLocator("LodgeSim0", "GetRoom", GL_STANCE_STAND)

			Sleep(1)

			SetState("", STATE_DUEL, false)
			SetState("LodgeSim0", STATE_DUEL, false)

			if HasProperty("LodgeSim0", "WaitForLodge") then
				RemoveProperty("LodgeSim0", "WaitForLodge")
			end

			if not HasProperty("LodgeSim0", "AssignedBed") then
				LogMessage("@TAVERN #E No bed assigned to " .. GetName("LodgeSim0"))
				f_ExitCurrentBuilding("LodgeSim0")
				SimResetBehavior("LodgeSim0")
			end

			Sleep(1)

			-- local Rank = SimGetRank("LodgeSim0")
			--CreateScriptcall("OrderCredit_End", 24, "Measures/ms_OrderCredit.lua", "ReturnCredit", "LodgeSim0", "MyBoss")
		end
	end
	StopMeasure()
end

function CleanUp()
	if GetState("", STATE_DUEL) then
		SetState("", STATE_DUEL, false)
	end

	StopAnimation("")

	CarryObject("", "", false)
	CarryObject("", "", true)

	MoveSetActivity("", "")
	f_EndUseLocator("", "ChiefPos", GL_STANCE_STAND)
end