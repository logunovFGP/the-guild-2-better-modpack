function kr_MirrorRoutes()
	if KontorSetRoute == nil then
		return
	end
	local frozen = GetData("#kr_freeze_all")
	local krCat
	for krCat = 1, 7 do
		local r = GetData("#kr_route_"..krCat)
		local open = 1
		if r ~= nil and r == 0 then open = 0 end
		if frozen ~= nil and frozen ~= 0 then open = 0 end
		KontorSetRoute("", krCat, open)

		if KontorSetLordship ~= nil then
			local lord = GetData("#kr_routelord_"..krCat)
			if lord == nil then lord = krCat end
			KontorSetLordship("", krCat, lord)
		end
	end
end

function Run()

	GetSettlement("", "City")

	ms_kontormeasure_kr_MirrorRoutes()

	local TimeToSleep = Gametime2Realtime(1)
	local LocalCityId = GetID("City")
	local Count

	while true do

		if ScenarioGetTimePlayed() > (24 + Rand(25)) then
			if Rand(100)>=90 then
				Count = GetData("#KontorEventCount")
				if (not Count) or Count<1 then
					if not GetState("", STATE_KONTOR_EVENT) then
						SetState("", STATE_KONTOR_EVENT, true)
					end
				end
			end
		end

		Sleep(TimeToSleep)

		ms_kontormeasure_kr_MirrorRoutes()

		if KontorFreezeAll ~= nil then
			local kf = GetData("#kr_freeze_all")
			if kf == nil then kf = 0 end
			KontorFreezeAll(kf)
		end

		local krFrozen = GetData("#kr_freeze_all")
		if krFrozen ~= nil and krFrozen ~= 0 then
			local fc = InventoryGetSlotCount("", INVENTORY_STD)
			local fg
			for fg = 0, fc - 1 do
				local fit, fam = InventoryGetSlotInfo("", fg, INVENTORY_STD)
				if fit and fit ~= -1 and fam and fam > 0 then
					RemoveItems("", fit, fam, INVENTORY_STD)
				end
			end
			RemoveEmptySlots("", INVENTORY_STD)
		else

		local now = GetGametime()
		local nextR = GetProperty("", "kr_next_refresh")
		if nextR == nil or now >= nextR then
			ms_kontormeasure_RefreshStock(LocalCityId)
			local hour = math.mod(now, 24)
			local to5 = 5 - hour
			if to5 <= 0 then to5 = to5 + 24 end
			SetProperty("", "kr_next_refresh", now + to5)
		end

		local sc = InventoryGetSlotCount("", INVENTORY_STD)
		local si
		for si = 0, sc - 1 do
			local sit = InventoryGetSlotInfo("", si, INVENTORY_STD)
			if sit and sit ~= -1 then
				ms_kontormeasure_SetKontorPrice(sit)
			end
		end

		end
	end
end

function RefreshStock(LocalCityId)
	local EventItem = GetProperty("", "EventItem")
	local EvID = -1
	if EventItem then EvID = ItemGetID(EventItem) end

	local fc = InventoryGetSlotCount("", INVENTORY_STD)
	local fg
	for fg = 0, fc - 1 do
		local fit, fam = InventoryGetSlotInfo("", fg, INVENTORY_STD)
		if fit and fit ~= -1 and fit ~= EvID and fam and fam > 0 then
			RemoveItems("", fit, fam, INVENTORY_STD)
		end
	end
	RemoveEmptySlots("", INVENTORY_STD)

	local items = {}
	local nItems = 0
	local cnt = ScenarioGetKontorGoodCount()
	local g
	for g = 0, cnt - 1 do
		local it, dm, cid = ScenarioGetKontorGoodInfo(g)
		if it ~= -1 and cid == LocalCityId and dm > 0 then
			items[nItems] = it
			nItems = nItems + 1
		end
	end
	if nItems == 0 then
		return
	end

	local pick = 4
	if pick > nItems then pick = nItems end
	local rot = GetProperty("", "kr_rot")
	if rot == nil then rot = 0 end

	local i
	for i = 0, pick - 1 do
		local idx = rot + i
		while idx >= nItems do idx = idx - nItems end
		local it = items[idx]
		local qty = 2 + Rand(4)
		AddItems("", it, qty, INVENTORY_STD)
		ms_kontormeasure_SetKontorPrice(it)
	end

	rot = rot + pick
	while nItems > 0 and rot >= nItems do rot = rot - nItems end
	SetProperty("", "kr_rot", rot)
end

function SetKontorPrice(Item)
	local Base = ItemGetBasePrice(Item)
	if Base == -1 then
		return
	end

	local PriceIn = Base * 0.1

	local Mult = 1.75
	if ItemGetCategory(Item) == 3 then
		Mult = 3.5
	end
	local PriceOut = Base * Mult

	CitySetFixedPrice("", Item, PriceIn, PriceOut, -1)
end
