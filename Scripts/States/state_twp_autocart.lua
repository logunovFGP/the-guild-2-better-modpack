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
		local Count, Items, ProtectedAmounts = economy_GetProducedItems("MyHome")
		for i = 1, Count do
			if ProtectedAmounts[i] then
				Items[i] = { Items[i], ProtectedAmounts[i] }
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
				ProfitCount, Profits, CityAlias = economy_CalcProfitsOutside("MyHome", Count, Items)
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
	AddItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD) 
	-- buy required resources
	if not NeedCount then -- may not be initialized yet
		NeedCount, Needs = state_twp_autocart_CalcResourceNeeds("MyHome")
	end
	state_twp_autocart_BuyResources(NeedCount, Needs, CityAlias, "MarketBld")
	Sleep(2)
end

function CalcResourceNeeds(BldAlias)
	local Count, Items = economy_GetResourceNeeds(BldAlias)
	if Count <= 0 then
		return 0, {}
	end 
	local NeedCount, Needs = economy_CalcCurrentResourceNeeds(BldAlias, Count, Items, 0.7)
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

function BuyResources(NeedCount, Needs, CurrentCityAlias, CurrentMarketAlias)
	if not NeedCount or NeedCount <= 0 then
		return
	end
	local CartSlots, CartSlotSize = cart_GetCartSlotInfo("")
	
	-- check local market first if we are somewhere else
	if GetID("MyCity") ~= GetID(CurrentCityAlias) then
		NeedCount, Needs = state_twp_autocart_MoveAndBuyItems(CurrentMarketAlias, CartSlots, CartSlotSize, NeedCount, Needs)
	end
	if NeedCount <= 0 or GetItemCount("", "EmptySlot") <= 0 then
		return
	end
	
	-- check own workshops
	GetDynasty("", "MyDyn")
	local BldCount = DynastyGetBuildingCount("MyDyn")
	for i=0, BldCount - 1 do
		if DynastyGetBuilding2("MyDyn", i, "Workshop") then
			NeedCount, Needs = state_twp_autocart_MoveAndBuyItems("Workshop", CartSlots, CartSlotSize, NeedCount, Needs)
		end
		if NeedCount <= 0 or GetItemCount("", "EmptySlot") <= 0 then
			return
		end
	end
	
	-- check home market
	if CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, "MyMarket") then
		NeedCount, Needs = state_twp_autocart_MoveAndBuyItems("MyMarket", CartSlots, CartSlotSize, NeedCount, Needs)
	end
	if NeedCount <= 0 or GetItemCount("", "EmptySlot") <= 0 then
		return
	end
	
	-- check other workshops at home
	local WorkshopAlias = "OtherWorkshop"
	local WorkshopCount = CityGetBuildings("MyCity", GL_BUILDING_CLASS_WORKSHOP, -1, -1, -1, FILTER_HAS_DYNASTY, WorkshopAlias)
	for i=0, WorkshopCount - 1 do
		WorkshopAlias = "OtherWorkshop"..i
		if GetDynastyID(WorkshopAlias) ~= GetDynastyID("") then
			NeedCount, Needs = state_twp_autocart_MoveAndBuyItems(WorkshopAlias, CartSlots, CartSlotSize, NeedCount, Needs)
		end
		if NeedCount <= 0 or GetItemCount("", "EmptySlot") <= 0 then
			return
		end
	end

	-- get other markets, but only if no items loaded at this point
	if GetItemCount("", "EmptySlot") < CartSlots*CartSlotSize then
		return
	end	
	local CityCount = ScenarioGetObjects("Settlement", 10, "OtherCity")
	for i = 0, CityCount - 1 do
		local Alias = "OtherCity"..i
		-- home city and current city have been checked before
		if GetID(Alias) ~= GetID(CurrentCityAlias) and GetID(Alias) ~= GetID("MyCity") then
			local MarketAlias = "OtherMarket"
			if not CityIsKontor(Alias) and CityGetRandomBuilding(Alias, -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, MarketAlias) then
				NeedCount, Needs = state_twp_autocart_MoveAndBuyItems(MarketAlias, CartSlots, CartSlotSize, NeedCount, Needs)
			end
			if NeedCount <= 0 or GetItemCount("", "EmptySlot") <= 0 then
				return
			end
		end
	end
end

function MoveAndBuyItems(Destination, CartSlots, CartSlotSize, NeedCount, Needs)
	if not economy_CheckAvailability(Destination, "", NeedCount, Needs) then
		return NeedCount, Needs
	end
	--state_twp_autocart_NotifyCurrentResourceOrder(Destination, NeedCount, Needs)
	
	if IsInLoadingRange("", Destination) or f_MoveTo("", Destination, GL_MOVESPEED_RUN) then
		RemoveItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD)
		NeedCount, Needs = cart_LoadItems("", Destination, NeedCount, Needs)
		AddItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD)
	end
	return NeedCount, Needs
end

function NotifyCurrentResourceOrder(Destination, NeedCount, Needs)
	local DestinationLabel, DestinationPlaceHolder
	if BuildingGetClass(Destination) == GL_BUILDING_CLASS_MARKET then
		-- use city name for markets
		DestinationLabel = GetSettlementID(Destination)
		DestinationPlaceHolder = "%2NAME"
	else
		-- use Building name
		DestinationLabel = GetID(Destination)
		DestinationPlaceHolder = "%2NAME"
	end
	local Msg = "Karren %3NAME von %1NAME fährt nach ".. DestinationPlaceHolder .." um zu einzukaufen:$N$N"
	local Labels = {}
	for i=1, NeedCount do
		Labels[i] = ItemGetLabel(Needs[i][1], false)
		Msg = Msg .. "$N"..Needs[i][2].." %"..(3+i).."l" -- Texts like: (linebreak) 20 Gold
	end
	
	CartGetOperator("", "Operator")
	MsgNewsNoWait("All", -- recipient
				"", -- jump to target
				"", -- panel params (buttons)
				"economie", -- message class
				-1, -- TimeOut 
				"Autocart", -- Header
				Msg, -- Body
				GetID("MyHome"), DestinationLabel, GetID("Operator"), helpfuncs_UnpackTable(Labels)) -- params
end

function CleanUp()
	local CartSlots, CartSlotSize = cart_GetCartSlotInfo("")
	RemoveItems("", "EmptySlot", CartSlots*CartSlotSize, INVENTORY_STD)
end
