---
-- Measure: SalesCart
-- Author: ThreeOfMe
-- Mod: TWP -- Trade, War, Politics
--
-- This cart measure may be used to automatically sell products of a workshop. 
-- It requires the table BuildingToItems to be up-to-date with the item production list.
-- 
-- The player may choose the following parts of the measure (see Init):
-- 
-- * The products that should be sold.
-- * The amount that should remain in storage.
-- * (possible extension) The minimum of the expected profit.  
-- 
-- The base algorithm will then be (see Run):
-- 
-- 1. For each product, check current amount in storage.
-- 2. If amount is above threshold, add item and expected profits to a list.
-- 3. Sort the list by profits, highest profit first.
-- 4. Load the cart.
-- 5. Go to the market and sell all goods.
-- 6. Return to workshop and restart at (1). 
--

function Init()
	local ProductCount, Products, TargetCount, Targets = ms_twp_salescart_InitMeasure()
	ms_twp_salescart_SetMeasureData(ProductCount, Products, TargetCount, Targets)
end

function ChooseProducts(ProductCount, Products)
	local ChosenItemId
	local Buttons = ""
	local Id, ItemTexture, Subtext
	local Tooltip = ""

	local ChosenItem
	repeat
		Buttons = "@P"
		for i=1, ProductCount do
			Id = Products[i][1]
			ItemTexture = "Hud/Items/Item_"..ItemGetName(Id)..".tga"
			Tooltip = ItemGetLabel(Id, false)
			Subtext = Products[i][2]
			-- result, Tooltip, label, icon
			Buttons = Buttons.."@B[" .. i .. "," .. Subtext .. "," .. Tooltip .. "," .. ItemTexture .."]"
		end
		Buttons = Buttons.."@B[C,@L_GENERAL_BUTTONS_OK_+0,@L_GENERAL_BUTTONS_OK_+0,Hud/Buttons/btn_Ok.tga]" 
		ChosenItem = InitData(
			Buttons, -- PanelParam
			0, -- AIFunc
			"@L_TWP_SALESCART_CHOOSEPRODUCT_HEAD_+0",-- HeaderLabel
			"Body"
		)
		if ChosenItem and ChosenItem == -1 then
			if ChosenItem == -1 then -- warehouse, add any available item from inventory
				BuildingGetOwner("", "BldOwner")
				ChosenItem = economy_ChooseItemFromInventory("", "BldOwner")
			end
		end
		if ChosenItem and ChosenItem ~= "C" then
			local Options = "@B[-1,@L_TWP_SALESCART_CHOOSEAMOUNT_+0,]".. -- do not sell
											"@B[0,@L_TWP_SALESCART_CHOOSEAMOUNT_+1,]".. -- sell all
											"@B[10,@L_TWP_SALESCART_CHOOSEAMOUNT_+2,]".. -- leave 10 in storage
											"@B[20,@L_TWP_SALESCART_CHOOSEAMOUNT_+3,]".. -- leave 20 in storage
											"@B[40,@L_TWP_SALESCART_CHOOSEAMOUNT_+4,]".. -- leave 40 in storage
											"@B[80,@L_TWP_SALESCART_CHOOSEAMOUNT_+5,]"   -- leave 80 in storage
			local ItemId = Products[ChosenItem][1]
			local ChosenMinAmount = MsgBox("","Owner","@P"..Options,"@L_TWP_SALESCART_CHOOSEAMOUNT_HEAD_+0","_TWP_SALESCART_CHOOSEAMOUNT_BODY_+0", ItemGetLabel(ItemId,false))
			if ChosenMinAmount and ChosenMinAmount ~= "C" then			
				Products[ChosenItem][2] = ChosenMinAmount
			end
		end
	until ChosenItem == nil or ChosenItem =="C"
	
	return ProductCount, Products
end

