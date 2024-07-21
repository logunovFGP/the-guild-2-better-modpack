function SpendMoney(Alias, Amount, Purpose)
	if DynastyIsPlayer(Alias) or IsGUIDriven() then
		-- call hardcoded f_SpendMoney since it works for these cases
		-- LogMessage("AITWP::SpendMoney::"..Purpose.." on "..GetName(Alias))
		return SpendMoney(Alias, Amount, Purpose)
	else
		-- save to property for later transfer
		if not GetDynasty(Alias, CRD_DYN_ALIAS) then
			return SpendMoney(Alias, Amount, Purpose)
		end
		local Current = GetProperty(CRD_DYN_ALIAS, "AITWP_Money") or 0
		SetProperty(CRD_DYN_ALIAS, "AITWP_Money", Current - Amount)
		return true
	end
end

function BeginUseLocator(Actor, LocatorName, Stance, MoveToLocator, Speed)
	
	if not AliasExists(Actor) or not AliasExists(LocatorName) then
		return false
	end
	if not BlockLocator(Actor, LocatorName) then
		return false
	end
	
	if(MoveToLocator) then 
		if not f_MoveTo(Actor, LocatorName, Speed) then
			ReleaseLocator(Actor, LocatorName)
			return false
		end
	end
	
	local WaitTime = CUseLocator(Actor, Stance)
	Sleep(WaitTime)

	return true
end

function BeginUseLocatorWeak(Actor, LocatorName, Stance, MoveToLocator, Speed)
	if not BlockLocator(Actor, LocatorName) then
		return false  
	end
	
	if(MoveToLocator) then 
		if not f_WeakMoveTo(Actor, LocatorName, Speed) then
			ReleaseLocator(Actor, LocatorName)
			return false
		end
	end
	
	local WaitTime = CUseLocator(Actor, Stance)
	Sleep(WaitTime)

	return true
end

function BeginUseLocatorNoWait(Actor, LocatorName, Stance, MoveToLocator)
	if not BlockLocator(Actor, LocatorName) then
		return false
	end
	
	if(MoveToLocator) then
		if not f_MoveToNoWait(Actor, LocatorName) then
			ReleaseLocator(Actor, LocatorName)
			return false
		end
	end
	CUseLocator(Actor, Stance)
	return true
end

function EndUseLocator(Actor, LocatorName, Stance)

	if not AliasExists(Actor) then
		return false
	end

	if LocatorName and AliasExists(LocatorName) then
		if LocatorGetBlocker(LocatorName) ~= GetID(Actor) then
			return false
		end
	end
	
	if Stance==nil or Stance=="" then
		Stance = GL_STANCE_STAND
	end
	
	local WaitTime = CUseLocator(Actor, Stance)
	Sleep(WaitTime)
	
	return ReleaseLocator(Actor, LocatorName)
end

function EndUseLocatorNoWait(Actor, LocatorName, Stance)

	if LocatorName and AliasExists(LocatorName) then
		if LocatorGetBlocker(LocatorName) ~= GetID(Actor) then
			return false
		end
	end

	CUseLocator(Actor, Stance)
	return ReleaseLocator(Actor, LocatorName)
end

function AttendMoveTo(Owner,Destination,Speed,Hours)

	for i=0,(Hours*2-1) do
		if f_MoveTo(Owner,Destination,Speed)==true then
			return true
		end

		if BuildingGetCutscene(Destination,"_a_cutscene") then
			f_Stroll(Owner, 300.0, 2.0)
			MsgSay(Owner,"@L_NEWSTUFF_WAITING_COMPLAINTS")
			Sleep(15)
			f_Stroll(Owner, 250.0, 2.0)
			Sleep(15)
		else
			return false
		end
	end
	return false
end

function MoveToSilent(Owner, Destination, iSpeed, fRange)
	if not AliasExists(Destination) then
		return false
	end
	local Result
	local ResultName
		ResultName = "__MoveToResult_"..GetID(Owner).."_"..GetID(Destination)
		Result = CMoveTo(Owner, Destination, iSpeed, ResultName, fRange, true)	
		if (Result) then 
			WaitForMessage("WaitForTask")
	 		local lateresult = GetProperty(Owner, ResultName)
			RemoveProperty(Owner, ResultName)
			if lateresult == NIL or lateresult ~= GL_MOVERESULT_TARGET_REACHED then 
				-- if IsType("","Sim") then
					-- ai_ShowMoveError(lateresult, Owner)
				-- end
				return false
			end
			return true
		end
	-- end
	
	-- ai_ShowMoveError(GL_MOVERESULT_ERROR_TARGET_UNREACHABLE, Owner)
	return false
