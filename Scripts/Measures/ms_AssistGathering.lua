SUCK_RADIUS = 4500

function Init()
end

function AIInit()
	return "C"
end

local function CartHasGoods()
	local slots = InventoryGetSlotCount("", INVENTORY_STD)
	for s = 0, slots - 1 do
		local id, cnt = InventoryGetSlotInfo("", s, INVENTORY_STD)
		if id and id > 0 and cnt and cnt > 0 then
			return true
		end
	end
	return false
end

local function CartHasSpace()
	local slots = InventoryGetSlotCount("", INVENTORY_STD)
	for s = 0, slots - 1 do
		local id, cnt = InventoryGetSlotInfo("", s, INVENTORY_STD)
		if not id or id == 0 or not cnt or cnt == 0 then
			return true
		end
	end
	return false
end

local function DriveTowardField()
	local wcount = BuildingGetWorkerCount("Destination")
	local bestDist = -1
	local anyOut = false
	for i = 0, wcount - 1 do
		if BuildingGetWorker("Destination", i, "Scan") then
			if not GetInsideBuilding("Scan", "ScanBld") then
				anyOut = true
				local d = GetDistance("Destination", "Scan")
				if d and d > bestDist then
					bestDist = d
					BuildingGetWorker("Destination", i, "FieldAnchor")
				end
			end
		end
	end
	if bestDist >= 0 then
		f_MoveToNoWait("", "FieldAnchor", GL_MOVESPEED_RUN)
	end
	return anyOut
end

local function SuckNearbyWorkers()
	local got = false
	local wcount = BuildingGetWorkerCount("Destination")
	for i = 0, wcount - 1 do
		if not AliasExists("Destination") then break end
		if BuildingGetWorker("Destination", i, "Worker") then
			if not GetInsideBuilding("Worker", "WorkerBld")
				and GetDistance("", "Worker") <= SUCK_RADIUS then

				local pulled = 0
				local slots = InventoryGetSlotCount("Worker", INVENTORY_STD)
				for s = slots - 1, 0, -1 do
					local id, cnt = InventoryGetSlotInfo("Worker", s, INVENTORY_STD)
					if id and id > 0 and cnt and cnt > 0 then
						local space = GetRemainingInventorySpace("", id)
						if space and space > 0 then
							local take = cnt
							if take > space then take = space end
							local removed = RemoveItems("Worker", id, take, INVENTORY_STD)
							if removed and removed > 0 then
								AddItems("", id, removed, INVENTORY_STD)
								pulled = pulled + removed
								got = true
							end
						end
					end
				end
				if pulled > 0 then
					ShowOverheadSymbol("Worker", false, true, 0, "%1t", pulled)
				end
			end
		end
	end
	return got
end

local function DeliverToWorkshop()
	if not f_MoveTo("", "Destination") then
		return
	end
	local slots = InventoryGetSlotCount("", INVENTORY_STD)
	for s = slots - 1, 0, -1 do
		local id, cnt = InventoryGetSlotInfo("", s, INVENTORY_STD)
		if id and id > 0 and cnt and cnt > 0 then
			local err, moved, price = f_Transfer("", "Destination", INVENTORY_STD, "", INVENTORY_STD, id, cnt)
			if price and GetHomeBuilding("", "homeBuilding") then
				economy_UpdateBalance("homeBuilding", "WaresSold", math.abs(price))
			end
		end
	end
end

function Run()
	if not AliasExists("Destination") then
		StopMeasure()
		return
	end

	while AliasExists("Destination") do
		local anyOut = DriveTowardField()
		local sucked = SuckNearbyWorkers()

		if not CartHasSpace() then
			DeliverToWorkshop()
		elseif not anyOut then
			if CartHasGoods() then
				DeliverToWorkshop()
			end
			Sleep(6)
		elseif sucked then
			Sleep(2)
		else
			Sleep(3)
		end
	end

	StopMeasure()
end

function CleanUp()
end
