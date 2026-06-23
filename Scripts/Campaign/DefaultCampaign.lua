function GetWorld()
	return ""
end

-- this function is called directly after the world is loaded
-- use this function for creating dynasties and sim's
-- on success return nothing or a empty string
-- on error return the error message

function Prepare()
	SetTime(EN_SEASON_SPRING, 1400, 5, 0)
	return true
end

function CreateShadowDynasty(Number, City, NewDynastyAlias)
	
	-- Priority for having at least one building in the city (highest level is taken)
	local PrimTypes = {  GL_BUILDING_TYPE_TAVERN, GL_BUILDING_TYPE_MINE, GL_BUILDING_TYPE_HOSPITAL, -- every village (2) has these 
					GL_BUILDING_TYPE_FARM, GL_BUILDING_TYPE_RANGERHUT, -- every small town (3) has these
					GL_BUILDING_TYPE_FRUITFARM, GL_BUILDING_TYPE_MILL, -- every city (4) has these
					GL_BUILDING_TYPE_ROBBER, GL_BUILDING_TYPE_PIRATESNEST, -- every free city (5) has these 
					GL_BUILDING_TYPE_CHURCH_CATH, GL_BUILDING_TYPE_CHURCH_EV } -- every imperial city (6) has these
	
	-- Shadows occupy these aswell with their spouses, if the buildings are at least level 2/3
	local SpouseTypes = { GL_BUILDING_TYPE_FISHINGHUT, GL_BUILDING_TYPE_SMITHY, GL_BUILDING_TYPE_TAILORING, -- most important
				GL_BUILDING_TYPE_BAKERY, GL_BUILDING_TYPE_JOINERY, GL_BUILDING_TYPE_ALCHEMIST, GL_BUILDING_TYPE_THIEF, GL_BUILDING_TYPE_STONEMASON, GL_BUILDING_TYPE_DIVEHOUSE,  -- second important
				GL_BUILDING_TYPE_NEKRO, GL_BUILDING_TYPE_BANKHOUSE, GL_BUILDING_TYPE_JUGGLER, GL_BUILDING_TYPE_MERCENARY  } -- least important
	
	local NumPrimTypes = 11
	local NumSpouseTypes = 13
	
	-- Get a working hut
	if not AliasExists("WorkingHut") then
		for i=1, NumPrimTypes do
			if CityGetBuildingCount(City, GL_BUILDING_CLASS_WORKSHOP, PrimTypes[i], -1, -1, FILTER_HAS_DYNASTY) < 1 then
				if CityGetRandomBuilding(City, GL_BUILDING_CLASS_WORKSHOP, PrimTypes[i], 3, -1, FILTER_NO_DYNASTY, "WorkingHut") then -- check level 3
					--LogMessage("ShadowDynasty No "..Number.." has found Building Type "..PrimTypes[i].." at level 3")
					break
				end
					
				if CityGetRandomBuilding(City, GL_BUILDING_CLASS_WORKSHOP, PrimTypes[i], 2, -1, FILTER_NO_DYNASTY, "WorkingHut") then -- check level 2
					--LogMessage("ShadowDynasty No "..Number.." has found Building Type "..PrimTypes[i].." at level 2")
					break
				end
					
				if CityGetRandomBuilding(City, GL_BUILDING_CLASS_WORKSHOP, PrimTypes[i], 1, -1, FILTER_NO_DYNASTY, "WorkingHut") then -- check level 1
					--LogMessage("ShadowDynasty No "..Number.." has found Building Type "..PrimTypes[i].." at level 1")
					break
				end
			end
		end
	end
	
	-- still no working hut? then check the Spouse-list in priority order
	if not AliasExists("WorkingHut") then
		for i=1, NumSpouseTypes do
			if CityGetBuildingCount(City, GL_BUILDING_CLASS_WORKSHOP, SpouseTypes[i], -1, -1, FILTER_HAS_DYNASTY) < 2 then
				if CityGetRandomBuilding(City, -1, SpouseTypes[i], 3, -1, FILTER_NO_DYNASTY, "WorkingHut") then -- level 3
					--LogMessage("ShadowDynasty No "..Number.." has found Building Type "..SpouseTypes[i].." at level 3")
					break
				end
					
				if CityGetRandomBuilding(City, -1, SpouseTypes[i], 2, -1, FILTER_NO_DYNASTY, "WorkingHut") then -- level 2
					--LogMessage("ShadowDynasty No "..Number.." has found Building Type "..SpouseTypes[i].." at level 2")
					break
				end
			end
		end
	end
	
	-- still no working hut? then try lvl 1 spouse list
	if not AliasExists("WorkingHut") then
		for i=1, NumSpouseTypes do
			if CityGetRandomBuilding(City, -1, SpouseTypes[i], 1, -1, FILTER_NO_DYNASTY, "WorkingHut") then -- level 1
				--LogMessage("ShadowDynasty No "..Number.." has found Building Type "..SpouseTypes[i].." at level 1")
				break
			end
		end
	end
	
	-- still no working hut, then build a new one.
	if not AliasExists("WorkingHut") then 
		--LogMessage("ShadowDynasty No "..Number.." needs to build a new Working Hut")
		local Class = Rand(4) + 1
		local Protos = {}
		local ProtoCount = 0
		if Class == GL_CLASS_PATRON then
			Protos = { GL_BUILDING_TYPE_TAVERN, GL_BUILDING_TYPE_BAKERY, GL_BUILDING_TYPE_MILL }
			ProtoCount = 3
		elseif Class == GL_CLASS_ARTISAN then
			Protos =  { GL_BUILDING_TYPE_SMITHY, GL_BUILDING_TYPE_JOINERY, GL_BUILDING_TYPE_TAILORING, GL_BUILDING_TYPE_STONEMASON }
			ProtoCount = 4
		elseif Class == GL_CLASS_SCHOLAR then
			Protos = { GL_BUILDING_TYPE_HOSPITAL, GL_BUILDING_TYPE_ALCHEMIST, GL_BUILDING_TYPE_CHURCH_CATH, GL_BUILDING_TYPE_CHURCH_EV, GL_BUILDING_TYPE_BANKHOUSE, GL_BUILDING_TYPE_NEKRO }
			ProtoCount = 6
		else -- rogue
			Protos = { GL_BUILDING_TYPE_THIEF, GL_BUILDING_TYPE_DIVEHOUSE, GL_BUILDING_TYPE_JUGGLER, GL_BUILDING_TYPE_MERCENARY }
			ProtoCount = 4
		end
					
		local Select = Rand(ProtoCount)+1
		local RandomProto = Protos[Select]
		local BuildProto = ScenarioFindBuildingProto(2, RandomProto, 1, -1)
					
		if BuildProto and BuildProto ~= -1 then
			if not CityBuildNewBuilding(City, BuildProto, nil, "WorkingHut") then
				return "unable to buy or build new workshop for Shadow Dynasty"
			end
		end
	end
	
	local Gender = Rand(2)
	local Class = BuildingGetCharacterClass("WorkingHut") or (Rand(4) + 1) -- get the class for our dynasty boss
		
	if Class == -1 then
		return "Illegal character class for building "..GetName("WorkingHut")
	end
		
	if not DynastyCreate(-1, false, 0, NewDynastyAlias, true) then
		return "cannot create the dynasty"
	end
		
	if not BossCreate("WorkingHut", Gender, Class, 5, "boss") then
		return "unable to create boss of the dynasty"
	end
		
	local Reli = 0 -- cath
	if Rand(10) >= 7 then
		Reli = 1 -- protestant. Start with less people of that faith.
	end

	SimSetReligion("boss", Reli)
	DynastyAddMember(NewDynastyAlias, "boss")
		
	-- Buy the workshop
	if not BuildingBuy("WorkingHut", "boss", BM_STARTUP) then
		return "unable to buy the building for the dynasty"
	end
		
	local Fame = 0
	local ImpFame = 0
	local NobLevel = 2 + Rand(3)
	local XP = GL_STARTUP_XP_SHADOW_DYNASTY
	local StartMoney = 10000
	local OfficeLevel = 0
		
	-- add some fame on random
	if Rand(10) == 0 then
		Fame = 1+Rand(10)
	end
	
	if Rand(20) == 0 then
		ImpFame = 1+Rand(12)
	end
		
	-- Set office and family
	if AliasExists("Office") then
		SimSetOffice("boss", "Office")
		
		-- start with random equipment
		local RandomWeapon = Rand(20)
		if RandomWeapon >= 0 and RandomWeapon <4 then
			AddItems("boss", "Dagger", 1, INVENTORY_EQUIPMENT)
		elseif RandomWeapon == 4 then
			AddItems("boss", "Dagger", 1, INVENTORY_EQUIPMENT)
			AddItems("boss", "LeatherArmor", 1, INVENTORY_EQUIPMENT)
		elseif RandomWeapon == 5 then
			AddItems("boss", "Mace", 1, INVENTORY_EQUIPMENT)
		elseif RandomWeapon == 6 then
			AddItems("boss", "Mace", 1, INVENTORY_EQUIPMENT)
			AddItems("boss", "LeatherArmor", 1, INVENTORY_EQUIPMENT)
		elseif RandomWeapon == 7 then
			AddItems("boss","Longsword", 1, INVENTORY_EQUIPMENT)
			local Weapon = Rand(5)
			if Weapon == 0 then
				AddItems("boss", "Chainmail", 1, INVENTORY_EQUIPMENT)
			elseif Weapon == 1 then
				AddItems("boss", "LeatherArmor", 1, INVENTORY_EQUIPMENT)
			end
		elseif RandomWeapon == 8 then
			AddItems("boss","Longsword", 1, INVENTORY_EQUIPMENT)
			if Rand(3) == 0 then
				AddItems("boss", "Platemail", 1, INVENTORY_EQUIPMENT)
			end
		end
			
		-- Get a residence
		if not CityGetRandomBuilding(City, -1, GL_BUILDING_TYPE_RESIDENCE, 5, -1, FILTER_NO_DYNASTY, "SleepingHut") then
			if not CityGetRandomBuilding(City, -1, GL_BUILDING_TYPE_RESIDENCE, 4, -1, FILTER_NO_DYNASTY, "SleepingHut") then
				if not CityGetRandomBuilding(City, -1, GL_BUILDING_TYPE_RESIDENCE, 3, -1, FILTER_NO_DYNASTY, "SleepingHut") then
					if not CityGetRandomBuilding(City, -1, GL_BUILDING_TYPE_RESIDENCE, 2, -1, FILTER_NO_DYNASTY, "SleepingHut") then
						local Proto = ScenarioFindBuildingProto(nil, GL_BUILDING_TYPE_RESIDENCE, (2+Rand(2)), -1)
						if Proto ~= -1 then
							CityBuildNewBuilding(City, Proto, nil, "SleepingHut")
						end
					end
				end
			end
		end
				
		if AliasExists("SleepingHut") then
			if not BuildingBuy("SleepingHut", "boss", BM_STARTUP) then
				CityGetNearestBuilding(City, "boss", -1, GL_BUILDING_TYPE_WORKER_HOUSING, -1, -1, FILTER_IGNORE, "NewHut")
				CopyAlias("NewHut", "SleepingHut")
			end
		else
			CityGetNearestBuilding(City, "boss", -1, GL_BUILDING_TYPE_WORKER_HOUSING, -1, -1, FILTER_IGNORE, "SleepingHut")
		end
		
		SetHomeBuilding("boss", "SleepingHut")
				
		OfficeLevel = OfficeGetLevel("Office") or 0
		if OfficeLevel <= 1 then
			if NobLevel < 4 then
				NobLevel = 4
			end
			
		elseif OfficeLevel == 2 then
			NobLevel = 4 + Rand(2)
		elseif OfficeLevel == 3 then
			NobLevel = 5 + Rand(2)
		else
			NobLevel = 6 + Rand(4)
		end
		
		local FirstAge = 16 + Rand(8)
		local Age = 32 + Rand(12)
		SimSetAge("boss", Age)
		local SpouseAge = 32 + Rand(12)
		
		-- get a spouse
		if BossCreate("SleepingHut", 1 - SimGetGender("boss"), (1+Rand(4)), 5, "Spouse") then
			SimSetAge("Spouse", SpouseAge)
			DynastyAddMember(NewDynastyAlias, "Spouse")
			IncrementXP("Spouse", (XP-500))
			SimMarry("boss", "Spouse")
		end
				
		-- get a workshop for the spouse if possible
		if AliasExists("Spouse") then
		
			--LogMessage("Find a SpouseShop for "..GetName("Spouse"))
			-- Get a SpouseShop
			for i=1, NumPrimTypes do
				if CityGetBuildingCount(City, GL_BUILDING_CLASS_WORKSHOP, PrimTypes[i], -1, -1, FILTER_HAS_DYNASTY) < 1 and not dyn_CheckForWorkshop("boss", PrimTypes[i]) then
					if CityGetRandomBuilding(City, GL_BUILDING_CLASS_WORKSHOP, PrimTypes[i], 3, -1, FILTER_NO_DYNASTY, "SpouseShop") then -- check level 3
						--LogMessage("ShadowDynasty No "..Number.." has found Building Type "..PrimTypes[i].." for "..GetName("Spouse").." at level 3")
						break
					end
						
					if CityGetRandomBuilding(City, GL_BUILDING_CLASS_WORKSHOP, PrimTypes[i], 2, -1, FILTER_NO_DYNASTY, "SpouseShop") then -- check level 2
						--LogMessage("ShadowDynasty No "..Number.." has found Building Type "..PrimTypes[i].." for "..GetName("Spouse").." at level 2")
						break
					end
					
					if CityGetRandomBuilding(City, GL_BUILDING_CLASS_WORKSHOP, PrimTypes[i], 1, -1, FILTER_NO_DYNASTY, "SpouseShop") then -- check level 1
						--LogMessage("ShadowDynasty No "..Number.." has found Building Type "..PrimTypes[i].." for "..GetName("Spouse").." at level 1")
						break
					end
				end
			end
			
			-- still no working hut? then check the Spouse-list in priority order
			if not AliasExists("SpouseShop") then
				--LogMessage("Check SpouseList for "..GetName("Spouse"))
				for i=1, NumSpouseTypes do
					if not dyn_CheckForWorkshop("boss", SpouseTypes[i]) then
						if CityGetRandomBuilding(City, -1, SpouseTypes[i], 3, -1, FILTER_NO_DYNASTY, "SpouseShop") then -- level 3
							--LogMessage("ShadowDynasty No "..Number.." has found Building Type "..SpouseTypes[i].." for "..GetName("Spouse").." at level 3")
							break
						end
							
						if CityGetRandomBuilding(City, -1, SpouseTypes[i], 2, -1, FILTER_NO_DYNASTY, "SpouseShop") then -- level 2
							--LogMessage("ShadowDynasty No "..Number.." has found Building Type "..SpouseTypes[i].." for "..GetName("Spouse").." at level 2")
							break
						end
					end
				end
			end
					
			-- if we found something, me might need to change our class
			if AliasExists("SpouseShop") then
				local BuildingClass = BuildingGetCharacterClass("SpouseShop")
				local MyClass = SimGetClass("Spouse")
				-- Pirate buildings have BuildingClass == 0, and if we use SimSetClass, then it will result in a corrupted sim that will cause crashes later.
				if BuildingClass == 0 then
					BuildingClass = 4 -- Rogue
				end
				if BuildingClass ~= MyClass then
					--LogMessage("Change Class of "..GetName("Spouse"))
					SimSetClass("Spouse", BuildingClass)
				end
			end
			
			if AliasExists("SpouseShop") then -- now buy it if possible
				BuildingBuy("SpouseShop", "Spouse", BM_STARTUP)
			end
		end
					
		-- Create childs
		if AliasExists("boss") and AliasExists("Spouse") then
			local ChildCount = 1+Rand(5) -- how many children?
			local FirstAge = 15+Rand(9)
			local ChildAge = FirstAge
				
			for i=1, ChildCount do
				local ChildGender = Rand(2)
				if ChildGender == 0 then
					ChildGender = 8
				else
					ChildGender = 7
				end
							
				SimCreate(ChildGender, "SleepingHut", "SleepingHut", "Shadowchild")
						
				if SimGetGender("boss") == GL_GENDER_MALE then
					SimSetFamily("Shadowchild", "Spouse", "boss")
				else
					SimSetFamily("Shadowchild", "boss", "Spouse")
				end
							
				SetHomeBuilding("Shadowchild", "SleepingHut")
				DoNewBornStuff("Shadowchild")
				SimSetAge("Shadowchild", (FirstAge-(SimGetChildCount("boss")+Rand(3))))
				if SimGetAge("Shadowchild") >= 15 then
					local RandomClass = Rand(4) + 1
					SimSetClass("Shadowchild", RandomClass)
				end
			end
		end
				
		XP = XP + OfficeGetLevel("Office")*200
	else
		if CityGetNearestBuilding(City, "boss", -1, GL_BUILDING_TYPE_WORKER_HOUSING, -1, -1, FILTER_IGNORE, "SleepingHut") then
			SetHomeBuilding("boss", "SleepingHut")
		end
	end
		
	SetNobilityTitle("boss", NobLevel, true)
	local AgeBonus = SimGetAge("boss")*10 + Rand(250)
	IncrementXP("boss", (XP+AgeBonus))
	StartMoney =  StartMoney + NobLevel*500 + OfficeLevel*750
	CreditMoney("boss", StartMoney, "GameStart")

	if Fame and ImpFame then
		dyn_AddFame("boss", Fame)
		dyn_AddImperialFame("boss", ImpFame)
	end

	-- MP advanced option
	if IsMultiplayerGame() then
		local optLevel = GetSettingNumber("OPTIONS", "ShadowStartLevel", 0)
		if optLevel > 1 then
			SimSetStartLevel("boss", optLevel)
		end
	end

	return ""
