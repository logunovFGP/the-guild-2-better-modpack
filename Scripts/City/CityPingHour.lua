function Run()

	GetScenario("World")
	if HasProperty("World", "static") then
		return
	end
		
	local currentGameTime = math.mod(GetGametime(), 24)
	local Level = CityGetLevel("")
	
	if Level < 2 then
		-- kontor city - do nothing here
		return
	end
		
	-- get important things rolling
	if GetData("#AldermanChooser") == nil or GetData("#AldermanChooser") == 0 then
		if CityGetRandomBuilding("", -1, GL_BUILDING_TYPE_GUILDHOUSE, -1, -1, FILTER_IGNORE, "Guildhouse") then
			SetData("#AldermanChooser", GetID(""))
		end
	end
	
	-- random diseases for dynasty members
	local trys = 5
		
	for i=1, trys do
		local TargetID = gameplayformulas_CityGetRandomDynastyMember("", true, true) or 0
		if TargetID > 0 then
			GetAliasByID(TargetID, "InfectSim")
			if AliasExists("InfectSim") then
				if not GetState("InfectSim", STATE_SICK) then
					if GetImpactValue("InfectSim", "Resist") == 0 then
						if GetDynasty("InfectSim", "InfectDyn") then
							if ReadyToRepeat("InfectDyn", "RandomIllness") then
								--LogMessage("City "..GetName("").." tries to infect "..GetName("InfectSim"))
								CopyAlias("InfectSim", "RandomInfected")
								break
							end
						end
					end
				end
			end
		end
	end
	
	if AliasExists("RandomInfected") then
		citypinghour_InfectionEvent("RandomInfected")
	end
	
	-- levelup public buildings if necessecary
	if ScenarioGetTimePlayed() > 12 then

		if Level == 2 then
			citypinghour_CheckVillage()
		elseif Level == 3 then
			citypinghour_CheckSmallTown()
		elseif Level == 4 then
			citypinghour_CheckTown()
		elseif Level == 5 or Level == 6 then
			citypinghour_CheckCapital()
		end
	end
		
	-- get special events rolling
	local CurrentRound = GetRound()
	
	if CurrentRound > 1 then -- round 3 +
		
		if GetData("#MusiciansChooser") == nil then
			SetData("#MusiciansChooser", GetID(""))
		elseif GetData("#MusiciansChooser") == 0 then
			SetData("#MusiciansChooser", GetID(""))
		end
			
		if GetData("#MusiciansChooser") == GetID("") then
			citypinghour_CheckMusicians()
		end
			
		if currentGameTime == 12 then
			if GetData("#AldermanChooser") == GetID("") then
				citypinghour_CheckAlderman()
			end
		end
			
		if CurrentRound > 2 then -- round 4+
			
			-- ToDo: City Events
			citypinghour_CityEvent("")
		end
	end
		
	------------------------------------------------------------------------------
	if (currentGameTime == 1) then	
			
		-- Stop rain once a day (Workaround)
		Weather_SetWeather("Fine", 4.0)
		
		-- SetNameSet once a day
		local NameSet = GetProperty("World", "NameSet") or "english"
		ScenarioSetNameLanguage(NameSet)
		
		-- Update City Balance
		citypinghour_CityBalance()	
	end
end

