function Run()
	GetScenario("World")
	if not HasProperty("World", "static") then
		
		local Level = CityGetLevel("")
		local DefaultID = GetID("")
		local City0ID = GetID("City0")
		
		if City0ID == -1 then
			local CityCount = ScenarioGetObjects("Settlement", 1, "City")
			City0ID = GetID("City0")
		end
		
		if ScenarioGetTimePlayed() > 4 then
		
			if Level == 1 then
				-- kontor city - do nothing here
				return
			elseif Level == 2 then
				citypinghour_CheckVillage()
			elseif Level == 3 then
				citypinghour_CheckSmallTown()
			elseif Level == 4 then
				citypinghour_CheckTown()
			elseif Level == 5 then
				citypinghour_CheckCapital()
			elseif Level == 6 then
				citypinghour_CheckCapital()
			end
		end
		
		if GetRound() > 1 then
			if GetData("#MusiciansChooser") == nil then
				SetData("#MusiciansChooser", GetID(""))
			elseif GetData("#MusiciansChooser") == 0 then
				SetData("#MusiciansChooser", GetID(""))
			end
			if GetData("#MusiciansChooser") == GetID("") then
				citypinghour_CheckMusicians()
			end
		end
	
		if GetData("#AldermanChooser") == nil then
			if CityGetRandomBuilding("", -1, GL_BUILDING_TYPE_GUILDHOUSE, -1, -1, FILTER_IGNORE, "Guildhouse") and (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_GUILDHOUSE)[1]>0) then
				SetData("#AldermanChooser",GetID(""))
			end
		elseif GetData("#AldermanChooser") == 0 then
			if CityGetRandomBuilding("", -1, GL_BUILDING_TYPE_GUILDHOUSE, -1, -1, FILTER_IGNORE, "Guildhouse") and (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_GUILDHOUSE)[1]>0) then
				SetData("#AldermanChooser",GetID(""))
			end
		end
		if GetData("#AldermanChooser")==GetID("") then
			citypinghour_CheckAlderman()
		end
	
		if GetData("#ImperialChooser")==nil then
			if CityGetRandomBuilding("", -1, GL_BUILDING_TYPE_ARSENAL, -1, -1, FILTER_IGNORE, "Arsenal") and (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_ARSENAL)[1]>0) then
				SetData("#ImperialChooser",GetID(""))
			end
		elseif GetData("#ImperialChooser")==0 then
			if CityGetRandomBuilding("", -1, GL_BUILDING_TYPE_ARSENAL, -1, -1, FILTER_IGNORE, "Arsenal") and (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_ARSENAL)[1]>0) then
				SetData("#ImperialChooser",GetID(""))
			end
		end
		if GetData("#ImperialChooser")==GetID("") then
			gameplayformulas_CheckImperialOfficer()
		end
		
		if ScenarioGetTimePlayed() > 16 then
			citypinghour_CheckCrimes()
		end
		
	------------------------------------------------------------------------------
		local currentGameTime = math.mod(GetGametime(),24)
	--	if (currentGameTime == 1) then	
			
			-- check weather (stop raining if it bugs!)
			Weather_SetWeather("Fine", 4.0)
			
			-- -----------------------
			-- City Treasury
			-- -----------------------
		
			local TaxValue = 0 + GetProperty("", "TurnoverTax")
			local Tax = 0
			local cost = 0
			local repairTotal = 0
			local repairedbuildings = 0
			local Alias, WorkshopLvl
	
			-- taxes (income)
			local WorkshopCount = CityGetBuildings("", GL_BUILDING_CLASS_WORKSHOP, -1, -1, -1, FILTER_HAS_DYNASTY, "Workshop") -- for the message
			SetProperty("", "Workshops", WorkshopCount)
			
			CityGetLocalMarket("", "Market")
			local TurnoverTax = 0 + GetProperty("", "TurnoverTax")
			
			-- tax efficiency
			local Tax1 = 0.15 -- cat 1 raw
			local Tax2 = 0.40 -- cat 2 food
			local Tax3 = 0.50 -- cat 3 handi
			local Tax4 = 0.40 -- cat 4 schol
			local Tax5 = 0.50 -- cat 5 herbs
			local Tax6 = 0.50 -- cat 6 iron
			
			local ItemToCheck, ItemCat, ItemCount

			local Sum1 = 0
			local Sum2 = 0
			local Sum3 = 0
			local Sum4 = 0
			local Sum5 = 0
			local Sum6 = 0
			
			for i=0, 166 do
				local BaseValue = 0
				ItemToCheck = GetDatabaseValue("ItemsToMarket", i, "name")
				
				if ItemToCheck ~= nil then
					ItemCat = ItemGetCategory(ItemToCheck)
					ItemCount = GetItemCount("Market", ItemToCheck)
					if ItemCat == 1 then
						BaseValue = ItemCount*ItemGetBasePrice(ItemToCheck)*Tax1
						Sum1 = math.floor(Sum1 + (BaseValue*(TurnoverTax/100)))
					elseif ItemCat == 2 then
						BaseValue = ItemCount*ItemGetBasePrice(ItemToCheck)*Tax2
						Sum2 = math.floor(Sum2 + (BaseValue*(TurnoverTax/100)))
					elseif ItemCat == 3 then
						BaseValue = ItemCount*ItemGetBasePrice(ItemToCheck)*Tax3
						Sum3 = math.floor(Sum3 + (BaseValue*(TurnoverTax/100)))
					elseif ItemCat == 4 then
						BaseValue = ItemCount*ItemGetBasePrice(ItemToCheck)*Tax4
						Sum4 = math.floor(Sum4 + (BaseValue*(TurnoverTax/100)))
					elseif ItemCat == 5 then
						BaseValue = ItemCount*ItemGetBasePrice(ItemToCheck)*Tax5
						Sum5 = math.floor(Sum5 + (BaseValue*(TurnoverTax/100)))
					else
						BaseValue = ItemCount*ItemGetBasePrice(ItemToCheck)*Tax6
						Sum6 = math.floor(Sum6 + (BaseValue*(TurnoverTax/100)))
					end
				
				end
			end
			
			Tax = Sum1 + Sum2 + Sum3 + Sum4 + Sum5 + Sum6
			
			LogMessage("Total Taxes for"..GetName("").." is "..Tax.." Raw Material is "..Sum1.." Food is "..Sum2.." Handi is "..Sum3.." Schol is "..Sum4.." Herbs is "..Sum5.." Ironstuff is "..Sum6)
			
				
			if Tax >0 then
				CreditMoney("", Tax, "Tax")
			end
			
			SetProperty("", "TaxValue", TaxValue) -- for the message
			SetProperty("", "TaxMoney", Tax) -- for the message
			SetProperty("", "TaxRaw", Sum1)
			SetProperty("", "TaxFood", Sum2)
			SetProperty("", "TaxHandi", Sum3)
			SetProperty("", "TaxSchol", Sum4)
			SetProperty("", "TaxHerbs", Sum5)
			SetProperty("", "TaxIron", Sum6)
			
			-- nobility titles (income)
			local NobilityMoney = 0
			if HasProperty("", "NobilityMoney") then
				NobilityMoney = GetProperty("", "NobilityMoney")
			end
			SetProperty("", "NobilityMoneyLY", NobilityMoney)
			SetProperty("", "NobilityMoney", 0)
			
			-- land tax (income)
			
			
			-- fees (income)
			
			
			-- trials (income)
			
				
			-- offices (costs)
			local officecostsTotal = gameplayformulas_GetTotalOfficeIncome("")
			if officecostsTotal > 0 then
				if GetMoney("") > officecostsTotal then
					SpendMoney("", officecostsTotal, "OfficeIncome")				
				else
					local tmpcosts = GetMoney("")
					SpendMoney("", tmpcosts, "OfficeIncome")				
				end
			end
			SetProperty("", "OfficeMoney", officecostsTotal)
			
			LogMessage("Office Costs for "..GetName("").." is "..officecostsTotal)
			
			-- guards (costs)
			local Cityguards, Eliteguards = economy_CityGetGuardCount("")
			local Totalguards = Cityguards + Eliteguards
			LogMessage(GetName("").." hat insgesamt "..Totalguards.." Stadtwachen")
			
			-- weapons (costs)
			
			
			-- servants (costs)
			local Servants = economy_CityGetServantCount("")
			LogMessage(GetName("").." hat insgesamt "..Servants.." Stadtbedienstete")
			
			-- repair for residences without owner (costs)
			local FreeResidenceCount = CityGetBuildings("", nil, GL_BUILDING_TYPE_RESIDENCE, -1, -1, FILTER_IS_BUYABLE, "FreeResidence")
			for f=0, FreeResidenceCount-1 do
				Alias = "FreeResidence"..f
				if not BuildingGetOwner(Alias, "Sim") and (GetHP(Alias) < GetMaxHP(Alias)) then
					cost = BuildingGetRepairPrice(Alias)
	
					if GetMoney("") > cost then
						repairedbuildings = repairedbuildings + 1
						SpendMoney("", cost, "BuildingRepairs")				
						ModifyHP(Alias, (GetMaxHP(Alias) - GetHP(Alias)), false)
						repairTotal = repairTotal + cost
					end
				end
			end
	
			-- repair for workshops without owner (costs)
			local FreeWorkshopCount = CityGetBuildings("", GL_BUILDING_CLASS_WORKSHOP, -1, -1, -1, FILTER_IS_BUYABLE, "FreeWorkshop")
			for f=0,FreeWorkshopCount-1 do
				Alias = "FreeWorkshop"..f
				if not BuildingGetOwner(Alias, "Sim") and (GetHP(Alias)<GetMaxHP(Alias)) then
					cost = BuildingGetRepairPrice(Alias)
	
					if GetMoney("") > cost then
						repairedbuildings = repairedbuildings + 1
						SpendMoney("", cost, "BuildingRepairs")				
						ModifyHP(Alias, (GetMaxHP(Alias)-GetHP(Alias)), false)
						repairTotal = repairTotal + cost
					end
				end
			end
	
			SetProperty("", "repairedbuildings", repairedbuildings)
			SetProperty("", "BuildingRepairs", repairTotal)
			
			-- test
			local Test = CityGetServantCount("", GL_PROFESSION_PEASANT)
			LogMessage(GetName("").." hat insgesamt "..Test.." Bauern")
			
			local Test2 = CityGetServantCount("", GL_PROFESSION_THIEF)
			LogMessage(GetName("").." hat insgesamt "..Test2.." Diebe")
			
			-- -----------------------
			-- City Clergy
			-- -----------------------
			
			local ChurchTithe = 0 + GetProperty("", "ChurchTithe")
			if not HasProperty("", "ChurchTreasury") then
				SetProperty("", "ChurchTreasury", 1000)
			end
			local ChurchTreasury = 0 + GetProperty("", "ChurchTreasury")
			
			-- unemployed count
			local NumUnemployed = economy_CityGetUnemployedCount("")
			
			LogMessage(GetName("").." hat genau "..NumUnemployed.." Arbeitslose gefunden")
			
			-- repair costs for workerhuts
			local WorkerhutCount = CityGetBuildings("", -1, GL_BUILDING_TYPE_WORKER_HOUSING, 1, -1, FILTER_IGNORE, "Workerhut")
			for f=0,WorkerhutCount-1 do
				Alias = "Workerhut"..f
				if not BuildingGetOwner(Alias, "Sim") and (GetHP(Alias)<GetMaxHP(Alias)) then
					cost = BuildingGetRepairPrice(Alias)
	
					if GetMoney("") > cost then
						repairedbuildings = repairedbuildings + 1
						SpendMoney("", cost, "BuildingRepairs")				
						ModifyHP(Alias,(GetMaxHP(Alias)-GetHP(Alias)),false)
						repairTotal = repairTotal + cost
					end
				end
			end

			local WarMoney = 0
			if HasProperty("", "Warcosts") then
				WarMoney = GetProperty("", "Warcosts")
			end
			SetProperty("", "WarcostsLY", WarMoney)
			SetProperty("", "Warcosts", 0)

	--	end
	end
