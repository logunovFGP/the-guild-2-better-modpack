-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching
end
 
-- -----------------------
-- GetEmployeesInBuilding
-- -----------------------
function GetEmployeesInBuilding(BuildingAlias)

	local WorkerCount = BuildingGetWorkerCount(BuildingAlias)
	local Counter = WorkerCount
	
	while(Counter>0) do		
		BuildingGetWorker(BuildingAlias, Counter-1, "EmployeeNr"..Counter)
		Counter = Counter - 1
	end

	return WorkerCount
end

-- -----------------------
-- Pays out bank account when on sale/sold
-- -----------------------
function ClearBuildingStash(BldAlias, OwnerAlias)
	if BuildingGetType(BldAlias) == GL_BUILDING_TYPE_BANKHOUSE and HasProperty(BldAlias, "BankAccount") then
		local invest = GetProperty(BldAlias, "BankAccount")
		RemoveProperty(BldAlias, "BankAccount")
		if AliasExists(OwnerAlias) then
			chr_CreditMoney(OwnerAlias, invest, "Credit")
			-- notify former owner
			MsgNewsNoWait(OwnerAlias, BldAlias, "", "building", -1, 
						"@L_BUYBUILDING_CREDIT_HEAD_+0",
						"@L_BUYBUILDING_CREDIT_BODY_+0", 
						GetID(BldAlias), invest)
		end
--	elseif BuildingGetType(BldAlias) == GL_BUILDING_TYPE_HOSPITAL then
		-- Remove all items from medicine stash and credit base value
--		local Items = {"Salve", "Bandage", "Medicine", "PainKiller", "Soap", "MiracleCure"}
--		local Value = 0

--		for i=1, 6 do
--			local ItemProp = Items[i].."s"
--			if HasProperty(BldAlias, ItemProp) then
--				local n = GetProperty(BldAlias, ItemProp)
--				Value = Value + (n * ItemGetBasePrice(Items[i]))
--				RemoveProperty(BldAlias, ItemProp)
--			end	
--		end

--		if Value > 0 and AliasExists(OwnerAlias) then
--			CreditMoney(OwnerAlias, Value, "misc")
--			MsgNewsNoWait(OwnerAlias, BldAlias, "", "building", -1, 
--				"@L_BUYBUILDING_MEDICINE_HEAD_+0",
--				"@L_BUYBUILDING_MEDICINE_BODY_+0", 
--				GetID(BldAlias), Value)
--		end			
	end
end

-- ------------------
-- GetScaffoldOffsets
-- ------------------
function GetScaffoldOffsets(Proto)
	
	local OffsetX = 0
	local OffsetZ = 0

	if Proto == 100 then -- Barnyard (Hufe)
		OffsetX = -780
		OffsetZ = 240
	elseif Proto == 101 then -- Farm (Bauernhof)
		OffsetX = -850
		OffsetZ = 350
	elseif Proto == 102 then -- FarmEstate (Gutshof)
		OffsetX = -850
		OffsetZ = -150
	elseif Proto == 120 then -- BreadShop (Backstube)
		OffsetX = 100
		OffsetZ = -30
	elseif Proto == 121 then -- Bakery2 (B�ckerei)
		OffsetX = 50
		OffsetZ = -80
	elseif Proto == 122 then -- PastryShop (Konditorei)
		OffsetX = 55
		OffsetZ = -15
	elseif Proto == 130 then -- Taproom (Sch�nke)
		OffsetX = -10
		OffsetZ = -100
	elseif Proto == 131 then -- Inn (Taverne)
		OffsetX = 50
		OffsetZ = 0
	elseif Proto == 132 then -- Tavern (Gasthaus)
		OffsetX = 0
		OffsetZ = -180
	elseif Proto == 140 then -- Foundry (Giesserei)
		OffsetX = 50
		OffsetZ = 20
	elseif Proto == 141 then -- Smithy (Schmiede)
		OffsetX = 250
		OffsetZ = -110
	elseif Proto == 142 then -- Goldsmithy (Goldschmiede)
		OffsetX = 160
		OffsetZ = -105
	elseif Proto == 143 then -- CannonFoundry (Kanonengiesserei)
		OffsetX = 300
		OffsetZ = -140
	elseif Proto == 144 then -- Armourer (R�stungsschmiede)
		OffsetX = 60
		OffsetZ = -1750
	elseif Proto == 150 then -- Joinery (Tischlerei)
		OffsetX = 190
		OffsetZ = 560
	elseif Proto == 151 then -- Turnery (Drechslerei)
		OffsetX = 140
		OffsetZ = 150
	elseif Proto == 152 then -- Finejoinery (Kunsttischlerei)
		OffsetX = 20
		OffsetZ = -200
	elseif Proto == 160 then -- WeavingMill (Weberei)
		OffsetX = 0
		OffsetZ = -100
	elseif Proto == 161 then -- TailorShop (Schneiderei)
		OffsetX = -50
		OffsetZ = -25
	elseif Proto == 162 then -- Couturier (Schneiderei)
		OffsetX = -20
		OffsetZ = -60
	elseif Proto == 170 then -- Tinctury (Tinkturei)
		OffsetX = 15
		OffsetZ = -135
	elseif Proto == 171 then -- AlchemistParlour (Alchimistenstube)
		OffsetX = 70
		OffsetZ = -115
	elseif Proto == 172 then -- InventorWorkshop (Erfinderwerkstatt)
		OffsetX = 100
		OffsetZ = -100
	elseif Proto == 173 then -- GloomyParlour (Zauberstube)
		OffsetX = 140
		OffsetZ = -130
	elseif Proto == 174 then -- SorcererHouse (Magiergilde)
		OffsetX = 300
		OffsetZ = -1350
	elseif Proto == 190 then -- ev.Church (Kirche)
		OffsetX = -40
		OffsetZ = 90
	elseif Proto == 191 then -- ev.Minster (ev.Dom)
		OffsetX = 60
		OffsetZ = 30
	elseif Proto == 192 then -- ev.Cathedral (ev.Kathedrale)
		OffsetX = 220
		OffsetZ = -300
	elseif Proto == 193 then -- kath.Church (kath.Kirche)
		OffsetX = -50
		OffsetZ = 80
	elseif Proto == 194 then -- kath.Minster (kath.Dom)
		OffsetX = 80
		OffsetZ = -100
	elseif Proto == 195 then -- kath.Cathedral (kath.Kathedrale)
		OffsetX = 280
		OffsetZ = -400
	elseif Proto == 230 then -- robber low
		OffsetX = -450
		OffsetZ = -200
	elseif Proto == 231 then -- robber med
		OffsetX = -450
		OffsetZ = -200
	elseif Proto == 240 then -- SmugglerHole (Schmugglerloch)
		OffsetX = 15
		OffsetZ = -100
	elseif Proto == 241 then -- ThievesShelter (Diebesunterschlupf)
		OffsetX = 30
		OffsetZ = -180
	elseif Proto == 242 then -- ThievesGuild (Diebesgilde)
		OffsetX = 130
		OffsetZ = -370
	elseif Proto == 270 then -- rangerhut
		OffsetX = 220
		OffsetZ = -160
	elseif Proto == 300 then -- Pawnshop (Pfandhaus)
		OffsetX = 100
		OffsetZ = -115
	elseif Proto == 301 then -- BankingHouse (Bank)
		OffsetX = 100
		OffsetZ = -1400
	elseif Proto == 310 then -- ConventionHouse (Versammlungshaus)
		OffsetX = -320
		OffsetZ = 60
	elseif Proto == 311 then -- TownHall (Rathaus)
		OffsetX = 100
		OffsetZ = -1950
	elseif Proto == 312 then -- CouncilPalace (Ratspalast)
		OffsetX = 200
		OffsetZ = -2200
	elseif Proto == 330 then -- Dungeon (Schuldturm)
		OffsetX = -30
		OffsetZ = 200
	elseif Proto == 331 then -- Prison (Kerker)
		OffsetX = 80
		OffsetZ = 330
	elseif Proto == 340 then -- School (Schule)
		OffsetX = 10
		OffsetZ = -130
	elseif Proto == 341 then -- University (Universit�t)
		OffsetX = 200
		OffsetZ = -440
	elseif Proto == 200 then -- Watchtower1
		OffsetX = 180
		OffsetZ = -150
	elseif Proto == 201 then -- Watchtower2
		OffsetX = 180
		OffsetZ = -100
	elseif Proto == 202 then -- Watchtower3
		OffsetX = 180
		OffsetZ = -100
	elseif Proto == 365 then -- Warehouse (Warenhaus)
		OffsetX = 750
		OffsetZ = -1900
	elseif Proto == 370 then -- Fishinghut1
		OffsetX = 0
		OffsetZ = -1150
	elseif Proto == 371 then -- Fishinghut2
		OffsetX = 0
		OffsetZ = -1150
	elseif Proto == 372 then -- Fishinghut3
		OffsetX = -100
		OffsetZ = -900
	elseif Proto == 390 then -- Hospital1
		OffsetX = -180
		OffsetZ = -1050
	elseif Proto == 391 then -- Hospital2
		OffsetX = 50
		OffsetZ = -75
	elseif Proto == 392 then -- Hospital3
		OffsetX = 150
		OffsetZ = -200
	elseif Proto == 430 then -- WorkersHut1 (Arbeiterhaus)
		OffsetX = 0
		OffsetZ = -200
	elseif Proto == 431 then -- WorkersHut2 (Arbeiterhaus)
		OffsetX = 80
		OffsetZ = -200
	elseif Proto == 432 then -- WorkersHut3 (Arbeiterhaus)
		OffsetX = 40
		OffsetZ = -210
	elseif Proto == 440 then -- H�tte
		OffsetX = -45
		OffsetZ = -180
	elseif Proto == 441 then -- Haus
		OffsetX = -30
		OffsetZ = -160
	elseif Proto == 442 then -- Giebelhaus
		OffsetX = -50
		OffsetZ = -130
	elseif Proto == 443 then -- Patrizierhaus
		OffsetX = 20
		OffsetZ = -160
	elseif Proto == 444 then -- Herrenhaus
		OffsetX = 200
		OffsetZ = -300
	elseif Proto == 483 then -- Prison_lv3 (Gef�ngnis)
		OffsetX = 130
		OffsetZ = -330
	elseif Proto == 654 then -- Piratenest
		OffsetX = 750
		OffsetZ = -1900
	elseif Proto == 1001 then -- Piratenest
		OffsetX = 790
		OffsetZ = -2000
	elseif Proto == 1002 then -- Piratenest
		OffsetX = 830
		OffsetZ = -2050
	end
	
	return OffsetX, OffsetZ
