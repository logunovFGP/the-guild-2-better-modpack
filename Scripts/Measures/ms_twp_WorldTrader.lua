--- 
-- Base concept of neutral traders in TWP:
-- 
-- * Each settlement owns a number of trader carts (1 per city level).
-- * Traders travel only in star shape from home settlement (home, target, home, other target, ...)
--     * Trader only buys resources and needed items when afar.
--     * Trader only takes items from own market when above max stock.
-- * Each market calculates the current resource needs once per day.
--     * Based on workshops in town (aggregated CalcResourceNeed for each workshop against current stock).
--     * Five most needed resources are written to property as list. (optional: 1 non-resource is also added to list)
--     * Sales Prices for these resources are increased and all players are notified (see kontor event). 
--  
-- 

function Init()
end

function Run() 
	-- find home: destination should be a market building
	if not AliasExists("Destination") and not GetHomeBuilding("", "Destination") then
		LogMessage("TWP::WorldTrader No destination given, aborting measure.")
		return
	end
	
	if not GetSettlement("Destination", "MyCity") then
		LogMessage("TWP::WorldTrader Could not get alias for settlement, aborting measure.")
		return
	end
	
	-- get home market
	local HomeMarket = "HomeMarket"
	if cart_IsShip("") then
		if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_HARBOR, -1, -1, FILTER_IGNORE, HomeMarket) then
			LogMessage("TWP::WorldTrader Could not get harbor for settlement %1NAME, aborting measure.", GetID("MyCity"))
			return
		end
	else
		if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, HomeMarket) then
			LogMessage("TWP::WorldTrader Could not get market for settlement %1NAME, aborting measure.", GetID("MyCity"))
			return
		end
	end
	
	-- initialize cart data
	local CartSlots, CartSlotSize = cart_GetCartSlotInfo("")
	if CartSlots <= 0 then
		LogMessage("TWP::WorldTrader Could not get cart data, aborting measure.")
		return
	end
	
	-- initialize other markets
	local CityCount = ScenarioGetObjects("Settlement", 20, "City")
	local MarketCount = 0
	local Markets = {}
	for i = 0, CityCount - 1 do
		local Alias = "City"..i
		if GetID(Alias) ~= GetID("MyCity") then
			local MarketAlias = "Market"..(MarketCount + 1)
			if cart_IsShip("") then
				if CityIsKontor(Alias) and CityGetRandomBuilding(Alias, -1, GL_BUILDING_TYPE_KONTOR, -1, -1, FILTER_IGNORE, MarketAlias) and BuildingGetWaterPos(MarketAlias, true, "WaterPos") then
					MarketCount = MarketCount + 1
					Markets[MarketCount] = MarketAlias
				elseif CityGetRandomBuilding(Alias, -1, GL_BUILDING_TYPE_HARBOR, -1, -1, FILTER_IGNORE, MarketAlias) then
					MarketCount = MarketCount + 1
					Markets[MarketCount] = MarketAlias
				end
			else
				if CityIsKontor(Alias) then
					if CityGetRandomBuilding(Alias, -1, GL_BUILDING_TYPE_KONTOR, -1, -1, FILTER_IGNORE, MarketAlias) and not BuildingGetWaterPos(MarketAlias, true, "WaterPos") then
						MarketCount = MarketCount + 1
						Markets[MarketCount] = MarketAlias
					end
				elseif CityGetRandomBuilding(Alias, -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, MarketAlias) then
					MarketCount = MarketCount + 1
					Markets[MarketCount] = MarketAlias
				end
			end
		end
	end
	for i=1, MarketCount do
		LogMessage("WorldTrader ID: "..GetID("").." knows market: " .. GetName(Markets[i]) .. ", ID: " .. GetID(Markets[i]))
	end
	
	while true do -- aborts on failures
		
		if not AliasExists(HomeMarket) then
			break
		end
		
		-- 1. Go home.
		if not IsInLoadingRange("", HomeMarket) and not f_MoveTo("", HomeMarket, GL_MOVESPEED_RUN) then
			LogMessage("TWP::WorldTrader Could not move to home market of settlement %1NAME, aborting measure.", GetID("MyCity"))
			return
		end
	
		-- 2. Unload all items.
		cart_UnloadAll("", HomeMarket)
		
		-- 3. Load some items that are above max for sale
		-- items for sale should be calculated once per day by market, call economy script instead
		local SalesCount, SalesItems = economy_GetSalesForMarket("MyCity")
		cart_LoadItems("", HomeMarket, SalesCount, SalesItems)
		
		-- 4. Get current resource needs.
		local NeedCount, Needs = economy_GetNeedsForMarket("MyCity")
		local Target = nil
		if SalesCount > 0 and NeedCount <= 0 then
			-- just go and sell some goods
			local RandomTarget = Rand(MarketCount) + 1
			Target = Markets[RandomTarget]
		end
		
		-- 5. Find possible source for resources.
		for i = 1, MarketCount do
			if economy_CheckAvailability(Markets[i], "", NeedCount, Needs) then
				Target = Markets[i]
				break
			end
		end
		
		-- (5b) If no other market offers resources, sell products anyway
		if not Target then
			local RandomTarget = Rand(MarketCount) + 1
			Target = Markets[RandomTarget]
		end
		
		-- 6. Go to target market, sell loaded items and load needs.
		if Target and AliasExists(Target) then
			--cart_NotifyRoute("", HomeMarket, Target)
			if f_MoveTo("", Target, GL_MOVESPEED_RUN) then
				cart_UnloadAll("", Target)
				cart_LoadItems("", Target, NeedCount, Needs)
			end
			--cart_NotifyRoute("", Target, HomeMarket) -- will return at beginning of loop, but current location is only known until this point
		end
		
		while GetImpactValue("", "WaitTime") > 0 do
			Sleep(10)
		end
	end
end

function CleanUp()
end
