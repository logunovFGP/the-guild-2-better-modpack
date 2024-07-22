-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_157_AssignEmployeeToService"
----
----	with this measure the player can assign an employee to do the service
----    this will sell drinks and food from the storage to customers, depending on settings
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
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
	end
	
	local RndLocator = Rand(6) + 1
	if GetLocatorByName("Tavern", "Stroll"..RndLocator, "StartPos") then
		f_MoveToNoWait("", "StartPos", GL_MOVESPEED_RUN)
	end
	
	-- Do some preps first
	local ItemList = { "GrainPap", "SmallBeer", "SalmonFilet", "WheatBeer", "RoastBeef", "FriedHerring", "Shellsoup", "SmokedSalmon"}
	local ItemID = { }
	local ItemCount = 8 -- if you add more items, add variables accordingly
	local Keep1, Keep2, Keep3, Keep4, Keep5, Keep6, Keep7, Keep8
	local Label1, Label2, Label3, Label4, Label5, Label6, Label7, Label8
	
	-- Get settings
	for i=1, ItemCount do
		if not HasProperty("Tavern", "Keep_"..ItemList[i]) then
			SetProperty("Tavern", "Keep_"..ItemList[i], 0) -- how many items should be kept instead of sold
		end
		
		ItemID[i] = ItemGetID(ItemList[i])
	end
	
	Keep1 = GetProperty("Tavern", "Keep_"..ItemList[1]) or 0
	Keep2 = GetProperty("Tavern", "Keep_"..ItemList[2]) or 0
	Keep3 = GetProperty("Tavern", "Keep_"..ItemList[3]) or 0
	Keep4 = GetProperty("Tavern", "Keep_"..ItemList[4]) or 0
	Keep5 = GetProperty("Tavern", "Keep_"..ItemList[5]) or 0
	Keep6 = GetProperty("Tavern", "Keep_"..ItemList[6]) or 0
	Keep7 = GetProperty("Tavern", "Keep_"..ItemList[7]) or 0
	Keep8 = GetProperty("Tavern", "Keep_"..ItemList[8]) or 0
	
	Label1 = ItemGetLabel(ItemList[1])
	Label2 = ItemGetLabel(ItemList[2])
	Label3 = ItemGetLabel(ItemList[3])
	Label4 = ItemGetLabel(ItemList[4])
	Label5 = ItemGetLabel(ItemList[5])
	Label6 = ItemGetLabel(ItemList[6])
	Label7 = ItemGetLabel(ItemList[7])
	Label8 = ItemGetLabel(ItemList[8])
	
	local ChangeItem
	
	-- display all settings
	if IsGUIDriven() then
		local Result = MsgBox("dynasty", "Tavern", "@P"..
				"@B[C,@L_MEASURE_ASSIGN_EMPLOYEES_TO_SERVICE_TAVERN_BTN_+0]".. -- all good
				"@B[1,@L_MEASURE_ASSIGN_EMPLOYEES_TO_SERVICE_TAVERN_BTN_+1]".. -- make changes to one item
				"@B[2,@L_MEASURE_ASSIGN_EMPLOYEES_TO_SERVICE_TAVERN_BTN_+2]", -- reset everything
				"@L_MEASURE_ASSIGN_EMPLOYEES_TO_SERVICE_TAVERN_HEAD_+0",
				"@L_MEASURE_ASSIGN_EMPLOYEES_TO_SERVICE_TAVERN_BODY_+0",
				GetID("Tavern"), Label1, Keep1, Label2, Keep2, Label3, Keep3, Label4, Keep4, Label5, Keep5, Label6, Keep6, Label7, Keep7, Label8, Keep8)
		
		if Result == 2 then -- reset
			for i=1, ItemCount do
				SetProperty("Tavern", "Keep_"..ItemList[i], 0) -- how many items should be kept instead of sold
			end
		elseif Result == 1 then -- make changes to an item
			result = InitData("@P".."@B[1,,"..Label1..",hud/items/item_"..ItemList[1]..".tga]"..
						"@B["..ItemID[2]..",,"..Label2..",hud/items/item_"..ItemList[2]..".tga]"..
						"@B["..ItemID[3]..",,"..Label3..",hud/items/item_"..ItemList[3]..".tga]"..
						"@B["..ItemID[4]..",,"..Label4..",hud/items/item_"..ItemList[4]..".tga]"..
						"@B["..ItemID[5]..",,"..Label5..",hud/items/item_"..ItemList[5]..".tga]"..
						"@B["..ItemID[6]..",,"..Label6..",hud/items/item_"..ItemList[6]..".tga]"..
						"@B["..ItemID[7]..",,"..Label7..",hud/items/item_"..ItemList[7]..".tga]"..
						"@B["..ItemID[8]..",,"..Label8..",hud/items/item_"..ItemList[8]..".tga]",
						1,"@L_MEASURE_ASSIGN_EMPLOYEES_TO_SERVICE_TAVERN_BTN_+1","@L_MEASURE_ASSIGN_EMPLOYEES_TO_SERVICE_TAVERN_BTN_+3")
			if result == "C" then
				StopMeasure()
			end
			ChangeItem = result
			
			-- how many should be kept?
			result2 = MsgBox("dynasty", "Tavern", "@P"..
					"@B[0,0]".. -- 0
					"@B[1,1]".. -- 1
					"@B[5,5]".. -- 5
					"@B[10,10]".. --10
					"@B[20,20]".. --20
					"@B[40,40]".. --40
					"@B[999,999]", --999
					"@L_MEASURE_ASSIGN_EMPLOYEES_TO_SERVICE_TAVERN_BTN_+1",
					"@L_MEASURE_ASSIGN_EMPLOYEES_TO_SERVICE_TAVERN_BTN_+4")
					
			if result2 == "C" then
				StopMeasure()
			end
			
			local ChangeProp = ItemGetName(ChangeItem)
			SetProperty("Tavern", "Keep_"..ChangeProp, result2)
		end
	end
	
	-- move to tavern if needed
	if not GetInsideBuilding("", "CurrentBuilding") then
		if not f_MoveTo("", "Tavern", GL_MOVESPEED_RUN) then
			StopMeasure()
		end
	end

	SetProperty("Tavern", "ServiceActive", 1)
	
	SetData("IsProductionMeasure", 0)
	SimSetProduceItemID("", -GetCurrentMeasureID(""), -1)
	SetData("IsProductionMeasure", 1)
		
	while true do
		if GetImpactValue("Tavern", "ServiceActive") == 0 then
			AddImpact("Tavern", "ServiceActive", 1, -1)
		end
		local GuestsFilter = "__F((Object.GetObjectsByRadius(Sim) == 10000) AND (Object.Property.WaitingForService==1))"
		local NumGuests = Find("", GuestsFilter, "Guest", -1)
		
		if NumGuests == 0 then
			ms_157_assignemployeetoservice_CleanTables()
		else
			ms_157_assignemployeetoservice_Serve()
		end
		Sleep(1)
	end
