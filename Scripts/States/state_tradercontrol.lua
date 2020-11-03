---
--  Here is what the script does:
-- Spawn trading carts and start measure "ms_WorldTrader" on them.
-- Keep track of any robberies on the carts.
-- Notify players when too many robberies have occured.
-- Stop trading for a while if robberies don't stop.
-- NOTE the corresponding script for ships is "state_marinecontrol.lua"

function Init()

end


function Run()
	if not BuildingGetCity("","MyCity") then
		return
	end

	if not HasProperty("", "TradersPlundered") then
		SetProperty("","TradersPlundered",0)
	end
	
	if not HasProperty("","TradersRobberMessageSaid") then
		SetProperty("","TradersRobberMessageSaid", 0)
	end
	
	if not HasProperty("", "TradersCartCount") then
		SetProperty("", "TradersCartCount", 0)
	end
	
	while true do -- check carts
		local CurrentCarts = GetProperty("", "TradersCartCount")
		if state_tradercontrol_CanBuyNewCart(CurrentCarts) then
			CurrentCarts = state_tradercontrol_BuyNewCart(CurrentCarts)
		else
			local CartID
			for i=1, CurrentCarts do
				CartID = GetProperty("", "TradersCart"..i)
				if CartID and GetAliasByID(CartID, "CurrentCart") then
					state_tradercontrol_CheckCart("CurrentCart")
				end
			end
		end			
		
		local MainPlunderCount = GetProperty("", "TradersPlundered")
		if MainPlunderCount > 4 then -- Too many robberies occured, stop trade for some time
			local Time = Rand(24) + 24
			AddImpact("", "TradingRoutePlundered", 1, Time) 
			MainPlunderCount = 0
			SetProperty("", "TradersPlundered", 0)
			SetProperty("", "TradersRobberMessageSaid", 0)			

			-- msg to all players;
			MsgNewsNoWait("All", "", "", "economie", -1, 
				"@L_KONTOR_TOOMANYROBBERIES_HEAD_+0", 
				"@L_KONTOR_TOOMANYROBBERIES_BODY_+1", GetID("MyCity")) 
			
		elseif MainPlunderCount > 2 and GetProperty("","TradersRobberMessageSaid") ~= 1 then
			MsgNewsNoWait("All", "", "", "economie", -1, 
				"@L_KONTOR_TOOMANYROBBERIES_HEAD_+0", 
				"@L_KONTOR_TOOMANYROBBERIES_BODY_+0", GetID("MyCity")) 
			SetProperty("", "TradersRobberMessageSaid", 1)
		end
		
		
		local CurrentRound = GetRound()
		if not HasProperty("", "LastTimeRobbed") then
			SetProperty("", "LastTimeRobbed", CurrentRound)
		end
		
		local LastTimeRobbed = GetProperty("","LastTimeRobbed")
		if CurrentRound - LastTimeRobbed > 2 then
			SetProperty("", "LastTimeRobbed", CurrentRound)	
			SetProperty("", "TradersPlundered", 0)
		end

		if MainPlunderCount == 0 then
			SetProperty("", "LastTimeRobbed", CurrentRound)
		end
		Sleep(37)
	end
end

function CheckCart(CurrentCart)
	local PlunderCount = GetProperty(CurrentCart, "BeingPlundered") or 0 -- update plundercount
	local MainPlunderCount = GetProperty("", "TradersPlundered") or 0
	if PlunderCount > 0 then
		MainPlunderCount = MainPlunderCount + PlunderCount
		SetProperty(CurrentCart, "BeingPlundered", 0)
		SetProperty("", "TradersPlundered", MainPlunderCount)
	end
	
	if GetState(CurrentCart, STATE_BUILDING) then
		return
	end
	
	if GetState(CurrentCart, STATE_DRIVERATTACKED) then
		return	
	end
	
	if GetCurrentMeasureName(CurrentCart) == "WorldTrader" then
		return
	end
	MeasureRun(CurrentCart, "", "WorldTrader", true)
end

function BuyNewCart(CartCount)
	local CityLevel = CityGetLevel("MyCity")

	local NewCartType = EN_CT_MIDDLE

	if CityLevel > 2 then
		NewCartType = EN_CT_OX
	end

	if CityLevel > 4 then
		NewCartType = EN_CT_HORSE
	end
	
	if GetOutdoorMovePosition(nil, "", "GroundPos") then
		if ScenarioCreateCart(NewCartType, nil, "GroundPos", "CartTrader") then
			if (GetOutdoorMovePosition("CartTrader", "", "GoodPos")) then
				SimBeamMeUp("CartTrader", "GoodPos", false) -- false added
			end
			SetEndlessMoney("CartTrader", true)
			SetProperty("CartTrader","BeingPlundered",0)
			CartCount = CartCount + 1
			SetProperty("", "TradersCartCount", CartCount)
			SetProperty("", "TradersCart"..CartCount, GetID("CartTrader"))
			MeasureRun("CartTrader", "", "WorldTrader", true)
		end
	end
	return CartCount
end

function CanBuyNewCart(CartCount)
	local CityLevel = CityGetLevel("MyCity") -- 1 for kontor, 2 and higher for regular settlements
	return (CartCount < CityLevel - 1) 
end


