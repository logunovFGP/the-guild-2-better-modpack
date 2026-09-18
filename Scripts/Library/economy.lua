-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching
end

PREFIX_SALESCOUNTER = "Salescounter_"
PREFIX_SALESCOUNTER_MAX = "SalescounterMax_"
SALESCOUNTER_PRICE = "SalescounterPrice"
 
---- returns count and the list of items (by itemId) that are being offered at this workshop. See INVENTORY_SELL
function GetItemsForSale(BldAlias)
	if (not BldAlias or not AliasExists(BldAlias)) then
		return 0, {} 
	end
	
	local Count, Items = 0, {}
	local SlotCount = InventoryGetSlotCount(BldAlias, INVENTORY_SELL)
	local ItemId, Amount
	for i = 0, SlotCount - 1 do
		ItemId, Amount = InventoryGetSlotInfo(BldAlias, i, INVENTORY_SELL)
		if ItemId and ItemId > 0 and Amount > 0 then
			Count = Count + 1
			Items[Count] = ItemId
		end
	end
	return Count, Items
end

---- returns count and the list of items (by itemId) that can be sold at this workshop. See BuildingToItems.dbt
function GetProducedItems(BldAlias)
	if (not BldAlias or not AliasExists(BldAlias)) then
		return 0, {}, {}
	end
	
	local BldId = BuildingGetProto(BldAlias)
	local ItemsString, ProtectedAmountsString
	-- production buildings may only offer their own products
	ItemsString = GetDatabaseValue("BuildingToItems", BldId, "produceditems")
	ProtectedAmountsString = GetDatabaseValue("BuildingToItems", BldId, "protectedproducts")
	if ItemsString == nil then
		return 0, {}, {}
	end
	
	local Count, Products = helpfuncs_StringToIdList(ItemsString)
	local _, ProtectedAmounts = helpfuncs_StringToIdList(ProtectedAmountsString)
	return Count, Products, ProtectedAmounts
end

-- Count and Items should be taken from above function GetItemsForSale
-- TODO this function is currently unused. It may be used to manage salescounter.
function UpdateSalescounter(BldAlias, Count, Items)
	if not Items then
		Count, Items = economy_GetItemsForSale(BldAlias)
	end

	local Id, CurrentAmount, Max, Inv, Diff, Transfered
	for i=1, Count do
		Id = ItemGetID(Items[i])
		Max = GetProperty(BldAlias, PREFIX_SALESCOUNTER_MAX..Id)
		if Max == nil then
			Max = 0
		end		
		CurrentAmount = GetProperty(BldAlias, PREFIX_SALESCOUNTER..Id)
		if CurrentAmount == nil then
			CurrentAmount = 0
		end
		Diff = Max - CurrentAmount
		if Diff > 0 then
			-- transfer to sales counter
			Transfered = RemoveItems(BldAlias, Id, Diff)
			SetProperty(BldAlias, PREFIX_SALESCOUNTER..Id, CurrentAmount + Transfered)
		elseif Diff < 0 and CanAddItems(BldAlias, Id, math.abs(Diff)) then
			-- transfer from counter to production
			AddItems(BldAlias, Id, math.abs(Diff))
			SetProperty(BldAlias, PREFIX_SALESCOUNTER..Id, Max)
		end
	end
end

--- Sales ranking is based on availability, charisma and craftmanship
-- It's currently not based on pricing since that depends on Bargaining
function CalculateSalesRanking(BldAlias, Count, Items)
	-- only applicable for owned shops 
	if not BuildingGetOwner(BldAlias, "Boss") then
		return 0
	end
	
	if not Items then
		Count, Items = economy_GetItemsForSale(BldAlias)
	end
	
	-- availablity of goods is based on a default of four slots
	local AvailableGoods = 0
	local Tmp
	for i=1, Count do
		Tmp = GetItemCount(BldAlias, Items[i], INVENTORY_SELL) 
		if Tmp ~= nil and Tmp > 0 then
			AvailableGoods = AvailableGoods + 1
		end
	end
	-- 10 points for each available item (up to 40)
	local RankingGoods = AvailableGoods * 10
	-- hospital and bankhouse are more attractive based on available services
	if BuildingGetType(BldAlias) == GL_BUILDING_TYPE_HOSPITAL then
		local MedCount = 0
		for Id in string.gfind("360 364 365 371", "%d+") do
			if GetItemCount(BldAlias, Id) > 0 then
				MedCount = MedCount + 1
			end 
		end
		RankingGoods = RankingGoods/2 + MedCount * 10
	elseif BuildingGetType(BldAlias) == GL_BUILDING_TYPE_BANKHOUSE and HasProperty(BldAlias, "KreditKonto") then
		RankingGoods = RankingGoods/2 + 20
	end
	
	-- use craftmanship or secret knowledge, depending on class 
	local Crafty
	if SimGetClass("Boss") == GL_CLASS_SCHOLAR then
		Crafty = GetSkillValue("Boss", SECRET_KNOWLEDGE)
	else
		Crafty = GetSkillValue("Boss", CRAFTSMANSHIP)
	end 
	local RankingCrafty = (math.min(12, Crafty) * 4) 
	
	local Charisma = GetSkillValue("Boss", CHARISMA)
	local RankingCharisma = (math.min(12, Charisma) * 4) 
	
	-- goods <= 40; crafty <= 48; charisma <= 48
	local Ranking = RankingGoods + RankingCrafty + RankingCharisma

	local Attractivity = GetImpactValue(BldAlias,"Attractivity")
	if Attractivity then
		Ranking = Ranking + Ranking * Attractivity
	end
	
	-- pricing gives bonus/penalty on total ranking 
	local Pricing = GetProperty(BldAlias, SALESCOUNTER_PRICE) or 100 -- 100, 125, 150, 175, 200
	local PricingBonus = 100 + (150 - Pricing)/2 -- 125, 112.5, 100, 87.5, 75
	Ranking = math.floor(Ranking * PricingBonus / 100)
	
	SetProperty(BldAlias, "SalescounterRanking", Ranking)
	return Ranking, RankingGoods, RankingCrafty, RankingCharisma, Attractivity
end

function GetRandomBuildingByRanking(CityAlias, ResultAlias, MinRanking, Type, MinLevel)
	MinRanking = MinRanking or 0
	Type = Type or -1
	MinLevel = MinLevel or 0
	local Count = CityGetBuildings(CityAlias, GL_BUILDING_CLASS_WORKSHOP, Type, -1, -1, FILTER_HAS_DYNASTY, "Result")
	
	-- calculated weighted choice
	local Ranking
	local RankingSum = 0
	for i = 0, Count-1 do
		if AliasExists("Result"..i) and BuildingGetLevel("Result"..i) >= MinLevel then
			Ranking = GetProperty("Result"..i, "SalescounterRanking") or 1
			if Ranking and Ranking >= MinRanking then
				RankingSum = RankingSum + Ranking 
			end
		end
	end
	if RankingSum <= 0 then
		return false
	end

	local Choice = Rand(RankingSum) + 1
	for i = 0, Count-1 do
		if AliasExists("Result"..i) and BuildingGetLevel("Result"..i) >= MinLevel then
			Ranking = GetProperty("Result"..i, "SalescounterRanking") or 1
			if Ranking and Ranking >= MinRanking  then
				Choice = Choice - Ranking 
			end
			if Choice <= 0 then
				CopyAlias("Result"..i, ResultAlias)
				return true
			end
		end
	end
	return false
end