function InitMeasure()
  -- find home
	if not GetHomeBuilding("","MyHome") then
		return
	end
	local Choice
	-- initialize Resources: {{Item1, Min1}, {Item2, Min2}, ...}
	local ProductCount, Products, ProtectedAmounts = economy_StorageGetProducts("MyHome")
	for i = 1, ProductCount do
		Products[i] = { Products[i], ProtectedAmounts[i] or 0 }
	end
	
	local TargetCount = 0
	local Targets = {} -- {Target1, Target2, ...}
	-- add local market as target for convenience
	if GetSettlement("MyHome", "MyCity") and not cart_IsShip("") then
		if CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, "MyMarket") then
			TargetCount = 1
			Targets[1] = "MyMarket"
		end
	end 
	 
	repeat
		-- First dialog handles control: Help, Choose resources, Choose Suppliers, Start
		local Options =
			"@B[1,@L_TWP_SUPPLYWORKSHOP_INITIATE_OPTION_+0,]".. -- Help	
			"@B[2,@L_TWP_SALESCART_INITIATE_OPTION_+0,]".. -- Choose products
			"@B[3,@L_TWP_SALESCART_INITIATE_OPTION_+1,]".. -- Choose targets
			-- "@B[3,@L_TWP_SALESCART_INITIATE_OPTION_+1,]".. -- Sales threshold (not yet implemented)
			"@B[99,@L_TWP_SALESCART_INITIATE_OPTION_+2,]" -- Start
			--"@B[C,@LAbort_+0,]" -- Abort by right mouse click
		
		Choice = MsgBox("","Owner","@P"..Options,"@L_TWP_SALESCART_INITIATE_HEAD_+0","_TWP_SALESCART_INITIATE_BODY_+0", GetID("MyHome"), 400)
		
		if Choice == 1 then
			MsgBox("", "Owner", "", "@L_TWP_SALESCART_INITIATE_HEAD_+0", "@L_TWP_SALESCART_HELP_BODY_+0")
		elseif Choice == 2 then
			ProductCount, Products = ms_twp_salescart_ChooseProducts(ProductCount, Products)
		elseif Choice == 3 then
			TargetCount, Targets = ms_twp_salescart_ChooseTargets(TargetCount, Targets)
		elseif Choice == nil or Choice == "C" then -- cancel
			StopMeasure()
		end
	until Choice == 99 -- Start measure
	
	return ProductCount, Products, TargetCount, Targets
end

function Run() 
	-- find home 
	if not GetHomeBuilding("", "MyHome") then
		return
	end
	if not GetOutdoorMovePosition("", "MyHome", "HomePos") then
		return
	end 
	if not GetSettlement("MyHome", "MyCity") then
		return 
	end 

	local TargetCount, Targets = ms_twp_salescart_GetMeasureData()
	
	-- 1. Go home.
	MsgMeasure("", "@L_GENERAL_MSGMEASURE_BACK_TO_WORK_+0")
	if not IsInLoadingRange("", "MyHome") and not f_MoveTo("", "HomePos", GL_MOVESPEED_RUN) then
		-- cannot get home, something went wrong
		ms_twp_salescart_Abort()
	end
	local CartSlots, CartSlotSize = cart_GetCartSlotInfo("")
	if CartSlots <= 0 then
		ms_twp_salescart_Abort()
	end

	cart_UnloadAll("", "MyHome")
	
	local NeedCount, Needs
	while true do 
		-- 3. Calculate expected profit for each item
		local ProfitCount, Profits = 0, {}
		local ExpectedTotalProfit = 0
		local ChosenTarget
		for i = 1, TargetCount do
			if Targets[i] and AliasExists(Targets[i]) then
			  -- selling to market or just send the goods to warehouse?
			  local UseBasePrice = GL_BUILDING_TYPE_WAREHOUSE == BuildingGetType(Targets[i])
				local TmpProfitCount, TmpProfits, TmpExpectedTotalProfit = economy_CalcProfits("Market"..i, "MyHome", ProductCount, Products, 250, UseBasePrice)
				if TmpExpectedTotalProfit and TmpExpectedTotalProfit > ExpectedTotalProfit then
					ChosenTarget = Targets[i]
					ProfitCount, Profits, ExpectedTotalProfit = TmpProfitCount, TmpProfits, TmpExpectedTotalProfit
				end
			end
		end
		
		if ProfitCount > 0 and ChosenTarget then
			MsgMeasure("", "@L_GENERAL_MSGMEASURE_TWP_CART_SELL_+0")
			-- 4. load the cart, slot by slot
			cart_LoadItems("", "MyHome", ProfitCount, Profits) 
			-- 5. go to the market
			f_MoveTo("", ChosenTarget, GL_MOVESPEED_RUN)
			-- careful: MoveResult is true when driver is attacked. SATE_DRIVERATTACKED lasts longer than the following code segment and would lead to abort
			if not IsInLoadingRange("", ChosenTarget) then
				while GetState("", STATE_ACTIVE_ESCORT) or (not CartGetOperator("", "Operator")) or GetState("Operator", STATE_DRIVERATTACKED) do
					Sleep(10) -- wait until movement is available again
				end
			end
			
			Sleep(3)
			-- 6. Unload (simply does nothing when not in range)
			cart_UnloadAll("", ChosenTarget)
			Sleep(2)
		else
			MsgMeasure("", "@L_GENERAL_MSGMEASURE_TWP_CART_NO_PROFIT_+0")
			Sleep(120) -- nothing to sell right now, wait a while
		end 
		
		MsgMeasure("", "@L_GENERAL_MSGMEASURE_BACK_TO_WORK_+0")
		-- return home if necessary
		if not IsInLoadingRange("", "MyHome") and not f_MoveTo("", "HomePos", GL_MOVESPEED_RUN) then
			-- cannot get gome, something went wrong
			ms_twp_salescart_Abort()
		end
		Sleep(30) -- give me some rest
	end
