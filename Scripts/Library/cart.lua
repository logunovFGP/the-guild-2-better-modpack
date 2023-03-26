-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching
end

-- returns (SlotCount, SlotSize)
function GetCartSlotInfo(CartAlias)
	local Type = CartGetType(CartAlias)
	if Type == EN_CT_SMALL then
		return 1, 20
	elseif Type == EN_CT_MIDDLE then
		return 2, 20
	elseif Type == EN_CT_HORSE then
		return 3, 20
	elseif Type == EN_CT_OX then
		return 3, 40
	elseif Type == EN_CT_MERCHANTMAN_SMALL then
		return 5, 30
	elseif Type == EN_CT_MERCHANTMAN_BIG then
		return 6, 40
	end
	return 0, 0
end

-- returns (OptionCount, Options)
function GetCartSpaceOptions(CartAlias)
	local Type = CartGetType(CartAlias)
	if Type == EN_CT_SMALL then
		return 4, {1, 5, 10, 20}
	elseif Type == EN_CT_MIDDLE then
		return 5, {1, 5, 10, 20, 40}
	elseif Type == EN_CT_HORSE then
		return 6, {1, 5, 10, 20, 40, 60}
	elseif Type == EN_CT_OX then
		return 7, {1, 5, 10, 20, 40, 80, 120}
	elseif Type == EN_CT_MERCHANTMAN_SMALL then
		return 10, {1, 5, 10, 20, 40, 60, 80, 100, 120, 180}
	elseif Type == EN_CT_MERCHANTMAN_BIG then
		return 10, {1, 5, 10, 20, 40, 80, 120, 160, 200, 240}
	end
end

function IsShip(CartAlias)
	local Type = CartGetType(CartAlias)
	return Type == EN_CT_MERCHANTMAN_SMALL 
		or Type == EN_CT_MERCHANTMAN_BIG
		or Type == EN_CT_CORSAIR
		or Type == EN_CT_WARSHIP
		or Type == EN_CT_FISHERBOOT
end

---- Auswahlmenü: Waren einladen
-- returns ItemId, Amount
function ChooseItemsToLoad(CartAlias, BldAlias)
	local ItemId, AvailableAmount = economy_ChooseItemFromInventory(BldAlias, CartAlias)
	if (not ItemId) or ItemId == 0 then
		return 0, 0
	end

	local OptionCount, Option = cart_GetCartSpaceOptions(CartAlias)
	local mengenWahl = ""
	for i=1, OptionCount do
		mengenWahl = mengenWahl.."@B["..Option[i]..","..Option[i]..",]"
	end
	mengenWahl = mengenWahl.."@B[C,@LBack_+0,]"
	
	local Amount = MsgBox(CartAlias,BldAlias,"@P"..mengenWahl,"@L_AUTOROUTE_COUNTSELECT_HEAD_+0","@L_AUTOROUTE_COUNTSELECT_BODY_+0", GetID(BldAlias), ItemGetLabel(ItemId,false))
	if Amount and Amount ~= "C" then
		return ItemId, Amount
	end
	return 0, 0
end

function UnloadAll(CartAlias, DestAlias)
	Sleep(2) 
	local	Slots = InventoryGetSlotCount(CartAlias, INVENTORY_STD)
	
	--do the transfer
	local	ItemId, ItemCount
	local	Error, ItemTransfered
	local BargainMoney = 0
	local EstimatedMoney = 0
	
	for i = 1, Slots do
		local ItemId, ItemCount = InventoryGetSlotInfo("", Slots-i)
		
		if ItemId and ItemCount then
			BuildingGetCity(DestAlias, "MyCity")
			local ItemStock = GetItemCount(DestAlias, ItemId)
			if CanAddItems(DestAlias, ItemId, ItemCount, INVENTORY_STD) then
				-- Add some bargain-bonus on market buys
				if BuildingGetClass(DestAlias) == GL_BUILDING_CLASS_MARKET then
					if GetHomeBuilding(CartAlias, "Business") then
						if BuildingGetOwner("Business", "MyBoss") then
							if GetSettlement(CartAlias, "MyCity") then
								CityGetLocalMarket("MyCity", "MyMarket")
								EstimatedMoney = ItemGetPriceSell(ItemId, "MyMarket")*ItemCount
								BargainMoney = math.floor(EstimatedMoney*((GetSkillValue("MyBoss", BARGAINING)*2)/100))
							end
						end
					end
				end
				--LogMessage("WorldTrader ID: "..GetID(CartAlias).." wants to unload "..ItemCount.." "..ItemGetName(ItemId).." at "..GetName(DestAlias).." of City "..GetName("MyCity")..". Stock currently is at: "..ItemStock)
				Transfer(CartAlias, DestAlias, INVENTORY_STD, CartAlias, INVENTORY_STD, ItemId, ItemCount)
				--LogMessage("WorldTrader ID: "..GetID(CartAlias).." unloads "..ItemCount.." "..ItemGetName(ItemId).." to "..GetName(DestAlias).." of City "..GetName("MyCity"))
				ItemStock = GetItemCount(DestAlias, ItemId)
				--LogMessage("Stock of "..ItemGetName(ItemId).." is now at "..ItemStock)
			else
				Transfer(CartAlias, DestAlias, INVENTORY_SELL, CartAlias, INVENTORY_STD, ItemId, ItemCount)
			end
		end
		Sleep(0.4)
	end
end