-- Currently unused. Requires SalesCounter as property to work.
FILTER_BY_ITEM = "__F((Object.GetObjectsByRadius(Building)==%d)AND(Object.IsClass(2))AND(Object.Property.Salescounter_%d >= %d))"
function GetRandomBuildingByOfferedItem(ForAlias, ResultAlias, ItemId, Amount)
	Amount = Amount or 0
	local Radius = 15000
	local FilterByItem = string.format(FILTER_BY_ITEM, Radius, ItemId, Amount)
	local Count = Find(ForAlias, FilterByItem, "Result", 10)
	if Count > 0 then
		local x = Rand(Count)
		CopyAlias("Result"..x, ResultAlias)
		return GetProperty("Result"..x, PREFIX_SALESCOUNTER..ItemId)
	end
	return 0
end

--- Buy some random items from the workshop
-- returns ItemId, ItemCount, TotalPrice
-- TotalPrice will be below the given Budget
-- Count and Items are optional. Provide them if you've already got them
function BuyRandomItems(BldAlias, BuyerAlias, Budget, Max, Count, Items, IgnoreMoney)
	-- initialize optional Count, Items
	if not Count or not Items then
		Count, Items = economy_GetItemsForSale(BldAlias)
	end
	Budget = Budget or 0
	
	local ItemId, Available, ItemPrice, ItemCount
	for i=1, Count do
		ItemId = Items[Rand(Count) + 1]
		Available = GetItemCount(BldAlias, ItemId, INVENTORY_SELL)
		if Available and Available > 0 then
			local MaxCount = math.min(Max, economy_ProtectSaleItems(BldAlias, ItemId, Available))
			if MaxCount > 0 then
				ItemPrice = economy_GetPrice(BldAlias, ItemId, BuyerAlias)
				ItemCount = math.min(Rand(MaxCount)+1, math.floor(Budget / ItemPrice))
				if ItemCount > 0 then
					ItemCount = RemoveItems(BldAlias, ItemId, ItemCount, INVENTORY_SELL)
					local TotalPrice = ItemCount * ItemPrice 
					CreditMoney(BldAlias, TotalPrice, "WaresSold")
					ShowOverheadSymbol(BldAlias, false, false, 0, "@L%1t", TotalPrice)
					economy_UpdateBalance(BldAlias, "WaresSold", TotalPrice, ItemId)
					if not IgnoreMoney then
						chr_SpendMoney(BuyerAlias, TotalPrice, "WaresBought")
						chr_UseBudget(BuyerAlias, 1, TotalPrice)
						LogMessage(GetName("").." bought random items for a price of "..TotalPrice)
					end
					return ItemId, ItemCount, TotalPrice
				end
			end
		end
	end
	return nil, 0, 0
end

--- Protects some items from outsales that are required for a building to function (Hospital)
PROTECTED_SALE_ITEMS = ".360.364.365.371."
function ProtectSaleItems(BldAlias, ItemId, Available)
	if BuildingGetType(BldAlias) == GL_BUILDING_TYPE_HOSPITAL then
		if string.find(PROTECTED_SALE_ITEMS, "."..ItemId..".", 1, true) then
			-- don't sell more than 20
			local MinStock = 20
			local Diff = Available - MinStock -- Item count above minimum
			return math.max(0, Diff) -- return 0 if negative Diff
		end
	end
	-- protect grog and sch�delbrand since they don't have sale values
	if ItemId == 935 or ItemId == 936 then
		return 0
	end
	-- no restriction, return all available items
	return Available
end

--- Buy some items from this workshop
-- Userful for inter-workshop trade
-- returns ItemCount, TotalPrice
function BuyItems(BldAlias, BuyerAlias, ItemId, DesiredAmount, BuyerInventory)
	ItemId = ItemGetID(ItemId) -- make sure it's the ID, not the name
	local Available = GetItemCount(BldAlias, ItemId, INVENTORY_SELL)
	local ItemPrice = economy_GetPrice(BldAlias, ItemId, BuyerAlias)
	local Affordable = math.floor(GetMoney(BuyerAlias) / ItemPrice)
	if Available > 0 and Affordable > 0 then
		local ItemCount = math.min(Available, Affordable, DesiredAmount)
		local TotalPrice = ItemCount * ItemPrice
		if chr_SpendMoney(BuyerAlias, TotalPrice, "WaresBought") then
			RemoveItems(BldAlias, ItemId, ItemCount, INVENTORY_SELL)
			CreditMoney(BldAlias, TotalPrice, "WaresSold")
			ShowOverheadSymbol(BldAlias, false, false, 0, "@L%1t", TotalPrice)
			economy_UpdateBalance(BldAlias, "WaresSold", TotalPrice, ItemId)
			if ItemCount > 0 and BuyerInventory then
				AddItems(BuyerAlias, ItemId, ItemCount, BuyerInventory)
			end
			return ItemCount, TotalPrice
		end
	end
	return 0, 0
end

--- calculates current price for offered item
-- Price is based on current market price and depends on Bargaining of Owner and Buyer 
function GetPrice(BldAlias, ItemId, Buyer)
	-- Piratengrog, Sch�delbrand
	if ItemId == 935 then
		return 35
	elseif ItemId == 936 then
		return 60
	end

	if not GetSettlement(BldAlias, "MyCity") then
		return -1
	end
	if not BuildingGetOwner(BldAlias, "BldOwner") then
		return -1
	end

	local BasePrice = GetAccessPriceTake(BldAlias, "", ItemId, 1, INVENTORY_SELL)
	if not BasePrice or BasePrice <= 0 then
		BasePrice = ItemGetBasePrice(ItemId)
		local level = BuildingGetAISetting(BldAlias, "BuySell_PriceLevel")
		local ratio = 1.0
		if level == 0 then ratio = 0.5
		elseif level == 1 then ratio = 0.75
		elseif level == 3 then ratio = 1.25
		elseif level == 4 then ratio = 1.5
		end
		BasePrice = BasePrice * ratio
	end
	
	-- get difference in bargaining between Owner and Buyer
	local BargOwner = GetSkillValue("BldOwner", BARGAINING)
	local TheBargain
	if Buyer and AliasExists(Buyer) then
		local BargBuyer = GetSkillValue(Buyer, BARGAINING)
		TheBargain = (BargOwner - BargBuyer) * 0.03
	else
		TheBargain = BargOwner * 0.03
	end
	if TheBargain < -0.3 then TheBargain = -0.3 end
	if TheBargain > 0.25 then TheBargain = 0.25 end
	
	-- this will result in a range of about 70..110% of the calculated price
	return math.floor((BasePrice * 0.9) + (BasePrice * TheBargain)) 
end

-- known suffixes: Salescounter, Autoroute, Wages, Service, Theft
function UpdateBalance(BldAlias, BalanceSuffix, TotalPrice, ItemId, Amount)
	local Current = GetProperty(BldAlias, "Balance"..BalanceSuffix) or 0
	SetProperty(BldAlias, "Balance"..BalanceSuffix, Current + TotalPrice)
	
	-- TODO update balance by round, removing properties that are older than two rounds
	-- or better/easier: give an option to clear the balance sheet
	
	-- logging
	--MsgBoxNoWait(BldAlias, BldAlias, "Balance updated", "The balance for "..BalanceSuffix.." was updated, difference is "..TotalPrice)
end


--- "Enable", 
-- "BuySell", 
-- "BuySell_Selection", 
-- "BuySell_Radius", 
-- "BuySell_Stock", 
-- "BuySell_PriceLevel", 
-- "BuySell_SellStock", 
-- "BuySell_Carts", 
-- "Workers", 
-- "Workers_Quality", 
-- "Workers_Favor", 
-- "Budget", 
-- "Budget_Repair", 
-- "Budget_Upgrades"
function LogAISettings(BldAlias)
	LogMessage("::TOM:: Logging AI Settings")
	local SettingTable = { "Enable", "Produce", "Produce_Selection", "Produce_Stock", "BuySell", "BuySell_Radius", "BuySell_PriceLevel", "BuySell_SellStock", "BuySell_Carts", "Workers", "Workers_Quality", "Workers_Favor", "Budget", "Budget_Repair", "Budget_Upgrades" }
	local Setting
	for i = 1, 15 do
		Setting = SettingTable[i]
		LogMessage(Setting.." = "..BuildingGetAISetting(BldAlias, Setting))
	end
