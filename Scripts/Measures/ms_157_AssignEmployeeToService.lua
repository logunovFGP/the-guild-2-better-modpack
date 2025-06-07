-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_157_AssignEmployeeToService"
----
----	with this measure the player can assign an employee to do the service
----
-------------------------------------------------------------------------------

function Run()

	if not SimGetWorkingPlace("", "Tavern") then
		if IsPartyMember("") then
			if not GetInsideBuilding("", "CurrentBuilding") then
				return
			end
			if BuildingGetType("CurrentBuilding") == GL_BUILDING_TYPE_TAVERN then
				CopyAlias("CurrentBuilding", "Tavern")
			else
				return
			end
		else
			return
		end
	else
		if not f_MoveTo("", "Tavern", GL_MOVESPEED_RUN) then
			StopMeasure()
		end
		if not GetInsideBuilding("", "CurrentBuilding") then
			StopMeasure()
		end
		if BuildingGetType("CurrentBuilding") == GL_BUILDING_TYPE_TAVERN then
			CopyAlias("CurrentBuilding", "Tavern")
		else
			StopMeasure()
		end
	end

	if not BuildingGetOwner("Tavern", "MyBoss") then
		LogMessage("@TAVERN #E Critical error in Lodge.")
		StopMeasure()
	end

	if not HasProperty("Tavern", "AmountBeds") then
		SetProperty("Tavern", "AmountBeds", 3)
	end

	if not HasProperty("Tavern", "LodgeAssigned") then
		SetProperty("Tavern", "LodgeAssigned", -1)
	end

	GetLocatorByName("Tavern", "GiveRoom", "LodgeManager")

	for i = 1, 3 do
		if not HasProperty("Tavern", "StatusBed"..i) then
			SetProperty("Tavern", "StatusBed"..i, "Vacant")
		end
		if not HasProperty("Tavern", "BedMoney"..i) then
			SetProperty("Tavern", "BedMoney"..i, 0)
		end
	end

	SetProperty("Tavern", "ServiceActive", 1)
	
	SetData("IsProductionMeasure", 0)
	SimSetProduceItemID("", -GetCurrentMeasureID(""), -1)
	SetData("IsProductionMeasure", 1)

	while true do
		local Count = {Guests=0, CanOrder=0}
		local GuestID, Time
		local isAssigned = false

		for i = 1, 6 do
			if not IsLocatorFree("Tavern", "sitrich"..i) then
				Count.Guests = Count.Guests +1
				GetLocatorByName("Tavern", "sitrich"..i, "Position"..i)
				GuestID = LocatorGetBlocker("Position"..i)
				if HasProperty("Tavern", "GuestServed#"..GuestID) then
					Time = GetProperty("Tavern", "GuestServed#"..GuestID)
					if Time < GetGametime() then
						Count.CanOrder = Count.CanOrder +1
					end
				else
					Count.CanOrder = Count.CanOrder +1
				end
			end
		end

		for i = 1, 15 do 
			if not IsLocatorFree("Tavern", "sitinn"..i) then
				Count.Guests = Count.Guests +1
				GetLocatorByName("Tavern", "sitinn"..i, "Position"..i)
				GuestID = LocatorGetBlocker("Position"..i)
				if HasProperty("Tavern", "GuestServed#"..GuestID) then
					Time = GetProperty("Tavern", "GuestServed#"..GuestID)
					if Time < GetGametime() then
						Count.CanOrder = Count.CanOrder +1
					end
				else
					Count.CanOrder = Count.CanOrder +1
				end
			end
		end

		local Result, Check

		-- Handle CheckOut Sims (for Tips)
		Check = GetProperty("Tavern", "LodgeAssigned")
		if (Check == -1) then
			Result = Find("", "__F((Object.GetObjectsByRadius(Sim) == 10000) AND (Object.HasProperty(WaitsForCheckout)))", "CheckOutSim", -1)
			if Result > 0 then
				MsgDebugMeasure("Collecting tips.")
				SetProperty("Tavern", "LodgeAssigned", GetID(""))
				f_MoveTo("", "LodgeManager", GL_MOVESPEED_WALK, 60)
				--f_BeginUseLocator("", "LodgeManager", GL_STANCE_STAND, true)
				ms_157_assignemployeetoservice_ProcessCheckout("CheckOutSim0")
			end
		end

		-- Handle Lodge sims (for Beds)
		Check = GetProperty("Tavern", "LodgeAssigned")
		if (Check == -1) then
			Result = Find("", "__F((Object.GetObjectsByRadius(Sim) == 10000) AND (Object.HasProperty(WaitForLodge)))", "LodgeSim", -1)
			if Result > 0 then
				MsgDebugMeasure("Assigning a bed to a guest.")
				SetProperty("Tavern", "LodgeAssigned", GetID(""))
				f_MoveTo("", "LodgeManager", GL_MOVESPEED_WALK, 60)
				--f_BeginUseLocator("", "LodgeManager", GL_STANCE_STAND, true)
				ms_157_assignemployeetoservice_ProcessLodge("LodgeSim0")
			end
		end

		if (Count.Guests > 0) and (Count.CanOrder > 0) then
			MsgDebugMeasure("Serving customers.")
			ms_157_assignemployeetoservice_Serve()
		end

		MsgDebugMeasure("Cleaning tables.")
		ms_157_assignemployeetoservice_CleanTables()

		Sleep(1)
	end
