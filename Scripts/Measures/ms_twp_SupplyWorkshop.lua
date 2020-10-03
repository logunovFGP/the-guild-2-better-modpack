-- Entry to enable use by players, MeasureToObjects.dbt:
-- 3099   13085   0   0   1509   3   ""   ()   ""   0   0   |

---
-- Measure: SupplyWorkshop
-- Author: ThreeOfMe
-- Mod: TWP -- Trade, War, Politics
--
-- This cart measure may be used to automatically supply a workshop with resources. 
-- It requires the table BuildingToItems to be up-to-date with the item production list.
-- 
-- The player may choose the following parts of the measure (see Init):
-- 
-- * The resources that should be supplied.
-- * The expected minimum for each resource that should be present in storage.
-- * The places that the cart may get the resources from.  
-- 
-- The base algorithm will then be (see Run):
--
-- 1. For each supplied resource, check current amount in storage.
-- 2. If resource amount is below minimum, add item and missing amount to a list.
-- 3. Sort the list by amounts, highest demand first.
-- 4. Check first possible supplier (i.e. market) for availability.
-- 5. If a resource is available, go and buy. 
-- 6. If space is left on cart, check other supplier for remaining items on list.
-- 7. Return to workshop, unload and restart at (1). 
--

function Init()
	local ResourceCount, Resources, SupplierCount, Suppliers = ms_twp_supplyworkshop_InitMeasure()
	ms_twp_supplyworkshop_SetMeasureData(ResourceCount, Resources, SupplierCount, Suppliers)
end

function GetResourcesForWorkshop(BldAlias)
	local BldId = BuildingGetProto(BldAlias)
	local ItemsString = GetDatabaseValue("BuildingToItems", BldId, "requireditems")
	if ItemsString == nil then
		return 0, {}
	end
	local Items = {}
	local Resources = {}
	local Count = 0
	for Id in string.gfind(ItemsString, "%d+") do
		Count = Count + 1
		Resources[Count] = { ItemGetID(Id), 20 }
	end
	return Count, Resources
end

function ChooseResources(ResourceCount, Resources)
	local ChosenItemId
	local Buttons = ""
	local Id, ItemTexture, Subtext
	local Tooltip = ""

	local ChosenItem
	repeat
		Buttons = "@P"
		for i=1, ResourceCount do
			Id = Resources[i][1]
			ItemTexture = "Hud/Items/Item_"..ItemGetName(Id)..".tga"
			Tooltip = ItemGetLabel(Id, false)
			Subtext = Resources[i][2]
			-- result, Tooltip, label, icon
			Buttons = Buttons.."@B[" .. i .. "," .. Subtext .. "," .. Tooltip .. "," .. ItemTexture .."]"
		end

		ChosenItem = InitData(
			Buttons, -- PanelParam
			0, -- AIFunc
			"@L_TWP_SUPPLYWORKSHOP_CHOOSERESOURCE_HEAD_+0",-- HeaderLabel
			"Body"
		)
		if ChosenItem and ChosenItem ~= "C" then
			local Options = "@B[80,80,]@B[60,60,]@B[50,50,]@B[40,40,]@B[30,30,]@B[20,20,]@B[10,10,]@B[0,0,]"
			local ItemId = Resources[ChosenItem][1]
			local ChosenMinAmount = MsgBox("","Owner","@P"..Options,"@L_TWP_SUPPLYWORKSHOP_CHOOSEAMOUNT_HEAD_+0","_TWP_SUPPLYWORKSHOP_CHOOSEAMOUNT_BODY_+0", ItemGetLabel(ItemId,false))			
			if ChosenMinAmount and ChosenMinAmount ~= "C" then
				Resources[ChosenItem][2] = ChosenMinAmount
			end
		end
	until ChosenItem == nil or ChosenItem =="C"
	
	return ResourceCount, Resources
end

function ChooseSuppliers(SupplierCount, Suppliers)
	local Choice
	local LabelIds = {}
	repeat
		local Options = "@P"
		-- show list of suppliers with option to add another one
		for i=1, SupplierCount do
			if BuildingGetClass(Suppliers[i]) == GL_BUILDING_CLASS_MARKET then
				-- use city name for markets
				Options = Options .. "@B["..i..",@L_TWP_SUPPLYWORKSHOP_MARKET_+"..i..",]"
				LabelIds[i] = GetSettlementID(Suppliers[i])
			else
				-- use Building name
				Options = Options .. "@B["..i..",%"..i.."GG,]"
				LabelIds[i] = GetID(Suppliers[i])
			end
		end
		-- TODO could this be done as icon list with building icons?
		Options = Options .. "@B[A,@L_TWP_SUPPLYWORKSHOP_ADDSUPPLIER_+0,]" .. "@B[C,@L_GENERAL_BUTTONS_OK_+0,]"
		Choice = MsgBox("","Owner",Options,"@L_TWP_SUPPLYWORKSHOP_INITIATE_HEAD_+0","_TWP_SUPPLYWORKSHOP_INITIATE_BODY_+0", helpfuncs_UnpackTable(LabelIds))
	
		if Choice == "A" then
			-- add new Supplier
			local SupplierAlias = ms_twp_supplyworkshop_SelectSupplier(SupplierCount)
			if SupplierAlias and AliasExists(SupplierAlias) then
				SupplierCount = SupplierCount + 1
				Suppliers[SupplierCount] = SupplierAlias
			end
		elseif Choice ~= "C" and Choice > 0 then
			-- delete this supplier from list and make sure to move other suppliers up by one
			SupplierCount, Suppliers = helpfuncs_RemoveElementFromList(Suppliers, SupplierCount, Choice)
		end
	until Choice == nil or Choice == "C"
	
	return SupplierCount, Suppliers