end

function LogProductionNeeds(BldAlias)
	LogMessage("::TWPECONOMY:: Logging AI Settings")
	local Count, Items = economy_GetProducedItems(BldAlias)
	GetInventory(BldAlias, INVENTORY_STD, "Inv") 
	
	local Item, Need
	for i = 1, Count do
		Item = Items[i]
		Need = GetProperty("Inv", "Need_"..Item) or 0
		LogMessage(ItemGetName(Item) .. ": " .. Need)
	end
end

--- Salescounter for AI will default to 
function InitializeDefaultSalescounter(BldAlias, Count, Items)
	if not GetSettlement(BldAlias, "MyCity") then
		return -1
	end
	if not BuildingGetOwner(BldAlias, "BldOwner") then
		return -1
	end

	-- get market
	CityGetLocalMarket("MyCity","MyMarket")

	-- initialize optional Count, Items
	if not (Count and Items) then
		Count, Items = economy_GetProducedItems(BldAlias)
	end

	local Budget = BuildingGetLevel(BldAlias) * 600
	local ItemId, MarketPrice, Max
	for i=1, Count do
		ItemId = ItemGetID(Items[i])
		MarketPrice = ItemGetPriceSell(ItemId, "MyMarket")
		if ItemId and ItemId > 0 and MarketPrice and MarketPrice > 0 then
			Max = math.floor(Budget / MarketPrice)
			SetProperty(BldAlias, PREFIX_SALESCOUNTER_MAX..ItemId, Max)
		end 
	end
	-- set ratio for sales price, default to 150% of base price
	SetProperty(BldAlias, SALESCOUNTER_PRICE, 150)
end

function CalculateWages(BldAlias)
	-- wages
	local numFound = 0
	local Alias
	local count = BuildingGetWorkerCount(BldAlias)

	for number=0, count-1 do
		Alias = "Worker"..numFound
		if BuildingGetWorker(BldAlias, number, Alias) then
			numFound = numFound + 1
		end
	end
	local Wages = 0
	if numFound > 0 then
		for i=0, numFound-1 do
			Alias = "Worker"..i
			Wages = Wages + SimGetWage(Alias, BldAlias)
		end
	end
	return Wages
end

function ChooseItemFromCounter(BldAlias, Count, Items)
	--LogMessage("TOM::economy::ChooseItemFromCounter starting")
	-- initialize optional Count, Items
	if not Count or not Items then
		Count, Items = economy_GetItemsForSale(BldAlias)
	end
	
	local Buttons = ""
	local CurrentAmount, MaxAmount, Id, ItemTexture, ItemLabel, Subtext, Price, PriceLabel
	local Prices = {}
	for i=1, Count do
		Id = ItemGetID(Items[i])
		Prices[i] = economy_GetPrice(BldAlias, Id)
		PriceLabel = "%"..i.."t"
		-- Appending the itemID finding the items again and even enables filters on the property
		--CurrentAmount = GetItemCount(BldAlias, Id, INVENTORY_SELL)
		--MaxAmount = GetImpactValue(BldAlias, "BonusSpace")
		CurrentAmount = GetProperty(BldAlias, PREFIX_SALESCOUNTER..Id) or 0
    MaxAmount = GetProperty(BldAlias, PREFIX_SALESCOUNTER_MAX..Id) or 0
		ItemTexture = "Hud/Items/Item_"..ItemGetName(Items[i])..".tga"
		-- result, Tooltip, label, icon
		ItemLabel = ItemGetLabel(Items[i], CurrentAmount == 1)
		Subtext = CurrentAmount
		Buttons = Buttons.."@B[" .. Id .. "," .. Subtext .. "," .. PriceLabel .. "," .. ItemTexture .."]"
	end
	-- add extra button if warehouse and Count < 16
	if GL_BUILDING_TYPE_WAREHOUSE == BuildingGetType(BldAlias) and Count < 16 then
		Buttons = Buttons.."@B[" .. -1 .. ",,,hud/buttons/btn_220_Train.tga]"
	end
	
	local ChosenItemId = InitData(
		"@P"..Buttons, -- PanelParam
		0, -- AIFunc
		"@L_MEASURE_SALESCOUNTER_HEAD_+0",-- HeaderLabel
		"Body",-- BodyLabel (obsolete)
		helpfuncs_UnpackTable(Prices)
		)-- optional variable list
	
	if ChosenItemId == "C" then
		return nil, 0
	end
	local Amount = GetProperty(BldAlias, PREFIX_SALESCOUNTER..ChosenItemId) or 0
	return ChosenItemId, Amount
end

---
-- returns ItemId, AvailableAmount
function ChooseItemFromInventory(BldAlias, PlayerAlias)
	--LogMessage("TOM::economy::ChooseItemFromInventory starting")
	-- not my own building and not market, use sales counter
	if GetDynastyID(PlayerAlias) ~= GetDynastyID(BldAlias) and BuildingGetClass(BldAlias) ~= GL_BUILDING_CLASS_MARKET then
		return economy_ChooseItemFromCounter(BldAlias)
	end
	
	local zSlots = InventoryGetSlotCount(BldAlias,INVENTORY_STD)
	-- market with too many slots, use Market function with pre-selected category
	if BuildingGetClass(BldAlias) == GL_BUILDING_CLASS_MARKET and zSlots > 20 then 
		return economy_ChooseItemFromMarket(BldAlias, PlayerAlias)
	end
	
	local itemInfo = {}	
	local schalter = ""
	local ItemLabel, ItemTexture, itemNam, itemMen, itemID, itemSchalt
	local itemTypeCount = 1

	-- initialize item information for every slot
	for slotNr = 0,zSlots-1 do
		itemID, itemMen = InventoryGetSlotInfo(BldAlias,slotNr,INVENTORY_STD)
		if itemMen and itemMen >= 0 and not economy_ContainsItemType(itemInfo, itemTypeCount, itemID) then
			ItemTexture = "Hud/Items/Item_"..ItemGetName(itemID)..".tga"
			-- result, label, Tooltip, icon
			ItemLabel = ItemGetLabel(itemID, itemMen == 1)
			schalter = schalter.."@B[" .. itemID .. "," .. itemMen .. "," .. ItemLabel .. "," .. ItemTexture .."]"

			itemInfo[itemTypeCount] = itemID
			itemTypeCount = itemTypeCount + 1
		end
	end
	
	local ItemId = InitData(
		"@P"..schalter, -- PanelParam
		0, -- AIFunc
		"@L_AUTOROUTE_TYPESELECT_HEAD_+0",-- HeaderLabel
		"Body"-- BodyLabel (obsolete)
		)-- optional variable list
	
	if ItemId and ItemId ~= "C" then
		return ItemId, GetItemCount(BldAlias, ItemId)
	end
	return nil, 0
end