end


function ReturnPrice(Slot)
	--local Element 	= FindNode("\\GUI\\HudRoot")
	--local Bed 		= Element:FindChildDepth("Bed0"..Slot)
	--local Price		= Bed:FindChildDepth("Price")
	--LogMessage( "@TAVERN #W ReturnPrice for Tavern is " .. 25* ( Price:GetValueInt("Price") ) )
	--return ( 25* ( Price:GetValueInt("Price") ) )
	return 50
end

function ProcessCheckout(CheckOutSim)
	RemoveProperty(CheckOutSim, "WaitsForCheckout")
	GetLocatorByName("Tavern", "GetRoom", "CheckOut")

	f_BeginUseLocator(CheckOutSim, "CheckOut", GL_STANCE_STAND, true)

	MeasureSetNotRestartable()

	SetState(CheckOutSim, STATE_DUEL, true)
	SetState("", STATE_DUEL, true)

	PlayAnimationNoWait(CheckOutSim, "talk_short")

	if SimGetGender(CheckOutSim) == GL_GENDER_MALE then
		MsgSay(CheckOutSim, "@L_LODGE_TIP_MALE_+"..Rand(4))
	else
		MsgSay(CheckOutSim, "@L_LODGE_TIP_FEMALE_+"..Rand(4))
	end

	local Slot = GetProperty(CheckOutSim, "AssignedBed")

	local Sim = {Rank=SimGetRank(CheckOutSim), Wage=SimGetWage(CheckOutSim)}

	local Tip = ms_157_assignemployeetoservice_ReturnPrice(Slot) * ( 100 + ( 50 * (-1 + Sim.Rank) ) / 100 )
	Tip = Tip + Sim.Wage / ( Rand(3) + 1 )

	LogMessage("@TAVERN_LODGE === Tip: " .. Tip)

	BuildingAddLodgeBedTips("Tavern", Slot-1, Tip/100)

	SetProperty("Tavern", "StatusBed"..Slot, "Vacant")
			
			-- CreditMoney("", Tip, "Lodge (Tips)")

			-- ShowOverheadSymbol("", false, false, 0, "@L%1t", Tip)

	Sleep(0.7)
	chr_ModifyFavor(CheckOutSim, "MyBoss", 5)

	Sleep(0.3)
	chr_ModifyFavor("MyBoss", CheckOutSim, 5)

	Sleep(0.3)
	chr_GainXP(CheckOutSim, 5)

	Sleep(0.3)
	chr_GainXP("", 5)

	f_EndUseLocator(CheckOutSim, "GetRoom", GL_STANCE_STAND)

	Sleep(1)

	SetState("", STATE_DUEL, false)
	SetState(CheckOutSim, STATE_DUEL, false)

	if HasProperty(CheckOutSim, "AssignedBed") then
		RemoveProperty(CheckOutSim, "AssignedBed")
		SimResetBehavior(CheckOutSim)
		SimStopMeasure(CheckOutSim)
	end

	SetProperty("Tavern", "LodgeAssigned", -1)
	Sleep(1)