end

function BauStuff(typeID, gebLVL, owner)
	local bNam,gLNam
	local nenr, gebId = 5, 1
	if typeID == 2 then
		bNam = "Residence"
	elseif typeID == 3 then
		bNam = "Farm"
	elseif typeID == 4 then
		bNam = "Tavern"
	elseif typeID == 6 then
		bNam = "Bakery"
	elseif typeID == 7 then
		bNam = "Blacksmith"
		if BuildingGetProto(owner) == 141 or BuildingGetProto(owner) == 142 then
			gebId = 5
		end
	elseif typeID == 8 then
		bNam = "Joinery"
	elseif typeID == 9 then
		bNam = "Couturier"
	elseif typeID == 11 then
		bNam = "Piratesnest"
	elseif typeID == 12 then
		bNam = "Mine"
	elseif typeID == 15 then
		bNam = "Robber"
	elseif typeID == 16 then
		bNam = "Alchemist"
		if BuildingGetProto(owner) == 173 or BuildingGetProto(owner) == 174 then
			gebId = 5
		end
	elseif typeID == 18 then
		bNam = "Rangerhut"
	elseif typeID == 19 or typeID == 20 then
		bNam = "Church"
		if BuildingGetProto(owner) == 191 or BuildingGetProto(owner) == 192 then
			gebId = 5
		end
	elseif typeID == 22 then
		bNam = "Thief"
	elseif typeID == 35 then
		bNam = "Fishinghut"
	elseif typeID == 36 then
	    bNam = "Divehouse"
	elseif typeID == 37 then
		bNam = "Hospital"
	elseif typeID == 38 then
		bNam = "Warehouse"
	elseif typeID == 43 then
		bNam = "Bank"
	elseif typeID == 98 then
		bNam = "Friedhof"
	elseif typeID == 104 then
		bNam = "Mill"
	elseif typeID == 110 then
		bNam = "Stonemason"
	else
		bNam = ""
	end	
	
	if gebLVL == 1 then
		gLNam = "low"
	elseif gebLVL == 2 then
		gLNam = "med"
	elseif gebLVL == 3 then
		gLNam = "high"
	elseif gebLVL == 4 then
		gLNam = "veryhigh"
	elseif gebLVL == 5 then
		gLNam = "max"
	end
	
	return bNam, gLNam, nenr, gebId
end	

function CalcTreatmentNeed(BldAlias, SimAlias)
	local MedicineNeed = 0
	local CheckNeed = 0
	local Medicine = { "Bandage", "Medicine", "PainKiller" }
	for i = 1, 3 do 
		if BuildingCanProduce(BldAlias, Medicine[i]) then
			CheckNeed = bld_GetNeedForMedicine(BldAlias, Medicine[i])
			if CheckNeed > MedicineNeed then
				MedicineNeed = CheckNeed
			end
			
			if MedicineNeed == 100 then
				break
			end
		end
	end
	
	local AvailableBandages = GetItemCount(BldAlias, "Bandage")
	if HasProperty(BldAlias, "Bandages") then
		AvailableBandages = AvailableBandages + GetProperty(BldAlias, "Bandages")
	end
	
	-- we need more bandages right now!
	if AvailableBandages == 0 then
		return 0
	end
	
	local SickSimFilter = "__F((Object.GetObjectsByRadius(Sim) == 10000) AND (Object.HasProperty(WaitingForTreatment)))"
	local NumSickSims = Find(SimAlias, SickSimFilter,"SickSim", -1)
	local Producer = BuildingGetProducerCount(BldAlias, PT_MEASURE, "MedicalTreatment")
	
	local HealerCount = 0
	if NumSickSims > 6 and MedicineNeed < 100 then
		HealerCount = 3
	elseif NumSickSims > 3 and MedicineNeed < 100 then
		HealerCount = 2
	elseif NumSickSims > 0 then
		HealerCount = 1
	end
	
	return HealerCount - Producer