---
-- returns ItemId, AvailableAmount
function ChooseItemFromMarket(BldAlias, PlayerAlias)
	local katWahl
	local itemInfo = {}	
	local schalter = ""
	local itemNam, itemKat, itemMen, itemID, itemSchalt
	local zSlots = InventoryGetSlotCount(BldAlias,INVENTORY_STD)

	repeat 	
		local itemTypeCount = 1
		katWahl = economy_SelectCategoryFromMarket(BldAlias, PlayerAlias)
		if katWahl == 0 then
			return nil, 0
		end
		-- bugfix: when repeating, reinitialize item list
		itemInfo = {}	
		schalter = ""
		-- initialize item information for every slot
		for slotNr = 0,zSlots-1 do
			itemID, itemMen = InventoryGetSlotInfo(BldAlias,slotNr,INVENTORY_STD)
			if itemMen and itemMen >= 0 then
				if(not economy_ContainsItemType(itemInfo, itemTypeCount, itemID)) then
					itemKat = ItemGetCategory(itemID)
					if itemKat == katWahl then
						itemNam = ItemGetLabel(itemID,true)
						itemSchalt = "@B["..itemID..",@L"..itemNam..",]"
						itemInfo[itemTypeCount] = itemID
						schalter = schalter..itemSchalt
						itemTypeCount = itemTypeCount + 1
					end
				end
			end
		end
		
		local ItemId = MsgBox(PlayerAlias,BldAlias,"@P"..schalter,"@L_AUTOROUTE_TYPESELECT_HEAD_+0","@L_AUTOROUTE_TYPESELECT_BODY_+0", GetID(BldAlias))
		if ItemId and ItemId ~= "C" then
			return ItemId, GetItemCount(BldAlias, ItemId)
		end
	until (ItemId and ItemId ~= "C")
end

---- itemInfo is an array wth IDs
function ContainsItemType(itemInfo, length, itemID)
	for i = 1, length - 1 do
		if itemInfo[i] == itemID then
			return true
		end
	end
	return false
end

function SelectCategoryFromMarket(BldAlias, PlayerAlias)
	local katSchalter = ""
	katSchalter = katSchalter.."@B[1,@L_BUILDING_Market_Ressource_NAME_+0,]"
	katSchalter = katSchalter.."@B[2,@L_BUILDING_Market_Food_NAME_+0,]"
	katSchalter = katSchalter.."@B[3,@L_BUILDING_Market_Smithy_NAME_+0,]"
	katSchalter = katSchalter.."@B[4,@L_BUILDING_Market_Textile_NAME_+0,]"
	katSchalter = katSchalter.."@B[5,@L_BUILDING_Market_Alchemist_NAME_+0,]"
	katSchalter = katSchalter.."@B[6,@L_BUILDING_Market_NewMarket_NAME_+0,]"
	katSchalter = katSchalter.."@B[C,@LBack_+0,]"
	local katWahl = MsgBox(PlayerAlias,BldAlias,"@P"..katSchalter,"@L_AUTOROUTE_CATEGORY_HEAD_+0","")
	if katWahl ~= "C" then
		return katWahl
	end
	return 0
end

function BuyDrinkOrFood(Tavern, SimAlias, Budget, MaxItems)
	-- ItemIDs for: Grainpap, SmallBeer, Stew , WheatBeer, SalmonFilet, RoastBeef, Wine
	local Items = {30, 31, 32, 34, 35, 37, 38}
	local Count = 7
	return economy_BuyRandomItems(Tavern, SimAlias, Budget, MaxItems, Count, Items)
end

function ClearBalance(BldAlias)
	if BldAlias and AliasExists(BldAlias) then
		local BalanceTypes = {"Autoroute", "Theft", "Salescounter", "Service", "Wages"}
		local Balance
		for i=1, 5 do
			Balance = "Balance"..BalanceTypes[i]
			if HasProperty(BldAlias, Balance) then
				RemoveProperty(BldAlias, Balance)
			end 
		end
	end
end

function CalcProductionPriorities(BldAlias, ProdCount, ProdItems)
	-- 1. initialize optional produced items and Building Type
	local BldType = BuildingGetType(BldAlias)
	if BldType == GL_BUILDING_TYPE_WAREHOUSE then
		return
	end
	
	if not GetInventory(BldAlias, INVENTORY_STD, "Inv") then
		return
	end
	
	if not ProdCount or not ProdItems then
		ProdCount, ProdItems = economy_GetProducedItems(BldAlias)
	end
	
	-- 2. Get local market
	if not GetSettlement(BldAlias, "MyCity") then
		return -1
	end
	CityGetLocalMarket("MyCity","MyMarket")
	
	-- 3. for each item: get min_stock, max_stock and current market stock
	local ItemId, BasePrice, Min, Max, Current, CurrentLocal
	local MarketValues = {}
	local TotalValue = 0
	for i=1, ProdCount do
		-- get values
		ItemId = ProdItems[i] 
		BasePrice = ItemGetBasePrice(ItemId)
		Min = GetDatabaseValue("Items", ItemId, "min_stock")
		Max = GetDatabaseValue("Items", ItemId, "max_stock")
		Current = GetItemCount("MyMarket", ItemId)
		CurrentLocal = GetItemCount(BldAlias, ItemId, INVENTORY_SELL) -- production is based on need and INVENTORY_STD anyway 
		-- normalize values
		Min = math.max(0, Min - Current - CurrentLocal)
		Max = math.max(1, Max - Current - CurrentLocal)
		BasePrice = math.ceil(BasePrice/50)
		-- increase base price of products required for services
		BasePrice = economy_IncreaseServiceBasePrice(BldType, ItemId, BasePrice)
		
		-- calculate market value
		MarketValues[i] = (Max + Min) * BasePrice   -- x
		TotalValue = TotalValue + MarketValues[i]
	end
	
	-- 4. Calculate the resulting priorities and set need property
	local NeedValue
	for i=1, ProdCount do
		ItemId = ProdItems[i]
		NeedValue = math.ceil(MarketValues[i]/TotalValue * 100)
		bld_SetInvNeedUnlocked(ItemId, NeedValue)
	end
	--economy_LogProductionNeeds(BldAlias)
end

function IncreaseServiceBasePrice(BldType, ItemId, BasePrice)
	-- special case: hospital (Salve, Bandage, Medicine, Painkiller)
	if BldType == GL_BUILDING_TYPE_HOSPITAL then
		if ItemId == 201 or ItemId == 202 or ItemId == 203 or ItemId == 204 then
			return BasePrice + 5 -- increase BasePrice by service income
		end
	elseif BldType == GL_BUILDING_TYPE_TAVERN then
		if ItemId == 30 or ItemId == 31 or ItemId == 32 or ItemId == 34 or ItemId == 35 or ItemId == 37 or ItemId == 38 then
			return BasePrice + 2
		end
	elseif BldType == GL_BUILDING_TYPE_CHURCH_EV or BldType == GL_BUILDING_TYPE_CHURCH_CATH then
		if ItemId == 181 then -- Housel
			return BasePrice + 2
		end
	end
	return BasePrice
end

-- Items.dbt keeps a recipe in three (nr, prod) pairs. Same walk as
-- ms_debug_HotTea.lua:PrintRequiredItems, which is what generated the requireditems
-- column of BuildingToItems.dbt in the first place.
function GetItemIngredients(ItemId)
	local Count = 0
	local Ingredients = {}
	for j = 1, 3 do
		local Prod = GetDatabaseValue("Items", ItemId, "prod"..j)
		if Prod and Prod > 0 then
			Count = Count + 1
			Ingredients[Count] = Prod
		end
	end
	return Count, Ingredients
end

-- Which products of a building proto consume which ingredient, keyed by ingredient id.
-- Each entry is a plain array with its length kept alongside: never iterated with pairs,
-- which this engine's Lua may not have (see ::TWP::ENV). Static per proto, built once.
ECONOMY_RECIPE_USERS = {}
ECONOMY_RECIPE_USERCOUNTS = {}

