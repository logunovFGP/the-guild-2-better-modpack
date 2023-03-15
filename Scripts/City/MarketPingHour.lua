function GameStart()
	
	GetSettlement("", "City")
	
	if CityIsKontor("City") then
		return 0
	end
	
	local Level = CityGetLevel("City")
	
	marketpinghour_SpawnItems("City", Level)
	
	-- far trader
	economy_CalcNeedsForMarket("City")
	economy_CalcSalesForMarket("City")
end

function PingHour()

	if CityIsKontor("") then
		return 0
	end
	
	if math.mod(GetGametime(), 12) == 5 then -- at 5am, 5pm
		local CityNeedCount, CityNeeds = economy_CalcNeedsForMarket("")
		if CityNeedCount > 0 then
			economy_CalcSalesForMarket("")
			-- additional trade outside of map for items that have notorious shortage
			marketpinghour_SendFarTrader(CityNeedCount, CityNeeds)
		end
	end
end

-- spawn at gamestart
function SpawnItems(City, CityLevel)
	
	local ItemName = ""
	local BuildingType = 0
	local MinLevel = 0
	local Spawn = 0
	local LevelFound = 0 -- count the higher level buildings multiple times
	
	-- db
	local TableName = "ItemsToMarket" 
	local NumItems = 166 -- this should be the last ID from DB/ItemsToMarket.dbt
	
	for i=0, NumItems do
		ItemName = GetDatabaseValue(TableName, i, "name")
		
		if ItemName and ItemName ~= nil and ItemName ~= "" then
			BuildingType = GetDatabaseValue(TableName, i, "buildingtype")
			MinLevel = GetDatabaseValue(TableName, i, "minlevel")
			Spawn = GetDatabaseValue(TableName, i, "spawn_gamestart")
			
			-- count the levels
			if MinLevel == 3 then
				LevelFound = (CityGetBuildingCount(City, GL_BUILDING_CLASS_WORKSHOP, BuildingType, 3, -1, FILTER_IGNORE)) * 3
			elseif MinLevel == 2 then
				LevelFound = (CityGetBuildingCount(City, GL_BUILDING_CLASS_WORKSHOP, BuildingType, 3, -1, FILTER_IGNORE)) * 3
				LevelFound = LevelFound + (CityGetBuildingCount(City, GL_BUILDING_CLASS_WORKSHOP, BuildingType, 2, -1, FILTER_IGNORE)) * 2
			else
				LevelFound = (CityGetBuildingCount(City, GL_BUILDING_CLASS_WORKSHOP, BuildingType, 3, -1, FILTER_IGNORE)) * 3
				LevelFound = LevelFound + (CityGetBuildingCount(City, GL_BUILDING_CLASS_WORKSHOP, BuildingType, 2, -1, FILTER_IGNORE)) * 2
				LevelFound = LevelFound + CityGetBuildingCount(City, GL_BUILDING_CLASS_WORKSHOP, BuildingType, 1, -1, FILTER_IGNORE)
			end
			
			-- special case for level 1 church items, count church_cath aswell
			if ItemName == "Parchment" or ItemName == "HolyWater" or ItemName == "Housel" or ItemName == "Poem" then
				-- count the levels
				LevelFound = LevelFound + (CityGetBuildingCount(City, GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_CHURCH_CATH, 3, -1, FILTER_IGNORE)) * 3
				LevelFound = LevelFound + (CityGetBuildingCount(City, GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_CHURCH_CATH, 2, -1, FILTER_IGNORE)) * 2
				LevelFound = LevelFound + CityGetBuildingCount(City, GL_BUILDING_CLASS_WORKSHOP, GL_BUILDING_TYPE_CHURCH_CATH, 1, -1, FILTER_IGNORE)
			end
			
			-- multiply and add
			Spawn = Spawn*LevelFound
			
			if Spawn == 0 then
				AddItems("", ItemName, 1, INVENTORY_STD) -- we spawn it anyway to have to slot shown
				RemoveItems("", ItemName, 1, INVENTORY_STD)
			else
				AddItems("", ItemName, Spawn, INVENTORY_STD)
			end
		end
	end
end

function SendFarTrader(CityNeedCount, CityNeeds)

	if CityNeedCount <= 0 then
		return -- nothing to do
	end
	
	-- get cart or create one
	local CartID = GetProperty("", "TWP_FarTraderCart")
	local CartAlias = "CartAlias"
	
	if not CartID or not GetAliasByID(CartID, CartAlias) then
	
		if not GetSettlement("", "MyCity") then
			LogMessage("TWP::MarketPingHour Could not create cart, settlement not found.")
			return
		end
		
		if not CityGetRandomBuilding("MyCity", -1, GL_BUILDING_TYPE_MARKET, -1, -1, FILTER_IGNORE, "MarketBld") then
			LogMessage("TWP::MarketPingHour Could not create cart, market building not found.")
			return
		end
	
		if not GetOutdoorMovePosition(CartAlias, "MarketBld", "SpawnPos") then
			LogMessage("TWP::MarketPingHour Could not create cart, no spawn position found.")
			return
		end
	
		-- create new cart and save ID as property
		if ScenarioCreateCart(EN_CT_OX, nil, "SpawnPos", CartAlias) then
			SetEndlessMoney(CartAlias, true)
			SetProperty("", "TWP_FarTraderCart", GetID(CartAlias))
			SetProperty(CartAlias, "TWP_HomeBuilding", GetID(""))
		else
			LogMessage("TWP::MarketPingHour Could not create cart.")
			return
		end
		
	elseif not HasProperty(CartAlias, "TWP_HomeBuilding") then
		-- should not happen, but the Property was lost once during testing 
		SetProperty(CartAlias, "TWP_HomeBuilding", GetID(""))
	end
	
	local CurrentMeasure = GetCurrentMeasureName(CartAlias)
	if CurrentMeasure == "FarTrader" then
		return
	end
	
	-- weighted random decision for one of the first 5 needs
	local Weights = {}
	
	for i=1, 5 do
		if CityNeeds[i] then
			Weights[i] = CityNeeds[i][2]
		else 
			break
		end
	end
	
	local Choice = helpfuncs_RandWeighted(Weights)
	local ItemToBuy = CityNeeds[Choice][1]
	
	-- start measure with item and budget of 10000
	MeasureCreate("Measure")
	MeasureAddData("Measure", "Item", ItemToBuy)
	MeasureAddData("Measure", "Budget", 10000)
	MeasureStart("Measure", CartAlias, nil, "FarTrader")	
end