end

function ProcessLodge(LodgeSim)

	SetProperty("Tavern", "GuestLodge"..GetID(LodgeSim).."Waiter", GetID(""))

	RemoveProperty(LodgeSim, "WaitForLodge")

	GetLocatorByName("Tavern", "GetRoom", "AskForBed")
	f_BeginUseLocator(LodgeSim, "AskForBed", GL_STANCE_STAND, true)

	MeasureSetNotRestartable()
	SetState(LodgeSim, STATE_DUEL, true)
	SetState("", STATE_DUEL, true)

	PlayAnimationNoWait(LodgeSim, "talk_short")

	if SimGetGender(LodgeSim) == GL_GENDER_MALE then
		MsgSay(LodgeSim, "@L_LODGE_ASK_FOR_BED_MALE_+"..Rand(8))
	else
		MsgSay(LodgeSim, "@L_LODGE_ASK_FOR_BED_FEMALE_+"..Rand(8))
	end
			
	local isSelectedBed = nil

	for i = 1, 3 do
		if HasProperty("Tavern", "StatusBed"..i) then
			local isBedAvailable = GetProperty("Tavern", "StatusBed"..i)
			if (isBedAvailable == "Vacant") then
				local Price = ms_157_assignemployeetoservice_ReturnPrice(i)
				local Favor = GetFavorToSim("", LodgeSim)
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
					PlayAnimationNoWait(LodgeSim, "nod")

					if SimGetGender(LodgeSim) == GL_GENDER_MALE then
						MsgSay(LodgeSim, "@L_LODGE_ACCEPT_PRICE_MALE_+"..Rand(1), Price)
					else
						MsgSay(LodgeSim, "@L_LODGE_ACCEPT_PRICE_FEMALE_+"..Rand(1), Price)
					end

					isSelectedBed = i
					SetProperty("Tavern", "StatusBed"..i, GetID(LodgeSim))
				else
					PlayAnimationNoWait(LodgeSim, "shakehead")

					if SimGetGender(LodgeSim) == GL_GENDER_MALE then
						MsgSay(LodgeSim, "@L_LODGE_REJECT_PRICE_MALE_+"..Rand(1), Price)
					else
						MsgSay(LodgeSim, "@L_LODGE_REJECT_PRICE_FEMALE_+"..Rand(1), Price)
					end

					isSelectedBed = nil
				end

				break
			end
		end
	end

	PlayAnimationNoWait("", "talk_short")

	if (isSelectedBed == nil) then
		local Favor = GetFavorToSim("", LodgeSim)
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
		local Favor = GetFavorToSim("", LodgeSim)
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

		local Price = ms_157_assignemployeetoservice_ReturnPrice(isSelectedBed)

		SetProperty("Tavern", "BedMoney"..isSelectedBed, GetProperty("Tavern", "BedMoney"..isSelectedBed) + Price)

		CreditMoney("", Price, "Lodge")
		ShowOverheadSymbol("", false, false, 0, "@L%1t", Price)

		Sleep(0.7)
		chr_ModifyFavor(LodgeSim, "MyBoss", 5)

		Sleep(0.3)
		chr_ModifyFavor("MyBoss", LodgeSim, 5)

		Sleep(0.3)
		chr_GainXP(LodgeSim, 15)

		Sleep(0.3)
		chr_GainXP("", 5)

		BuildingAddLodgeBedMoney("Tavern", isSelectedBed-1, Price)
		BuildingAddLodgeSim("Tavern", LodgeSim)

		SetProperty(LodgeSim, "AssignedBed", isSelectedBed)
		MeasureRun(LodgeSim, nil, "SleepTavern", true)
	end

	f_EndUseLocator(LodgeSim, "GetRoom", GL_STANCE_STAND)

	Sleep(1)

	SetState("", STATE_DUEL, false)
	SetState(LodgeSim, STATE_DUEL, false)

	if not HasProperty(LodgeSim, "AssignedBed") then
		LogMessage("@TAVERN #E No bed assigned to " .. GetName(LodgeSim))
		SimResetBehavior(LodgeSim)
	end

	SetProperty("Tavern", "LodgeAssigned", -1)
	Sleep(1)
