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
		local BuildingType = BuildingGetProto("MyHome")
		local Count, Items = economy_GetProducedItems("MyHome")
		for i = 1, Count do
			if Items[i] == 360 or Items[i] == 360 or Items[i] == 364 or Items[i] == 365 or Items[i] == 371 then
				Items[i] = { Items[i], 30 }
			else
				Items[i] = { Items[i], 0 }
			end
		end
	
		-- 3. Calculate expected profit for each item
		local CityAlias = "MyCity"
		local ProfitCount, Profits = 0, {}
		if Count and Count > 0 then
			CityGetLocalMarket("MyCity","MyMarket")
			ProfitCount, Profits = economy_CalcProfits("MyMarket", "MyHome", Count, Items, 400) 
			if ProfitCount <= 0 then
				ProfitCount, Profits, CityAlias = state_twp_autocart_CalcProfitsOutside("MyHome", Count, Items)
			end 
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
		RemoveItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD)
		cart_LoadItems("", "MyHome", ProfitCount, Profits)
		AddItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD) 
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
		cart_LoadItems("", "MarketBld", NeedCount, Needs)
	end
	 
	-- fill up remaining space with dummy item
	AddItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD)
	Sleep(2)
end

function CalcResourceNeeds(BldAlias)
	local Count, Items = economy_GetResourceNeeds(BldAlias)
	if Count <= 0 then
		return 0, {}
	end 
	local NeedCount, Needs = economy_CalcCurrentResourceNeeds(BldAlias, Count, Items, 0.4)
	return NeedCount, Needs
end

--- returns ProfitCount, Profits, CityAlias
function CalcProfitsOutside(HomeAlias, ProductCount, Products)
	local Count = ScenarioGetObjects("Settlement", 20, "City")
	
	local ProfitCount, Profits, CityAlias
	for l=0,Count-1 do
		CityAlias = "City"..l
		if CityIsKontor(CityAlias) then
			if CityGetRandomBuilding(CityAlias, -1, GL_BUILDING_TYPE_KONTOR, -1, -1, FILTER_IGNORE, "SomeMarketBld") and not BuildingGetWaterPos("SomeMarketBld", true, "WaterPos") then
				CityGetLocalMarket(CityAlias, "Market"..l)
				ProfitCount, Profits = economy_CalcProfits("Market"..l, HomeAlias, ProductCount, Products, 500)  
				if ProfitCount > 0 then 
					return ProfitCount, Profits, CityAlias
				end
			end
		else -- regular settlement
			CityGetLocalMarket(CityAlias, "Market"..l)
			ProfitCount, Profits = economy_CalcProfits("Market"..l, HomeAlias, ProductCount, Products, 500)   
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

function CleanUp()
	local CartSlots, CartSlotSize = cart_GetCartSlotInfo("")
	RemoveItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD)
end