end

function MoveTo(Owner, Destination, iSpeed, fRange, Special)
	if not AliasExists(Owner) then
		return false
	end
	
	if not AliasExists(Destination) then
		return false
	end

	if Special == "AIDance" then
		SetProperty(Destination, "GoToDance", 1)
	elseif Special == "AIService" then
		SetProperty(Destination, "GoToService", 1)
	end

	StopAllAnimations("")

	--workaround for spinning carts...
	SetState(Owner, STATE_CHECKFORSPINNINGS, true)
	----------------------------------

	--workaround for unreachable entry locators...
	if HasProperty(Owner,"BlockLocB") then
		if SimIsInside(Owner) and (GetProperty(Owner,"BlockLocB") == GetInsideBuildingID(Owner)) then
			f_ExitCurrentBuilding(Owner)
		else
			RemoveProperty(Owner,"BlockLocB")
		end
	end
	----------------------------------------------
	
	local ResultName = "__MoveToResult_"..GetID(Owner).."_"..GetID(Destination)
	local Result = CMoveTo(Owner, Destination, iSpeed, ResultName, fRange, true)

	if (Result) then
		WaitForMessage("WaitForTask")
		local lateresult = GetProperty(Owner, ResultName)
		RemoveProperty(Owner, ResultName)
		
		if lateresult == NIL or lateresult ~= GL_MOVERESULT_TARGET_REACHED then 
			if IsType(Owner, "Sim") then
				ai_ShowMoveError(lateresult, Owner)
			end
			--workaround for spinning carts...
			SetState(Owner, STATE_CHECKFORSPINNINGS, false)
			----------------------------------
			return false
		end
		--workaround for spinning carts...
		SetState(Owner, STATE_CHECKFORSPINNINGS, false)
		----------------------------------
		return true
	end

	--workaround for unreachable entry locators...
	if IsType(Destination, "cl_Building") and BuildingCanBeEntered(Destination,Owner) then

		local locator = "Walledge1"
		GetLocatorByName(Destination, locator, "entry")
		
		if AliasExists("entry") then
			
			local ResultName2 = "__MoveToResult_"..GetID(Owner).."_"..GetID(Destination)
			local Result2 = CMoveTo(Owner, "entry", iSpeed, ResultName, fRange, true)
			
			
			if (Result2) then
				WaitForMessage("WaitForTask")
				local lateresult = GetProperty(Owner, ResultName2)
				RemoveProperty(Owner, ResultName2)
				
				if lateresult == NIL or lateresult ~= GL_MOVERESULT_TARGET_REACHED then 
					local locator = "Walledge2"
					GetLocatorByName(Destination, locator, "entry")

					local Result3 = CMoveTo(Owner, "entry", iSpeed, ResultName, fRange, true)
				end

				SetProperty(Owner, "BlockLocL", locator)
				SetProperty(Owner, "BlockLocB", GetID(Destination))
			end
			--workaround for spinning carts...
			SetState(Owner, STATE_CHECKFORSPINNINGS, false)

			SimBeamMeUp(Owner, Destination, false)
			return true
		else
			return false
		end

	end
	----------------------------------------------

	ai_ShowMoveError(GL_MOVERESULT_ERROR_TARGET_UNREACHABLE, Owner)
	--workaround for spinning carts...
	SetState(Owner, STATE_CHECKFORSPINNINGS, false)
	----------------------------------
	return false
end

function MoveToBuildingAction(Owner, Destination, iSpeed, fRange)
	local Moving = true
	local OwnerOutside = false
	local DestOutside = false
	local Distance

	while Moving == true do

		if not GetInsideRoom(Owner,"OwnerRoom") then
			OwnerOutside = true
		end
		if not GetInsideRoom(Destination,"DestRoom") then
			DestOutside = true
		end

		if (OwnerOutside == false) and (DestOutside == true) then
			f_ExitCurrentBuilding(Owner)
		elseif (OwnerOutside == true) and (DestOutside == false) then
			f_MoveTo(Owner, Destination, iSpeed, fRange)
		end

		if (GetID("OwnerRoom") == GetID("DestRoom")) or ((OwnerOutside == true) and (DestOutside == true)) then
			Distance = GetDistance(Owner,Destination)
			if Distance > fRange then
				f_MoveToNoWait(Owner, Destination, iSpeed, fRange)
				f_MoveToNoWait(Destination, Owner, iSpeed, fRange)
			end

			if Distance > 3000 then
				Sleep(10)
			elseif Distance > 2200 then
				Sleep(6)
			elseif Distance > 1700 then
				Sleep(4)	
			elseif Distance > 1200 then
				Sleep(2)
			elseif Distance > 820 then
				Sleep(0.6)
			elseif Distance < 270 then
				Moving = false
				return true
			else
				Sleep(2)
			end
		end
	end

	return false
