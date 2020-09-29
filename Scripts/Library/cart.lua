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
	local	ItemId
	local	ItemCount
	local	Error, ItemTransfered
	for i = 1, Slots do
		local ItemId, ItemCount = InventoryGetSlotInfo("", Slots-i)
		
		if ItemId and ItemCount then
			if CanAddItems(DestAlias, ItemId, ItemCount, INVENTORY_STD) then				
				Transfer(CartAlias,DestAlias,INVENTORY_STD,CartAlias,INVENTORY_STD,ItemId,ItemCount)
			else
				Transfer(CartAlias,DestAlias,INVENTORY_SELL,CartAlias,INVENTORY_STD,ItemId,ItemCount)
			end
		end
		Sleep(0.4)
	end
end