function GetProtoIngredientUsers(BldId)
	if ECONOMY_RECIPE_USERS[BldId] then
		return ECONOMY_RECIPE_USERS[BldId], ECONOMY_RECIPE_USERCOUNTS[BldId]
	end
	local Users, UserCounts = {}, {}
	local ProductsString = GetDatabaseValue("BuildingToItems", BldId, "produceditems")
	if ProductsString then
		-- same conversion GetProducedItems uses, so these ids match GetLiveProducts
		local ProductCount, Products = helpfuncs_StringToIdList(ProductsString)
		for p = 1, ProductCount do
			local ProductId = Products[p]
			local IngCount, Ingredients = economy_GetItemIngredients(ProductId)
			for k = 1, IngCount do
				local Ing = Ingredients[k]
				if not Users[Ing] then
					Users[Ing] = {}
					UserCounts[Ing] = 0
				end
				UserCounts[Ing] = UserCounts[Ing] + 1
				Users[Ing][UserCounts[Ing]] = ProductId
			end
		end
	end
	ECONOMY_RECIPE_USERS[BldId] = Users
	ECONOMY_RECIPE_USERCOUNTS[BldId] = UserCounts
	return Users, UserCounts
end

-- meta/engine.signatures.tsv declares BuildingCanProduce(building, string), every call
-- site in this mod passes the numeric id. Ask both ways and take a yes from either.
function BuildingCanProduceItem(BldAlias, ItemId)
	if BuildingCanProduce(BldAlias, ItemId) then
		return 1
	end
	local Name = ItemGetName(ItemId)
	if Name and Name ~= "" and BuildingCanProduce(BldAlias, Name) then
		return 1
	end
	return nil
end

-- The products this building may actually make right now: unlocked in the engine, and
-- still selected when the player configured a managed-storage product list. Unlocked is
-- returned beside Live so a dropped resource can say which of the two filters took it.
function GetLiveProducts(BldAlias)
	local Live, Unlocked = {}, {}
	local LiveCount = 0
	local Count, Products = economy_GetProducedItems(BldAlias)

	local IsSelected, HasSelection = {}, nil
	local StoredString = GetProperty(BldAlias, "MgmStor_Products")
	if StoredString and StoredString ~= "" then
		HasSelection = 1
		local SelectedCount, Selected = economy_StorageGetProducts(BldAlias)
		for i = 1, SelectedCount do
			IsSelected[Selected[i]] = 1
		end
	end

	for i = 1, Count do
		local ItemId = Products[i]
		if ItemId and economy_BuildingCanProduceItem(BldAlias, ItemId) then
			Unlocked[ItemId] = 1
			if not HasSelection or IsSelected[ItemId] then
				Live[ItemId] = 1
				LiveCount = LiveCount + 1
			end
		end
	end
	return LiveCount, Live, Unlocked
end

-- Drop the resources that only feed recipes this building cannot make.
-- requireditems is a per-level union: a level 3 hospital lists toad excrement because
-- Mixture needs it, on every hospital, including the ones that never bought the 1000
-- gold Mixture upgrade. An entry that no product of this proto references at all is
-- deliberate - the divehouse drinks, the alchemist's own herbs - and is always kept.
-- <type>:<value> for one engine return, with nothing in it that kv() in ai_telemetry.py
-- would split on. The type is the whole point: "963" and 963 are different table keys, so
-- two id lists that print identically can still never match.
function ProbeValue(Value)
	local Kind = type(Value)
	if Value == nil then
		return "nil:-"
	end
	return Kind .. ":" .. string.gsub(tostring(Value), "%s", "_")
end

-- Once per session: what the engine actually returns for the two id spaces this filter
-- compares, and which argument form BuildingCanProduce accepts.
--
-- Why reading the metadata cannot settle it. meta/engine.signatures.tsv gives
-- BuildingCanProduce building,string and ItemGetID string - but that column records the
-- accessor the binding calls, not a requirement. ItemGetName is declared string too and
-- every caller in this tree passes it a number, because lua_tostring converts a number in
-- place. So a numeric argument cannot raise a type error, and that silence says nothing
-- about whether the engine then resolves "963" as item 963.
--
-- What rides on it. economy_GetResourceNeeds builds its ids with
-- ItemGetID(<numeric string from gfind>) - vanilla, unchanged - while
-- economy_GetProtoIngredientUsers keys its table from GetDatabaseValue("Items", id,
-- "prodN"). Disagree in type or value and Users[ItemId] never hits, Matched stays 0, and
-- the filter silently drops nothing: the supply-filter-dead ERROR, reported rather than
-- guessed at. These lines are what turn that ERROR into a diagnosis.
ECONOMY_IDPROBE_DONE = nil
function ProbeItemIdSpaces(BldAlias, BldId)
	if ECONOMY_IDPROBE_DONE or not utility_LogEnabled() then
		return
	end
	local ProductCount, Products = helpfuncs_StringToIdList(
		GetDatabaseValue("BuildingToItems", BldId, "produceditems") or "")
	if ProductCount < 1 then
		return                          -- produces nothing; the next building will answer
	end
	ECONOMY_IDPROBE_DONE = 1
	local P = Products[1]
	local Name = ItemGetName(P)
	utility_Emit("::TWP::IDPROBE t=" .. string.format("%.2f", GetGametime())
		.. " bld=" .. GetID(BldAlias) .. " proto=" .. BldId
		-- the id as helpfuncs_StringToIdList makes it, and the name the engine gives back
		.. " listid=" .. economy_ProbeValue(P)
		.. " getname=" .. economy_ProbeValue(Name)
		-- three ItemGetID forms: by name, by the numeric string vanilla passes, by number
		.. " id_byname=" .. economy_ProbeValue(ItemGetID(Name))
		.. " id_bynumstr=" .. economy_ProbeValue(ItemGetID(tostring(P)))
		.. " id_bynum=" .. economy_ProbeValue(ItemGetID(P))
		-- the other side of the comparison, read straight from the recipe column
		.. " prod1=" .. economy_ProbeValue(GetDatabaseValue("Items", P, "prod1"))
		-- and which argument form the engine accepts for a product it certainly makes
		.. " canprod_num=" .. economy_ProbeValue(BuildingCanProduce(BldAlias, P))
		.. " canprod_numstr=" .. economy_ProbeValue(BuildingCanProduce(BldAlias, tostring(P)))
		.. " canprod_name=" .. economy_ProbeValue(BuildingCanProduce(BldAlias, Name)))
end

function FilterNeedsByLiveRecipes(BldAlias, BldId, Count, Items, Multiplier, UsageCount)
	economy_ProbeItemIdSpaces(BldAlias, BldId)
	local Users, UserCounts = economy_GetProtoIngredientUsers(BldId)
	local LiveCount, Live, Unlocked = economy_GetLiveProducts(BldAlias)

	local Kept, KeptCount, Matched = {}, 0, 0
	local KeptLog, DroppedLog = "", ""
	-- requireditemusages longer than requireditems: Count comes from the items, so the
	-- surplus never reaches a caller, but the row is still wrong and nothing else says so
	for i = Count + 1, (UsageCount or Count) do
		DroppedLog = DroppedLog .. "usage" .. i .. ":orphan;"
	end
	for i = 1, Count do
		local ItemId = Items[i] and Items[i][1]
		local Keep = 1
		if not ItemId then
			-- requireditemusages shorter: this slot reaches callers as { nil, amount } and
			-- CalcCurrentResourceNeeds indexes [1] on it
			Keep = nil
			DroppedLog = DroppedLog .. "slot" .. i .. ":malformed;"
		elseif Users[ItemId] then
			Matched = Matched + 1
			Keep = nil
			local Deselected = nil
			for k = 1, UserCounts[ItemId] do
				local ProductId = Users[ItemId][k]
				if Live[ProductId] then
					Keep = 1
				elseif Unlocked[ProductId] then
					Deselected = 1
				end
			end
			if not Keep then
				local Why = "locked"
				if Deselected then
					Why = "deselected"
				end
				DroppedLog = DroppedLog .. ItemId .. ":" .. (ItemGetName(ItemId) or "?") .. ":" .. Why .. ";"
			end
		end
		if Keep then
			KeptCount = KeptCount + 1
			Kept[KeptCount] = Items[i]
			KeptLog = KeptLog .. ItemId .. ":" .. Items[i][2] .. ";"
		end
	end

	if Count > 0 and (DroppedLog ~= "" or Matched == 0) then
		utility_Emit("::TWP::SUPPLY t=" .. string.format("%.2f", GetGametime())
			.. " bld=" .. GetID(BldAlias) .. " proto=" .. BldId
			.. " workers=" .. Multiplier .. " live=" .. LiveCount .. " matched=" .. Matched
			.. " kept=" .. KeptLog .. " dropped=" .. DroppedLog)
	end
	-- a misdetection must never starve a working building
	if KeptCount <= 0 then
		return Count, Items
	end
	return KeptCount, Kept