function InfectionEvent(Target)
	
	local Difficulty = ScenarioGetDifficulty()
	local Round = GetRound()
	
	if not GetSettlement(Target, "HomeTown") then
		return
	end
	
	local Illness = { "Cold", "Sprain", "Influenza", "Pox", "Caries", "Blackdeath" }
	local IllnessCount = 6
	local MinDifficulty = { 0, 0, 2, 2, 3, 3 }
	local MinRound = { 0, 0, 1, 1, 1, 2 }
	
	local MyIllnessList = { }
	local MyIllnessCount = 0
	
	-- go through all illnesses and check conditions (difficulty + availabilty of hospital at the needed level)
	for i=1, IllnessCount do
		if MinDifficulty[i] <= Difficulty then
			local IllnessMinRound = MinRound[i] * (5 - Difficulty) -- Blackdeath on diff. 3 at round 4; on diff 4 at round 2
			if IllnessMinRound <= Round then -- min round reached
				if gameplayformulas_CityCheckHospital("HomeTown", Illness[i], false) then -- we have a hospital in town that could cure the disease
					local Index = MyIllnessCount + 1
					MyIllnessList[Index] = Illness[i]
					MyIllnessCount = Index
				end
			end
		end
	end
	
	if MyIllnessCount > 0 then
		local RandomIllness = Rand(MyIllnessCount) + 1
		local Illness = MyIllnessList[RandomIllness]
		local Hazard = 0
		local Infected = false
		Hazard = gameplayformulas_CalcIllnessHazard(Target, Illness)
		
		if Illness == "Cold" then
			if Hazard > Rand(100) then
				Disease.Cold:infectSim(Target)
				Infected = true
				LogMessage(GetName(Target).." received random illness "..Illness)
			end
		elseif Illness == "Influenza" then
			if Hazard > Rand(100) then
				Disease.Influenza:infectSim(Target)
				Infected = true
				LogMessage(GetName(Target).." received random illness "..Illness)
			end
		elseif Illness == "Pneumonia" then
			if Hazard > Rand(100) then
				Disease.Influenza:infectSim(Target)
				Infected = true
				LogMessage(GetName(Target).." received random illness "..Illness)
			end
		elseif Illness == "Pox" then
			if Hazard > Rand(100) then
				Disease.Pox:infectSim(Target)
				Infected = true
				LogMessage(GetName(Target).." received random illness "..Illness)
			end
		elseif Illness == "Blackdeath" then
			if not HasState(Target, "BlackdeathImmunity") then
				local CurrentRound = GetRound()
				local StartingRound = GetProperty("HomeTown", "ActivePlague") or 0
				if CurrentRound < (StartingRound + 4) then
					if Hazard > Rand(100) then
						Disease.Blackdeath:infectSim(Target)
						Infected = true
						LogMessage(GetName(Target).." received random illness "..Illness)
					end
				end
			end
		end
		
		if not Infected then
			LogMessage(GetName(Target).." resisted random illness")
		else
			if GetDynasty(Target, "TargetDyn") then
				SetRepeatTimer("TargetDyn", "RandomIllness", 12)
			end
		end
	end
end

function CityEvent(Target)
	--ToDo
end