--- debug function to notify player of current route
function NotifyRoute(CartAlias, CurrentStop, Destination)
	if not AliasExists(CurrentStop) then
		return
	end
	local SlotCount, SlotSize = cart_GetCartSlotInfo(CartAlias)
	local Msg = "Händler %3NAME verlässt %1NAME mit Ziel %2NAME und folgender Ladung.$N"
	local ItemId, Count
	local Labels = {}
	local HasItems = false
	for i=0, SlotCount - 1 do
		ItemId, Count = InventoryGetSlotInfo("", i)
		if ItemId and Count > 0 then
			Msg = Msg .. "$N"..Count.." %"..(4+i).."l" -- Texts like: (linebreak) 20 Gold
			Labels[i+1] = ItemGetLabel(ItemId, Count==1)
			HasItems = true
		end
	end
	if not HasItems then
		Msg = Msg .. "$N--- Nichts ---"
	end
	CartGetOperator(CartAlias, "Operator")
	MsgNewsNoWait("All", -- recipient
				CartAlias, -- jump to target
				"", -- panel params (buttons)
				"economie", -- message class
				-1, -- TimeOut 
				"World Trader", -- Header
				Msg, -- Body
				GetSettlementID(CurrentStop), GetSettlementID(Destination), GetID("Operator"), helpfuncs_UnpackTable(Labels)) -- params
end

---
-- Attempts to load as many items as possible onto the cart.
-- shopping list must look like: {{ItemId, RequiredAmount}, {ItemId2, RequiredAmount2}, ...}
-- returns the ShoppingList with reduced item amounts
function LoadItems(CartAlias, BldAlias, Count, ShoppingList)

	if not Count or Count <= 0 then
		-- nothing to load...
		return Count, ShoppingList
	end
	
	local SlotCount, CartSlotSize = cart_GetCartSlotInfo(CartAlias)
	local BldInv = INVENTORY_STD
	if GetDynastyID(CartAlias) ~= GetDynastyID(BldAlias) and BuildingGetClass(BldAlias) ~= GL_BUILDING_CLASS_MARKET then
		-- use sales inventory for workshops of other dynasties
		BldInv = INVENTORY_SELL
	end
	
	-- loop through slots and try to buy items from shopping list. fills up more than one slot with the same item after finishing the list
	local CurrentItem = 1 
	local OpenSlots = SlotCount
	local ItemId, ReqAmount
	local BargainMoney = 0
	local EstimatedMoney = 0
	
	while OpenSlots > 0 and CurrentItem <= Count do
	--	LogMessage("WorldTrader ID: "..GetID(CartAlias) .. " open slots: " .. OpenSlots)
		ItemId = ShoppingList[CurrentItem][1]
		ReqAmount = ShoppingList[CurrentItem][2]
		BuildingGetCity(BldAlias, "City")
		local ItemStock = GetItemCount(BldAlias, ItemId)
	--	LogMessage("WorldTrader ID: "..GetID(CartAlias).." is buying "..ItemGetName(ItemId).." from "..GetName(BldAlias).." of City "..GetName("City")..". Current Stock is at "..ItemStock)
		if ItemId and ReqAmount > 0 then
			local Error, ItemTransfered = Transfer(CartAlias, CartAlias, INVENTORY_STD, BldAlias, BldInv, ItemId, math.min(CartSlotSize, ReqAmount))
			-- Add some bargain-bonus on market buys
			if BuildingGetClass(BldAlias) == GL_BUILDING_CLASS_MARKET then
				if GetHomeBuilding(CartAlias, "Business") then
					if BuildingGetOwner("Business", "MyBoss") then
						if GetSettlement(CartAlias, "MyCity") then
							CityGetLocalMarket("MyCity", "MyMarket")
							EstimatedMoney = ItemGetPriceSell(ItemId, "MyMarket")*ItemTransfered
							BargainMoney = math.floor(EstimatedMoney*((GetSkillValue("MyBoss", BARGAINING)*2)/100))
						end
					end
				end
			end
			--LogMessage("WorldTraderID: "..GetID(CartAlias).." loads "..ItemTransfered.." "..ItemGetName(ItemId).." from "..GetName(BldAlias).." of "..GetName("City"))
			ItemStock = GetItemCount(BldAlias, ItemId)
			--LogMessage("New stock is now "..ItemStock)
			
			if BargainMoney > 0 then
				local BalanceSheet = "WaresSold"
				local CartType = CartGetType(CartAlias)
				if CartType == EN_CT_CORSAIR or CartType == EN_CT_FISHERBOOT or CartType == EN_CT_MERCHANTMAN_SMALL or
					CartType == EN_CT_MERCHANTMAN_BIG or CartType == EN_CT_WARSHIP then
				
					BalanceSheet = "WaresSeaSold"
				end
				CreditMoney(CartAlias, BargainMoney, BalanceSheet)
				ShowOverheadSymbol(CartAlias, false, false, 0, "@L(+ %1t)", BargainMoney)
			end
			
			-- 6. make sure list is repeated if slots are still available
			if ItemTransfered and ItemTransfered > 0 then
				ShoppingList[CurrentItem][2] = ShoppingList[CurrentItem][2] - ItemTransfered -- reduces required amount
				if ShoppingList[CurrentItem][2] <= 0 then
					Count, ShoppingList = helpfuncs_RemoveElementFromList(ShoppingList, Count, CurrentItem)
				end
				CurrentItem = math.mod(CurrentItem, Count) + 1
				OpenSlots = OpenSlots - 1
			else 
				-- slot not used, check next item
				CurrentItem = CurrentItem + 1
			end 
		else
			-- invalid item, check next item (necessary to prevent endless loop)
			CurrentItem = CurrentItem + 1
		end
	end
	return Count, ShoppingList
end