end

function CheckMusicians()
	if not CityGetRandomBuilding("",3,23,-1,-1,FILTER_IGNORE,"MusicianHomeBuilding") then
		return
	end
	GetLocatorByName("MusicianHomeBuilding", "Entry1", "MusicianSpawnPos")	
	--GetPosition("MusicianHomeBuilding","MusicianSpawnPos")

	if GetData("#MusicStage")==nil then
		SetData("#MusicStage",0)
	end
	if GetData("#RestPlace")==nil then
		SetData("#RestPlace",0)
	end

	if not AliasExists("#Musician1") then
		SimCreate(900,"MusicianHomeBuilding","MusicianSpawnPos","#Musician1")
		SimSetFirstname("#Musician1", "@L_VERSENGOLD_MUSICIAN_FIRSTNAME_+0")
		SimSetLastname("#Musician1", "@L_VERSENGOLD_MUSICIAN_LASTNAME_+0")
		SimSetBehavior("#Musician1","Musician")

		--Groupie
		SimCreate(6,"MusicianHomeBuilding","MusicianSpawnPos","Groupie1")
		SimSetAge("Groupie1", 16)
		SetState("Groupie1",STATE_TOWNNPC,true)
		SimSetBehavior("Groupie1","Groupie")
	end
	if not AliasExists("#Musician2") then
		SimCreate(901,"MusicianHomeBuilding","MusicianSpawnPos","#Musician2")
		SimSetFirstname("#Musician2", "@L_VERSENGOLD_MUSICIAN_FIRSTNAME_+1")
		SimSetLastname("#Musician2", "@L_VERSENGOLD_MUSICIAN_LASTNAME_+1")
		SimSetBehavior("#Musician2","Musician")

		--Groupie
		SimCreate(6,"MusicianHomeBuilding","MusicianSpawnPos","Groupie2")
		SimSetAge("Groupie2", 16)
		SetState("Groupie2",STATE_TOWNNPC,true)
		SimSetBehavior("Groupie2","Groupie")
	end
	if not AliasExists("#Musician3") then
		SimCreate(902,"MusicianHomeBuilding","MusicianSpawnPos","#Musician3")
		SimSetFirstname("#Musician3", "@L_VERSENGOLD_MUSICIAN_FIRSTNAME_+2")
		SimSetLastname("#Musician3", "@L_VERSENGOLD_MUSICIAN_LASTNAME_+2")
		SimSetBehavior("#Musician3","Musician")

		--Groupie
		SimCreate(6,"MusicianHomeBuilding","MusicianSpawnPos","Groupie3")
		SimSetAge("Groupie3", 16)
		SetState("Groupie3",STATE_TOWNNPC,true)
		SimSetBehavior("Groupie3","Groupie")
	end
	if not AliasExists("#Musician4") then
		SimCreate(905,"MusicianHomeBuilding","MusicianSpawnPos","#Musician4")
		SimSetFirstname("#Musician4", "@L_VERSENGOLD_MUSICIAN_FIRSTNAME_+3")
		SimSetLastname("#Musician4", "@L_VERSENGOLD_MUSICIAN_LASTNAME_+3")
		SimSetBehavior("#Musician4","Musician")

		--Groupie
		SimCreate(6,"MusicianHomeBuilding","MusicianSpawnPos","Groupie4")
		SimSetAge("Groupie4", 16)
		SetState("Groupie4",STATE_TOWNNPC,true)
		SimSetBehavior("Groupie4","Groupie")
	end
	if not AliasExists("#Musician5") then
		SimCreate(946,"MusicianHomeBuilding","MusicianSpawnPos","#Musician5")
		SimSetFirstname("#Musician5", "@L_VERSENGOLD_MUSICIAN_FIRSTNAME_+4")
		SimSetLastname("#Musician5", "@L_VERSENGOLD_MUSICIAN_LASTNAME_+4")
		SimSetBehavior("#Musician5","Musician")

		--Groupie
		SimCreate(6,"MusicianHomeBuilding","MusicianSpawnPos","Groupie5")
		SimSetAge("Groupie5", 16)
		SetState("Groupie5",STATE_TOWNNPC,true)
		SimSetBehavior("Groupie5","Groupie")
	end