end

-- -----------------------
-- CheckRivals (of given buildings and returns the ID of the rival dynasty)
-- -----------------------
function CheckRivals(BldAlias)
	
	if not ReadyToRepeat(BldAlias, "ai_CheckRivals") then
		return
	end
	
	if ScenarioGetTimePlayed() < 3 then
		return
	end
	
	local Difficulty = ScenarioGetDifficulty()
	
	if Difficulty < 2 then
		return
	end
	
	SetRepeatTimer(BldAlias, "ai_CheckRivals", 12)

	if not GetDynasty(BldAlias, "MyDynasty") then
		return
	end 
	
	if not BuildingGetOwner(BldAlias, "MyBoss") or not BuildingGetCity(BldAlias, "MyCity") then
		return
	end
	
	if DynastyIsPlayer("MyBoss") then
		return
	end
	
	local BuildType = BuildingGetType(BldAlias)
	local BuildID = GetID(BldAlias)
	
	-- check for same buisnesses nearby
	local BuildingCount = CityGetBuildings("MyCity", GL_BUILDING_CLASS_WORKSHOP, BuildType, -1, -1, FILTER_HAS_DYNASTY, "RivalBuilding") or 1
	local RivBld, RivID
	
	if BuildingCount < 2 then
		return
	end
	
	for i=0, BuildingCount-1 do
		RivBld = "RivalBuilding"..i
		RivID = GetDynastyID("RivalBuilding"..i)
		if RivID ~= GetDynastyID(BldAlias) then
			if not HasProperty(BldAlias, "Rival"..RivID) then
				if not GetState(RivBld, STATE_BUILDING) then
					if BuildingGetOwner(RivBld, "RivalBoss") then
						-- rival needs to be a player
						if DynastyIsPlayer("RivalBoss") then
							-- check for diplomacy
							if DynastyGetDiplomacyState("MyBoss", "RivalBoss") < DIP_ALLIANCE then
								SetProperty(BldAlias, "Rival"..RivID, 1) -- only one msg
								MsgNewsNoWait("RivalBoss", "MyBoss", "", "economie", -1,
											"@L_AI_NEWRIVALINTOWN_HEAD", "@L_AI_NEWRIVALINTOWN_BODY", GetID("MyBoss"), GetID(BldAlias), GetID(RivBld))
								chr_ModifyFavor("MyBoss", "RivalBoss", -GL_FAVOR_MOD_VERYLARGE)
								break
							end
						end
					end
				end
			end
		end
	end
end

-- ----------------------------------------------
-- Remove highlevel weapons and armory & heal
-- ----------------------------------------------

function ResetWorkers(BldAlias)
	
	Sleep(5) -- wait a few seconds before starting this cleanup.
	local NumWorkers = BuildingGetWorkerCount(BldAlias)
	
	for i=0 , NumWorkers -1 do
		if BuildingGetWorker(BldAlias, i, "Worker") then
			if not HasProperty("Worker", "ResetWorker") then
		
				-- remove armor
				if GetItemCount("Worker", "LeatherArmor", INVENTORY_EQUIPMENT) > 0 then
					RemoveItems("Worker", "LeatherArmor", 1, INVENTORY_EQUIPMENT)
				elseif GetItemCount("Worker", "Chainmail", INVENTORY_EQUIPMENT) > 0 then
					RemoveItems("Worker", "Chainmail", 1, INVENTORY_EQUIPMENT)
				elseif GetItemCount("Worker", "Platemail", INVENTORY_EQUIPMENT) > 0 then
					RemoveItems("Worker", "Platemail", 1, INVENTORY_EQUIPMENT)
				end
				
				-- remove weapon
				if GetItemCount("Worker", "Mace", INVENTORY_EQUIPMENT) > 0 then
					RemoveItems("Worker", "Mace", 1, INVENTORY_EQUIPMENT)
				elseif GetItemCount("Worker", "Shortsword", INVENTORY_EQUIPMENT) > 0 then
					RemoveItems("Worker", "Shortsword", 1, INVENTORY_EQUIPMENT)
				elseif GetItemCount("Worker", "Longsword", INVENTORY_EQUIPMENT) > 0 then
					RemoveItems("Worker", "Longsword", 1, INVENTORY_EQUIPMENT)
				elseif GetItemCount("Worker", "Axe", INVENTORY_EQUIPMENT) > 0 then
					RemoveItems("Worker", "Axe", 1, INVENTORY_EQUIPMENT)
				end
				
				-- add dagger if needed
				if SimGetClass("Worker") == GL_CLASS_CHISELER then
					if GetItemCount("Worker", "Dagger", INVENTORY_EQUIPMENT) <= 0 then
						AddItems("Worker", "Dagger", 1, INVENTORY_EQUIPMENT)
					end
				end
				
				-- heal default worker.
				if GetImpactValue("Worker", "Sickness") > 0 then
					diseases_removeAllSickness("Worker")
					MoveSetActivity("Worker")
				end
				
				SetProperty("Worker", "ResetWorker", 1)
			end
		end
	end
end

-- ----------------------------------------------
-- Modify AI production priorities TODO
-- ----------------------------------------------

function SetInvNeedUnlocked(itemId, value)
	if (GetProperty("Inv", "NeedLock_"..itemId) or 0) ~= 0 then
		return
	end
	SetProperty("Inv", "Need_"..itemId, value)
end