end

function SelectSupplier(Index)
	-- filter for waypoint selection
	InitAlias("Supplier"..Index, MEASUREINIT_SELECTION,
		"__F((Object.BelongsToMe()) OR (Object.IsClass(2)) OR (Object.IsClass(5)) AND (Object.Type == Building))",
		"@L_TRADEROUTE_NEXT_BUILDING_+0",0)
	return "Supplier"..Index
end

function InitMeasure()
  -- find home
	if not GetHomeBuilding("","MyHome") then
		return
	end
	local Choice
	-- initialize Resources: {{Item1, Min1}, {Item2, Min2}, ...}
	local ResourceCount, Resources = ms_twp_supplyworkshop_GetResourcesForWorkshop("MyHome")
	local SupplierCount = 0
	local Suppliers = {} -- {Supplier1, Supplier2, ...}
	-- add local market as supplier for convenience
	if GetSettlement("MyHome", "MyCity") then
		if CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, "MyMarket") then
			SupplierCount = 1
			Suppliers[1] = "MyMarket"
		end
	end 
	 
	repeat
		-- First dialog handles control: Help, Choose resources, Choose Suppliers, Start
		local Options = --"@B[1,@L_TWP_SUPPLYWORKSHOP_INITIATE_OPTION_+0,]".. -- Help
			"@B[2,@L_TWP_SUPPLYWORKSHOP_INITIATE_OPTION_+1,]".. -- Choose Resources
			"@B[3,@L_TWP_SUPPLYWORKSHOP_INITIATE_OPTION_+2,]".. -- Choose Suppliers
			"@B[4,@L_TWP_SUPPLYWORKSHOP_INITIATE_OPTION_+3,]" -- Start
			--"@B[C,@LAbort_+0,]" -- Abort by right mouse click
		
		Choice = MsgBox("","Owner","@P"..Options,"@L_TWP_SUPPLYWORKSHOP_INITIATE_HEAD_+0","_TWP_SUPPLYWORKSHOP_INITIATE_BODY_+0", GetID("MyHome"))
		
		if Choice == 1 then
			MsgBox("", "Owner", "", "@L_TWP_SUPPLYWORKSHOP_HELP_HEAD_+0", "@L_TWP_SUPPLYWORKSHOP_HELP_BODY_+0")
		elseif Choice == 2 then
			ResourceCount, Resources = ms_twp_supplyworkshop_ChooseResources(ResourceCount, Resources)
		elseif Choice == 3 then
			SupplierCount, Suppliers = ms_twp_supplyworkshop_ChooseSuppliers(SupplierCount, Suppliers)
		elseif Choice == nil or Choice == "C" then -- cancel
			StopMeasure()
		end
	until Choice == 4 -- Start measure
	
	return ResourceCount, Resources, SupplierCount, Suppliers
end

function Run() 
	-- find home 
	if not GetHomeBuilding("","MyHome") then
		return
	end
	if not GetOutdoorMovePosition("", "MyHome", "HomePos") then
		return
	end 

	local ResourceCount, Resources, SupplierCount, Suppliers = ms_twp_supplyworkshop_GetMeasureData()
	
	-- 1. Go home.
	if not IsInLoadingRange("", "MyHome") and not f_MoveTo("","HomePos", GL_MOVESPEED_RUN) then
		-- cannot get gome, something went wrong
		StopMeasure()
	end
	local CartSlots, CartSlotSize = cart_GetCartSlotInfo("")
	if CartSlots <= 0 then
		StopMeasure()
	end

	cart_UnloadAll("", "MyHome")
	
	local NeedCount, Needs
	while true do 
		-- 3. Calculate current demand at workshop
		local NeedCount, Needs = ms_twp_supplyworkshop_CalcResourceNeeds("MyHome", ResourceCount, Resources)
		if NeedCount and NeedCount > 0 then
			for i = 1, SupplierCount do
				if ms_twp_supplyworkshop_CheckAvailability(Suppliers[i], NeedCount, Needs) then
					f_MoveTo("", Suppliers[i], GL_MOVESPEED_RUN)
					Needs = ms_twp_supplyworkshop_GoShopping(Suppliers[i], NeedCount, Needs, CartSlots, CartSlotSize)
				end
			end
		else
			Sleep(120) -- nothing to do, wait a while
		end	
		
		-- return home if necessary
		if not IsInLoadingRange("", "MyHome") and not f_MoveTo("","HomePos", GL_MOVESPEED_RUN) then
			-- cannot get gome, something went wrong
			StopMeasure() 
		end
		-- Unload at home and rest
		cart_UnloadAll("", "MyHome")		
		Sleep(30) 
	end