end

function WeakMoveTo(Owner, Destination, iSpeed, fRange)
	local ResultName = "__MoveToResult_"..GetID(Owner).."_"..GetID(Destination)
	if not AliasExists(Destination) then
		return false
	end
	local Result = CMoveToWeak(Owner, Destination, iSpeed, ResultName, fRange, true)
	if (Result) then 
		WaitForMessage("WaitForTask")
		--local lateresult = GetData(ResultName)
 		local lateresult = GetProperty(Owner, ResultName)
		RemoveProperty(Owner, ResultName)
		if lateresult == nil or lateresult ~= GL_MOVERESULT_TARGET_REACHED then 
			if IsType(Owner, "Sim") then
				ai_ShowMoveError(lateresult, Owner)
			end
			return false
		end
		return true
	end
	ai_ShowMoveError(GL_MOVERESULT_ERROR_TARGET_UNREACHABLE, Owner)
	return false
end

function Follow(pOwner, pDestination, iSpeed, fRange, bFollowOnce)
	if not pDestination or not GetID(pDestination) then
		return
	end
	
	local ResultName = "__FollowResult_"..GetID(pOwner).."_"..GetID(pDestination)
	
	local Result = CFollow(pOwner, pDestination, iSpeed, ResultName, fRange, bFollowOnce, true)
	if (Result) then 
		WaitForMessage("WaitForTask")
		--local lateresult = GetData(ResultName)
 		local lateresult = GetProperty("", ResultName)
		RemoveProperty("", ResultName)
		if lateresult ~= GL_MOVERESULT_TARGET_REACHED then 
			ai_ShowMoveError(lateresult, pOwner)
			return false
		end
		return true
	end
	ai_ShowMoveError(GL_MOVERESULT_ERROR_TARGET_UNREACHABLE, pOwner)
	return Result
end	


function MoveToNoWait(pOwner, pDestination, iSpeed, fRange) 
	--workaround for spinning carts...
	SetState(pOwner, STATE_CHECKFORSPINNINGS, true)
	----------------------------------
	return CMoveTo(pOwner, pDestination, iSpeed, NIL, fRange, false)
end

function WeakMoveToNoWait(Owner, Destination, iSpeed, fRange)
	return CMoveToWeak(Owner, Destination, iSpeed, NIL, fRange, true)
end
	
function FollowNoWait(pOwner, pDestination, iSpeed, fRange, bFollowOnce)
	if not AliasExists(pOwner) or not AliasExists(pDestination) then
		return false
	end

	return CFollow(pOwner, pDestination, iSpeed, NIL, fRange, bFollowOnce, false)
end	

function Fight(pSource, pDestination, Type)
	local Result=CFight(pSource,pDestination, Type)	
	if(Result) then
		WaitForMessage("WaitForTask")
	end
	return Result
end
	
function FightNoWait(pSource, pDestination, Type)
	return CFight(pSource, pDestination, Type)
end

function Stroll(pSource, Range, Duration)
	local Result = CStroll(pSource,Range,Duration)
	if(Result) then
		WaitForMessage("WaitForTask")
	end
end
  
function StrollNoWait(pSource, Range, Duration)
	return CStroll(pSource,Range,Duration)
end
			
function ExitCurrentBuilding(Alias)
	if not AliasExists(Alias) then
		return false
	else
		local Result = CExitCurrentBuilding(Alias)
		if (Result) then
			WaitForMessage("WaitForTask")
		end
	
		--workaround for unreachable entry locators...
		if HasProperty(Alias,"BlockLocB") then
	    	GetNearestSettlement(Alias, "TheCity")
	    	CityGetNearestBuilding("TheCity", Alias, -1, -1, -1, -1, FILTER_IGNORE, "TheBuilding")
			local l = GetProperty(Alias, "BlockLocL")
			local b = GetProperty(Alias, "BlockLocB")
			RemoveProperty(Alias, "BlockLocL")
			RemoveProperty(Alias, "BlockLocB")
	
			if GetID("TheBuilding") == b then
				GetLocatorByName("TheBuilding", l, "entry")
				SimBeamMeUp(Alias, "entry", false)
			end
		end
		----------------------------------------------

		return Result
	end
end

