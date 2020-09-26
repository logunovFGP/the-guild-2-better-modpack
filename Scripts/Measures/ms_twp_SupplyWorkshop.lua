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
	-- find home 
	if not GetHomeBuilding("","MyHome") then
		return
	end
	local Choice
	local ResourceCount = 0
	local Resources = {} -- {{Item1, Min1}, {Item2, Min2}, ...}
	local SupplierCount = 0
	local Suppliers = {} -- {Supplier1, Supplier2, ...}
	
	repeat
		-- First dialog handles control: Help, Choose resources, Choose Suppliers, Start
		local Options = "@B[1,@L_TWP_SUPPLYWORKSHOP_INITIATE_OPTION_+1,]".. -- Help
			"@B[2,@L_TWP_SUPPLYWORKSHOP_INITIATE_OPTION_+2,]".. -- Choose Resources
			"@B[3,@L_TWP_SUPPLYWORKSHOP_INITIATE_OPTION_+3,]".. -- Choose Suppliers
			"@B[4,@L_TWP_SUPPLYWORKSHOP_INITIATE_OPTION_+4,]" -- Start
			--"@B[C,@LAbort_+0,]" -- Abort by right mouse click
		
		Choice = MsgBox("","Owner","@P"..Options,"@L_TWP_SUPPLYWORKSHOP_INITIATE_HEAD_+0","_TWP_SUPPLYWORKSHOP_INITIATE_BODY_+0", GetID("MyHome"))
		
		if Choice == 1 then
			MsgBox("", "Owner", "", "@L_TWP_SUPPLYWORKSHOP_HELP_HEAD_+0", "@L_TWP_SUPPLYWORKSHOP_HELP_BODY_+0")
		elseif Choice == 2 then
			ResourceCount, Resources = ms_twp_supplyworkshop_ChooseResources(ResourceCount, Resources)
		elseif Choice == 3 then
			SupplierCount, Suppliers = ms_twp_supplyworkshop_ChooseSuppliers(SupplierCount, Suppliers)
		elseif vorgang == "C" then -- cancel
			StopMeasure()
		end
	until Choice == 4 -- Start measure
	-- TODO SetData for Run-function
end


function ChooseResources(ResourceCount, Resources)
	-- TODO implement by using BuildingToItems and MeasureInit (icon dialog)
	return ResourceCount, Resources
end

function ChooseSuppliers(SupplierCount, Suppliers)
	local Choice
	repeat
		local Options = "@P"
		-- show list of suppliers with option to add another one
		for i=1, SupplierCount do
			Options = Options .. "@B["..i..","..GetName(Suppliers[i])..",]"
		end
		-- TODO could this be done as icon list with building icons?
		Options = Options .. "@B[A,@L_TWP_SUPPLYWORKSHOP_ADDSUPPLIER_+0,]" .. "@B[C,@LAbort_+0,]"
		Choice = MsgBox("","Owner",Options,"@L_TWP_SUPPLYWORKSHOP_INITIATE_HEAD_+0","_TWP_SUPPLYWORKSHOP_INITIATE_BODY_+0", GetID("MyHome"))
	
		if Choice == "A" then
			-- add new Supplier
			local SupplierAlias = ms_twp_supplyworkshop_SelectSupplier(SupplierCount)
			if SupplierAlias and AliasExists(SupplierAlias) then
				SupplierCount = SupplierCount + 1
				Suppliers[SupplierCount] = GetID(SupplierAlias)
			end
		elseif Choice ~= "C" and Choice > 0 then
			-- TODO delete this supplier from list, make sure to move other suppliers up by one or ignore empty places in list
		end
	until Choice == "C"
	
	return SupplierCount, Suppliers
end

function SelectSupplier(Index)
	-- filter for waypoint selection
	local Success = InitAlias("Supplier"..Index, MEASUREINIT_SELECTION,
		"__F((Object.BelongsToMe()) OR (Object.IsClass(2)) OR (Object.IsClass(5)) AND (Object.Type == Building))",
		"@L_TRADEROUTE_NEXT_BUILDING_+0",0)
	if Success then
		return "Supplier"..Index
	else 
		return nil
	end
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
		StopMeasure()
	end
	local CartSlots, CartSlotSize = cart_GetCartSlotInfo("")
	if CartSlots <= 0 then
		StopMeasure()
	end

	cart_UnloadItems(CartSlots, CartSlotSize, "MyHome")
	
	while true do 
		-- 3. Calculate current demand at workshop
		
		-- 4. Check suppliers and go there
		
		-- return home if necessary
		if not IsInLoadingRange("", "MyHome") and not f_MoveTo("","HomePos", GL_MOVESPEED_RUN) then
			-- cannot get gome, something went wrong
			Sleep(60)
			StopMeasure() 
		end
		-- Unload at home and wait some time
		ms_twp_autocart_UnloadItems(CartSlots, CartSlotSize, "MyHome")		
		Sleep(120) 
	end
end


-- unload at home and fill with dummy items (prevents AI from filling up the slots)
function UnloadItems(CartSlots, CartSlotSize, HomeAlias)
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
end

function SortProfits(a,b) 
	return a[2] > b[2] 
end

function CleanUp()
end