end

function CheckCrimes()
	ListCrimeReport("crime_report_list")		-- liste mit (DynastyID, ActorID, CrimeTotal) 
	
	-- modifizieren
	local TopBias = -1
	local TopReport = -1
	local TopDynastyID = -1
	local TopActorID = -1
	local TopCrimeTotal = -1
	
	local DepositionTopBias = -1
	local DepositionTopReport = -1
	local DepositionTopDynastyID = -1
	local DepositionTopActorID = -1
	local DepositionTopCrimeTotal = -1
		
	for iReport = 0,ListSize("crime_report_list")-1 do
		ListGetElement("crime_report_list",iReport,"crime_report")
		local DynastyID  = GetProperty("crime_report", "DynastyID")
		local ActorID	 = GetProperty("crime_report", "ActorID")
		local CrimeTotal = GetProperty("crime_report", "CrimeTotal")
		
		if GetAliasByID(ActorID,"_actor") then
			if SimCanBeCharged("_actor")==0 then
				if GetAliasByID(DynastyID,"_dyn") then
					for iMember = 0, DynastyGetMemberCount("_dyn")-1 do
						if DynastyGetMember("_dyn",iMember,"_sim") then
							if GetSettlementID("_sim")==GetID("") then
								local Bias = CrimeTotal * 10	-- 0.. ~200
								
								local Hours = GetHoursToNextTrial("")
								if Hours>16 then 
									Bias = Bias - Hours * 2	-- 
								end
								
								local DiplomaticState = DynastyGetDiplomacyState("_dyn", "_actor")
								
								if DiplomaticState> DIP_NEUTRAL then
									Bias = 0
								elseif DiplomaticState==DIP_FOE then
									Bias = Bias
								else
									Bias = Bias * ((100.0-GetFavorToDynasty("_dyn","_actor"))/100)
								end

								if GetImpactValue("_actor","HaveImmunity")==1 then
									if Bias>DepositionTopBias and Bias>0 then
										DepositionTopBias = Bias
										DepositionTopReport = iReport
										DepositionTopDynastyID = DynastyID
										DepositionTopActorID = GetID("_actor")
										DepositionTopCrimeTotal = CrimeTotal
									end
								else
									if Bias>TopBias and Bias>0 then
										TopBias = Bias
										TopReport = iReport
										TopDynastyID = DynastyID
										TopActorID = GetID("_actor")
										TopCrimeTotal = CrimeTotal
									end
								end
							end
						end
					end
				end
			end
		end
	end
	
	SetProperty("","Crimes_TopAccuserDynastyID",TopDynastyID)
	SetProperty("","Crimes_TopActorID",TopActorID)
	SetProperty("","Crimes_TopBias",TopBias)
	SetProperty("","Crimes_TopCrimeTotal",TopCrimeTotal)

	SetProperty("","Crimes_DepositionTopActorID",DepositionTopActorID)
