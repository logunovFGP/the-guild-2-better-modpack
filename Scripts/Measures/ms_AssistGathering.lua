function Init()
end

function AIInit()
	return "C"
end

local function CartHasGoods()
	local slots = InventoryGetSlotCount("", INVENTORY_STD)
	for s = 0, slots - 1 do
		local id, cnt = InventoryGetSlotInfo("", s, INVENTORY_STD)
		if id and cnt and cnt > 0 then
			return true
		end
	end
	return false
end

local function DeliverToWorkshop()
	if not f_MoveTo("", "Destination") then
		return
	end
	local slots = InventoryGetSlotCount("", INVENTORY_STD)
	for s = slots - 1, 0, -1 do
		local id, cnt = InventoryGetSlotInfo("", s, INVENTORY_STD)
		if id and cnt and cnt > 0 then
			local err, moved, price = f_Transfer("", "Destination", INVENTORY_STD, "", INVENTORY_STD, id, cnt)
			if price and GetHomeBuilding("", "homeBuilding") then
				economy_UpdateBalance("homeBuilding", "WaresSold", math.abs(price))
			end
		end
	end
end

local function HarvestWorker(WorkerAlias)
	if not f_MoveTo("", WorkerAlias) then
		return false
	end
	local got = false
	local slots = InventoryGetSlotCount(WorkerAlias, INVENTORY_STD)
	for s = slots - 1, 0, -1 do
		local id, cnt = InventoryGetSlotInfo(WorkerAlias, s, INVENTORY_STD)
		if id and cnt and cnt > 0 then
			local err, moved = f_Transfer(WorkerAlias, "", INVENTORY_STD, "", INVENTORY_STD, id, cnt)
			if moved and moved > 0 then
				got = true
			end
		end
	end
	return got
end

function Run()
	if not AliasExists("Destination") then
		StopMeasure()
		return
	end

	while AliasExists("Destination") do
		local collectedSomething = false

		local wcount = BuildingGetWorkerCount("Destination")
		for i = 0, wcount - 1 do
			if not AliasExists("Destination") then
				break
			end
			if BuildingGetWorker("Destination", i, "Worker") then
				if not GetInsideBuilding("Worker", "WorkerBld") then
					local slots = InventoryGetSlotCount("Worker", INVENTORY_STD)
					local hasGoods = false
					for s = 0, slots - 1 do
						local id, cnt = InventoryGetSlotInfo("Worker", s, INVENTORY_STD)
						if id and cnt and cnt > 0 then
							hasGoods = true
							break
						end
					end
					if hasGoods then
						if HarvestWorker("Worker") then
							collectedSomething = true
						end
					end
				end
			end
		end

		if CartHasGoods() then
			DeliverToWorkshop()
		end

		if not collectedSomething then
			Sleep(8)
		else
			Sleep(2)
		end
	end

	StopMeasure()
end

function CleanUp()
end