end

function CleanTables()
	local Type = Rand(4)
	if Type == 0 then	
		GetFreeLocatorByName("Tavern", "ServeSitRich", 0, 3,"MovePos")
		f_BeginUseLocator("", "MovePos", GL_STANCE_STAND, true)
		PlayAnimation("", "manipulate_middle_twohand")
		f_EndUseLocator("", "MovePos", GL_STANCE_STAND)
	elseif Type == 1 then
		GetFreeLocatorByName("Tavern", "ServeStand", 0, 5, "MovePos")
		f_BeginUseLocator("", "MovePos", GL_STANCE_STAND, true)
		PlayAnimation("", "manipulate_middle_twohand")
		f_EndUseLocator("", "MovePos", GL_STANCE_STAND)
	elseif Type == 2 then
		GetFreeLocatorByName("Tavern", "ServeAloneStand", -1, -1, "MovePos")
		f_BeginUseLocator("", "MovePos", GL_STANCE_STAND, true)
		PlayAnimation("", "manipulate_middle_twohand")
		f_EndUseLocator("", "MovePos", GL_STANCE_STAND)
	else
		PlayAnimation("", "cogitate")
	end
end

function Serve()
	for i = 1, 6 do
		ms_157_assignemployeetoservice_ServeCustomer("sitrich", i)
	end
	for i = 1, 15 do 
		ms_157_assignemployeetoservice_ServeCustomer("sitinn", i)
	end
end