end

function Abort()
	GetHomeBuilding("", "MyHome")
	local ret = MsgNews("", "", 
				"", -- Buttons 
				0,
				"production", 
				1, 
				"@L_TWP_SALESCART_ABORTWARNING_HEAD_+0", 
				"@L_TWP_SALESCART_ABORTWARNING_BODY_+0", 
				GetID("MyHome"))
	StopMeasure()
end

function ChooseTargets(TargetCount, Target)
	local Choice
	local LabelIds = {}
	repeat
		local Options = "@P"
		-- show list of suppliers with option to add another one
		for i=1, TargetCount do
			if BuildingGetClass(Target[i]) == GL_BUILDING_CLASS_MARKET then
				-- use city name for markets
				Options = Options .. "@B["..i..",@L_TWP_SUPPLYWORKSHOP_MARKET_+"..i..",]"
				LabelIds[i] = GetSettlementID(Target[i])
			else
				-- use Building name (not possible right now, but maybe later)
				Options = Options .. "@B["..i..",%"..i.."GG,]"
				LabelIds[i] = GetID(Target[i])
			end
		end

		Options = Options .. "@B[A,@L_TWP_SUPPLYWORKSHOP_ADDSUPPLIER_+0,]" .. "@B[C,@L_GENERAL_BUTTONS_OK_+0,]"
		Choice = MsgBox("","Owner",Options,"@L_TWP_SALESCART_INITIATE_HEAD_+0","_TWP_SALESCART_CHOOSE_TARGETS_+0", helpfuncs_UnpackTable(LabelIds))
	
		if Choice == "A" then
			-- add new Supplier
			local TargetAlias = ms_twp_salescart_SelectTarget(TargetCount)
			if TargetAlias and AliasExists(TargetAlias) then
				TargetCount = TargetCount + 1
				Target[TargetCount] = TargetAlias
			end
		elseif Choice ~= "C" and Choice > 0 then
			-- delete this target from list and make sure to move other suppliers up by one
			TargetCount, Target = helpfuncs_RemoveElementFromList(Target, TargetCount, Choice)
		end
	until Choice == nil or Choice == "C"
	return TargetCount, Target
end

function SelectTarget(Index)
	local FreeIndex = Index
	while AliasExists("Target"..FreeIndex) do
		FreeIndex = FreeIndex + 1
	end
	-- filter for market/building selection
	InitAlias("Target"..FreeIndex, MEASUREINIT_SELECTION,
		--"__F((Object.IsClass(5)) AND (Object.Type == Building))",
		"__F( ((Object.Type == Building) AND (Object.IsClass(5))) OR ((Object.Type == Building) AND (Object.IsClass(2)) AND (Object.BelongsToMe())) )",
		"@L_TRADEROUTE_NEXT_BUILDING_+0",0)
	return "Target"..FreeIndex
end


function CleanUp()
end

function SetMeasureData(ProductCount, Products, TargetCount, Targets)
	-- filter resources with a minimum of -1
	local ReducedProductCount = 0
	for i = 1, ProductCount do
		if Products[i][2] >= 0 then
			ReducedProductCount = ReducedProductCount + 1
			SetData("Product"..ReducedProductCount, Products[i][1])
			SetData("ProductMin"..ReducedProductCount, Products[i][2] )
		end
	end
	SetData("ProductCount", ReducedProductCount)
	SetData("TargetCount", TargetCount)
	for i = 1, TargetCount do
		SetData("Target"..i, GetID(Targets[i]))
	end
end

function GetMeasureData()
	local ProductCount = GetData("ProductCount")
	local Products = {}
	for i = 1, ProductCount do
		Products[i] = { GetData("Product"..i), GetData("ProductMin"..i) }
	end
	local TargetCount = GetData("TargetCount")
	local Targets = {}
	for i = 1, TargetCount do
		GetAliasByID(GetData("Target"..i), "Target"..i) -- ID from Data to Alias
		Targets[i] = "Target"..i -- saving alias
		-- initialize markets of each target for price calculation
		if GetSettlement("Target"..i, "SomeCity") then
			CityGetLocalMarket("SomeCity","Market"..i)
		end
	end
	return ProductCount, Products, TargetCount, Targets
end