end

function CheckVillage()

	CitySetMaxWorkerhutLevel("", 1)

	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_TOWNHALL, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_PRISON, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_WELL, 1, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_LINGERPLACE, 1, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_EXECUTIONS_PLACE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_DUELPLACE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GRAVEYARD, -1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_MARKET, GL_BUILDING_TYPE_HARBOR, 1)

	if (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_GUILDHOUSE)[1]>0) then
		citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GUILDHOUSE, gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_GUILDHOUSE)[1])
	end
	
	if (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_ARSENAL)[1]>0) then
		citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_ARSENAL, gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_ARSENAL)[1])
	end
	
	if (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_SOLDIERPLACE)[1]>0) then
		citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_SOLDIERPLACE, gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_SOLDIERPLACE)[1])
	end
	
	-- for water-maps
	GetScenario("World")
	if HasProperty("World", "seamap") then
		if GetProperty("World", "seamap") == 1 then
			AICheckWorkingPlace("", GL_BUILDING_TYPE_FISHINGHUT, 1)
		end
	end
end

function CheckSmallTown()

	CitySetMaxWorkerhutLevel("", 2)

	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_TOWNHALL, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_PRISON, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_WELL, 1, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_LINGERPLACE, 1, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GRAVEYARD, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_EXECUTIONS_PLACE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_DUELPLACE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_MARKET, GL_BUILDING_TYPE_HARBOR, 2)

	if (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_GUILDHOUSE)[1]>0) then
		citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GUILDHOUSE, gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_GUILDHOUSE)[1])
	end
	
	if (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_ARSENAL)[1]>0) then
		citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_ARSENAL, gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_ARSENAL)[1])
	end
	
	if (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_SOLDIERPLACE)[1]>0) then
		citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_SOLDIERPLACE, gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_SOLDIERPLACE)[1])
	end
	
	-- for water-maps
	GetScenario("World")
	if HasProperty("World", "seamap") then
		if GetProperty("World", "seamap") == 1 then
			AICheckWorkingPlace("", GL_BUILDING_TYPE_FISHINGHUT, 1)
		end
	end
