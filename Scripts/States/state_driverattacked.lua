function Init()
	SetStateImpact("no_hire")
	SetStateImpact("no_control")
	SetStateImpact("no_attackable")
	SetStateImpact("no_measure_attach")
	SetStateImpact("no_measure_start")	
	SetStateImpact("no_action")	
end

function Run()

	if not (GetVehicle("", "MyCart")) then
		return
	end 

	if not ExitCurrentVehicle("MyCart") then
		return
	end

	if not GetEvadePosition("", 1200, "fleepos") then
	 	return
	end
	
	SetProperty("MyCart", "BeingPlundered", 1)

 	f_MoveTo("", "fleepos", GL_MOVESPEED_RUN)
	AlignTo("", "MyCart")
	Sleep(1)

	PlayAnimation("", "insult_character")
	PlayAnimation("", "threat")
	local	Empty
	local	ItemID
	local ItemCount
	local Slots
	
	--scan for enemies
	local Enemies = 1
	while (Enemies > 0) do
	
		Enemies = Find("MyCart","__F( (Object.GetObjectsByRadius(Sim) == 1200)AND(Object.IsHostile()) AND(Object.HasProperty(DontLeave)) )", "FindResult",-1)
		
		Slots = InventoryGetSlotCount("MyCart", INVENTORY_STD)
		Empty = true
		
		for s=0, Slots-1 do
			ItemID, ItemCount = InventoryGetSlotInfo("MyCart", INVENTORY_STD, s)
			if ItemID ~= nil and ItemCount ~= nil and ItemCount > 0 and ItemID ~= 999 then
				Empty = false
				break
			end
		end
		
		if Empty or Enemies < 1 then
			break
		end
		
		Sleep(1)
	end
		
	--return to cart
	if not AliasExists("MyCart") then
		if not (GetVehicle("", "MyCart")) then
			return
		end
	end

	local radius = GetRadius("MyCart")
	f_MoveTo("", "MyCart", GL_MOVESPEED_RUN, radius )
	AlignTo("", "MyCart")	
end

function CleanUp()
	--return to cart
	if not AliasExists("MyCart") then
		if not (GetVehicle("", "MyCart")) then
			return
		end
	end
	EnterVehicle("", "MyCart")
	
	if GetCurrentMeasureName("MyCart") == "WorldTrader" then
		if GetHomeBuilding("MyCart", "Home") then
			f_MoveToNoWait("MyCart", "Home")
		end
	end
end

