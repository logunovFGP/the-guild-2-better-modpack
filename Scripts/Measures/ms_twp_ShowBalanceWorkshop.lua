--- 
-- TODOs for Salescounter rework:
-- * add income from services and theft to individual measure scripts
-- * add hiring fee to wages
-- 

BALANCE_PREFIX = "Balance"
--BALANCE_TYPES = {"Autoroute", "Salescounter", "Service"}
--BALANCE_SUFFIXES = {"", "Last", "Total"}

function Run()
	CopyAlias("","Workshop")
	
	-- initialize: turn off messages for workshop
	if not HasProperty("Workshop","MsgSell") then
		SetProperty("Workshop","MsgSell",0)
	end
	
--	-- DEBUG: Show current production priorities
--	local MsgBody = ""
--	local Count, Items = economy_GetItemsForSale("")
--	GetInventory("", INVENTORY_STD, "Inv") 
--	local Item, Need
--	for i = 1, Count do
--		Item = Items[i]
--		Need = GetProperty("Inv", "Need_"..Item) or 0
--		
--		MsgBody = MsgBody..ItemGetName(Item) .. ": " .. Need.."$N"
--	end
--	-- add lavender
--	Need = GetProperty("Inv", "Need_"..160) or 0
--	MsgBody = MsgBody..ItemGetName(160) .. ": " .. Need.."$N"
--		
--	MsgBox("", "Owner", "", "Prioritäten", MsgBody)
--	-- DEBUG END
--	
	-- differentiate rogue buildings
	local BldType = BuildingGetType("Workshop")
	if GL_BUILDING_TYPE_THIEF == BldType or GL_BUILDING_TYPE_ROBBER == BldType or GL_BUILDING_TYPE_PIRATESNEST == BldType then
		ms_twp_showbalanceworkshop_ShowForRogue("Workshop")
	else
		ms_twp_showbalanceworkshop_ShowForWorkshop("Workshop")
	end 
end

function ShowForWorkshop(BldAlias)
	local BalanceTypes = {"WaresSold", "WaresBought", "Service", "Wages", "TownSold"}
	local Balances = {}
	local TotalBalance = 0
	for i=1, 5 do
		Balances[i] = GetProperty(BldAlias, BALANCE_PREFIX..BalanceTypes[i]) or 0
		TotalBalance = TotalBalance + Balances[i]
	end
	
	local Wages = economy_CalculateWages(BldAlias)
	-- XXX unused for now
	local Ranking, RankingGoods, RankingCrafty, RankingCharisma, Attractivity = economy_CalculateSalesRanking(BldAlias)
	
	-- add extra button to choose pricing
	
	-- buttons for more information about (1) current attractivity and (b) current prices  
	local Choice = MsgBox("dynasty", BldAlias,
			"@B[CLR,@L_MEASURE_SHOWBALANCE_SHEET_CLEARBALANCE_+0,]"
			--"@B[ATTR,@L_MEASURE_SHOWBALANCE_SHEET_ATTRACTIVITY_+0,]".."@B[PRIC,@L_MEASURE_SHOWBALANCE_SHEET_PRICES_+0,]"
			, 
			"@L_MEASURE_SHOWBALANCE_SHEET_HEAD_+0",
			"@L_MEASURE_SHOWBALANCE_SHEET_BODY_+1",
			GetID(BldAlias), -- %1GG
			TotalBalance, -- %2t total balance
			Wages, -- %3t Wages per round
			--Ranking, -- %4i Ranking
			Balances[1], -- %4t WaresSold 
			Balances[2], -- %5t WaresBought 
			Balances[3], -- %6t Service
			Balances[4], -- %7t Wages
			Balances[5] -- %8t TownSold
			--, PriceRatio -- %8i%% current PriceRatio
			)
	if Choice == "ATTR" then
		MsgBoxNoWait("dynasty", BldAlias,
			"@L_MEASURE_SHOWBALANCE_SHEET_ATTRACTIVITY_+0",
			"@L_MEASURE_SHOWBALANCE_SHEET_ATTRACTIVITY_+1",
			Ranking, RankingCharisma, RankingCrafty, RankingGoods, Attractivity
			)
	elseif Choice == "PRIC" then
		ms_twp_showbalanceworkshop_ChangePriceRatio(BldAlias)
	elseif Choice == "CLR" then
		for i=1, 5 do
			SetProperty(BldAlias, BALANCE_PREFIX..BalanceTypes[i], 0) 
		end
		ms_twp_showbalanceworkshop_ShowForWorkshop(BldAlias)
	end