end

function CheckTown()

	CitySetMaxWorkerhutLevel("", 3)

	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_TOWNHALL, 3)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_PRISON, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_WELL, 1, 3)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_LINGERPLACE, 1, 4)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GRAVEYARD, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_EXECUTIONS_PLACE, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_DUELPLACE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_MARKET, GL_BUILDING_TYPE_HARBOR, 3)

	if (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_GUILDHOUSE)[1]>0) then
		citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GUILDHOUSE, gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_GUILDHOUSE)[1])
	end
	
	if (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_ARSENAL)[1]>0) then
		citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_ARSENAL, gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_ARSENAL)[1])
	end
	
	if (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_SOLDIERPLACE)[1]>0) then
		citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_SOLDIERPLACE, gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_SOLDIERPLACE)[1])
	end

	AICheckWorkingPlace("", GL_BUILDING_TYPE_ROBBER, 1)
	AICheckWorkingPlace("", GL_BUILDING_TYPE_HOSPITAL, 1)
	
	-- for water-maps
	GetScenario("World")
	if HasProperty("World", "seamap") then
		if GetProperty("World", "seamap") == 1 then
			AICheckWorkingPlace("", GL_BUILDING_TYPE_FISHINGHUT, 1)
			AICheckWorkingPlace("", GL_BUILDING_TYPE_PIRATESNEST, 1)
		end
	end
	
	AICheckWorkingPlace("", GL_BUILDING_TYPE_THIEF, 1)

	citypinghour_CheckChurch(1)
	
