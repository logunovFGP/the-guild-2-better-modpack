function Init()
	SetStateImpact("no_measure_start")
	SetStateImpact("no_control")
	SetStateImpact("no_idle")
	SetStateImpact("no_action")
	SetStateImpact("no_cancel_button")
	StopMeasure()
end

function Run() 
	-- find home 
	if not GetHomeBuilding("","MyHome") then
		return
	end
	if not GetSettlement("MyHome", "MyCity") then
		return 
	end
	if not GetOutdoorMovePosition("", "MyHome", "HomePos") then
		return
	end
	
	-- 1. Go home.
	if not IsInLoadingRange("", "MyHome") and not f_MoveTo("","HomePos", GL_MOVESPEED_RUN) then
		-- cannot get gome, something went wrong
		return
	end
	local CartSlots, CartSlotSize = cart_GetCartSlotInfo("")
	if CartSlots <= 0 then
		return
	end

	state_twp_autocart_UnloadItems(CartSlots, CartSlotSize, "MyHome")
	
	while true do 
		-- 3. Calculate expected profit for each item
		CityGetLocalMarket("MyCity","MyMarket")
		local ProfitCount, Profits = state_twp_autocart_CalcProfits("MyMarket", "MyHome")
		local CityAlias = "MyCity"
		if ProfitCount <= 0 then
			ProfitCount, Profits, CityAlias = state_twp_autocart_CalcProfitsOutside("MyHome")
		end 
		
		-- go to market, sell products and buy resources
		state_twp_autocart_LoadAndSellAtMarket(Profits, ProfitCount, CartSlots, CartSlotSize, CityAlias)
		
		-- return home if necessary
		if not IsInLoadingRange("", "MyHome") and not f_MoveTo("","HomePos", GL_MOVESPEED_RUN) then
			-- cannot get gome, something went wrong
			return
		end
		-- Unload at home and wait some time
		state_twp_autocart_UnloadItems(CartSlots, CartSlotSize, "MyHome")		
		Sleep(30) 
	end
end

function LoadAndSellAtMarket(Profits, ProfitCount, CartSlots, CartSlotSize, CityAlias) 
	local NeedCount, Needs
	if ProfitCount > 0 then
		LogMessage("AITWP::AutoCart " .. GetName("") .. " Loading items at workshop.")
		-- 5. load the cart, slot by slot
		local CurrentItem = 1
		for i = 1, CartSlots do
			RemoveItems("", "EmptySlot", CartSlotSize, INVENTORY_STD)
			local ItemId = Profits[CurrentItem][1]
			local Error, ItemTransfered = Transfer("","",INVENTORY_STD,"MyHome",INVENTORY_STD, ItemId, CartSlotSize)
			if ItemTransfered < CartSlotSize then
				local Error, ItemTransfered = Transfer("","",INVENTORY_STD,"MyHome",INVENTORY_SELL, ItemId, CartSlotSize - ItemTransfered)
			end
			-- 6. make sure list is repeated if slots are still available
			CurrentItem = math.mod(CurrentItem, ProfitCount) + 1 
		end 
	else
		NeedCount, Needs = state_twp_autocart_CalcResourceNeeds("MyHome")
		if not NeedCount or NeedCount <= 0 then
			-- nothing to do right now, wait a while
			Sleep(120)
			return
		end
	end
	-- 7. go to the market
	-- get market building
	if not CityGetRandomBuilding(CityAlias, -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, "MarketBld") then
		return
	end
	
	f_MoveTo("","MarketBld", GL_MOVESPEED_RUN)
	Sleep(3)
	-- Unload
	RemoveItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD)
	cart_UnloadAll("", "MarketBld", true)
	-- buy required resources
	if not NeedCount then -- may not be initialized yet
		NeedCount, Needs = state_twp_autocart_CalcResourceNeeds("MyHome")
	end
	if NeedCount and NeedCount > 0 then
		local CurrentItem = 1 
		local OpenSlots = CartSlots
		local ItemId, ReqAmount 
		while OpenSlots > 0 and CurrentItem <= NeedCount do
			ItemId = Needs[CurrentItem][1]
			ReqAmount = Needs[CurrentItem][2]
			if ItemId then
				local Error, ItemTransfered = Transfer("","",INVENTORY_STD,"MarketBld",INVENTORY_STD, ItemId, math.min(CartSlotSize, ReqAmount))
				-- 6. make sure list is repeated if slots are still available
				if ItemTransfered and ItemTransfered > 0 then
					-- update balance with estimated costs
					local EstimatedCost = ItemGetPriceBuy(ItemId,"MarketBld")*ItemTransfered
					--economy_UpdateBalance("MyHome", "Autoroute", -EstimatedCost)
					Needs[CurrentItem][2] = Needs[CurrentItem][2] - ItemTransfered
					CurrentItem = math.mod(CurrentItem, NeedCount) + 1
					OpenSlots = OpenSlots - 1
				else 
					-- slot not used, keep going
					CurrentItem = CurrentItem + 1
				end 
			end
		end
	end
	 
	-- fill up remaining space with dummy item
	AddItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD)
	Sleep(2)
end