function ServeCustomer(Locator, Index)
	Sleep(1)
	GetInsideBuilding("Owner", "Tavern") 
	GetDynasty("Tavern", "Dynasty")

	if not IsLocatorFree("Tavern", Locator..Index) then
		if GetLocatorByName("Tavern", Locator..Index, "Position"..Index) then
			local Guest = LocatorGetBlocker("Position"..Index)
			if HasProperty("Tavern", "GuestServed#"..Guest) then
				local Time = GetProperty("Tavern", "GuestServed#"..Guest)
				GetAliasByID(Guest, "Guest")
				if Time < GetGametime() then
					RemoveProperty("Tavern", "GuestServed#"..Guest)
					--if DynastyIsPlayer("Dynasty") then
						LogMessage("@TAVERN_TABLE #W " .. GetName("Guest") .. " can order again because next checkpoint " .. Time .. " has been passed by current time " .. GetGametime())
					--end
				end
			else
				GetAliasByID(Guest, "Guest")

				--if DynastyIsPlayer("Dynasty") then
					LogMessage("@TAVERN_TABLE #W " .. GetName("Guest") .. " is ordering now -> " .. GetGametime())
				--end
				SetProperty("Tavern", "GuestServed#"..Guest, GetGametime() + 1.5)
				SetProperty("Tavern", "Guest"..Guest.."Waiter", GetID(""))

				f_MoveTo("", "Position"..Index, GL_MOVESPEED_WALK)
				
				PlayAnimationNoWait("", "talk_short")
				MsgSay("", "What will it be today?")
				PlayAnimationNoWait("Guest", "talk_sit_short")
				PlayAnimationNoWait("", "nod")

				local Request, Amount, WantsDrink, TotalPrice
				local ItemCount = 0

				if HasProperty("Tavern", "Guest"..Guest.."WantsType") then
					Request, Amount = GetProperty("Tavern", "Guest"..Guest.."WantsType"), GetProperty("Tavern", "Guest"..Guest.."WantsAmount")
					if Request == "Drink" then
						WantsDrink = true
					else
						WantsDrink = false
					end
					MsgSay("Guest", "I'll get a " .. Request)
					ItemCount, TotalPrice = economy_BuyItems("Tavern", "Guest", Request, Amount, true)
				end

				-- if SimGetNeed("", 8) > 0.3 or  SimGetNeed("", 1) > 0.3 then

				if ItemCount == 0 then
					MsgSay("", "I'm sorry, we've ran out.")
					SimStopMeasure("Guest")
				end

				if ItemCount > 0 then
					local Bonus = 1

					if HasProperty("Tavern", "Versengold") then
						Bonus = Bonus + 1
					end

					--SatisfyNeed("", needo, 0.3)
					local Tavern = {Level=BuildingGetLevel("Tavern"), Attractivity=GetImpactValue("Tavern", "Attractivity")}
					chr_CreditMoney("Tavern", math.floor(Tavern.Level * (5 + (Rand(20)+1) * (Tavern.Attractivity + Bonus))), "WaresSold")
					--chr_CreditMoney("Tavern", 3 * chr_GetRank("") + 1, "WaresSold")

					if WantsDrink then
						GetLocatorByName("Tavern", "servealonehigh0", "MovePos")
						if not f_BeginUseLocator("", "MovePos", GL_STANCE_STAND, true) then
							f_MoveTo("", "MovePos")
						end
						PlayAnimation("", "manipulate_top_r")

						CarryObject("", "Handheld_Device/ANIM_beaker_sit_drink.nif", false)

						GetLocatorByName("Tavern", "servealoneknee0", "MovePos")
						f_BeginUseLocator("", "MovePos", GL_STANCE_STAND, true)
						PlayAnimation("", "manipulate_middle_low_r")

						f_MoveTo("", "Position"..Index, GL_MOVESPEED_WALK)
						PlayAnimation("", "manipulate_middle_low_r")
						CarryObject("", "", false)
						MoveSetActivity("")
						SetProperty("Tavern", "Guest"..Guest.."Has", "Drink")
					end

					if not WantsDrink then
						GetLocatorByName("Tavern", "servealonestand0", "MovePos")
						f_BeginUseLocator("", "MovePos", GL_STANCE_STAND, true)
						PlayAnimation("", "manipulate_middle_twohand")
						MoveSetActivity("", "carry")
						CarryObject("", "Handheld_Device/ANIM_Bowl_Stew.nif", false)
						f_MoveTo("", "Position"..Index, GL_MOVESPEED_WALK)
						PlayAnimation("", "manipulate_middle_low_r")
						CarryObject("", "", false)
						MoveSetActivity("")
						SetProperty("Tavern", "Guest"..Guest.."Has", "Food")
					end

					MeasureRun("", nil, "AssignEmployeeToService")
				end
			end
		end
	end
end

function CleanUp()
	SetState("", STATE_DUEL, false)
	StopAnimation("")
	CarryObject("", "", false)
	CarryObject("", "", true)
	MoveSetActivity("")

	if not AliasExists("Tavern") then
	 	SimGetWorkingPlace("", "Tavern")
	end

	Sleep(0.5)

	local Lodge = GetProperty("Tavern", "LodgeAssigned")
	local Sim = GetID("")

	if (Sim == Lodge) then
		SetProperty("Tavern", "LodgeAssigned", -1)
	end

	RemoveProperty("Tavern",  "ServiceActive")
	RemoveProperty("Tavern",  "GoToService")
end