function CityBalance()
	-- -----------------------
	-- City Treasury (Income + Cost)
	-- -----------------------
	local TurnoverTax = GetProperty("", "TurnoverTax") or 0
	SetProperty("", "TaxValue", TurnoverTax) -- save it for the balance
	local ChurchTithe = GetProperty("", "ChurchTithe") or 0
	SetProperty("", "TitheValue", ChurchTithe)
	local IncomeTotal = 0
	local CostTotal = 0
	local repairTotal = 0
	local Alias
	
	-- Taxes from market (income)
	CityGetLocalMarket("", "Market")
			
	-- Tax efficiency
	local Tax1 = 0.15 -- cat 1 raw
	local Tax2 = 0.35 -- cat 2 food
	local Tax3 = 0.40 -- cat 3 handi
	local Tax4 = 0.40 -- cat 4 schol
	local Tax5 = 0.40 -- cat 5 herbs
	local Tax6 = 0.40 -- cat 6 iron
	
	local ItemToCheck, ItemCat, ItemCount

	local Sum1 = 0
	local Sum2 = 0
	local Sum3 = 0
	local Sum4 = 0
	local Sum5 = 0
	local Sum6 = 0
	local ChurchIncome = 0
			
	for i=0, 166 do
		local BaseValue = 0
		ItemToCheck = GetDatabaseValue("ItemsToMarket", i, "name")
				
		if ItemToCheck and ItemToCheck ~= nil and ItemToCheck ~= "" then
			ItemCat = ItemGetCategory(ItemToCheck)
			ItemCount = GetItemCount("Market", ItemToCheck)
			if ItemCat == 1 then
				BaseValue = ItemCount*ItemGetBasePrice(ItemToCheck)*Tax1
				Sum1 = math.floor(Sum1 + (BaseValue*(TurnoverTax/100)))
				ChurchIncome = math.floor(ChurchIncome + (BaseValue*(ChurchTithe/100)))
			elseif ItemCat == 2 then
				BaseValue = ItemCount*ItemGetBasePrice(ItemToCheck)*Tax2
				Sum2 = math.floor(Sum2 + (BaseValue*(TurnoverTax/100)))
				ChurchIncome = math.floor(ChurchIncome + (BaseValue*(ChurchTithe/100)))
			elseif ItemCat == 3 then
				BaseValue = ItemCount*ItemGetBasePrice(ItemToCheck)*Tax3
				Sum3 = math.floor(Sum3 + (BaseValue*(TurnoverTax/100)))
				ChurchIncome = math.floor(ChurchIncome + (BaseValue*(ChurchTithe/100)))
			elseif ItemCat == 4 then
				BaseValue = ItemCount*ItemGetBasePrice(ItemToCheck)*Tax4
				Sum4 = math.floor(Sum4 + (BaseValue*(TurnoverTax/100)))
				ChurchIncome = math.floor(ChurchIncome + (BaseValue*(ChurchTithe/100)))
			elseif ItemCat == 5 then
				BaseValue = ItemCount*ItemGetBasePrice(ItemToCheck)*Tax5
				Sum5 = math.floor(Sum5 + (BaseValue*(TurnoverTax/100)))
				ChurchIncome = math.floor(ChurchIncome + (BaseValue*(ChurchTithe/100)))
			else
				BaseValue = ItemCount*ItemGetBasePrice(ItemToCheck)*Tax6
				Sum6 = math.floor(Sum6 + (BaseValue*(TurnoverTax/100)))
				ChurchIncome = math.floor(ChurchIncome + (BaseValue*(ChurchTithe/100)))
			end
		end
	end
			
	IncomeTotal = Sum1 + Sum2 + Sum3 + Sum4 + Sum5 + Sum6
			
	SetProperty("", "ChurchIncome", ChurchIncome)
	SetProperty("", "TaxRaw", Sum1)
	SetProperty("", "TaxFood", Sum2)
	SetProperty("", "TaxHandi", Sum3)
	SetProperty("", "TaxSchol", Sum4)
	SetProperty("", "TaxHerbs", Sum5)
	SetProperty("", "TaxIron", Sum6)
			
	-- nobility titles (income)
	local NobilityMoney = GetProperty("", "NobilityMoney") or 0
	SetProperty("", "NobilityMoneyLY", NobilityMoney)
	SetProperty("", "NobilityMoney", 0)
			
	-- fees (income)
	local Fees = GetProperty("", "CityFees") or 0
	SetProperty("", "CityFeesLY", Fees)
	SetProperty("", "CityFees", 0)
			
	-- trials (income)
	local TrialIncome = GetProperty("", "TrialIncome") or 0
	SetProperty("", "TrialIncomeLY", TrialIncome)
	SetProperty("", "TrialIncome", 0)
		
	-- add it
	IncomeTotal = IncomeTotal + TrialIncome + Fees + NobilityMoney
	SetProperty("", "TotalIncome", IncomeTotal) -- for the balance
	CreditMoney("", IncomeTotal, "misc")
				
	-- offices (costs)
	local officecostsTotal = gameplayformulas_GetTotalOfficeIncome("")
	CostTotal = officecostsTotal
	SetProperty("", "OfficeMoney", officecostsTotal)
		
	-- guards (costs)
	local Cityguards, Eliteguards = economy_CityGetGuardCount("")
	local CostCG = Cityguards * 150 or 0
	local CostEG = Eliteguards * 100 or 0
	SetProperty("", "CityGC", CostCG)
	SetProperty("", "EliteGC", CostEG)
	CostTotal = CostTotal + CostCG + CostEG
			
	-- servants (costs)
	local Servants = economy_CityGetServantCount("")
	local ServCost = Servants * 200
	SetProperty("", "ServantCost", ServCost)
	CostTotal = CostTotal + ServCost
			
	-- repair buildings without owner (costs)
	local FreeBuildings = CityGetBuildings("", -1, -1, -1, -1, FILTER_NO_DYNASTY, "FreeBuilding")
	for f=0, FreeBuildings-1 do
		Alias = "FreeBuilding"..f
		if not BuildingGetOwner(Alias, "Sim") and (GetHP(Alias) < GetMaxHP(Alias)) then
			cost = BuildingGetRepairPrice(Alias)
			if GetMoney("") > cost then
				ModifyHP(Alias, (GetMaxHP(Alias) - GetHP(Alias)), false)
				repairTotal = repairTotal + cost
			end
		end
	end
		
	-- -----------------------
	-- War
	-- -----------------------
	local WarMoney = 0
		
	if HasProperty("", "Warcosts") then
		WarMoney = GetProperty("", "Warcosts")
	end
		
	SetProperty("", "WarcostsLY", WarMoney)
	SetProperty("", "Warcosts", 0)
		
	-- pay
	SetProperty("", "BuildingRepairs", repairTotal)
	CostTotal = CostTotal + WarMoney + repairTotal
	SetProperty("", "TotalCost", CostTotal)
	SpendMoney("", CostTotal, "misc", true)
			
	-- -----------------------
	-- City Clergy
	-- -----------------------
	if not HasProperty("", "ChurchTreasury") then
		SetProperty("", "ChurchTreasury", 1000)
	end
		
	local ChurchTreasury = GetProperty("", "ChurchTreasury")
	ChurchTreasury = ChurchTreasury + ChurchIncome
		
	-- unemployed count
	local NumUnemployed = economy_CityGetUnemployedCount("")
	local NewCost = 100*NumUnemployed
	SetProperty("", "UnemployedCost", NewCost)
			
	ChurchTreasury = ChurchTreasury - NewCost
	SetProperty("", "ChurchTreasury", ChurchTreasury)
			
	-- send message to all politicians of the City
	feedback_CityBalanceRound("")