function CalcProfits(MarketAlias, HomeAlias)
	local Profits = {} -- table of ItemId -> Profit
	local ProfitCount = 0

	local Count, Items = economy_GetItemsForSale(HomeAlias)
	for i = 1, Count do
		local Amount = GetItemCount(HomeAlias, Items[i], INVENTORY_STD) + GetItemCount(HomeAlias, Items[i], INVENTORY_SELL)
		local Profit = Amount *	ItemGetPriceSell(Items[i], MarketAlias) 
		if Amount > 0 and Profit > 500 then
			ProfitCount = ProfitCount + 1
			Profits[ProfitCount] = {Items[i], Profit}
		end
	end
 
 	if ProfitCount == 0 then
 		return 0, {}
 	end
 	
	-- 4. sort by expected profit, highest first
	Profits = helpfuncs_QuickSort(Profits, 1, ProfitCount, state_twp_autocart_SortProfits)
	return ProfitCount, Profits 
end

function CalcResourceNeeds(BldAlias)
	local BldLevel = BuildingGetLevel(BldAlias)
	local Needs = {}
	local NeedCount = 0
	local Count, Items = state_twp_autocart_GetResourceNeeds(BldAlias)
	if Count <= 0 then
		return 0, {}
	end 
	for i = 1, Count do
		local CurrentAmount = GetItemCount(BldAlias, Items[i][1])
		local MaxNeed = Items[i][2] * (3 + BldLevel)
		local ActualNeed = MaxNeed - CurrentAmount
		-- need resources when stores down to 40%
		if MaxNeed > 0 and ActualNeed > 0 and ActualNeed/MaxNeed >= 0.4 then
			NeedCount = NeedCount + 1
			local InvSpace = GetImpactValue(BldAlias, "BonusSpace")
			Needs[NeedCount] = {Items[i][1], math.min(InvSpace, ActualNeed)}
		end
	end
	-- no current needs
	if NeedCount == 0 then
 		return 0, {}
 	end
 	
 	-- 4. sort by actual needs, highest first (SortProfits sorts highest first so it will do)
	Needs = helpfuncs_QuickSort(Needs, 1, NeedCount, state_twp_autocart_SortProfits)
	return NeedCount, Needs 
end

-- TODO move to library script, i.e. economy
function GetResourceNeeds(BldAlias)
	if (not BldAlias or not AliasExists(BldAlias)) then
		return 0, {} 
	end
	
	local BldId = BuildingGetProto(BldAlias)
	-- get values from DBT
	local ItemsString = GetDatabaseValue("BuildingToItems", BldId, "requireditems")
	local AmountsString = GetDatabaseValue("BuildingToItems", BldId, "requireditemusages")
	if ItemsString == nil or AmountsString == nil then
		return 0, {}
	end
	-- initialize return list
	local Items = {}
	local Ids = {}
	local Count = 0
	for Id in string.gfind(ItemsString, "%d+") do
		Count = Count + 1
		Ids[Count] = ItemGetID(Id)
	end
	local i = 0
	for Amount in string.gfind(AmountsString, "%d+") do
		i = i + 1
		Items[i] = { Ids[i], Amount }
	end
	return Count, Items
end

--- returns ProfitCount, Profits, CityAlias
function CalcProfitsOutside(HomeAlias)
	local Count = ScenarioGetObjects("Settlement", 20, "City")
	
	local ProfitCount, Profits, CityAlias
	for l=0,Count-1 do
		CityAlias = "City"..l
		if CityIsKontor(CityAlias) then
			if CityGetRandomBuilding(CityAlias, -1, GL_BUILDING_TYPE_KONTOR, -1, -1, FILTER_IGNORE, "SomeMarketBld") and not BuildingGetWaterPos("SomeMarketBld", true, "WaterPos") then
				CityGetLocalMarket(CityAlias, "Market"..l)
				ProfitCount, Profits = state_twp_autocart_CalcProfits("Market"..l, HomeAlias)
				if ProfitCount > 0 then 
					return ProfitCount, Profits, CityAlias
				end
			end
		else -- regular settlement
			CityGetLocalMarket(CityAlias, "Market"..l)
			ProfitCount, Profits = state_twp_autocart_CalcProfits("Market"..l, HomeAlias)
			if ProfitCount > 0 then 
				return ProfitCount, Profits, CityAlias
			end
		end
	end
	
	return 0, {}, "MyCity"
end

-- unload at home and fill with dummy items (prevents AI from filling up the slots)
function UnloadItems(CartSlots, CartSlotSize, HomeAlias)
	RemoveItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD)
	for i = 1, CartSlots do
		local ItemId, ItemCount = InventoryGetSlotInfo("", CartSlots-i)
		if ItemId and ItemCount > 0 then
			if CanAddItems(HomeAlias, ItemId, ItemCount, INVENTORY_STD) then				
				Transfer("",HomeAlias,INVENTORY_STD,"",INVENTORY_STD, ItemId, ItemCount)
			else
				Transfer("",HomeAlias,INVENTORY_SELL,"",INVENTORY_STD, ItemId, ItemCount)
			end
		end 
	end
	AddItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD) 
end

function SortProfits(a,b) 
	return a[2] > b[2] 
end

function CleanUp()
	local CartSlots, CartSlotSize = cart_GetCartSlotInfo("")
	RemoveItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD)
end