end

function CheckCapital()

	CitySetMaxWorkerhutLevel("", 3)

	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_TOWNHALL, 4)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_PRISON, 2)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_WELL, 1, 3)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_LINGERPLACE, 1, 5)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_EXECUTIONS_PLACE, 3)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_DUELPLACE, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GRAVEYARD, 1)
	citypinghour_CheckBuilding( GL_BUILDING_CLASS_MARKET, GL_BUILDING_TYPE_HARBOR, 3)

	if (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_GUILDHOUSE)[1]>0) then
		citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_GUILDHOUSE, gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_GUILDHOUSE)[1])
	end
	
	if (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_ARSENAL)[1]>0) then
		citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_ARSENAL, gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_ARSENAL)[1])
	end
	
	if (gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_SOLDIERPLACE)[1]>0) then
		citypinghour_CheckBuilding( GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_SOLDIERPLACE, gameplayformulas_CheckPublicBuilding("", GL_BUILDING_TYPE_SOLDIERPLACE)[1])
	end

	AICheckWorkingPlace("", GL_BUILDING_TYPE_HOSPITAL, 1)
	AICheckWorkingPlace("", GL_BUILDING_TYPE_MINE, 1)
	AICheckWorkingPlace("", GL_BUILDING_TYPE_ROBBER, 1)
	
	-- for water-maps
	GetScenario("World")
	if HasProperty("World", "seamap") then
		if GetProperty("World", "seamap") == 1 then
			AICheckWorkingPlace("", GL_BUILDING_TYPE_FISHINGHUT, 1)
			AICheckWorkingPlace("", GL_BUILDING_TYPE_PIRATESNEST, 1)
		end
	end
	
	AICheckWorkingPlace("", GL_BUILDING_TYPE_THIEF, 1)
	AICheckWorkingPlace("", GL_BUILDING_TYPE_NEKRO, 1)

	citypinghour_CheckChurch(2)
	
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
	
	for l=0,BuildTotal-1 do
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