end

function CheckMusicians()
	
	-- spawn Versengold band
	
	if not CityGetRandomBuilding("", GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_TOWNHALL, -1, -1, FILTER_IGNORE, "MusicianHomeBuilding") then
		return
	end
	
	GetLocatorByName("MusicianHomeBuilding", "Entry1", "MusicianSpawnPos")	

	if GetData("#MusicStage") == nil then
		SetData("#MusicStage", 0)
	end
	
	if GetData("#RestPlace") == nil then
		SetData("#RestPlace", 0)
	end

	if not AliasExists("#Musician1") then
		SimCreate(900, "MusicianHomeBuilding", "MusicianSpawnPos", "#Musician1")
		SimSetFirstname("#Musician1", "@L_VERSENGOLD_MUSICIAN_FIRSTNAME_+0")
		SimSetLastname("#Musician1", "@L_VERSENGOLD_MUSICIAN_LASTNAME_+0")
		SimSetBehavior("#Musician1", "Musician")

		--Groupie
		SimCreate(6, "MusicianHomeBuilding", "MusicianSpawnPos", "Groupie1")
		SimSetAge("Groupie1", 16)
		SetState("Groupie1", STATE_TOWNNPC, true)
		SimSetBehavior("Groupie1", "Groupie")
	end
	
	if not AliasExists("#Musician2") then
		SimCreate(901, "MusicianHomeBuilding", "MusicianSpawnPos", "#Musician2")
		SimSetFirstname("#Musician2", "@L_VERSENGOLD_MUSICIAN_FIRSTNAME_+1")
		SimSetLastname("#Musician2", "@L_VERSENGOLD_MUSICIAN_LASTNAME_+1")
		SimSetBehavior("#Musician2", "Musician")

		--Groupie
		SimCreate(6, "MusicianHomeBuilding", "MusicianSpawnPos", "Groupie2")
		SimSetAge("Groupie2", 16)
		SetState("Groupie2", STATE_TOWNNPC, true)
		SimSetBehavior("Groupie2", "Groupie")
	end
	
	if not AliasExists("#Musician3") then
		SimCreate(902, "MusicianHomeBuilding", "MusicianSpawnPos", "#Musician3")
		SimSetFirstname("#Musician3", "@L_VERSENGOLD_MUSICIAN_FIRSTNAME_+2")
		SimSetLastname("#Musician3", "@L_VERSENGOLD_MUSICIAN_LASTNAME_+2")
		SimSetBehavior("#Musician3", "Musician")

		--Groupie
		SimCreate(6, "MusicianHomeBuilding", "MusicianSpawnPos", "Groupie3")
		SimSetAge("Groupie3", 16)
		SetState("Groupie3", STATE_TOWNNPC, true)
		SimSetBehavior("Groupie3", "Groupie")
	end
	
	if not AliasExists("#Musician4") then
		SimCreate(905, "MusicianHomeBuilding", "MusicianSpawnPos", "#Musician4")
		SimSetFirstname("#Musician4", "@L_VERSENGOLD_MUSICIAN_FIRSTNAME_+3")
		SimSetLastname("#Musician4", "@L_VERSENGOLD_MUSICIAN_LASTNAME_+3")
		SimSetBehavior("#Musician4", "Musician")

		--Groupie
		SimCreate(6, "MusicianHomeBuilding", "MusicianSpawnPos", "Groupie4")
		SimSetAge("Groupie4", 16)
		SetState("Groupie4", STATE_TOWNNPC, true)
		SimSetBehavior("Groupie4", "Groupie")
	end
	
	if not AliasExists("#Musician5") then
		SimCreate(946,"MusicianHomeBuilding", "MusicianSpawnPos", "#Musician5")
		SimSetFirstname("#Musician5", "@L_VERSENGOLD_MUSICIAN_FIRSTNAME_+4")
		SimSetLastname("#Musician5", "@L_VERSENGOLD_MUSICIAN_LASTNAME_+4")
		SimSetBehavior("#Musician5", "Musician")

		--Groupie
		SimCreate(6, "MusicianHomeBuilding", "MusicianSpawnPos", "Groupie5")
		SimSetAge("Groupie5", 16)
		SetState("Groupie5", STATE_TOWNNPC, true)
		SimSetBehavior("Groupie5", "Groupie")
	end