function SetupAI(BldAlias)
	if not BuildingGetOwner(BldAlias, "MyBoss") then
		return
	end
	
	if not GetInventory(BldAlias, INVENTORY_STD, "Inv") then
		return
	end
	
	if not GetSettlement(BldAlias, "City") then
		GetNearestSettlement(BldAlias, "City")
	end
	
	CityGetLocalMarket("City","Market")
	if not AliasExists("Market") then
		return
	end
	
	local Items -- Arry, name of items. First items in this list have a lower value to produce than the last (So if you want to boost a items production priority, put it at the end of this list
	local ItemsNum -- total count of items to check
	local MarketStock = {} -- Array, If this is not -1, AI will prefer to produce items that have a lower amount on stock on the local market
	local LocalStock = {} -- Array, If this is not -1, AI will prefer to produce items that have a lower amount on stock on your workshops stock
	local CheckItem
	local CheckID
	local Value
	
	local BldType = BuildingGetType(BldAlias)
	
	if BldType == GL_BUILDING_TYPE_SMITHY then
		if BuildingGetLevel(BldAlias) == 1 then
			Items = 		{ "Nails", "Tool", "Dagger" }
			ItemsNum = 3
			MarketStock = 	{ 50, 40, 30 }
			LocalStock = 	{ 3, 3, 1 }
		else	
			-- check for sublevels
			if BuildingHasUpgrade(BldAlias, "engravingtoolset") then -- gold smith
				Items = {	"Nails", "Tool", "Dagger", "SilverRing", "IronBrachelet", 
						"GoldChain", "BeltOfMetaphysic", "GemRing", "Diamond"
					}
				ItemsNum = 9
				MarketStock = { 50, 40, 30, 30, 30, 15, 15, 15, 15 }
				LocalStock = { 3, 3, 1, -1, -1, -1, -1, -1, -1 }
			else
				Items = {	"Nails", "Tool", "Dagger", "Shortsword", "IronCap", 
						"Chainmail", "Steel", "Longsword", "FullHelmet", "Platemail"
					}
				ItemsNum = 10
				MarketStock = { 50, 40, 30, 30, 30, 15, -1, 20, 20, 15 }
				LocalStock = { 3, 3, 1, -1, -1, -1, 4, -1, -1, -1 }
			end
		end
		
	elseif BldType == GL_BUILDING_TYPE_ALCHEMIST_SHOP then
		if BuildingGetLevel(BldAlias) == 1 then
			Items = { "HerbTea", "Phiole"
					}
			ItemsNum = 2
			MarketStock = { 50, 35 }
			LocalStock = { 3, 1 }
		else	
			-- check for sublevels
			if BuildingHasUpgrade(BldAlias, "FlowerOfDiscord") then -- perfumery
				Items = {	"HerbTea", "Phiole", "FlowerOfDiscord", "Perfume", "BoobyTrap", 
						"FragranceOfHoliness", "DrFaustusElixir"
					}
				ItemsNum = 7
				MarketStock = { 50, 35, 20, 30, 20, 20, 15 }
				LocalStock = { 5, 5, -1, -1, -1, -1, -1 }
			else
				Items = {	"HerbTea", "Phiole", "WeaponPoison", "InvisiblePotion", "ToadExcrements", 
						"ParalysisPoison", "Toadslime", "BlackWidowPoison"
					}
				ItemsNum = 8
				MarketStock = { 50, 35, 15, 30, 15, 15, 15, 10 }
				LocalStock = { 3, 1, -1, -1, -1, -1, -1, -1 }
			end
		end
		
	elseif BldType == GL_BUILDING_TYPE_MINE then
		Items = {	"Gemstone", "Gold", "Salt", "Silver", "Iron"
					}
		ItemsNum = 5
		MarketStock = { 50, 50, 60, 70, 70 }
		LocalStock = { -1, -1, -1, -1, -1 }
		
	elseif BldType == GL_BUILDING_TYPE_TAILORING then
		Items = {	"Blanket", "FarmersClothes", "MoneyBag", "CitizensClothes", "LeatherGloves", 
				"CamouflageCloak", "NoblesClothes", "GlovesOfDexterity", "LeatherArmor", "Cloth"
					}
		ItemsNum = 10
		MarketStock = { 50, 50, 50, 50, 50, 20, 30, 20, 20, -1 }
		LocalStock = { 2, 2, 2, -1, -1, -1, -1, -1, -1, 4 }
		
	elseif BldType == GL_BUILDING_TYPE_BAKERY then
		Items = {	"Cookie", "Wheatbread", "Cake", "Pretzel", "BreadRoll", 
				"CreamPie", "Candy", "Pastry", "BreadDough", "CakeBatter"
					}
		ItemsNum = 10
		MarketStock = { 50, 50, 30, 40, 40, 40, 20, 25, -1, -1 }
		LocalStock = { 4, 3, -1, -1, -1, -1, -1, -1, 4, 4 }
	
	elseif BldType == GL_BUILDING_TYPE_TAVERN then
		Items = {	"GrainPap", "SmallBeer", "Stew", "WheatBeer", "SalmonFilet", 
				"Mead", "RoastBeef", "BoozyBreathBeer", "GhostlyFog", "Wein",
				"Weingeist"
					}
		ItemsNum = 11
		MarketStock = { 40, 40, 40, 40, 40, 20, 30, 20, 15, 20, 50 }
		LocalStock = { 4, 4, 4, 4, 4, -1, 4, -1, -1, 4, 2 }
		
	elseif BldType == GL_BUILDING_TYPE_JOINERY then
		Items = {	"Torch", "Schnitzi", "WalkingStick", "BuildMaterial", "Holzpferd", 
				"Mace", "CartBooster", "Kamm", "CrossOfProtection", "RubinStaff",
				"Axe"
					}
		ItemsNum = 11
		MarketStock = { 40, 40, 40, 50, 40, 30, 20, 15, 20, 15, 15 }
		LocalStock = { 2, 2, 1, -1, -1, -1, -1, -1, -1, -1, -1 }
	
	elseif BldType == GL_BUILDING_TYPE_RANGERHUT then
		Items = {	"Pinewood", "Oakwood", "Charcoal", "Fungi", "Pech"
					}
		ItemsNum = 5
		MarketStock = { 60, 60, 60, 60, 60 }
		LocalStock = { -1, -1, -1, -1, -1 }
		
	elseif BldType == GL_BUILDING_TYPE_CHURCH_EV then
		Items = {	"Poem", "ThesisPaper", "AboutTalents2", "Hasstirade", "Bible", 
				"Kerzen", "Housel", "Ink"
					}
		ItemsNum = 8
		MarketStock = { 50, 30, 30, 15, 15, 50, 60, -1 }
		LocalStock = { 1, -1, -1, -1, -1, 5, 10, 2 }
		
	elseif BldType == GL_BUILDING_TYPE_CHURCH_CATH then
		Items = {	"Poem", "Chaplet", "AboutTalents1", "LetterOfIndulgence", "LetterFromRome", 
				"Kerzen", "Housel", "Ink"
					}
		ItemsNum = 8
		MarketStock = { 50, 30, 30, 20, 15, 50, 60, -1 }
		LocalStock = { 1, -1, -1, -1, -1, 5, 10, 2 }
		
	elseif BldType == GL_BUILDING_TYPE_HOSPITAL then
		Items = {	"Antidote", "Mixture" }
		ItemsNum = 2
		MarketStock = { 15, 5 }
		LocalStock = { -1, -1 }
		
		-- special case medicine
		local Medicine = { "Salve", "Bandage", "Medicine", "PainKiller", "Soap", "MiracleCure" }
		local ItemId 
		local Need
		
		for i=1, 6 do
			if BuildingHasUpgrade(BldAlias, Medicine[i]) then
				ItemId = ItemGetID(Medicine[i])
				Need = bld_GetNeedForMedicine(BldAlias, Medicine[i])
				if Medicine[i] == "Soap" or Medicine[i] == "MiracleCure" then
					Need = Need - 25
				end
				if Need >= 25 then
					bld_SetInvNeedUnlocked(ItemId, Need)
				else
					bld_SetInvNeedUnlocked(ItemId, Rand(3))
				end
			end
		end
	
	elseif BldType == GL_BUILDING_TYPE_FISHINGHUT then
		Items = {	"FriedHerring", "FishSoup", "SmokedSalmon", "Shellchain", "Shellsoup", 
				"Pearlchain", "Perle", "Shell"
					}
		ItemsNum = 8
		MarketStock = { 50, 40, 40, 30, 30, 15, -1, -1 }
		LocalStock = { -1, -1, -1, -1, -1, -1, 3, 3 }
		
	elseif BldType == GL_BUILDING_TYPE_CRYPT then
		Items = {	"Schadelkerze", "Knochenarmreif", "BoneFlute", "HexerdokumentI", "Robe", 
				"FalseRelict", "HexerdokumentII", "pddv", "Knochen", "Schadel",
				"Ektoplasma", "Leichenhemd"
					}
		ItemsNum = 12
		MarketStock = { 30, 30, 30, 15, 10, 10, 10, 10, -1, -1, -1, -1 }
		LocalStock = { 4, 4, -1, -1, -1, -1, -1, -1, 2, 2, 2, 1 }
		
	elseif BldType == GL_BUILDING_TYPE_MILL then
		Items = {	"Saft", "Oil", "Dye", "WheatFlour"
					}
		ItemsNum = 4
		MarketStock = { 30, 50, 60, 70 }
		LocalStock = { -1, -1, -1, -1 }
		
	elseif BldType == GL_BUILDING_TYPE_BANKHOUSE then
		Items = {	"Siegelring", "Schuldenbrief", "Optieisen", "Urkunde", "Optisilber", 
				"Pfandbrief", "Optigold", "Empfehlung", "Handwerksurkunde", "Siegel"
					}
		ItemsNum = 10
		MarketStock = { 40, 40, 40, 30, 35, 15, 20, 10, 15, -1 }
		LocalStock = { -1, -1, -1, -1, -1, -1, -1, -1, -1, 2 }
		
	elseif BldType == GL_BUILDING_TYPE_STONEMASON then
		Items = {	"Grindingbrick", "vase", "Chisel", "Stonerotary", "Blissstone", 
				"Gravestone", "statue", "Gargoyle", "Clay", "Granite"
					}
		ItemsNum = 10
		MarketStock = { 50, 25, -1, 20, 15, 15, 10, 10, -1, -1 }
		LocalStock = { 5, 3, 3, -1, -1, -1, -1, -1, 2, 3 }
		
	else
		return
	end
	
	local CheckStock
	local CheckMarket

	for i=1, ItemsNum do
		CheckItem = Items[i]
		CheckStock = LocalStock[i]
		CheckMarket = MarketStock[i]
		if CheckItem ~= nil then
			CheckID = bld_GetKnownItemID(CheckItem)
			if CheckID and BuildingCanProduce(BldAlias, CheckID) then
				Value = 5+(i*5)
				if BldType == GL_BUILDING_TYPE_HOSPITAL then
					Value = 25
				end
				if CheckMarket ~= nil and CheckMarket ~= -1 then
					if GetItemCount("Market", CheckID, INVENTORY_STD) <= CheckMarket and GetItemCount(BldAlias, CheckID, INVENTORY_STD) <= CheckMarket then
						bld_SetInvNeedUnlocked(CheckID, Value)
					else
						bld_SetInvNeedUnlocked(CheckID, Rand(6))
					end
				end

				if CheckStock ~= nil and CheckStock ~= -1 then
					if GetItemCount(BldAlias, CheckID, INVENTORY_STD) <= CheckStock then
						bld_SetInvNeedUnlocked(CheckID, Value*3)
					else
						bld_SetInvNeedUnlocked(CheckID, 0)
					end
				end
			end
		end
	end
end

-- ----------------------------------------------
-- Safe item-name lookup for SetupAI
-- ----------------------------------------------
function GetKnownItemID(Name)
	if not BLD_KNOWN_ITEM_IDS then
		BLD_KNOWN_ITEM_IDS = {}
		for id = 1, 999 do
			local ItemName = GetDatabaseValue("Items", id, "name")
			if ItemName and ItemName ~= "" then
				BLD_KNOWN_ITEM_IDS[ItemName] = id
			end
		end
	end
	return BLD_KNOWN_ITEM_IDS[Name]
end

-- ----------------------------------------------
-- Need for Medicine
-- ----------------------------------------------

function GetNeedForMedicine(HospAlias, ItemName)
	-- calculate available items
	local AvailableItems = GetItemCount(HospAlias, ItemName)
	if HasProperty(HospAlias, ItemName.."s") then
		AvailableItems = AvailableItems + GetProperty(HospAlias, ItemName.."s")
	end
	
	-- one item is missing
	if AvailableItems == 0 then
		return 100
	end

	-- Are we low on important stuff?
	if ItemName == "Bandage" then
		if AvailableItems < 5 then
			return 75
		elseif AvailableItems < 10 then
			return 50
		elseif AvailableItems < 25 then
			return 25
		else
			return 0
		end
	elseif ItemName == "Medicine" then
		if AvailableItems < 3 then
			return 75
		elseif AvailableItems < 6 then
			return 50
		elseif AvailableItems < 9 then
			return 25
		else
			return 0
		end
	elseif ItemName == "PainKiller" then
		if AvailableItems < 3 then
			return 75
		elseif AvailableItems < 6 then
			return 50
		elseif AvailableItems < 9 then
			return 25
		else
			return 0
		end
	else
		return 0
	end
end

---- 1. Make sure the building has at least 2 carts
--   2. Make sure the carts are ox carts (resource buildings) or horse carts (producers) for buildings tier 2/3
--   3. Make sure the carts are running the auto cart state (overrides default AI behaviour)
function CheckCarts(BldAlias)
	-- 1. Make sure the building has at least 2 carts
	local CartCount = BuildingGetCartCount(BldAlias)
	local BldType = BuildingGetType(BldAlias)
	local BestCount = 2
	
	if BldType == GL_BUILDING_TYPE_THIEF or BldType == GL_BUILDING_TYPE_MERCENARY then
		-- no state_autocart or forced carts for robbers
		return
	end
	
	if BldType == GL_BUILDING_TYPE_ROBBER and BuildingGetLevel(BldAlias) <= 1 then
		-- low level robbers should be fine with one cart, add second cart for higher levels
		BestCount = 1
	end
	
	if BldType == GL_BUILDING_TYPE_DIVEHOUSE then
		BestCount = 1
	end
	
	-- special case pirate
	if BldType == GL_BUILDING_TYPE_PIRATESNEST then
		if not ReadyToRepeat(BldAlias, "ai_BuyPirateShip") then
			return 
		end

		if not BuildingGetOwner(BldAlias, "CheckCartsMyBoss") then
			return
		end
		
		if GetMoney("CheckCartsMyBoss") < 3000 then
			return
		end
	
		-- be safe
		local ShipFound = false
	
		for i=0, BuildingGetCartCount(BldAlias)-1 do
			if BuildingGetCart(BldAlias, i, "Cart") then
				if CartGetType("Cart") == EN_CT_CORSAIR then
					ShipFound = true
					break
				end
			end
		end
	
		if not ShipFound then
			SetRepeatTimer(BldAlias, "ai_BuyPirateShip", 12)
			BuildingBuyCart(BldAlias, EN_CT_CORSAIR, true, "PirateShip")
		end
		
		return
	end
	
	if CartCount < BestCount then
		bld_BuyCart(BldAlias, "CartAlias", bld_GetIdealCartType(BldAlias))
	end
	
	-- no autocart measure for divehouse and robber
	if BldType == GL_BUILDING_TYPE_ROBBER or BldType == GL_BUILDING_TYPE_DIVEHOUSE then
		return
	end
	
	CartCount = BuildingGetCartCount(BldAlias)
	for i=0, CartCount - 1 do
		if BuildingGetCart(BldAlias, i, "CartAlias") then
			if not GetState("CartAlias", 54) then -- state_twp_autocart
				local Measure = GetCurrentMeasureName("CartAlias")
				if Measure ~= "AutoRoute" and Measure ~= "SupplyWorkshop" and Measure ~= "SalesCart" and Measure ~= "SendCartAndUnload" then
					SetState("CartAlias", 54, true)
				end
			end
		end
	end
end

function GetIdealCartType(BldAlias)
	local BldType = BuildingGetType(BldAlias)
	
	-- resource buildings with only one level
	if GL_BUILDING_TYPE_RANGERHUT == BldType 
			or GL_BUILDING_TYPE_FRUITFARM == BldType 
			or GL_BUILDING_TYPE_MILL == BldType then
		return EN_CT_OX
	end
	
	-- resource buildings with more levels and normal workshops, currently lvl 1
	local Lvl = BuildingGetLevel(BldAlias)
	if Lvl <= 1 then
		return EN_CT_MIDDLE
	end
	
	if GL_BUILDING_TYPE_FARM == BldType or GL_BUILDING_TYPE_MINE == BldType then 
		return EN_CT_OX
	end
	
	-- producers with more levels
	return EN_CT_HORSE
end

function BuyCart(BldAlias, CartAlias, CartType)
	CartType = CartType or EN_CT_MIDDLE
	if GetOutdoorMovePosition(nil, "", "GroundPos") then
		if ScenarioCreateCart(CartType, BldAlias, "GroundPos", "NewCart") then
			return CopyAlias("NewCart", CartAlias)
		end
	end
end

function RemoveCart(BldAlias, CartAlias)
	if not GetState("CartAlias", STATE_CHECKFORSPINNINGS) then -- means it is standing still
		if GetDistance("CartAlias", BldAlias) < 500 then -- is the cart at home?
			-- Check for currently loaded items
			local ItemId
			local Found = 0
			local Count = InventoryGetSlotCount("CartAlias", INVENTORY_STD)
			local HasItems = false
			for i=0, Count-1 do
				ItemId, Found = InventoryGetSlotInfo("CartAlias", i, INVENTORY_STD)
				if ItemId and ItemId>0 and Found>0 then
					HasItems = true
				end
			end
			if not HasItems then -- only remove cart if it is empty
				chr_CreditMoney(BldAlias, 250, "misc") -- add some money for compensation (needs testing)
				InternalRemove("CartAlias")
			end
		end
	end
end

function GetItemCountForBld(BldAlias, RequestedItemId)
	local SlotCount = InventoryGetSlotCount(BldAlias, INVENTORY_STD)
	local Retval = 0
	for i=0, SlotCount-1 do
		local ItemId, ItemCount = InventoryGetSlotInfo(BldAlias, i, INVENTORY_STD)
		if ItemId and ItemId == RequestedItemId then
			Retval = Retval + ItemCount
		end
	end
	return Retval
end

function CheckRepairs(BldAlias)
	local BuildHP = GetHPRelative(BldAlias) * 100
	if BuildHP >= 90 then
		-- no repairs necessary yet
		return
	end

	if GetState(BldAlias, STATE_REPAIRING) 
			or GetState(BldAlias, STATE_FIGHTING) 
			or GetState(BldAlias, STATE_BURNING)
			or GetState(BldAlias, STATE_LEVELINGUP)
			or GetState(BldAlias, STATE_DEAD) then
		-- no repairs possible
		return
	end
	-- leave the rest to chance...
	local Chance = Rand(70) + 20 -- always below 20%, never above 90% (70 + 20)
	if Chance >= BuildHP then
		MeasureRun(BldAlias, BldAlias, "RenovateBuilding")
	end		
end

function ForceLevelUp(BldAlias)
	
	if not ReadyToRepeat(BldAlias, "ai_ForceLevelUp") then
		return
	end
	
	if GetRound() < 3 then
		return
	end

	if not BuildingGetOwner(BldAlias, "MyBoss") then
		return
	end
	
	if GetState(BldAlias, STATE_BUILDING) or GetState(BldAlias, STATE_LEVELINGUP) then
		return
	end
	
	local BuildLevel = BuildingGetLevel(BldAlias)
	
	if BuildLevel == 3 then
		return
	end
	
	local BuildType = BuildingGetType(BldAlias)
	
	local Cost = 0
	local BossLevel = 0
	
	if BuildLevel == 2 then
		Cost = 22500
		BossLevel = 5
	else
		Cost = 7500
		BossLevel = 3
	end
	
	if GetMoney("MyBoss") < (Cost + 2500) then
		SetRepeatTimer(BldAlias, "ai_ForceLevelUp", 12)
		return
	end
	
	if SimGetLevel("MyBoss") < BossLevel then
		SetRepeatTimer(BldAlias, "ai_ForceLevelUp", 24)
		return
	end
	
	-- Special case SubLevel
	local SubLevel = -1
	if BuildType == GL_BUILDING_TYPE_ALCHEMIST_SHOP then
		if BuildLevel == 1 then
			SubLevel = 1 + Rand(2)
		else
			-- only upgrade to the sublevel you already had
			if BuildingHasUpgrade(BldAlias, "Perfume") then -- building id 171
				SubLevel = 1
			else
				SubLevel = 2
			end
		end
			
	elseif BuildType == GL_BUILDING_TYPE_SMITHY then
		if BuildLevel == 1 then
			SubLevel = 1 + Rand(2)
		else
			-- only upgrade to the sublevel you already had
			if BuildingHasUpgrade(BldAlias, "engravingtoolet") then -- building id 141
				SubLevel = 1
			else
				SubLevel = 2
			end
		end
	end
	
	local Proto = ScenarioFindBuildingProto(2, BuildType, BuildLevel+1, SubLevel)
	
	if Proto and chr_SpendMoney("MyBoss", Cost, "BuildingLevelUp") then
		local RepeatTime = 148 - 12*ScenarioGetDifficulty()
		SetRepeatTimer(BldAlias, "ai_ForceLevelUp", RepeatTime)
		SetProperty(BldAlias, "LevelUpProto", Proto)
		SetState(BldAlias, STATE_LEVELINGUP, true)
		return
	end
end

function HandlePingHour(BldAlias, ForceLevelUp)
	if not BuildingGetOwner(BldAlias, "MyBoss") then
		return
	end
	-- Check every worker every hour for bonuses from employer's abilities
	chr_CheckWorkerBonuses(BldAlias)
	
	-- abilities for buildings (last forever)
	bld_AbilityBoosts(BldAlias, "MyBoss")
	
	--if BuildingGetAISetting(BldAlias, "Produce_Selection") > 0 then
		--disable because not sure?
		--bld_SetupAI(BldAlias)
	--end
	
	if math.mod(GetGametime(), 8) == 3 then
		economy_CalculateSalesRanking(BldAlias)
	end
	
	-- at 1am: subtract current wages from balance
	if math.mod(GetGametime(), 24) == 1 then
		local Wages = economy_CalculateWages(BldAlias)
		economy_UpdateBalance(BldAlias, "Wages", -Wages)
	end
	
	-- Only for AI
	if GetHomeBuilding("MyBoss", "MyHome") then
		if DynastyIsAI("MyBoss") then -- or BuildingGetAISetting(BldAlias, "BuySell") > 0 then 
			bld_CheckCarts(BldAlias) 
		end
		
		if DynastyIsAI("MyBoss") then
			if ForceLevelUp then
				bld_ForceLevelUp(BldAlias)
			end
			
			bld_CheckRivals(BldAlias)
			bld_CheckRepairs(BldAlias)
		end
	end
end

function AbilityBoosts(BldAlias, BossAlias)
	
	local GeneralBossAbility = 0
	
	-- all buildings
	GeneralBossAbility = GetImpactValue(BossAlias, "SafeguardI")
	if GeneralBossAbility > GetImpactValue(BldAlias, "SafeBoost") then
		AddImpact(BldAlias, "SafeBoost", 1, -1)
		AddImpact(BldAlias, "ProtectionOfBurglary", 0.15, -1)
		AddImpact(BldAlias, "ProtectionFromFire", 0.15, -1)
	end
	
	-- specific buildings
	local Type = BuildingGetType(BldAlias)
	if Type == GL_BUILDING_TYPE_TAVERN then
		local BossAbility = GetImpactValue(BossAlias, "BestHouseI")
		if BossAbility > 0 then
			if GetImpactValue(BldAlias, "BestHouseBoost") < BossAbility then
				AddImpact(BldAlias, "BestHouseBoost", 1, -1)
				AddImpact(BldAlias, "Attractivity", 0.3, -1)
			end
		end
	elseif Type == GL_BUILDING_TYPE_FARM then
		local BossAbility = GetImpactValue(BossAlias, "FarmBonusI")
		if BossAbility > 0 then
			if GetImpactValue(BldAlias, "FarmBoost") < BossAbility then
				AddImpact(BldAlias, "FarmBoost", 1, -1)
				AddImpact(BldAlias, "Productivity", 0.25, -1)
			end
		end
	elseif Type == GL_BUILDING_TYPE_FRUITFARM then
		local BossAbility = GetImpactValue(BossAlias, "FarmBonusI")
		if BossAbility > 0 then
			if GetImpactValue(BldAlias, "FarmBoost") < BossAbility then
				AddImpact(BldAlias, "FarmBoost", 1, -1)
				AddImpact(BldAlias, "Productivity", 0.25, -1)
			end
		end
	elseif Type == GL_BUILDING_TYPE_ROBBER then
		local BossAbility = GetImpactValue(BossAlias, "ThiefI")
		if BossAbility > 0 then
			if GetImpactValue(BldAlias, "ThiefBoost") < BossAbility then
				AddImpact(BldAlias, "ThiefBoost", 1, -1)
				AddImpact(BldAlias, "RogueBonus", 0.10, -1)
			end
		end
	elseif Type == GL_BUILDING_TYPE_DIVEHOUSE then
		local BossAbility = GetImpactValue(BossAlias, "ThiefI")
		if BossAbility > 0 then
			if GetImpactValue(BldAlias, "ThiefBoost") < BossAbility then
				AddImpact(BldAlias, "ThiefBoost", 1, -1)
				AddImpact(BldAlias, "RogueBonus", 0.10, -1)
			end
		end
	elseif Type == GL_BUILDING_TYPE_THIEF then
		local BossAbility = GetImpactValue(BossAlias, "ThiefI")
		if BossAbility > 0 then
			if GetImpactValue(BldAlias, "ThiefBoost") < BossAbility then
				AddImpact(BldAlias, "ThiefBoost", 1, -1)
				AddImpact(BldAlias, "RogueBonus", 0.10, -1)
			end
		end
	elseif Type == GL_BUILDING_TYPE_DIVEHOUSE then
		local BossAbility = GetImpactValue(BossAlias, "ThiefI")
		if BossAbility > 0 then
			if GetImpactValue(BldAlias, "ThiefBoost") < BossAbility then
				AddImpact(BldAlias, "ThiefBoost", 1, -1)
				AddImpact(BldAlias, "RogueBonus", 0.10, -1)
			end
		end
	elseif Type == GL_BUILDING_TYPE_JUGGLER then
		local BossAbility = GetImpactValue(BossAlias, "ThiefI")
		if BossAbility > 0 then
			if GetImpactValue(BldAlias, "ThiefBoost") < BossAbility then
				AddImpact(BldAlias, "ThiefBoost", 1, -1)
				AddImpact(BldAlias, "RogueBonus", 0.10, -1)
			end
		end
	elseif Type == GL_BUILDING_TYPE_MERCENARY then
		local BossAbility = GetImpactValue(BossAlias, "ThiefI")
		if BossAbility > 0 then
			if GetImpactValue(BldAlias, "ThiefBoost") < BossAbility then
				AddImpact(BldAlias, "ThiefBoost", 1, -1)
				AddImpact(BldAlias, "RogueBonus", 0.10, -1)
			end
		end
	elseif Type == GL_BUILDING_TYPE_CHURCH_EV then
		local BossAbility = GetImpactValue(BossAlias, "PreacherI")
		if BossAbility > 0 then
			if GetImpactValue(BldAlias, "PreacherBoost") < BossAbility then
				AddImpact(BldAlias, "PreacherBoost", 1, -1)
				AddImpact(BldAlias, "Attractivity", 0.25, -1)
			end
		end
	elseif Type == GL_BUILDING_TYPE_CHURCH_CATH then
		local BossAbility = GetImpactValue(BossAlias, "PreacherI")
		if BossAbility > 0 then
			if GetImpactValue(BldAlias, "PreacherBoost") < BossAbility then
				AddImpact(BldAlias, "PreacherBoost", 1, -1)
				AddImpact(BldAlias, "Attractivity", 0.25, -1)
			end
		end
	end
end

function HandleSetup(BldAlias)
	-- Check every worker (only once) for illness and equipment 
	if not HasProperty(BldAlias, "CheckDefaultWorkers") then
		bld_ResetWorkers(BldAlias)
		SetProperty(BldAlias, "CheckDefaultWorkers", 1)
	end
	economy_CalculateSalesRanking(BldAlias)
end

function HandleOnLevelUp(BldAlias)
	-- Check every worker (only once) for illness and equipment 
	if not HasProperty(BldAlias, "CheckDefaultWorkers") then
		bld_ResetWorkers(BldAlias)
		SetProperty(BldAlias, "CheckDefaultWorkers", 1)
	end
	
	economy_StorageUpdateOnLevelUp(BldAlias)
	economy_CalculateSalesRanking(BldAlias)
end

function HandleNewOwner(BldAlias, FormerOwner)
	bld_ClearBuildingStash(BldAlias, FormerOwner)
	--bld_BuildingWorkersStopWorking(BldAlias) -- this seemed necessary at some point
	bld_ResetWorkers(BldAlias)
	economy_ClearBalance(BldAlias)
	economy_StorageClearProperties(BldAlias)
end

function IsResourceAvailable(BldAlias, ResourceItem)
	local Radius = 4000
	local IgnoreOwnership = (GL_BUILDING_TYPE_FRUITFARM == BuildingGetType(BldAlias) and DynastyIsAI(BldAlias))
	local DynFilter = "AND(Object.CanBeControlled())"
	if IgnoreOwnership then
		DynFilter = ""
	end
	
	local AvailableResourceCount = 0
	local FilterByItem = string.format("__F((Object.GetObjectsByRadius(Building)==%d)AND(Object.IsClass(6))AND(Object.IsType(33))%s)", Radius, DynFilter)
	local Count = Find(BldAlias, FilterByItem, "ResourceSearchResult", 20)
	for i=0, Count - 1 do
		local ResItemId = GetProperty("ResourceSearchResult"..i, "ResourceItemID") or -1
		LogMessage("Checking resource ".. GetID("ResourceSearchResult"..i) .. " with this current item: " .. ResItemId)
		if AliasExists("ResourceSearchResult"..i) -- safety check
				and ResourceCanBeChanged("ResourceSearchResult"..i) -- it's a changeable resource like a field or meadow
				and ResItemId == ItemGetID(ResourceItem) then
			AvailableResourceCount = AvailableResourceCount + 1
		end
	end
	if AvailableResourceCount > 0 then
		return AvailableResourceCount
	end
	return nil
end

function CheckResource(BldAlias, ResourceProto, ResourceCount)
	local IgnoreOwnership = (GL_BUILDING_TYPE_FRUITFARM == BuildingGetType(BldAlias) and DynastyIsAI(BldAlias))
	--ResourceProto = ResourceProto or FindResourceProto(ItemGetID(Resource))
	--ResourceGetTypeCount("Destination")
	
	-- 1. Find out how many buildings of this type we need
	-- ResourceCount = ResourceCount
	
	-- 2. Find out how many buildings are available nearby
	local Radius = 4000
	local DynFilter = "AND(Object.CanBeControlled())"
	if IgnoreOwnership then
		DynFilter = ""
	end
	
	local AvailableResourceCount = 0
	local FilterByItem = string.format("__F((Object.GetObjectsByRadius(Building)==%d)AND(Object.IsClass(6))AND(Object.IsType(33))%s)", Radius, DynFilter)
	local Count = Find(BldAlias, FilterByItem, "ResourceSearchResult", 20)
	for i=0, Count - 1 do
		if AliasExists("ResourceSearchResult"..i) -- safety check
				and ResourceCanBeChanged("ResourceSearchResult"..i) -- it's a changeable resource like a field or meadow
				and ResourceProto == BuildingGetProto("ResourceSearchResult"..i) then
			AvailableResourceCount = AvailableResourceCount + 1
		end
	end
	if AvailableResourceCount >= ResourceCount then
		-- there are enough resources for production, nothing else to do here (sowing is sim measure)
		return AvailableResourceCount
	end

	-- 3. Not enough resources around or owned, maybe there is one available to buy?
	local FilterByEmpty= string.format("__F((Object.GetObjectsByRadius(Building)==%d)AND(Object.IsClass(6))AND(Object.IsType(33))AND(Object.IsBuyable()))", Radius)
	Count = Find(BldAlias, FilterByEmpty, "ResourceSearchResult", 10)
	for i = 0, Count - 1 do
		if AliasExists("ResourceSearchResult"..i) -- safety check
				and ResourceCanBeChanged("ResourceSearchResult"..i) -- it's a changeable resource like a field or meadow
				and ResourceProto == BuildingGetProto("ResourceSearchResult"..i) then
			BuildingGetOwner(BldAlias, "CheckResourceBldOwner")
			if BuildingBuy("ResourceSearchResult"..i, "CheckResourceBldOwner", BM_NORMAL) then
				AvailableResourceCount = AvailableResourceCount + 1
			end
			if AvailableResourceCount >= ResourceCount then
				-- there are enough resources for production, nothing else to do here (sowing is sim measure)
				return AvailableResourceCount
			end
		end
	end
	
	-- 4. No more resource buildings aroung, try to build new
	while AvailableResourceCount < ResourceCount do
		GetPosition(BldAlias, "TargetPosition")
		if BuildingGetCity(BldAlias, "BuildCity") 
				and BuildingGetOwner(BldAlias, "CheckResourceBldOwner")
				and CityBuildNewBuilding("BuildCity", ResourceProto, "CheckResourceBldOwner", "ResourceAlias", "TargetPosition", 4000) then
			AvailableResourceCount = AvailableResourceCount + 1
		else
			break
		end
	end
	
	if AvailableResourceCount >= ResourceCount then
		-- there are enough resources for production, nothing else to do here (sowing is sim measure)
		return AvailableResourceCount
	end
	
	-- 5. No way to get more resource buildings, initiate regular crop change
	FilterByItem = string.format("__F((Object.GetObjectsByRadius(Building)==%d)AND(Object.IsClass(6))AND(Object.IsType(33))%s)", Radius, DynFilter)
	Count = Find(BldAlias, FilterByItem, "ResourceSearchResult", 20)
	for i=0, Count - 1 do
		if AliasExists("ResourceSearchResult"..i) -- safety check
				and ResourceCanBeChanged("ResourceSearchResult"..i) -- it's a changeable resource like a field or meadow
				and ResourceProto == BuildingGetProto("ResourceSearchResult"..i) then
			SetProperty(BldAlias, "CropChangeResource", GetID("ResourceSearchResult"..i))
		end
	end
end