end

function CheckAvailability(BldAlias, NeedCount, Needs)
	-- can only buy from market if I have enough money
	if BuildingGetClass(BldAlias) == GL_BUILDING_CLASS_MARKET or GetDynastyID("") ~= GetDynastyID(BldAlias) then
		if GetMoney("") < 200 then
			return false
		end
	end
	for i = 1, NeedCount do
		if Needs[i][2] > 0 and GetItemCount(BldAlias, Needs[i][1]) > 0 then
			return true
		end
	end
	return false
end

function GoShopping(BldAlias, NeedCount, Needs, CartSlots, CartSlotSize)
	local BldInv = INVENTORY_STD
	if GetDynastyID("") ~= GetDynastyID(BldAlias) and BuildingGetClass(BldAlias) ~= GL_BUILDING_CLASS_MARKET then
		-- use sales inventory for workshops of other dynasties
		BldInv = INVENTORY_SELL
	end
	if NeedCount and NeedCount > 0 then
		local CurrentItem = 1 
		local OpenSlots = CartSlots
		local ItemId, ReqAmount
		while OpenSlots > 0 and CurrentItem <= NeedCount do
			ItemId = Needs[CurrentItem][1]
			ReqAmount = Needs[CurrentItem][2]
			if ItemId and ReqAmount > 0 then
				local Error, ItemTransfered = Transfer("","",INVENTORY_STD,BldAlias, BldInv, ItemId, math.min(CartSlotSize, ReqAmount))
				-- 6. make sure list is repeated if slots are still available
				if ItemTransfered and ItemTransfered > 0 then
					-- update balance with estimated costs (TWP)
					--local EstimatedCost = ItemGetPriceBuy(ItemId,"MarketBld")*ItemTransfered
					--economy_UpdateBalance("MyHome", "Autoroute", -EstimatedCost)
					CurrentItem = math.mod(CurrentItem, NeedCount) + 1
					OpenSlots = OpenSlots - 1
					Needs[CurrentItem][2] = Needs[CurrentItem][2] - ItemTransfered
				else 
					-- slot not used, keep going
					CurrentItem = CurrentItem + 1
				end 
			end
		end
	end
	return Needs
end

function CalcResourceNeeds(BldAlias, ResourceCount, Resources)
	if ResourceCount <= 0 then
		return 0, {}
	end 
	local Needs = {}
	local NeedCount = 0
	for i = 1, ResourceCount do
		local CurrentAmount = GetItemCount(BldAlias, Resources[i][1])
		local MaxNeed = Resources[i][2]
		local ActualNeed = MaxNeed - CurrentAmount
		-- need resources when stores down to 60%
		if MaxNeed > 0 and ActualNeed > 0 and ActualNeed/MaxNeed >= 0.6 then
			NeedCount = NeedCount + 1
			ActualNeed = math.ceil(ActualNeed/MaxNeed * 100)
			Needs[NeedCount] = {Resources[i][1], ActualNeed}
		end
	end
	-- no current needs
	if NeedCount == 0 then
 		return 0, {}
 	end
 	
 	-- 4. sort by actual needs, highest first (SortProfits sorts highest first so it will do)
	Needs = helpfuncs_QuickSort(Needs, 1, NeedCount, ms_twp_supplyworkshop_SortNeeds)
	return NeedCount, Needs 
end

function SortNeeds(a,b) 
	return a[2] > b[2] 
end

function CleanUp()
end


function SetMeasureData(ResourceCount, Resources, SupplierCount, Suppliers)
	-- filter resources with a minimum of 0
	local ReducedResourceCount = 0
	for i = 1, ResourceCount do
		if Resources[i][2] > 0 then
			ReducedResourceCount = ReducedResourceCount + 1
			SetData("Resource"..ReducedResourceCount, Resources[i][1])
			SetData("ResourceMin"..ReducedResourceCount, Resources[i][2] )
		end
	end
	SetData("ResourceCount", ReducedResourceCount)
	SetData("SupplierCount", SupplierCount)
	for i = 1, SupplierCount do
		SetData("Supplier"..i, Suppliers[i])
	end
end

function GetMeasureData()
	local ResourceCount = GetData("ResourceCount")
	local Resources = {}
	for i = 1, ResourceCount do
		Resources[i] = { GetData("Resource"..i), GetData("ResourceMin"..i) }
	end
	local SupplierCount = GetData("SupplierCount")
	local Suppliers = {}
	for i = 1, SupplierCount do
		Suppliers[i] = GetData("Supplier"..i)
	end
	return ResourceCount, Resources, SupplierCount, Suppliers
end