end

function CheckVillage()

	CitySetMaxWorkerhutLevel("", 1)

	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_TOWNHALL, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_PRISON, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_EXECUTIONS_PLACE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_DUELPLACE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GRAVEYARD, 1)
end

function CheckSmallTown()

	CitySetMaxWorkerhutLevel("", 2)

	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_TOWNHALL, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_PRISON, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_EXECUTIONS_PLACE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_DUELPLACE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GRAVEYARD, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GUILDHOUSE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_ARSENAL, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_SOLDIERPLACE, 1)
end

function CheckTown()

	CitySetMaxWorkerhutLevel("", 3)

	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_TOWNHALL, 3)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_PRISON, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_EXECUTIONS_PLACE, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_DUELPLACE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GRAVEYARD, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GUILDHOUSE, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_ARSENAL, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_SOLDIERPLACE, 1)
end

function CheckCapital()

	CitySetMaxWorkerhutLevel("", 3)

	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_TOWNHALL, 4)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_PRISON, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_EXECUTIONS_PLACE, 3)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_DUELPLACE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GRAVEYARD, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GUILDHOUSE, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_ARSENAL, 3)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_SOLDIERPLACE, 1)
end

function CheckBuilding(Class, Type, Level, Count)

	if not Count then
		Count = 1
	end
	
	local	BuildTotal = CityGetBuildings("", Class, Type, -1, -1, FILTER_IGNORE, "Found")
	local	Ist = 0
	
	for l=0,BuildTotal-1 do
		if BuildingGetLevel("Found"..l) >= Level then
			Ist = Ist + 1
			if Ist >= Count then
				return
			end
		end
	end
	
	for l=0, BuildTotal-1 do
		if BuildingGetLevel("Found"..l) < Level then
			BuildingLevelMeUp("Found"..l, -1)
			Ist = Ist + 1
			if Ist>=Count then
				return
			end
		end
	end
	
	while Ist < Count do
		local Proto = ScenarioFindBuildingProto(Class, Type, Level, -1)
		if not Proto or Proto==-1 then
			break
		end

		if not CityBuildNewBuilding("", Proto, nil, "Building") then
			break
		end
		Ist = Ist + 1
	end