function CheckChurch(MaxCount)
	local ChEv			= CityGetBuildingCount("", -1, GL_BUILDING_TYPE_CHURCH_EV, -1, -1, FILTER_HAS_DYNASTY)
	local ChCa			= CityGetBuildingCount("", -1, GL_BUILDING_TYPE_CHURCH_CATH, -1, -1, FILTER_HAS_DYNASTY)

	if ChEv + ChCa < MaxCount then
		-- no church, so create one
	
		local TotalChEv	= CityGetBuildingCount("", -1, GL_BUILDING_TYPE_CHURCH_EV, -1, -1, FILTER_NO_DYNASTY)
		local TotalChCa	= CityGetBuildingCount("", -1, GL_BUILDING_TYPE_CHURCH_CATH, -1, -1, FILTER_NO_DYNASTY)
	
		if TotalChEv>0 and TotalChCa==0 then
			AICheckWorkingPlace("", GL_BUILDING_TYPE_CHURCH_EV, ChEv+1)
		elseif TotalChCa>0 and TotalChEv==0 then
			AICheckWorkingPlace("", GL_BUILDING_TYPE_CHURCH_CATH, ChCa+1)
		else
			if Rand(100) < 50 then
				AICheckWorkingPlace("", GL_BUILDING_TYPE_CHURCH_EV, ChEv+1)
			else
				AICheckWorkingPlace("", GL_BUILDING_TYPE_CHURCH_CATH, ChCa+1)
			end
		end
	end
end

function CheckAlderman()
	local currentRound = GetRound()
	if currentRound > 1 then

		local currentGameTime = math.mod(GetGametime(),24)
		if (currentGameTime == 12) or ((currentGameTime > 12) and (currentGameTime < 13)) then

			local year = GetYear() - 2 + math.mod(GetGametime(),6)
			local DynCount = ScenarioGetObjects("cl_Dynasty", 99, "Dyn")
			local SimCount
			local Alias
			local SimArray = {}
			local SimFameArray = {}
			local SimArrayCount = 0

			for d=0,DynCount-1 do
				Alias = "Dyn"..d
				if GetID(Alias)>0 and DynastyIsPlayer(Alias) or DynastyIsAI(Alias) or DynastyIsShadow(Alias) then
					SimCount = DynastyGetMemberCount(Alias)
					for e=0,SimCount do
						DynastyGetMember(Alias, e, "Sim")
						if HasProperty("Sim", "PatronMaster") or HasProperty("Sim", "ArtisanMaster") or HasProperty("Sim", "ScholarMaster") or HasProperty("Sim", "ChiselerMaster") then
							local num = 0
							while num<100 do
								if dyn_GetFameLevel("Sim") > 0 then
									if SimArray[num] == GetID("Sim") then
										break
									elseif SimArray[num]==nil then
										SimArray[num] = GetID("Sim")
										SimFameArray[num] = dyn_GetFame("Sim")
										SimArrayCount = SimArrayCount + 1
										break
									end
								end
							num = num + 1
							end
						end
					end
				end
			end

			local AldermanWinner
			local AldermanFame = -1
			if SimArrayCount>0 then
				for x=0,SimArrayCount do
					if SimFameArray[x]~=nil and SimFameArray[x]>AldermanFame then
						AldermanFame = SimFameArray[x]
						AldermanWinner = x
					end
				end
				
				local oldalderman = chr_GetAlderman()
				
				if oldalderman > 0 then
					GetAliasByID(oldalderman, "Old")
					dyn_AddImperialFame("Old", 1)
					RemoveProperty("Old", "Alderman")
				end
				
				SetData("#Alderman", 0)
				if GetAliasByID(SimArray[AldermanWinner],"New") then
					SetProperty("New","Alderman",1)
					SetData("#Alderman",SimArray[AldermanWinner])

					local label
					if SimGetClass("New")==1 then
						label = "@L_GUILDHOUSE_MASTERLIST_PATRON"
					elseif SimGetClass("New")==2 then
						label = "@L_GUILDHOUSE_MASTERLIST_ARTISAN"
					elseif SimGetClass("New")==3 then
						label = "@L_GUILDHOUSE_MASTERLIST_SCHOLAR"
					elseif SimGetClass("New")==4 then
						label = "@L_GUILDHOUSE_MASTERLIST_CHISELER"
					end

					if SimGetGender("New")==GL_GENDER_MALE then
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
	end
end