end

function GetResourceNeeds(BldAlias)
	if (not BldAlias or not AliasExists(BldAlias)) then
		return 0, {} 
	end
	
	-- get values from DBT
	local BldId = BuildingGetProto(BldAlias)
	local ItemsString = GetDatabaseValue("BuildingToItems", BldId, "requireditems")
	if ItemsString == nil then
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
	
	local Multiplier = BuildingGetWorkerCount(BldAlias)
	if Multiplier < 1 then
		Multiplier = 1
	end
	local AmountsString = GetDatabaseValue("BuildingToItems", BldId, "requireditemusages")
	local i = 0
	
	for Amount in string.gfind(AmountsString, "%d+") do
		i = i + 1
		-- multiply base amount by workercount or productivity
		Items[i] = { Ids[i], Amount * Multiplier }
	end
	-- requireditems lists every recipe of this building level, unlocked or not
	return economy_FilterNeedsByLiveRecipes(BldAlias, BldId, Count, Items, Multiplier, i)
end

---
-- Given the general resource requirements, calculate the current needs.
-- returns NeedCount, Needs
function CalcCurrentResourceNeeds(BldAlias, ResourceCount, Resources, Threshold)
	if ResourceCount <= 0 then
		return 0, {}
	end 
	local Needs = {}
	local NeedCount = 0
	for i = 1, ResourceCount do
		local CurrentAmount = GetItemCount(BldAlias, Resources[i][1])
		-- AI tends to put spare materials into sales inventory, take these into account
		local SalesCount = GetItemCount(BldAlias, Resources[i][1], INVENTORY_SELL) or 0 
		CurrentAmount = CurrentAmount + SalesCount
		local MaxNeed = Resources[i][2]
		local ActualNeed = MaxNeed - CurrentAmount
		-- need resources when stores below threshold
		if MaxNeed > 0 and ActualNeed > 0 and CurrentAmount/MaxNeed <= Threshold then
			NeedCount = NeedCount + 1
			local InvSpace = GetImpactValue(BldAlias, "BonusSpace") 
			if InvSpace <= 0 then
				InvSpace = 500 -- in case of market
			end
			Needs[NeedCount] = {Resources[i][1], math.min(InvSpace, ActualNeed)}
		end
	end
	-- no current needs
	if NeedCount == 0 then
 		return 0, {}
 	end
 	
 	-- 4. sort by actual needs, highest first (SortProfits sorts highest first so it will do)
	return NeedCount, helpfuncs_QuickSort(Needs, 1, NeedCount, helpfuncs_SortBySecondValue) 
end

function CheckAvailability(BldAlias, CartAlias, NeedCount, Needs)
	-- can only buy from market if I have enough money
	if BuildingGetClass(BldAlias) == GL_BUILDING_CLASS_MARKET or GetDynastyID(CartAlias) ~= GetDynastyID(BldAlias) then
		if GetMoney(CartAlias) < 200 then
			return false
		end
	end
	-- use sales inventory for workshops not owned by cart dynasty
	local BldInv = INVENTORY_STD
	if GetDynastyID(CartAlias) ~= GetDynastyID(BldAlias) and BuildingGetClass(BldAlias) ~= GL_BUILDING_CLASS_MARKET then
		-- use sales inventory for workshops of other dynasties
		BldInv = INVENTORY_SELL
	end
	-- check availability of at least one resource
	local IsProducer
	for i = 1, NeedCount do
		if Needs[i][2] > 0 and GetItemCount(BldAlias, Needs[i][1], BldInv) > 0 then
			IsProducer = BuildingGetClass(BldAlias) == GL_BUILDING_CLASS_MARKET or BuildingCanProduce(BldAlias, Needs[i][1]) or BuildingGetType(BldAlias) == GL_BUILDING_TYPE_WAREHOUSE
			if IsProducer then
				-- if not producer, still check other Needs
				return IsProducer
			end
		end
	end
	return false
end

function CalcProfits(MarketAlias, HomeAlias, ProductCount, Products, ProfitThreshold, UseBasePrice)
	local Profits = {} -- table of {ItemId, MinAmount, Profit}
	local ProfitCount = 0
	local ExpectedTotalProfit = 0
	local ItemId, Amount
	for i = 1, ProductCount do
		ItemId = Products[i][1]
		local ProductMin = Products[i][2] or 0
		Amount = GetItemCount(HomeAlias, ItemId, INVENTORY_STD) + GetItemCount(HomeAlias, ItemId, INVENTORY_SELL)
		Amount = Amount - ProductMin
		if ProductMin < 0 then
			-- protected product, never loaded onto the cart
			Amount = 0
		end
		-- normalize amount to no more than 120 (max cart size)
		Amount = math.min(Amount, 120)
		local Profit
		if UseBasePrice then
      Profit = Amount * ItemGetBasePrice(ItemId)
		else
		  Profit = Amount *	ItemGetPriceSell(ItemId, MarketAlias) 
		end
		if Amount > 0 and Profit > ProfitThreshold then
			ProfitCount = ProfitCount + 1
			Profits[ProfitCount] = {ItemId, Amount, Profit}
			ExpectedTotalProfit = ExpectedTotalProfit + Profit
		end
	end
 
 	if ProfitCount == 0 then
 		return 0, {}
 	end
 	
	-- sort by expected profit, highest first
	Profits = helpfuncs_QuickSort(Profits, 1, ProfitCount, helpfuncs_SortByThirdValue)
	return ProfitCount, Profits, ExpectedTotalProfit
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
				ProfitCount, Profits = economy_CalcProfits("Market"..l, HomeAlias, ProductCount, Products, 1000)  
				if ProfitCount > 0 then 
					return ProfitCount, Profits, CityAlias
				end
			end
		else -- regular settlement
			CityGetLocalMarket(CityAlias, "Market"..l)
			ProfitCount, Profits = economy_CalcProfits("Market"..l, HomeAlias, ProductCount, Products, 1000)   
			if ProfitCount > 0 then 
				return ProfitCount, Profits, CityAlias
			end
		end
	end
	
	return 0, {}, "MyCity"
end