end

function CheckAlderman()

	local year = GetYear() - 2 + math.mod(GetGametime(), 6)
	local DynCount = ScenarioGetObjects("cl_Dynasty", 99, "Dyn")
	local SimCount, Alias, SimPrioNew
	local SimArray = {}
	local SimFameArray = {}
	local SimArrayCount = 0
	local SimPrio = 0

	for i=0, DynCount-1 do
		Alias = "Dyn"..i
		if GetID(Alias) > 0 then
			SimCount = DynastyGetMemberCount(Alias)
			for e=0, SimCount do
				DynastyGetMember(Alias, e, "Sim"..e)
				if HasProperty("Sim"..e, "PatronMaster") or HasProperty("Sim"..e, "ArtisanMaster") or HasProperty("Sim"..e, "ScholarMaster") or HasProperty("Sim"..e, "ChiselerMaster") then
					SimPrioNew = SimGetLevel("Sim"..e) + SimGetOfficeLevel("Sim"..e)*3	
					if SimPrioNew > SimPrio then
						SimPrio = SimPrioNew
						CopyAlias("Sim"..e, "Candidate"..i)
					end
				end
			end
					
			if AliasExists("Candidate"..i) then
				SimArrayCount = SimArrayCount + 1
				SimArray[SimArrayCount] = GetID("Candidate"..i)
				SimFameArray[SimArrayCount] = dyn_GetFame("Candidate"..i)
			end
		end
	end

	local AldermanWinner
	local AldermanFame = -1
			
	if SimArrayCount > 0 then
		for x=1, SimArrayCount do
			if SimFameArray[x]~=nil and SimFameArray[x] > AldermanFame then
				AldermanFame = SimFameArray[x]
				AldermanWinner = x
			end
		end
				
		-- goodby old man
		local OldAlderman = chr_GetAlderman()
				
		if OldAlderman > 0 then
			GetAliasByID(OldAlderman, "Old")
			dyn_AddImperialFame("Old", 1)
			RemoveProperty("Old", "Alderman")
		end
				
		SetData("#Alderman", 0)
				
		-- welcome new man
		if GetAliasByID(SimArray[AldermanWinner], "New") then
			SetProperty("New", "Alderman", 1)
			SetData("#Alderman", SimArray[AldermanWinner])

			local label
			if SimGetClass("New") == 1 then
				label = "@L_GUILDHOUSE_MASTERLIST_PATRON"
			elseif SimGetClass("New") == 2 then
				label = "@L_GUILDHOUSE_MASTERLIST_ARTISAN"
			elseif SimGetClass("New") == 3 then
				label = "@L_GUILDHOUSE_MASTERLIST_SCHOLAR"
			elseif SimGetClass("New") == 4 then
				label = "@L_GUILDHOUSE_MASTERLIST_CHISELER"
			end

			if SimGetGender("New") == GL_GENDER_MALE then
				label = label.."_MALE_+0"
			else
				label = label.."_FEMALE_+0"
			end

			GetSettlement("New", "settlement")
			local fameleveldyn = "@L_GUILDHOUSE_FAME_DYNASTY_+"..dyn_GetFameLevel("New")

			MsgNewsNoWait("All", "New", "", "politics", -1,
							"@L_CHECKALDERMAN_HEAD_+0",
							"@L_CHECKALDERMAN_BODY_+0",
							GetYear(), GetID("New"), label, GetID("settlement"), fameleveldyn, dyn_GetFame("New"))
		end
	else
		SetData("#Alderman", 0)
	end
end