end

function FindResidenceElsewhere(CityAlias)
	local n = ScenarioGetObjects("Settlement", 99, "AltCity")
	for i = 0, n - 1 do
		local Alt = "AltCity"..i
		if AliasExists(Alt) and not CityIsKontor(Alt) and GetID(Alt) ~= GetID(CityAlias) then
			if CityGetRandomBuilding(Alt, nil, GL_BUILDING_TYPE_RESIDENCE, 1, -1, FILTER_IS_BUYABLE, "Residence") then
				CopyAlias(Alt, CityAlias)
				return true
			end
			local Proto = ScenarioFindBuildingProto(nil, GL_BUILDING_TYPE_RESIDENCE, 1, -1)
			if Proto and Proto ~= -1 and CityBuildNewBuilding(Alt, Proto, nil, "Residence") then
				CopyAlias(Alt, CityAlias)
				return true
			end
		end
	end
	return false
end

function CreateDynasty(ID, SpawnPoint, IsPlayer, PeerID, PlayerDescLabel)

	local Section
	Section = "INIT-PLAYER-"
	Section = Section .. ScenarioGetDifficulty()

	local Money = GetSettingNumber(Section, "Money", 5000)
	
	if Money < 5000 then
		Money = 5000
	end
	
	local optMoney, optResLevel = 0, 0
	if IsMultiplayerGame() then
		optMoney = GetSettingNumber("OPTIONS", (IsPlayer and "PlayerStartMoney") or "AIStartMoney", 0)
		if optMoney > 0 then
			Money = optMoney
		end	
	
		optResLevel = GetSettingNumber("OPTIONS", (IsPlayer and "StartBuildings") or "AIStartBuildings", 0)
		if optResLevel > 0 then
			if optResLevel > 4 then
				optResLevel = 4
			end
		end
	end

	if IsPlayer then
		LogMessage("@NAO #E Player creation -> ID: " .. ID .. ", SpawnPoint: " .. SpawnPoint .. ", " .. PeerID .. ", PlayerDesc: " .. PlayerDescLabel)
	end

	local DynastyAlias = "NewDynasty"

	if not AliasExists(SpawnPoint) then
		return "invalid spawn point"
	end
	
	local PlayerDescNode = nil
	local CityName = nil

	if PlayerDescLabel~=nil then
		local PlayerDescPath = "\\Application\\Game\\PlayerDesc"..PlayerDescLabel
		PlayerDescNode = FindNode(PlayerDescPath)
		LogMessage("@NAO #W ("..ID..") PlayerDescNode found.")
	end
	
	if IsPlayer then
		if not PlayerCreate(nil, "boss") then
			return "unable to create player character"
		end	
	else
		local RandGender = Rand(2)
		if not BossCreate(nil, RandGender, 1, 1, "boss") then
			return "unable to create boss of the dynasty"
		end
	end	
	
	if not DynastyCreate(ID, IsPlayer, PeerID, DynastyAlias, false) then
		return "cannot create the dynasty "..ID
	end
	
	if(CityName == nil) then
		CityName = ""
	end
	
	local CityAlias = "CityName"
	
	local BeamPos
	
	local Workshops = 1
	
	-- get city name from playerdescnode
	if PlayerDescNode ~= nil then
		CityName = PlayerDescNode:GetValueString("City")
		LogMessage("@NAO #W ("..ID..") City -> " .. CityName)
	end
	
	if IsPlayer then
		if CityName and CityName ~= "" then
			ScenarioGetObjectByName("Settlement", CityName, CityAlias)
		end

		if not AliasExists(CityAlias) then
			CityName = GetSettingString("ENDLESS", "City", "")
			LogMessage("@NAO #W ("..ID..") City not found. Using Endless City -> " .. CityName)
			if CityName ~= "" then
				ScenarioGetObjectByName("Settlement", CityName, CityAlias)
			end
		end
		
		Workshops = 0
	end
	
	local RandClass = 1
	
	if not IsPlayer then
		-- random class
		RandClass = 1+Rand(4)
		SimSetClass("boss", RandClass)
		SimSetAge("boss", 17+Rand(6))
	end

	if not AliasExists(CityAlias) then
		LogMessage("@NAO #W AI " .. GetName("boss") .. " Check 1, City Alias not AliasExists(CityAlias)")

		local CityCount = ScenarioGetObjects("Settlement", 99, "CityList")

		local BestOccupancy = nil
		local BestCity = nil
		local EqualBestCount = 0
		local FallbackOccupancy = nil
		local FallbackCity = nil
		local FallbackEqual = 0

		for cc=0, CityCount-1 do
			local Candidate = "CityList"..cc

			if AliasExists(Candidate) then
				local Occupancy = CityGetBuildingCount(Candidate, nil, GL_BUILDING_TYPE_RESIDENCE, 1, -1, FILTER_HAS_DYNASTY)
				local FreeResidences = CityGetBuildingCount(Candidate, nil, GL_BUILDING_TYPE_RESIDENCE, 1, -1, FILTER_IS_BUYABLE)

				if FallbackOccupancy == nil or Occupancy < FallbackOccupancy then
					FallbackOccupancy = Occupancy
					FallbackCity = Candidate
					FallbackEqual = 1
				elseif Occupancy == FallbackOccupancy then
					FallbackEqual = FallbackEqual + 1
					if Rand(FallbackEqual) == 0 then
						FallbackCity = Candidate
					end
				end

				if FreeResidences >= 1 then
					if BestOccupancy == nil or Occupancy < BestOccupancy then
						BestOccupancy = Occupancy
						BestCity = Candidate
						EqualBestCount = 1
					elseif Occupancy == BestOccupancy then
						EqualBestCount = EqualBestCount + 1
						if Rand(EqualBestCount) == 0 then
							BestCity = Candidate
						end
					end
				end
			end
		end

		if not BestCity then
			BestCity = FallbackCity
			BestOccupancy = FallbackOccupancy
		end

		if BestCity then
			LogMessage(
				"@NAO #W AI "
				.. GetName("boss")
				.. " selected city "
				.. GetName(BestCity)
				.. " (occupancy "
				.. BestOccupancy
				.. ")"
			)

			CopyAlias(BestCity, CityAlias)
		elseif not ScenarioGetRandomObject("Settlement", CityAlias) then
			return "unable to find a start city for AI dynasty"
		end
	end
	
	if not DynastyAddMember(DynastyAlias, "boss") then
		return "unable to add the first member to the dynasty"
	end

	if IsMultiplayerGame() then
		local optTitle = GetSettingNumber("OPTIONS", (IsPlayer and "StartNobility") or "AIStartNobility", 0)
		if (optTitle > 0) then
			SetNobilityTitle("boss", optTitle)
		end
	end

	local resMin, resMax = 1, -1
	if optResLevel and optResLevel > 0 then
		resMin = optResLevel
		resMax = optResLevel 
	end

	-- Find residence
	if not CityGetRandomBuilding(CityAlias, nil, GL_BUILDING_TYPE_RESIDENCE, resMin, resMax, FILTER_IS_BUYABLE, "Residence") then
		local Proto = ScenarioFindBuildingProto(nil, GL_BUILDING_TYPE_RESIDENCE, resMin, -1)
		if (not Proto or Proto==-1) and resMin > 1 then
			Proto = ScenarioFindBuildingProto(nil, GL_BUILDING_TYPE_RESIDENCE, 1, -1)
		end
		if Proto and Proto~=-1 then
			if not CityBuildNewBuilding(CityAlias, Proto, nil, "Residence") then
				if not IsPlayer then
					defaultcampaign_FindResidenceElsewhere(CityAlias)
				end
			end
		end
	end

	LogMessage("@NAO #W AI " .. GetName("boss") .. "spawned at city " .. GetName(CityAlias) )
	
	-- Buy the residence
	if AliasExists("Residence") then
		BuildingBuy("Residence", "boss", BM_STARTUP)
		GetOutdoorMovePosition("boss", "Residence", "BeamPos")
		BeamPos = "BeamPos"
		SetHomeBuilding("boss", "Residence")
	else
		if IsPlayer then
			local RProto = ScenarioFindBuildingProto(nil, GL_BUILDING_TYPE_RESIDENCE, 1, -1)
			local Refund = 0
			if RProto and RProto ~= -1 then
				Refund = BuildingGetPriceProto(RProto)
			end
			if Refund and Refund > 0 then
				CreditMoney("boss", Refund, "GameStart")
			end
			local Body = "@L_SPAWN_NOROOM_SP_BODY"
			if IsMultiplayerGame() then
				Body = "@L_SPAWN_NOROOM_MP_BODY"
			end
			MsgBoxNoWait("boss", "", "@L_SPAWN_NOROOM_HEAD", Body, GetName(CityAlias), Refund)
		end

		if CityGetRandomBuilding(CityAlias, GL_BUILDING_CLASS_PUBLICBUILDING, GL_BUILDING_TYPE_TOWNHALL, -1, -1, FILTER_IGNORE, "TownHall") and GetOutdoorMovePosition("boss", "TownHall", "Position") then
			BeamPos = "Position"
		elseif GetOutdoorMovePosition("boss", SpawnPoint, "Position") then
			BeamPos = "Position"
		else
			BeamPos = SpawnPoint
		end
	end
	SimBeamMeUp("boss", BeamPos)
	
	-- Set age to 17 for players and get XP bonus for older AIs
	if not IsPlayer then
		local AgeBonus = (SimGetAge("boss")-17) * 100
		IncrementXP("boss", AgeBonus)
	else
		SimSetAge("boss", 17)
		LogMessage("@NAO #W ("..ID..") Character is " .. GetName("boss"))
	end

	-- MP advanced option
	if IsMultiplayerGame() then
		local optLevel = GetSettingNumber("OPTIONS", (IsPlayer and "PlayerStartLevel") or "AIStartLevel", 0)
		if optLevel > 1 then
			SimSetStartLevel("boss", optLevel)
		end
	end

	-- start money
	CreditMoney("boss", Money, "GameStart")
	
	-- buy the workshops for the character
	local Class = SimGetClass("boss")
	if Workshops > 0 then
		local FoundWS = false
		local NumBuildings = CityGetBuildings(CityAlias, GL_BUILDING_CLASS_WORKSHOP, -1, 1, -1, FILTER_NO_DYNASTY, "Building")
		
		if NumBuildings >0 then
			for i=0, NumBuildings-1 do
				if BuildingGetCharacterClass("Building"..i) == Class then
					if BuildingGetType("Building"..i) ~= GL_BUILDING_TYPE_RANGERHUT and BuildingGetType("Building"..i) ~= GL_BUILDING_TYPE_MINE then
						if BuildingBuy("Building"..i, "boss", BM_STARTUP) then
							FoundWS = true
							break
						end
					end
				end
			end
			
			if not FoundWS then -- no workshop found, build a new one
				local Protos = {}
				local ProtoCount = 0
				if Class == GL_CLASS_PATRON then
					Protos = { GL_BUILDING_TYPE_TAVERN, GL_BUILDING_TYPE_BAKERY, GL_BUILDING_TYPE_MILL }
					ProtoCount = 3
				elseif Class == GL_CLASS_ARTISAN then
					Protos =  { GL_BUILDING_TYPE_SMITHY, GL_BUILDING_TYPE_JOINERY, GL_BUILDING_TYPE_TAILORING, GL_BUILDING_TYPE_STONEMASON }
					ProtoCount = 4
				elseif Class == GL_CLASS_SCHOLAR then
					Protos = { GL_BUILDING_TYPE_HOSPITAL, GL_BUILDING_TYPE_ALCHEMIST, GL_BUILDING_TYPE_CHURCH_CATH, GL_BUILDING_TYPE_CHURCH_EV, GL_BUILDING_TYPE_BANKHOUSE, GL_BUILDING_TYPE_NEKRO }
					ProtoCount = 6
				else -- rogue
					Protos = { GL_BUILDING_TYPE_THIEF, GL_BUILDING_TYPE_DIVEHOUSE, GL_BUILDING_TYPE_JUGGLER }
					ProtoCount = 3
				end
				
				local Select = Rand(ProtoCount)+1
				local RandomProto = Protos[Select]
				local BuildProto = ScenarioFindBuildingProto(2, RandomProto, 1, -1)
				
				if BuildProto and BuildProto~= -1 then
					if CityBuildNewBuilding(CityAlias, BuildProto, nil, "NewWS") then
					--	LogMessage("Neubau fertig!")
						if BuildingBuy("NewWS", "boss", BM_STARTUP) then
					--		LogMessage("Neubau gekauft!")
							FoundWS = true
						end
					end
				end
			end
		end
	end
						
	-- init mission
	local PlayerDescNode = nil

	if PlayerDescLabel~=nil then
		local PlayerDescPath = "\\Application\\Game\\PlayerDesc"..PlayerDescLabel
		PlayerDescNode = FindNode(PlayerDescPath)
	end

	if PlayerDescNode~=nil then

		local Team
		local Success
		
		Success, Team = PlayerDescNode:GetValueInt("Team", 0)
		if Team and Team > 0 then
			DynastySetTeam(DynastyAlias, Team)
		end
		
		SetProperty(DynastyAlias, "PlayerDesc", PlayerDescLabel)
		local MissionType = PlayerDescNode:GetValueInt("MissionType")
		local MissionSubtype = PlayerDescNode:GetValueInt("MissionSubType")
		
		-- save mission to scenario (used for AI decisions in TWP)
		GetScenario("Scenario")
		SetProperty("Scenario", "AITWP_Mission", MissionType)
	
		if (MissionType == 0) then			-- ausloeschung
			StartMission("Mission_DeathMatch", DynastyAlias)
		elseif (MissionType == 1) then		-- timelimit
			StartMission("Mission_TimeLimit", DynastyAlias)
		elseif (MissionType == 2)  then		-- common goal 
			if (MissionSubtype == 0) then
				StartMission("Mission_MakeMoney", DynastyAlias)
			elseif (MissionSubtype == 1) then
				StartMission("Mission_Office", DynastyAlias)
			elseif (MissionSubtype == 2) then
				StartMission("Mission_Acuss", DynastyAlias)
			elseif (MissionSubtype == 3) then
				StartMission("Mission_Criminal", DynastyAlias)
			end
		elseif (MissionType == 4) then
			StartMission("Mission_Endless", DynastyAlias)
		end
	end

	return ""