---
-- * Each market calculates the current resource needs once per day.
--     * Based on workshops in town (aggregated CalcResourceNeed for each workshop against current stock).
--     * Five most needed resources are written to property as list. (optional: 1 non-resource is also added to list)
--     * Sales Prices for these resources are increased and all players are notified (see kontor event). 
function CalcNeedsForMarket(CityAlias)
	-- get all workshops in town
	local WorkshopCount = CityGetBuildings(CityAlias, GL_BUILDING_CLASS_WORKSHOP, -1, -1, -1, FILTER_HAS_DYNASTY, "Workshop") or 0
	local CityNeedCount, CityNeeds =  0, {}
	
	if WorkshopCount >= 1 then
		-- iterate over workshops
		local Alias, NeedCount, Needs  -- for use in iteration
		for i = 0, WorkshopCount - 1 do
			Alias = "Workshop"..i
			NeedCount, Needs  = economy_GetResourceNeeds(Alias)
			-- merge needs into global needs
			CityNeedCount, CityNeeds = economy_MergeNeedLists(CityNeedCount, CityNeeds, NeedCount, Needs)
		end
		CityGetLocalMarket(CityAlias, "MarketAlias")
		CityNeedCount, CityNeeds = economy_CalcCurrentResourceNeeds("MarketAlias", CityNeedCount, CityNeeds, 0.4)
		-- save first five needs as properties
		for i=1, 6 do
			if i <= CityNeedCount and CityNeeds[i] then
				SetProperty("MarketAlias", "twpNeed"..i, CityNeeds[i][1])
				SetProperty("MarketAlias", "twpNeedAmount"..i, CityNeeds[i][2])
				--LogMessage(GetName(CityAlias) .. " sells: " .. CityNeeds[i][2] .. " " .. ItemGetName(CityNeeds[i][1]))
			else
				RemoveProperty("MarketAlias", "twpNeed"..i)
				RemoveProperty("MarketAlias", "twpNeedAmount"..i)
			end
		end
		return CityNeedCount, CityNeeds
	else
		return -1, -1
	end
end

function GetNeedsForMarket(CityAlias)
	-- read from properties
	local CityNeedCount, CityNeeds = 0, {}
	CityGetLocalMarket(CityAlias, "MarketAlias")
	local tmp, Amount
	for i=1, 6 do
		tmp = GetProperty("MarketAlias", "twpNeed"..i)
		if tmp then
			CityNeedCount = CityNeedCount + 1
			Amount = GetProperty("MarketAlias", "twpNeedAmount"..i)
			CityNeeds[CityNeedCount] = { tmp, Amount }
			--LogMessage(GetName(CityAlias) .. " needs: " .. Amount .. " " .. ItemGetName(tmp))
		end
	end
	return CityNeedCount, CityNeeds 
end

function CalcSalesForMarket(CityAlias)

	local SalesCount, Sales = 0, {}
	-- check all items in storage
	if not CityGetRandomBuilding(CityAlias, -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, "MarketBld") then
		return SalesCount, Sales
	end
		
	local Slots = InventoryGetSlotCount("MarketBld", INVENTORY_STD)
	local ItemId, Amount, MaxAmount, Surplus
	for i = 0, Slots - 1 do
		ItemId, Amount = InventoryGetSlotInfo("MarketBld", i, INVENTORY_STD)
		MaxAmount = GetDatabaseValue("Items", ItemId, "max_stock")
		Surplus = Amount - MaxAmount
		if Surplus > 0 then
			SalesCount = SalesCount + 1
			Sales[SalesCount] = { ItemId, Surplus } -- TODO consider a relative value instead based on MaxAmount
		end 
	end
	-- sort list
	Sales = helpfuncs_QuickSort(Sales, 1, SalesCount, helpfuncs_SortBySecondValue)
	CityGetLocalMarket(CityAlias, "MarketAlias")
	-- save first six items as properties
	for i=1, 6 do
		if i <= SalesCount and Sales[i] then
			--LogMessage(GetName(CityAlias) .. " sells: " .. Sales[i][2] .. " " .. ItemGetName(Sales[i][1]))
			SetProperty("MarketAlias", "twpSales"..i, Sales[i][1])
			SetProperty("MarketAlias", "twpSalesAmount"..i, Sales[i][2])
		else
			RemoveProperty("MarketAlias", "twpSales"..i)
			RemoveProperty("MarketAlias", "twpSalesAmount"..i)
		end
	end
	
	return SalesCount, Sales
end

function GetSalesForMarket(CityAlias)
	-- read from properties
	local SalesCount, Sales = 0, {}
	CityGetLocalMarket(CityAlias, "MarketAlias")
	local ItemId, ItemCount, MaxAmount, Surplus
	
	for i=1, 6 do
		ItemId = GetProperty("MarketAlias", "twpSales"..i)
		if ItemId then
			SalesCount = SalesCount + 1
			--Amount = GetProperty("MarketAlias", "twpSalesAmount"..i)
			ItemCount = GetItemCount("MarketAlias", ItemId)
			MaxAmount = GetDatabaseValue("Items", ItemId, "max_stock")
			Surplus = ItemCount - MaxAmount
			Sales[SalesCount] = { ItemId, Surplus }
		end
	end
	
	return SalesCount, Sales 
end

function MergeNeedLists(CityNeedCount, CityNeeds, NeedCount, Needs)

	local ItemExists 
	
	for j = 1, NeedCount do
		ItemExists = false
		for i = 1, CityNeedCount do
			if CityNeeds[i][1] == Needs[j][1] then
				CityNeeds[i][2] = CityNeeds[i][2] + Needs[j][2]
				ItemExists = true
			end
		end
		if not ItemExists then
			CityNeedCount = CityNeedCount + 1
			CityNeeds[CityNeedCount] = Needs[j]
		end
	end
	
	return CityNeedCount, CityNeeds
end

function ChooseFromItems(ItemCount, ItemList, IncludeOK)
	local Id, ItemTexture, Tooltip, Subtext
	local Buttons = "@P"
	
	for i=1, ItemCount do
		Id = ItemList[i][1]
		ItemTexture = "Hud/Items/Item_"..ItemGetName(Id)..".tga"
		Tooltip = ItemGetLabel(Id, false)
		Subtext = ItemList[i][2]
		-- result, Tooltip, label, icon
		Buttons = Buttons.."@B[" .. i .. "," .. Subtext .. "," .. Tooltip .. "," .. ItemTexture .."]"
	end
	
	if IncludeOK then
		Buttons = Buttons.."@B[C,@L_GENERAL_BUTTONS_OK_+0,@L_GENERAL_BUTTONS_OK_+0,Hud/Buttons/btn_Ok.tga]"
	end	

	local ChosenItem = InitData(
		Buttons, -- PanelParam
		0, -- AIFunc
		"@L_TWP_SUPPLYWORKSHOP_CHOOSERESOURCE_HEAD_+0",-- HeaderLabel
		"Body")
		
	if ChosenItem and ChosenItem ~= "C" then
		return ChosenItem
	end
	
	return nil
end

function CityGetUnemployedCount(CityAlias)
	
	local GlobalSimCount = ScenarioGetObjects("cl_Sim", -1, "Sim")
	local UnemployedCity = 0
	local CityID = GetID(CityAlias)
	
	for i=0, GlobalSimCount-1 do
		local Alias = "Sim"..i
		if not IsDynastySim(Alias) and GetSettlementID(Alias) == CityID and SimGetAge(Alias) >= 17 and SimGetWorkingPlaceID(Alias) < 0 and not GetStateImpact(Alias, "no_hire") then
			UnemployedCity = UnemployedCity + 1
		end
	end
	
	return UnemployedCity
end

function CityGetGuardCount(CityAlias)
	
	local Cityguard, Eliteguard
	Cityguard = 0 + CityGetServantCount(CityAlias, GL_PROFESSION_CITYGUARD)
	Eliteguard = 0 + CityGetServantCount(CityAlias, GL_PROFESSION_ELITEGUARD)
	
	return Cityguard, Eliteguard
end

function CityGetServantCount(CityAlias)
	
	local Servants = 0
	Servants = Servants + CityGetServantCount(CityAlias, GL_PROFESSION_PRISONGUARD)
	Servants = Servants + CityGetServantCount(CityAlias, GL_PROFESSION_INSPECTOR)
	Servants = Servants + CityGetServantCount(CityAlias, GL_PROFESSION_MONITOR)
	Servants = Servants + CityGetServantCount(CityAlias, GL_PROFESSION_INQUISITOR)
	
	return Servants
end