end

function CleanTables()
	local Type = Rand(5)
	if Type == 0 then
		local RndLoc = Rand(4)
		if not GetFreeLocatorByName("Tavern", "ServeSitRich", RndLoc, 3,"MovePos") then
			GetFreeLocatorByName("Tavern", "ServeSitRich", 0, 3,"MovePos")
		end
		
		if AliasExists("MovePos") then
			f_BeginUseLocator("", "MovePos", GL_STANCE_STAND, true)
			PlayAnimation("", "manipulate_middle_twohand")
			f_EndUseLocator("", "MovePos", GL_STANCE_STAND)
		else
			Sleep(5)
		end
	elseif Type == 1 then
		local RndLoc = Rand(6)
		if not GetFreeLocatorByName("Tavern", "ServeStand", RndLoc, 5, "MovePos") then
			GetFreeLocatorByName("Tavern", "ServeStand", 0, 5, "MovePos")
		end
		
		if AliasExists("MovePos") then
			f_BeginUseLocator("", "MovePos", GL_STANCE_STAND, true)
			PlayAnimation("", "manipulate_middle_twohand")
			f_EndUseLocator("", "MovePos", GL_STANCE_STAND)
		end
	elseif Type == 2 then
		GetFreeLocatorByName("Tavern", "ServeAloneStand", -1, -1, "MovePos")
		f_BeginUseLocator("", "MovePos", GL_STANCE_STAND, true)
		PlayAnimation("", "manipulate_middle_twohand")
		f_EndUseLocator("", "MovePos", GL_STANCE_STAND)
	elseif Type == 3 then
		PlayAnimation("", "cogitate")
	else
		local RndLoc = Rand(6) + 1
		if not GetFreeLocatorByName("Tavern", "Stroll", RndLoc, 6, "MovePos") then
			GetFreeLocatorByName("Tavern", "Stroll", 1, 6, "MovePos")
		end
		
		if AliasExists("MovePos") then
			f_BeginUseLocator("", "MovePos", GL_STANCE_STAND, true)
		end
		
		CarryObject("", "Handheld_Device/ANIM_besen.nif", false)
		PlayAnimation("", "hoe_in")	
		for i=0, 5 do
			local waite = PlayAnimationNoWait("", "hoe_loop")
			Sleep(0.5)
			PlaySound3DVariation("", "Locations/herbs", 1.0)
			Sleep(waite-0.5)
		end
		PlayAnimation("", "hoe_out")
		CarryObject("", "", false)
		if AliasExists("MovePos") then
			f_EndUseLocator("", "MovePos", GL_STANCE_STAND)
		end
	end
	
	if BuildingGetAISetting("Tavern", "Produce_Selection") > 0 then -- maybe do something more useful instead
		if Rand(2) == 0 then
			StopMeasure()
		end
	end