end

function CreateComputerDynasty(Number, SpawnPoint)
	return defaultcampaign_CreateDynasty(Number, SpawnPoint, false, -1)
end

-- this function is called, after the init of the scenario is finished.
function Start()
	defaultcampaign_SetupDiplomacy()
end

function SetupDiplomacy()

	local CityCount = ScenarioGetObjects("Settlement", -1, "Cities")
	local DynCount 	= ScenarioGetObjects("Dynasty", 100, "DynList")
	if CityCount == 0 or DynCount == 0 then
		return
	end
	
	local CityID
	local Count
	
	for dyn=0, DynCount-1 do
		if DynastyGetBuilding2("DynList"..dyn, 0, "Home"..dyn) then
			SetData("CityID"..dyn, GetSettlementID("Home"..dyn))
		else
			SetData("CityID"..dyn, -1)
		end
	end
	
	local Difficulty = ScenarioGetDifficulty()
	
	local FriendCount = 8 - (Difficulty*2)
		
	for CityNo=0, CityCount-1 do
	
		CityID = GetID("Cities"..CityNo)
		Count = 0
		
		for dyn=0, DynCount-1 do
			if GetData("CityID"..dyn)==CityID then
				CopyAlias("DynList"..dyn, "Dynasties"..Count)
				Count = Count + 1
			end
		end
		
		local Alias
		
		for dyn=0,Count-1 do
		
			Alias = "Dynasties"..dyn
			
			local Friends = defaultcampaign_GetStateCount(Alias, DIP_NAP, Count)
			
			while Friends < FriendCount do
			
				if Friends<FriendCount and Rand(3) == 0 then
					local Friend = defaultcampaign_FindDynasty(DIP_NAP, FriendCount, dyn+1, Count, Friends == 0)
					if Friend then
						DynastySetDiplomacyState(Alias, Friend, DIP_NAP)
					end
					Friends = Friends + 1
				end
			end
		end
	end
	
	
	local EnemyCount = Difficulty
		
	for CityNo=0, CityCount-1 do
	
		CityID = GetID("Cities"..CityNo)
		Count = 0
		
		for dyn=0, DynCount-1 do
			if GetData("CityID"..dyn)==CityID then
				CopyAlias("DynList"..dyn, "Dynasties"..Count)
				Count = Count + 1
			end
		end
		
		local Alias
		
		for dyn=0,Count-1 do
		
			Alias = "Dynasties"..dyn
			
			local Enemies = defaultcampaign_GetStateCount(Alias, DIP_FOE, Count)
			
			while Enemies < EnemyCount do
			
				if Enemies < EnemyCount and Rand(3) == 0 then
					local Friend = defaultcampaign_FindDynasty(DIP_FOE, EnemyCount, dyn+1, Count, Enemies == 0)
					if Friend then
						DynastySetDiplomacyState(Alias, Friend, DIP_FOE)
					end
					Enemies = Enemies + 1
				end
			end
		end
	end