function StorageGetProducts(BldAlias)
	-- need to match the return values of economy_GetProducedItems 
	if (not BldAlias or not AliasExists(BldAlias)) then
		return 0, {}, {}
	end
	
	local ItemsString, ProtectedAmountsString
	ItemsString = GetProperty(BldAlias, "MgmStor_Products")
	ProtectedAmountsString = GetProperty(BldAlias, "MgmStor_ProductsProt")
	
	if not ItemsString or ItemsString == "" then
		-- fallback to default product list
		return economy_GetProducedItems(BldAlias)
	end
	
	local Count, Products = helpfuncs_StringToIdList(ItemsString)
	local _, ProtectedAmounts = helpfuncs_StringToIdList(ProtectedAmountsString)
	return Count, Products, ProtectedAmounts
end

function StorageSaveProducts(BldAlias, ProductCount, Products, ProtectedAmounts)
	local ProductsString = helpfuncs_IdListToString(Products, ProductCount)
	if ProductsString then
		SetProperty(BldAlias, "MgmStor_Products", ProductsString)
	end

	local ProtAmountsString = helpfuncs_IdListToString(ProtectedAmounts, ProductCount)
	if ProtAmountsString then
		SetProperty(BldAlias, "MgmStor_ProductsProt", ProtAmountsString)
	end
end

function StorageGetResources(BldAlias)
	-- need to match the return values of economy_GetResourceNeeds 
	if (not BldAlias or not AliasExists(BldAlias)) then
		return 0, {}
	end
	
	local ItemsString, MinAmounts
	ItemsString = GetProperty(BldAlias, "MgmStor_Resources")
	MinAmounts = GetProperty(BldAlias, "MgmStor_ResourceMins")
	
	if not ItemsString or ItemsString == "" then
		return economy_GetResourceNeeds(BldAlias)
	end
	-- The new StorageGetResources() logic repairs saved SupplyWorkshop resource lists before they are shown or used.
	-- Older savegames can contain stale or duplicated MgmStor_Resources entries after DB changes. Instead of trusting that saved list blindly, the code now normalizes it by item ID: duplicate or invalid items are removed, existing minimum amounts are preserved, and regular workshops are rebuilt from the current BuildingToItems.requireditems order. This restores missing default resources such as Fungi or Silver while keeping the player’s configured stock amounts where possible.
	-- For warehouses, custom resource lists are still allowed, but duplicate or invalid entries are cleaned up. If the function detects that the stored list was repaired, it saves the normalized list back to the building so the same savegame does not keep showing the broken popup.
	local StoredCount, StoredResources = helpfuncs_StringToIdList(ItemsString)
	local _, StoredMinAmounts = helpfuncs_StringToIdList(MinAmounts)
	local DefaultCount, DefaultResources = economy_GetResourceNeeds(BldAlias)
	local MinAmountByItem = {}
	local HasStoredItem = {}
	local Changed = false
	local ItemId, Amount
	
	for i = 1, StoredCount do
		ItemId = ItemGetID(StoredResources[i])
		Amount = StoredMinAmounts[i] or 0
		if ItemId and ItemId > 0 then
			if HasStoredItem[ItemId] then
				Changed = true
				if Amount > MinAmountByItem[ItemId] then
					MinAmountByItem[ItemId] = Amount
				end
			else
				HasStoredItem[ItemId] = true
				MinAmountByItem[ItemId] = Amount
			end
		else
			Changed = true
		end
	end

	local Count = 0
	local Resources = {}
	local BldType = BuildingGetType(BldAlias)
	if BldType == GL_BUILDING_TYPE_WAREHOUSE then
		for i = 1, StoredCount do
			ItemId = ItemGetID(StoredResources[i])
			if ItemId and ItemId > 0 and MinAmountByItem[ItemId] then
				Count = Count + 1
				Resources[Count] = { ItemId, MinAmountByItem[ItemId] }
				MinAmountByItem[ItemId] = nil
				if ItemId ~= StoredResources[i] or Count ~= i then
					Changed = true
				end
			end
		end
	else
		for i = 1, DefaultCount do
			ItemId = DefaultResources[i][1]
			Amount = MinAmountByItem[ItemId]
			if Amount == nil then
				Amount = DefaultResources[i][2] or 0
				Changed = true
			end
			Count = Count + 1
			Resources[Count] = { ItemId, Amount }
			if i > StoredCount or ItemId ~= ItemGetID(StoredResources[i]) or Amount ~= (StoredMinAmounts[i] or 0) then
				Changed = true
			end
			MinAmountByItem[ItemId] = nil
		end
		if StoredCount ~= DefaultCount then
			Changed = true
		end
	end

	if Changed then
		economy_StorageSaveResources(BldAlias, Count, Resources)
	end
	
	return Count, Resources
end

function StorageSaveResources(BldAlias, ResourceCount, Resources)
	local ResourcesList = {}
	local MinAmounts = {}
	for i = 1, ResourceCount do
		ResourcesList[i] = Resources[i][1]
		MinAmounts[i] = Resources[i][2] or 0
	end

	local ResourceString = helpfuncs_IdListToString(ResourcesList, ResourceCount)
	if ResourceString then
		SetProperty(BldAlias, "MgmStor_Resources", ResourceString)
	end

	local MinAmountsString = helpfuncs_IdListToString(MinAmounts, ResourceCount)
	if MinAmountsString then
		SetProperty(BldAlias, "MgmStor_ResourceMins", MinAmountsString)
	end
end

function StorageUpdateOnLevelUp(BldAlias)
	if not DynastyIsPlayer(BldAlias) then
		-- irrelevant for ai buildings
		return
	end

	-- Both halves below merge by item id. The old version appended the tail of the new
	-- default list by position, which assumes every level of a building lists its items in
	-- the same order; BuildingToItems does not. Hospital 2 to 3 alone duplicated Pinewood
	-- and Charcoal, lost Fungi and Salve, and moved the configured minimum amounts onto
	-- whatever item happened to land on their index.
	local Count, Resources = economy_StorageGetResources(BldAlias)
	local DefaultCount, DefaultNeeds = economy_GetResourceNeeds(BldAlias)
	local Known = {}
	for i = 1, Count do
		if Resources[i] and Resources[i][1] then
			Known[Resources[i][1]] = 1
		end
	end
	local NewCount = Count
	for i = 1, DefaultCount do
		local ItemId = DefaultNeeds[i] and DefaultNeeds[i][1]
		if ItemId and not Known[ItemId] then
			Known[ItemId] = 1
			NewCount = NewCount + 1
			Resources[NewCount] = DefaultNeeds[i]
		end
	end
	if NewCount > Count then
		economy_StorageSaveResources(BldAlias, NewCount, Resources)
	end

	-- update product list if necessary
	local ProductCount, Products, ProtAmounts = economy_StorageGetProducts(BldAlias)
	local DefaultProdCount, DefaultProducts, DefaultProtAmounts = economy_GetProducedItems(BldAlias)
	local KnownProduct = {}
	for i = 1, ProductCount do
		if Products[i] then
			KnownProduct[Products[i]] = 1
		end
	end
	local NewProductCount = ProductCount
	for i = 1, DefaultProdCount do
		local ItemId = DefaultProducts[i]
		if ItemId and not KnownProduct[ItemId] then
			KnownProduct[ItemId] = 1
			NewProductCount = NewProductCount + 1
			Products[NewProductCount] = ItemId
			ProtAmounts[NewProductCount] = DefaultProtAmounts[i]
		end
	end
	if NewProductCount > ProductCount then
		economy_StorageSaveProducts(BldAlias, NewProductCount, Products, ProtAmounts)
	end
end

function StorageClearProperties(BldAlias)
	RemoveProperty(BldAlias, "MgmStor_Products")
	RemoveProperty(BldAlias, "MgmStor_ProductsProt")
	RemoveProperty(BldAlias, "MgmStor_Resources")
	RemoveProperty(BldAlias, "MgmStor_ResourceMins")
end

