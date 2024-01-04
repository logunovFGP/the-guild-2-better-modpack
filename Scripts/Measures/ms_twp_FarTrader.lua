--- 
-- Base concept of far traders:
-- 
-- * Cart measure for warehouse and markets. 
-- * The measure is initialized with Item and Budget.
-- * The cart will leave the map through the nearest MapExit and return some time later.
-- * On return the cart is loaded with requested items up to the given budget.
-- * Prices for the aquired items will depend on baseprice (not market) and on bargaining skill.
-- * The measure may be set to repeat on regular basis (only warehouse). 
--  
-- 

function Init()
	if IsAIDriven() then
		-- AI needs to specify data beforehand with: 
		-- MeasureAddData("Measure", "Item", ItemIdOrName)
		-- MeasureAddData("Measure", "Budget", Budget)
		return
	end
	
	-- Display dialogs to select item and budget.
	
	SetData("Item", "WheatFlour")
	SetData("Budget", 2000)
end

function Run()
	local Item = GetData("Item")
	local Budget = GetData("Budget")
	if not Item or not Budget then
		-- not nough data supplied, stop measure
		return
	end
	
	Item = ItemGetID(Item) -- make sure we have the ID and not the name (allows measure to be started with either)

	-- find home (either warehouse or market)
	MsgDebugMeasure("Looking for my home")
	local HomeAlias, HomePos = "MyHome", "HomePos"
	local IsMarket = false
	local DynastyID = GetDynastyID("") or -1
	if DynastyID > 0 then
		if not GetHomeBuilding("", HomeAlias) then
			LogMessage("TWP::FarTrader No home found, aborting measure.")
			return
		end
		GetOutdoorMovePosition("", HomeAlias, HomePos)
	else
		-- home is a market, check custom owner property (ID of market)
		IsMarket = true
		local HomeID = GetProperty("", "TWP_HomeBuilding")
		if not HomeID then
			LogMessage("TWP::FarTrader No home found for free cart, aborting measure.")
			return
		end
		GetAliasByID(HomeID, HomeAlias)
		GetSettlement(HomeAlias, "MyCity")
		if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, "MarketBld") then
			LogMessage("TWP::FarTrader Could not get market building for settlement %1NAME, aborting measure.", GetID("MyCity"))
		end
		GetOutdoorMovePosition("", "MarketBld", HomePos)
	end
	
	-- initialize cart data
	local CartSlots, CartSlotSize = cart_GetCartSlotInfo("")
	if CartSlots <= 0 then
		LogMessage("TWP::FarTrader Could not get cart data, aborting measure.")
		return
	end

	-- if the measure is GUIDriven, it may be repeated. Otherwise the loop ends with "return".	
	while true do -- aborts on failures
		-- 1. Find a map exit and go there. Disable cancel button for the meantime.
		MsgDebugMeasure("Going to the map exit.")
		local FoundExit = f_GetNearestMapExit("", "NearestExit")
		if not FoundExit then
			LogMessage("TWP::FarTrader No map exit found, aborting measure.")
			MsgQuick("All", "TWP::FarTrader No map exit found, aborting measure.")			
-- TODO for GUIDriven measure notify player
			return
		end
		if not f_MoveTo("", "NearestExit", GL_MOVESPEED_RUN) then
			GetScenario("World")
			SetProperty("World", "BrokenMapExit"..FoundExit)
			LogMessage("TWP::FarTrader Unable to reach map exit, aborting measure.")
			MsgQuick("All", "TWP::FarTrader Unable to reach map exit, aborting measure.")
			-- TODO for GUIDriven measure notify player
			return
		end
		
		-- disappear
		MsgDebugMeasure("Disappearing to shop.")
		SetState("", STATE_DUEL, true)
		SetInvisible("", true)
		AddImpact("", "Hidden", 1 , -1) 
		
		-- 2. Sleep for some time, partly random. 4 < t < 8
		local HoursToWait = 4 + Rand(5)
		-- TODO change back to: * 60
		Sleep(HoursToWait * 60)
		
		-- 3. Calculate the amount of items that can be bought with given budget
		local Price = ItemGetBasePrice(Item) * 1.5
		local BargainingCheck = 0
		if not IsMarket then
			BuildingGetOwner(HomeAlias, "MyBoss")
			local Difficulty = ScenarioGetDifficulty()
			BargainingCheck = chr_SkillCheck("MyBoss", BARGAINING, Difficulty, nil, nil, true) -- returns boolean
			if BargainingCheck then
				BargainingCheck = GetSkillValue("MyBoss", BARGAINING)
			end
			Budget = math.min(Budget, GetMoney("MyBoss"))
		end
		
		-- BargainingCheck ranges from -1..3 and will decrease price by 25% per point
		local TheBargain = 1 + (BargainingCheck * -0.25)
		Price = math.ceil(Price * TheBargain)
		local Amount = math.floor(Budget / Price)
		local PrevAmount = GetItemCount("", Item) or 0
		AddItems("", Item, Amount)
		if not IsMarket then
			local ActualAmount = GetItemCount("", Item) - PrevAmount
			local ActualPrice = ActualAmount * Price
			chr_SpendMoney("", ActualPrice, "WaresBought", true)
		end

		-- 4. Go home.
		MsgDebugMeasure("Returning home.")
		SetState("",	STATE_DUEL,	false)
		SetInvisible("", false)
		RemoveImpact("","Hidden") 
		
		if not f_MoveTo("", HomePos, GL_MOVESPEED_RUN) then
			SimBeamMeUp("", HomePos, false)
			LogMessage("TWP::FarTrader Could not return home, aborting measure.")
			return
		end
	
		-- 5. Unload all items.
		cart_UnloadAll("", HomeAlias)
		Sleep(5)
		
		if not IsGUIDriven() then
			return
		end
		Sleep(42)
	end
end

function CleanUp()
	RemoveData("Item")
	RemoveData("Budget")
	RemoveAlias("MyHome")
	RemoveAlias("HomePos")
	
	SetState("",	STATE_DUEL,	false)
	SetInvisible("", false)
	RemoveImpact("","Hidden") 
end
