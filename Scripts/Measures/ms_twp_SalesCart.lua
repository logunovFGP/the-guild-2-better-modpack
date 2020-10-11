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
	local ProductCount, Products = ms_twp_salescart_InitMeasure()
	ms_twp_salescart_SetMeasureData(ProductCount, Products)
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
	local ProductCount, Products = economy_GetItemsForSale("MyHome")
	for i = 1, ProductCount do
		if Products[i] == 360 or Products[i] == 360 or Products[i] == 364 or Products[i] == 365 or Products[i] == 371 then
			-- protect medicince required for treatment
			Products[i] = { Products[i], 30 }
		else
			Products[i] = { Products[i], 0 }
		end
	end
	 
	repeat
		-- First dialog handles control: Help, Choose resources, Choose Suppliers, Start
		local Options =	"@B[1,@L_TWP_SALESCART_INITIATE_OPTION_+0,]".. -- Choose Resources
			-- "@B[2,@L_TWP_SALESCART_INITIATE_OPTION_+1,]".. -- Sales threshold (not yet implemented)
			"@B[99,@L_TWP_SALESCART_INITIATE_OPTION_+2,]" -- Start
			--"@B[C,@LAbort_+0,]" -- Abort by right mouse click
		
		Choice = MsgBox("","Owner","@P"..Options,"@L_TWP_SALESCART_INITIATE_HEAD_+0","_TWP_SALESCART_INITIATE_BODY_+0", GetID("MyHome"))
		
		if Choice == 1 then
			ProductCount, Products = ms_twp_salescart_ChooseProducts(ProductCount, Products)
		elseif Choice == nil or Choice == "C" then -- cancel
			StopMeasure()
		end
	until Choice == 99 -- Start measure
	
	return ProductCount, Products
end

function Run() 
	-- find home 
	if not GetHomeBuilding("","MyHome") then
		return
	end
	if not GetOutdoorMovePosition("", "MyHome", "HomePos") then
		return
	end 
	if not GetSettlement("MyHome", "MyCity") then
		return 
	end 

	local ProductCount, Products = ms_twp_salescart_GetMeasureData()
	
	-- 1. Go home.
	if not IsInLoadingRange("", "MyHome") and not f_MoveTo("","HomePos", GL_MOVESPEED_RUN) then
		-- cannot get gome, something went wrong
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
		CityGetLocalMarket("MyCity","MyMarket")
		local ProfitCount, Profits = economy_CalcProfits("MyMarket", "MyHome", ProductCount, Products, 250)
		if ProfitCount > 0 then
			-- 4. load the cart, slot by slot
			cart_LoadItems("", "MyHome", ProfitCount, Profits) 
			-- 5. go to the market
			if CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, "MarketBld") then
				f_MoveTo("","MarketBld", GL_MOVESPEED_RUN)
			end
			Sleep(3)
			-- 6. Unload
			cart_UnloadAll("", "MarketBld")
			Sleep(2)
		else
			Sleep(120) -- nothing to sell right now, wait a while
		end 
		
		-- return home if necessary
		if not IsInLoadingRange("", "MyHome") and not f_MoveTo("","HomePos", GL_MOVESPEED_RUN) then
			-- cannot get gome, something went wrong
			ms_twp_salescart_Abort()
		end
		Sleep(30) -- give me some rest
	end
end

function Abort()
	GetHomeBuilding("","MyHome")
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

function CleanUp()
end

function SetMeasureData(ProductCount, Products)
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
end

function GetMeasureData()
	local ProductCount = GetData("ProductCount")
	local Products = {}
	for i = 1, ProductCount do
		Products[i] = { GetData("Product"..i), GetData("ProductMin"..i) }
	end
	return ProductCount, Products
end