end

function InitCameraPosition()

	if GetLocalPlayerDynasty("LocalPlayer") then
		if DynastyGetMember("LocalPlayer", 0, "Boss") then
			local Rotation = 180
			if GetHomeBuilding("Boss", "Home") then
				Rotation = GetRotation("Boss", "home") + 90
			end
			CameraTerrainSetPos("Boss", 1200, Rotation)
		end
	end
end

function FindDynasty(DipState, MaxState, StartNo, EndNo, FirstOfType)

	local DynNo
	local Found
	local Count = 0
	
	for DynNo=StartNo, EndNo-1 do
		if DynastyGetDiplomacyState("Dynasties"..(StartNo-1), "Dynasties"..DynNo) == DIP_NEUTRAL then
			if defaultcampaign_GetStateCount("Dynasties"..DynNo, DipState, EndNo) < MaxState then
				Count = Count + 1
				if Rand(100) <= 100/Count then
					Found = "Dynasties"..DynNo
					if FirstOfType and GetSettlementID("Dynasties"..(StartNo-1)) == GetSettlementID("Dynasties"..DynNo) then
						return Found
					end
				end
			end
		end
	end
	
	return Found
end

function GetStateCount(DynAlias, DipState, EndNo)
	
	local Count = 0
	local i
	local	Alias

	for i=0,EndNo-1 do
		Alias = "Dynasties"..i
		if Alias ~= DynAlias then
			if DynastyGetDiplomacyState(DynAlias, Alias) == DipState then
				Count = Count + 1
			end
		end
	end
	
	return Count
end

-- this function is called right bevor starting the frames
function GameStart()
	-- deactivated and moved to CityPingHour.lua
	--defaultcampaign_InitiateGodModule() 
end
