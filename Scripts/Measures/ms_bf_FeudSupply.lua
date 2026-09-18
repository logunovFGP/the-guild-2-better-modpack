-- The feud supply run, on a residence cart (BloodFeud/bf_Procure starts it). Stops in
-- order: the house's own workshops for the reserve kept back from sale, the home
-- town's market or Kontor, its ownerless and foreign workshops that sell and the
-- resource buildings in its surroundings, then every other town the same way. One of each tool per run (aitwp_ShoppingList); unload at
-- the residence. Nobody of the house walks to market for the feud. Ends with a
-- ::TWP::CART action=arrive line, result= the count brought home.
function Run()
	MeasureSetNotRestartable()
	if not GetHomeBuilding("", "Home") or not GetDynasty("", "Dyn") then
		StopMeasure()
		return
	end
	local PlayerID = GetProperty("Dyn", "AI_BloodEnemyOf") or 0
	if PlayerID <= 0 or not GetAliasByID(PlayerID, "PlayerDyn") then
		StopMeasure()
		return
	end
	local Needs = {}
	local N = aitwp_ShoppingList("Dyn", "PlayerDyn", Needs)
	local Wanted = N
	N, Needs = ms_bf_feudsupply_CollectReserve(N, Needs)
	if N > 0 and GetSettlement("Home", "MyCity") then
		N, Needs = ms_bf_feudsupply_BuyInTown("MyCity", N, Needs)
	end
	local Cities = ScenarioGetObjects("Settlement", 20, "City")
	for i = 0, Cities - 1 do
		if N > 0 and (not AliasExists("MyCity") or GetID("City" .. i) ~= GetID("MyCity")) then
			N, Needs = ms_bf_feudsupply_BuyInTown("City" .. i, N, Needs)
		end
		RemoveAlias("City" .. i)
	end
	if GetOutdoorMovePosition("", "Home", "HomePos") and (IsInLoadingRange("", "Home") or f_MoveTo("", "HomePos", GL_MOVESPEED_RUN)) then
		cart_UnloadAll("", "Home")
	end
	local Total, Busy = aitwp_ResidenceCarts("Dyn", "Other")
	aitwp_LogCart("Dyn", "arrive", "", Total, Busy, Needs, N, Wanted - N)
	StopMeasure()
end

-- The house's own workshops: the reserve kept back from sale (AI_Reserve_<item>, set
-- daily by aitwp_ReserveProduction), free, at most the reserve per item and day.
function CollectReserve(N, Needs)
	local Buildings = DynastyGetBuildingCount2("Dyn")
	for b = 0, Buildings - 1 do
		if N > 0 and DynastyGetBuilding2("Dyn", b, "Own") and BuildingGetClass("Own") == GL_BUILDING_CLASS_WORKSHOP then
			if (GetProperty("Own", "AI_ReserveDay") or -1) ~= GetRound() then
				SetProperty("Own", "AI_ReserveDay", GetRound())
				for i = 1, N do
					SetProperty("Own", "AI_ReserveTaken_" .. ItemGetName(Needs[i][1]), 0)
				end
			end
			local Moved = false
			for i = 1, N do
				local Name = ItemGetName(Needs[i][1])
				local Reserve = GetProperty("Own", "AI_Reserve_" .. Name) or 0
				local Taken = GetProperty("Own", "AI_ReserveTaken_" .. Name) or 0
				local Take = math.min(Needs[i][2], Reserve - Taken, GetItemCount("Own", Needs[i][1], INVENTORY_STD))
				if Take > 0 and (Moved or IsInLoadingRange("", "Own") or f_MoveTo("", "Own", GL_MOVESPEED_RUN)) then
					Moved = true
					local _, Got = f_Transfer("", "", INVENTORY_STD, "Own", INVENTORY_STD, Needs[i][1], Take)
					Got = Got or 0
					SetProperty("Own", "AI_ReserveTaken_" .. Name, Taken + Got)
					Needs[i][2] = Needs[i][2] - Got
				end
			end
			local Kept = {}
			for i = 1, N do
				if Needs[i][2] > 0 then
					Kept[#Kept + 1] = Needs[i]
				end
			end
			Needs, N = Kept, #Kept
		end
	end
	RemoveAlias("Own")
	return N, Needs
end

-- One town: its market or Kontor, then its ownerless and foreign workshops that sell.
function BuyInTown(CityAlias, N, Needs)
	if CityGetRandomBuilding(CityAlias, -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, "Shop")
			or CityGetRandomBuilding(CityAlias, -1, GL_BUILDING_TYPE_KONTOR, -1, -1, FILTER_IGNORE, "Shop") then
		N, Needs = ms_bf_feudsupply_BuyAt("Shop", N, Needs)
		RemoveAlias("Shop")
	end
	-- Workshops first, then the resource buildings in the surroundings - farms, mills,
	-- fruitfarms, rangerhuts, fishing huts. Only the workshop class was scanned before,
	-- so anything a town produced but did not stock at the market read as unavailable:
	-- session 4 reported Voodo, BlackWidowPoison and Mixture as findable "nowhere".
	local Classes = { GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_CLASS_RESOURCE }
	local Filters = { FILTER_NO_DYNASTY, FILTER_HAS_DYNASTY }
	for c = 1, 2 do
		for f = 1, 2 do
			local Count = CityGetBuildings(CityAlias, Classes[c], -1, -1, -1, Filters[f], "Seller")
			for i = 0, Count - 1 do
				if N > 0 and GetDynastyID("Seller" .. i) ~= GetDynastyID("") then
					N, Needs = ms_bf_feudsupply_BuyAt("Seller" .. i, N, Needs)
				end
				RemoveAlias("Seller" .. i)
			end
		end
	end
	return N, Needs
end

-- Buys what the list still wants at one seller, when it has any of it on offer. At the
-- blood enemy's own shop, only the part of the list that is worth funding them for.
function BuyAt(Seller, N, Needs)
	if N <= 0 then
		return N, Needs
	end
	-- At a counter the blood enemy owns, offer the list only what is worth funding them
	-- for (aitwp_WorthBuyingFromEnemy). The rest is held back and put on the list again
	-- afterwards, so the next seller in the town can still supply it.
	local Held = {}
	if AliasExists("PlayerDyn") and GetDynastyID(Seller) > 0
			and GetDynastyID(Seller) == GetID("PlayerDyn") then
		local Offer = {}
		for i = 1, N do
			if aitwp_WorthBuyingFromEnemy(Needs[i][1], Seller) then
				Offer[#Offer + 1] = Needs[i]
			else
				Held[#Held + 1] = Needs[i]
			end
		end
		if #Held > 0 then
			aitwp_Log("skips " .. #Held .. " of " .. N .. " at the rival's "
				.. GetName(Seller) .. ": not worth the coin", "Dyn")
		end
		Needs, N = Offer, #Offer
		if N <= 0 then
			return #Held, Held
		end
	end
	local Any = false
	for i = 1, N do
		if GetItemCount(Seller, Needs[i][1], INVENTORY_STD) > 0 or GetItemCount(Seller, Needs[i][1], INVENTORY_SELL) > 0 then
			Any = true
		end
	end
	if Any and (IsInLoadingRange("", Seller) or f_MoveTo("", Seller, GL_MOVESPEED_RUN)) then
		N, Needs = cart_LoadItems("", Seller, N, Needs)
	end
	for i = 1, #Held do
		N = N + 1
		Needs[N] = Held[i]
	end
	return N, Needs
end