function GetRandomPositionFromAlias(AliasName,Range)
	GetPosition(AliasName,"NewPos")
	local X,Y,Z = PositionGetVector("NewPos")
	X = X + ((Rand(Range)*2)-Range)
	Z = Z + ((Rand(Range)*2)-Range)
	PositionModify("NewPos",X,Y,Z)
	return "NewPos"
end

function SimIsValid(Target)

	if (not AliasExists(Target) or
	GetHP(Target) < 1 or 
	GetStateImpact(Target, "no_control")) then
		return false
	else
		return true
	end
end

function GetNearestMapExit(Alias, RetAlias)

	GetScenario("World")
	local Distance
	local ExitIndex
	
	for i=1, 5 do
		if not HasProperty("World", "BrokenMapExit"..i) then
			if GetOutdoorLocator("MapExit"..i, 1, "ExitLocator") then
				local Tmp = GetDistance(Alias, "ExitLocator")
				if Tmp and Tmp >= 0 then
					if not Distance or Tmp < Distance then
						Distance = Tmp
						CopyAlias("ExitLocator", RetAlias)
						ExitIndex = i
					end
				end
			end
		end
	end
	
	return ExitIndex
end

function BlockMusicForConcert(force)
	SetData("#BlockMusicForConcert",force)
	if force==1 then
		StartHighPriorMusic(39, true)
	end
end

function StartHighPriorMusic(event, val)
	if GetData("#BlockMusicForConcert")==nil or GetData("#BlockMusicForConcert")==0 then
		if val then
			StartHighPriorMusic(event, val)
		else
			StartHighPriorMusic(event)
		end
	end
end

function GetDatabaseIdByName(table, name)
	local id = 1
	while id<1000 do
		if (GetDatabaseValue(table, id, "name") == name) then
			break
		else
			id = id + 1
		end
	end
	return id
end

function GetLocalPolitician(SimAlias, SameDyn, ResultAlias)
	
	if not GetSettlement(SimAlias, "City") then
		return false
	end
	
	local OffLevel = CityGetHighestOfficeLevel("City")
	local RandomOff= 0
	
	while OffLevel > 0 do
		local Offices = SettlementGetOfficeCnt("City", OffLevel)
		if Offices > 1 then
			RandomOff = Rand(Offices)
		else
			RandomOff = 0
		end
		
		if not SettlementGetOfficeHolder("City", OffLevel, RandomOff, "Mayor") then
			OffLevel = OffLevel  -1
		else
			CopyAlias("Mayor", ResultAlias)
			return true
		end
	end
	
	return false
end

function Transfer(Executer, Buyer, BuyerInv, Seller, SellerInv, Item, ItemCount)
	if not AliasExists(Buyer) or not AliasExists(Seller) then
		return nil
	end
	
	if IsType(Buyer, "Market") or IsType(Seller, "Market") then