end

function ShowForRogue(BldAlias)
	local BalanceTypes = {"WaresSold", "WaresBought", "Theft", "Wages", "Service"}
	local Balances = {}
	local TotalBalance = 0
	for i=1, 5 do
		Balances[i] = GetProperty(BldAlias, BALANCE_PREFIX..BalanceTypes[i]) or 0
		TotalBalance = TotalBalance + Balances[i]
	end
	local TheftBalance = Balances[3] + Balances[5] -- add service balance to theft
	
	local Wages = economy_CalculateWages(BldAlias)
	-- XXX unused for now
	local Ranking, RankingGoods, RankingCrafty, RankingCharisma, Attractivity = economy_CalculateSalesRanking(BldAlias)
	
	-- add extra button to choose pricing
	
	-- buttons for more information about (1) current attractivity and (b) current prices  
	local Choice = MsgBox("dynasty", BldAlias,
			"@B[CLR,@L_MEASURE_SHOWBALANCE_SHEET_CLEARBALANCE_+0,]"
			--"@B[ATTR,@L_MEASURE_SHOWBALANCE_SHEET_ATTRACTIVITY_+0,]".."@B[PRIC,@L_MEASURE_SHOWBALANCE_SHEET_PRICES_+0,]"
			, 
			"@L_MEASURE_SHOWBALANCE_SHEET_HEAD_+0",
			"@L_MEASURE_SHOWBALANCE_SHEET_BODY_+1",
			GetID(BldAlias), -- %1GG
			TotalBalance, -- %2t total balance
			Wages, -- %3t Wages per round
			--Ranking, -- %4i Ranking
			Balances[1], -- %4t WaresSold 
			Balances[2], -- %5t WaresBought 
			TheftBalance, -- %6t Theft
			Balances[4] -- %7t Wages
			--, PriceRatio -- %8i%% current PriceRatio
			)
	if Choice == "ATTR" then
		MsgBoxNoWait("dynasty", BldAlias,
			"@L_MEASURE_SHOWBALANCE_SHEET_ATTRACTIVITY_+0",
			"@L_MEASURE_SHOWBALANCE_SHEET_ATTRACTIVITY_+1",
			Ranking, RankingCharisma, RankingCrafty, RankingGoods, Attractivity
			)
	elseif Choice == "PRIC" then
		ms_twp_showbalanceworkshop_ChangePriceRatio(BldAlias)
	elseif Choice == "CLR" then
		for i=1, 5 do
			SetProperty(BldAlias, BALANCE_PREFIX..BalanceTypes[i], 0) 
		end
		ms_twp_showbalanceworkshop_ShowForRogue(BldAlias)
	end
end

function ChangePriceRatio(BldAlias)
  local PriceRatio = GetProperty(BldAlias, "SalescounterPrice") or 150
  local Buttons = "@B[100,@L_MEASURE_SHOWBALANCE_SHEET_PRICES_OPTION_+0,]"
  	.."@B[125,@L_MEASURE_SHOWBALANCE_SHEET_PRICES_OPTION_+1,]"
  	.."@B[150,@L_MEASURE_SHOWBALANCE_SHEET_PRICES_OPTION_+2,]"
  	.."@B[175,@L_MEASURE_SHOWBALANCE_SHEET_PRICES_OPTION_+3,]"
  	.."@B[200,@L_MEASURE_SHOWBALANCE_SHEET_PRICES_OPTION_+4,]"
  
	local Choice = MsgBox(
		BldAlias, -- building
		BldAlias, -- jump to target
		"@P"..Buttons,
		"@L_MEASURE_SHOWBALANCE_SHEET_HEAD_+0",
		"@L_MEASURE_SHOWBALANCE_SHEET_PRICES_BODY_+0",
		PriceRatio -- params)
	)
	if (Choice and Choice ~= "C" and Choice >= 100) then
		SetProperty(BldAlias, "SalescounterPrice", Choice)
	end
end