end

function Serve()

	if not AliasExists("Guest0") then
		--LogMessage("Tavern: NoGuest0 found")
		return
	end
	
	if AliasExists("MovePos") then
		RemoveAlias("MovePos")
	end
	
	SetProperty("Guest0", "Served", 1)
	RemoveProperty("Guest0", "WaitingForService")
	
	local LocatorListOld = { "servesitrich1", "servesitrich2", "servesitrich0", "servesitrich3", "servestand0", "servestand1", "servestand3", "servestand4", "servestand5" }
	local LocatorCount = 9
	local Distance
	local BestDistance = 5000
	local BestLocatorID = 0
	
	-- get best serve stand
	for i=1, LocatorCount do
		GetLocatorByName("Tavern", LocatorListOld[i], "CheckLoc"..i)
		Distance = GetDistance("Guest0", "CheckLoc"..i)
		if Distance < BestDistance then
			BestDistance = Distance
			BestLocatorID = i
		end
	end
	
	local AloneStand = Rand(3)
	
	if AloneStand == 0 then
		if GetLocatorByName("Tavern", "ServeAloneStand0", "MovePos") then
			f_MoveTo("", "MovePos", GL_MOVESPEED_WALK)
			PlayAnimation("", "manipulate_middle_twohand")
		end
	elseif AloneStand == 1 then
		if GetLocatorByName("Tavern", "ServeAloneKnee0", "MovePos") then
			f_MoveTo("", "MovePos", GL_MOVESPEED_WALK)
			Sleep(1)
		end
	else
		if GetLocatorByName("Tavern", "ServeAloneHigh", "MovePos") then
			f_MoveTo("", "MovePos", GL_MOVESPEED_WALK)
			PlayAnimation("", "manipulate_top_r")
		end
	end
	
	RemoveAlias("MovePos")
	Sleep(0.3)
	
	-- get the locator blocked by Guest
	local LocatorList = { "SitRich1", "SitRich2", "SitRich3", "SitRich4", "SitRich5", "SitRich6", "SitInn1", "SitInn2", "SitInn3", "SitInn4", "SitInn5", "SitInn6", "SitInn7",
					"SitInn8", "SitInn9", "SitInn10", "SitInn11", "SitInn12", "SitInn13", "SitInn14", "SitInn15" }
	local LocatorCount = 21
	local LocatorGuest = "default"
	
	for i=1, LocatorCount do
		if GetLocatorByName("Tavern", LocatorList[i], "CheckLocator") then
			if LocatorGetBlocker("CheckLocator") == GetID("Guest0") then
				LocatorGuest = LocatorList[i]
				break
			end
		end
	end
	
	local ServeLocator = "default"
	
	-- select the right serving position
	if LocatorGuest == "SitRich1" or LocatorGuest == "SitRich6" then
		ServeLocator = "ServeSitRich1"
	elseif LocatorGuest == "SitRich2" then
		ServeLocator = "ServeSitRich2"
	elseif LocatorGuest == "SitRich4" then
		ServeLocator = "ServeSitRich3"
	elseif LocatorGuest == "SitRich3" or LocatorGuest == "SitRich5" then
		ServeLocator = "ServeSitRich0"
	elseif LocatorGuest == "SitInn2" or LocatorGuest == "SitInn4" then
		ServeLocator = "ServeStand3"
	elseif LocatorGuest == "SitInn1" or LocatorGuest == "SitInn3" then
		ServeLocator = "ServeStand4"
	elseif LocatorGuest == "SitInn5" or LocatorGuest == "SitInn6" or LocatorGuest == "SitInn7" or LocatorGuest == "SitInn8" then
		ServeLocator = "ServeStand1"
	elseif LocatorGuest == "SitInn9" or LocatorGuest == "SitInn10" or LocatorGuest == "SitInn11" or LocatorGuest == "SitInn12" then
		ServeLocator = "ServeStand0"
	elseif LocatorGuest == "SitInn13" or LocatorGuest == "SitInn14" or LocatorGuest == "SitInn15" then
		ServeLocator = "ServeStand5"
	end
	
	if LocatorGuest == "default" or ServeLocator == "default" then -- error, just go to them
		f_MoveTo("", "Guest0", GL_MOVESPEED_WALK, 125)
	else
		if GetLocatorByName("Tavern", ServeLocator, "MovePos") then
			f_MoveTo("", "MovePos", GL_MOVESPEED_WALK)
		end
	end		
	
	PlayAnimation("", "talk_short")
	-- bring something to eat or drink
	local EatChance = Rand(50)
	local DrinkChance = Rand(50)
	local Time = math.mod(GetGametime(),24)
	
	if Time >= 18 or Time < 6 then
		DrinkChance = DrinkChance + Rand(50)
	elseif Time >= 10 and Time <= 17 then
		EatChance = EatChance + Rand(50)
	end
	
	local choice = ""
	local NewProp
	local Available, Protected
	local VarietyBonus = 0
	if EatChance > DrinkChance then -- eat
		local List = { "GrainPap", "SalmonFilet", "RoastBeef", "FriedHerring", "Shellsoup", "SmokedSalmon" }
		local Count = 6
		local FinalList = {}
		local FinalCount = 0
		for i=1, Count do
			Available = GetItemCount("Tavern", List[i], INVENTORY_STD) + GetItemCount("Tavern", List[i], INVENTORY_SELL) or 0
			Protected = GetProperty("Tavern", "Keep_"..List[i]) or 0
			
			if Available > 0 then
				FinalCount = FinalCount + 1
				FinalList[FinalCount] = List[i]
				VarietyBonus = VarietyBonus + 2
			end
		end
		
		if FinalCount > 0 then
			local Choice = 0
			if FinalCount == 1 then
				Choice = 1
			else
				Choice = Rand(FinalCount) + 1
			end
			choice = FinalList[Choice]
			NewProp = "EatSomething"
		else
			choice = ""
		end
	else -- drink
		local List = { "SmallBeer", "WheatBeer" }
		local Count = 2
		local FinalList = {}
		local FinalCount = 0
		for i=1, Count do
			Available = GetItemCount("Tavern", List[i], INVENTORY_STD) + GetItemCount("Tavern", List[i], INVENTORY_SELL) or 0
			Protected = GetProperty("Tavern", "Keep_"..List[i]) or 0
			
			if Available > 0 then
				FinalCount = FinalCount + 1
				FinalList[FinalCount] = List[i]
				VarietyBonus = VarietyBonus + 2
			end
		end
		
		if FinalCount > 0 then
			local Choice = 0
			if FinalCount == 1 then
				Choice = 1
			else
				Choice = Rand(FinalCount) + 1
			end
			
			choice = FinalList[Choice]
			NewProp = "DrinkSomething"
		else
			choice = ""
		end
	end
	
	if choice == "" then -- nothing found
		AlignTo("", "Guest0")
		PlayAnimationNoWait("", "shake_head")
		MsgSay("", "@L_MEASURE_ASSIGN_EMPLOYEES_TO_SERVICE_NO_ITEMS")
		Sleep(1)
		PlayAnimation("Guest0", "sit_no")
		RemoveProperty("Guest0", "WaitingForService")
	else
		if RemoveItems("Tavern", choice, 1, INVENTORY_STD) < 1 then
			RemoveItems("Tavern", choice, 1, INVENTORY_SELL)
		end
		local Label = ItemGetLabel(choice, true)
		AlignTo("", "Guest0")
		MsgSay("", "@L_MEASURE_ASSIGN_EMPLOYEES_TO_SERVICE_ORDER", Label)
		Sleep(1)
		RemoveProperty("Guest0", "WaitingForService")
		SetProperty("Guest0", NewProp, 1)
		local BasePrice = ItemGetBasePrice(choice)
		local Favor = GetFavorToSim("", "Guest0")
		local FavorBonus = 0
		if Favor > 50 then
			FavorBonus = (5*math.floor(Favor/5))*0.01
		end
		local TipPercent = 0.1 + chr_GetRank("Guest0")*0.05 + chr_GetSkillValue("", CHARISMA)*0.03 + FavorBonus + GetImpactValue("Tavern", "Attractivity")/10
		LogMessage("Tavern: TipPercent is "..TipPercent)
		local Tip = math.ceil(BasePrice*(1+TipPercent))
		local Final = math.ceil(Tip+BasePrice)
		if Final > chr_GetBudget("Guest0", 1) then
			Final = BasePrice
			Tip = 0
		end
		chr_UseBudget("Guest0", 1, Final, "WaresBought")
		LogMessage("Tavern: Tip is "..Tip)
		CreditMoney("Tavern", (Tip+BasePrice), "WaresSold")
		ShowOverheadSymbol("Guest0", false, false, 0, "@L%1t", Final)
		
		-- maybe become a regular customer
		local BaseChance = 10
		
		if Rand(100) < (BaseChance+VarietyBonus) then
			SetProperty("", "Regular_"..BuildingGetType("Tavern"), GetID("Tavern"))
			MsgSay("Guest0", "@L_MEASURE_ASSIGN_EMPLOYEES_TO_SERVICE_REGULAR")
		end
	end
	RemoveProperty("Guest0", "Served")
end

function CleanUp()
	
	if AliasExists("MovePos") then
		f_EndUseLocator("", "MovePos", GL_STANCE_STAND)
	end
	
	ReleaseLocator("")
	
	if AliasExists("Tavern") then
		SimGetWorkingPlace("","Tavern")
		RemoveProperty("Tavern", "ServiceActive")
		RemoveImpact("Tavern", "ServiceActive")
		RemoveProperty("Tavern", "GoToService")
	end

	StopAnimation("")
	MoveSetActivity("")
end

