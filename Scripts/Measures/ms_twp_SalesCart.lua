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

function GetProductsForWorkshop(BldAlias)
	local BldId = BuildingGetProto(BldAlias)
	local ItemsString = GetDatabaseValue("BuildingToItems", BldId, "produceditems")
	if ItemsString == nil then
		return 0, {}
	end
	local Items = {}
	local Products = {}
	local Count = 0
	for Id in string.gfind(ItemsString, "%d+") do
		Count = Count + 1
		Products[Count] = { ItemGetID(Id), 0 }
	end
	return Count, Products
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
		Products[i] = { Products[i], 0 }
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
		StopMeasure()
	end
	local CartSlots, CartSlotSize = cart_GetCartSlotInfo("")
	if CartSlots <= 0 then
		StopMeasure()
	end

	cart_UnloadAll("", "MyHome")
	
	local NeedCount, Needs
	while true do 
		-- 3. Calculate expected profit for each item
		CityGetLocalMarket("MyCity","MyMarket")
		local ProfitCount, Profits = ms_twp_salescart_CalcProfits("MyMarket", "MyHome", ProductCount, Products)
		local CityAlias = "MyCity"
		if ProfitCount > 0 then
			-- go to market and sell products
			ms_twp_salescart_LoadAndSellAtMarket(Profits, ProfitCount, CartSlots, CartSlotSize, CityAlias)
		else
			Sleep(120) -- nothing to sell right now, wait a while
		end 
		
		-- return home if necessary
		if not IsInLoadingRange("", "MyHome") and not f_MoveTo("","HomePos", GL_MOVESPEED_RUN) then
			-- cannot get gome, something went wrong
			local ret = MsgNews("", "", 
				"", -- Buttons 
				0,
				"production", 
				1, 
				"@L_TWP_SALESCART_ABORTWARNING_HEAD_+0", 
				"@L_TWP_SALESCART_ABORTWARNING_BODY_+0", 
				"MyHome")
			StopMeasure() 
		end
		Sleep(30) -- give me some rest
	end
end

function CalcProfits(MarketAlias, HomeAlias, ProductCount, Products)
	local Profits = {} -- table of {{ItemId, MinAmount}, Profit}
	local ProfitCount = 0
	local ItemId
	for i = 1, ProductCount do
		ItemId = Products[i][1]
		local Amount = GetItemCount(HomeAlias, ItemId)
		Amount = Amount - Products[i][2]
		local Profit = Amount *	ItemGetPriceSell(ItemId, MarketAlias) 
		if Amount > 0 and Profit > 250 then
			ProfitCount = ProfitCount + 1
			Profits[ProfitCount] = {Products[i], Profit} -- {{ItemId, MinAmount}, Profit}
		end
	end
 
 	if ProfitCount == 0 then
 		return 0, {}
 	end
 	
	-- 4. sort by expected profit, highest first
	Profits = helpfuncs_QuickSort(Profits, 1, ProfitCount, ms_twp_salescart_SortProfits)
	return ProfitCount, Profits 
end

function SortProfits(a,b) 
	return a[2] > b[2] 
end

function LoadAndSellAtMarket(Profits, ProfitCount, CartSlots, CartSlotSize, CityAlias) 
	local NeedCount, Needs
	if ProfitCount > 0 then
		LogMessage("AITWP::SalesCart " .. GetName("") .. " Loading items at workshop.")
		-- 5. load the cart, slot by slot
		local CurrentItem = 1
		for i = 1, CartSlots do
			local ItemId = Profits[CurrentItem][1][1]
			local Error, ItemTransfered = Transfer("","",INVENTORY_STD,"MyHome",INVENTORY_STD, ItemId, CartSlotSize)
			-- 6. make sure list is repeated if slots are still available
			CurrentItem = math.mod(CurrentItem, ProfitCount) + 1 
		end 
	end
	-- 7. go to the market
	-- get market building
	if CityGetRandomBuilding(CityAlias, -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, "MarketBld") then
		f_MoveTo("","MarketBld", GL_MOVESPEED_RUN)
	end
	Sleep(3)
	-- Unload
	cart_UnloadAll("", "MarketBld")
	Sleep(2)
end

function GoShopping(BldAlias, NeedCount, Needs, CartSlots, CartSlotSize)
	local BldInv = INVENTORY_STD
	if GetDynastyID("") ~= GetDynastyID(BldAlias) and BuildingGetClass(BldAlias) ~= GL_BUILDING_CLASS_MARKET then
		-- use sales inventory for workshops of other dynasties
		BldInv = INVENTORY_SELL
	end
	if NeedCount and NeedCount > 0 then
		local CurrentItem = 1 
		local OpenSlots = CartSlots
		while OpenSlots > 0 and CurrentItem <= NeedCount do
			local ItemId = Needs[CurrentItem][1]
			if ItemId then
				local Error, ItemTransfered = Transfer("","",INVENTORY_STD,BldAlias, BldInv, ItemId, CartSlotSize)
				-- 6. make sure list is repeated if slots are still available
				if ItemTransfered and ItemTransfered > 0 then
					-- update balance with estimated costs (TWP)
					--local EstimatedCost = ItemGetPriceBuy(ItemId,"MarketBld")*ItemTransfered
					--economy_UpdateBalance("MyHome", "Autoroute", -EstimatedCost)
					CurrentItem = math.mod(CurrentItem, NeedCount) + 1
					OpenSlots = OpenSlots - 1
					Needs[CurrentItem][2] = Needs[CurrentItem][2] - ItemTransfered
				else 
					-- slot not used, keep going
					CurrentItem = CurrentItem + 1
				end 
			end
		end
	end
	return Needs
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