--		LogMessage("f_Transfer was called with market type instead of market building!")
	end

	local RequiresPayment = (GetDynastyID(Buyer) ~= GetDynastyID(Seller))
	local UseBuyPrice = IsType(Seller, "Market") or BuildingGetClass(Seller) == GL_BUILDING_CLASS_MARKET
	local UseSellPrice = IsType(Buyer, "Market") or BuildingGetClass(Buyer) == GL_BUILDING_CLASS_MARKET
	
	local PriceBefore = ItemGetBasePrice(Item)
	if UseBuyPrice 
			and GetHomeBuilding(Buyer, "TransferHomeBld")
			and BuildingGetOwner("TransferHomeBld", "TransferBargOwner")
			and GetSettlement(Seller, "TransferBargCity") then
		CityGetLocalMarket("TransferBargCity", "TransferBargMarket")
		PriceBefore = ItemGetPriceBuy(Item, "TransferBargMarket")
	end
	
	if UseSellPrice 
			and GetHomeBuilding(Seller, "TransferHomeBld")
			and BuildingGetOwner("TransferHomeBld", "TransferBargOwner")
			and GetSettlement(Buyer, "TransferBargCity") then
		CityGetLocalMarket("TransferBargCity", "TransferBargMarket")
		PriceBefore = ItemGetPriceSell(Item, "TransferBargMarket")
	end
	
	local ErrorNumber, TransfItemCount = Transfer(Executer, Buyer, BuyerInv, Seller, SellerInv, Item, ItemCount)
	--LogTransferError(ErrorNumber, Buyer, Seller, Item, ItemCount)
	if not RequiresPayment then
		return ErrorNumber, TransfItemCount
	end
	
	if not AliasExists("TransferBargOwner") then
		if not ErrorNumber or ErrorNumber == 0 then
			f_LogTransferError(1, Buyer, Seller, Item, ItemCount)
		else
			f_LogTransferError(ErrorNumber, Buyer, Seller, Item, ItemCount)
		end

		return ErrorNumber, TransfItemCount
	end

	local PriceAfter = ItemGetBasePrice(Item)
	if UseBuyPrice and AliasExists("TransferBargMarket") then
		PriceAfter = ItemGetPriceBuy(Item, "TransferBargMarket")
	end
	
	if UseSellPrice and AliasExists("TransferBargMarket") then
		PriceAfter = ItemGetPriceSell(Item, "TransferBargMarket")
	end
	
	-- average price per item
	local Price = (PriceBefore + PriceAfter) / 2 -- still an estimate, but closer then just taking one of the two
	
	-- total price for all transfered items
	local TotalPrice = math.floor(TransfItemCount * Price)
	
	-- Calc bargaining bonus
	local BargainMoney = math.floor(TotalPrice*((GetSkillValue("TransferBargOwner", BARGAINING)*2)/100))
	
	-- give normal bargaining bonus for player
	if DynastyIsPlayer("TransferBargOwner") then
		local BalanceSheet = "WaresSold"
		if CartType == EN_CT_CORSAIR or CartType == EN_CT_FISHERBOOT or CartType == EN_CT_MERCHANTMAN_SMALL or
			CartType == EN_CT_MERCHANTMAN_BIG or CartType == EN_CT_WARSHIP then
			BalanceSheet = "WaresSeaSold"
		end
		chr_CreditMoney("TransferBargOwner", BargainMoney, BalanceSheet)
		Sleep(0.5)
		ShowOverheadSymbol(Executer, false, false, 0, "@L(+ %1t)", BargainMoney)
		return ErrorNumber, TransfItemCount, TotalPrice
	end
	
	-- use workaround for AI: SpendMoney and CreditMoney
	if UseSellPrice then
		-- Selling action (can only be at market)
		TotalPrice = math.max(0, TotalPrice + BargainMoney)
		chr_CreditMoney("TransferBargOwner", TotalPrice, "WaresSold")
	else
		-- buying action (may be at market or other workshop)
		TotalPrice = math.max(0, TotalPrice - BargainMoney)
		chr_SpendMoney(Buyer, TotalPrice, "WaresBought")
		if BuildingGetClass(Seller) ~= GL_BUILDING_CLASS_MARKET and not IsType(Seller, "Market") and DynastyIsAI(Seller) then
			chr_CreditMoney(Seller, TotalPrice, "WaresSold")
		end
	end
	return ErrorNumber, TransfItemCount, TotalPrice
end

function LogTransferError(ErrorNumber, BuyerAlias, SellerAlias, ItemId, ItemCount)
	if ErrorNumber==TRANSFER_SUCCESS then
		return
	end

	local TransferErrorList= 
	{
		[TRANSFER_RESULT_UNKNOWN] = "Unknown Error";
		[TRANSFER_ERROR_ILLEGAL] = "Illegal";
		[TRANSFER_ERROR_NO_MARKET] = "No market";
		[TRANSFER_ERROR_ILLEGAL_ITEM] = "Illegal item";
		[TRANSFER_ERROR_OUT_OF_RANGE] = "Out of range";
		[TRANSFER_ERROR_ILLEGAL_EXECUTER] = "Illegal executer";
		[TRANSFER_ERROR_NO_ITEM_AT_SOURCE] = "No item at source";
		[TRANSFER_ERROR_NO_SPACE_AT_DEST] = "No space at destination";
		[TRANSFER_ERROR_ACCESS_DENIED] = "Access denied";
		[TRANSFER_ERROR_NOT_COMPLETE_TRANSFER] = "not enough items for a complete transfer";
		[TRANSFER_ERROR_NOT_ENOUGH_MONEY] = "not enough money";
		[TRANSFER_ERROR_INVALID_ITEM] = "Invalid item"
	}
	
	local Text = TransferErrorList[ErrorNumber]
	if Text then
		local	BuyerName = "(unknown)"
		if AliasExists(BuyerAlias) then
			BuyerName = GetName(BuyerAlias)
		end

		local	SellerName = "(unknown)"
		if AliasExists(SellerAlias) then
			SellerName = GetName(SellerAlias)
		end
		
		local	ItemName = ItemGetName(ItemId) or "(unknown)"
		ItemCount = ItemCount or -1

		local Msg = string.format("LogTransferError::%i %s : Transfer %i %s from %s to %s", ErrorNumber, Text, ItemCount, ItemName, SellerName, BuyerName)
		LogMessage("LogTransferError::" .. ErrorNumber .. " " .. Text)
	end
end


