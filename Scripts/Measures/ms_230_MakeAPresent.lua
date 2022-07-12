-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_230_MakeAPresent"
----
----	with this measure the player can make a present to another sim
----
-------------------------------------------------------------------------------
function AIDecide()
--	NumItems = GetData("NumItems")
--	return "A"..NumItems
	return 0
end

function Run()

	-- only for CourtLovers, Liaisons or Spouses
	if not SimGetCourtLover("", "MyLover") then
		if not SimGetLiaison("", "MyLiaison") then
			if not SimGetSpouse("", "MySpouse") then
				MsgBoxNoWait("", "", "@L_MEASURE_MakeAPresent_NAME_+0", "@L_MEASURE_MAKEAPRESENT_ERROR_NOLOVER_+0")
				StopMeasure()
			end
		end
	end
	
	local CheckPresent = false
	if AliasExists("MyLover") and GetID("MyLover") == GetID("Destination") then
		CheckPresent = true
	elseif AliasExists("MyLiaison") and GetID("MyLiaison") == GetID("Destination") then
		CheckPresent = true
	elseif AliasExists("MySpouse") and GetID("MySpouse") == GetID("Destination") then
		CheckPresent = true
	end
	
	if not CheckPresent then
		MsgBoxNoWait("", "", "@L_MEASURE_MakeAPresent_NAME_+0", "@L_MEASURE_MAKEAPRESENT_ERROR_NOLOVER_+1")
		StopMeasure()
	end
	
	-- The time in hours until the measure can be repeated
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	local OwnerGender = SimGetGender("")
	local DestGender = SimGetGender("Destination")
	local DestTitle = GetNobilityTitle("Destination")
	local TitleDifference = DestTitle - GetNobilityTitle("")*2
	local EmpathySkill = GetSkillValue("", EMPATHY)
	
	-- special
	if not HasProperty("Destination", "CourtingPerso") then
		DestPersonality = Rand(4)
		SetProperty("Destination", "CourtingPerso", DestPersonality)
	end
	local DestPersonality = GetProperty("Destination", "CourtingPerso") or 0
	
	local DestClass = SimGetClass("Destination")
	local CourtingClass = DestClass
	if DestClass == 0 or DestClass > 4 then
		CourtingClass = GetProperty("Destination", "FakeClass") or 1
	end
	
	-- the more favor the better you know what your Destination wants (more correct Options)
	local Favor = 0
	if SimGetSpouse("", "Spouse") and GetID("Destination") == GetID("Spouse") then
		Favor = 100
	else
		Favor = GetFavorToSim("Destination", "") + GetSkillValue("", EMPATHY)
	end
	
	local MinimumFavor = GL_PRESENT_MINFAVOR + TitleDifference
	local FavorWon = 10
	local ModifyFavor = 0
	
	-- Courting related
	local CourtingProgress = gameplayformulas_GetCourtingProgress("", "Destination", MeasureID)
	local VariationFactor = gameplayformulas_GetCourtingMeasureVariation(MeasureID, "Destination") 
	local CurrentProgress = 0
	
	-- for court lovers you might wanna do Janes Ring, so get the love progress
	if AliasExists("MyLover") and GetID("Destination") == GetID("MyLover") then
		CurrentProgress = SimGetProgress("")
	end
	
	if IsGUIDriven() then
	
		-- some info at the beginning
		local KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+0"
		local DontLikeLabel = "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+0"
		local HisLabel = "@L_REPLACEMENTS_TEXTVAR_HIS_+0"
		local EveryManLabel = "@L_REPLACEMENTS_TEXTVAR_EVERYMAN_DAT_+0"
		
		-- Gender stuff
		if DestGender == GL_GENDER_FEMALE then
			HisLabel = "@L_REPLACEMENTS_TEXTVAR_HER_+0"
			EveryManLabel = "@L_REPLACEMENTS_TEXTVAR_EVERYWOMAN_DAT_+0"
		end
		
		local EnoughProgress = false
		if CurrentProgress >= (80 - EmpathySkill) then
			EnoughProgress = true
		end
		local RingLabel = "@L_MEASURE_MAKEAPRESENT_JANESRING_+0"
		
		if EnoughProgress then
			RingLabel = "@L_MEASURE_MAKEAPRESENT_JANESRING_+1"
		end
		
		if Favor >= 60 then
			if CourtingClass == 1 then 
				if DestPersonality == 0 then
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+1"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+1"
					end
				elseif DestPersonality == 1 then
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+2"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+2"
					end
				elseif DestPersonality == 2 then
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+3"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+3"
					end
				else
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+4"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+4"
					end
				end
			elseif CourtingClass == 2 then
				if DestPersonality == 0 then
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+5"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+5"
					end
				elseif DestPersonality == 1 then
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+6"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+6"
					end
				elseif DestPersonality == 2 then
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+7"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+7"
					end
				else
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+8"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+8"
					end
				end
			elseif CourtingClass == 3 then
				if DestPersonality == 0 then
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+9"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+9"
					end
				elseif DestPersonality == 1 then
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+10"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+10"
					end
				elseif DestPersonality == 2 then
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+11"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+11"
					end
				else
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+12"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+12"
					end
				end
			else
				if DestPersonality == 0 then
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+13"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+13"
					end
				elseif DestPersonality == 1 then
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+14"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+14"
					end
				elseif DestPersonality == 2 then
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+15"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+15"
					end
				else
					KnowledgeLabel = "@L_MEASURE_MAKEAPRESENT_KNOWLEDGE_+16"
					if Favor >= 80 then
						DontLikeLabel =  "@L_MEASURE_MAKEAPRESENT_DONTLIKE_+16"
					end
				end
			end
		end
		
		local Continue = MsgBox("", "Destination", "@P"..
										"@B[1, @L_REPLACEMENTS_BUTTONS_NEXT_+0]"..
										"@B[C, @L_REPLACEMENTS_BUTTONS_CANCEL_+0]",
										"@L_MEASURE_MakeAPresent_NAME_+0",
										"@L_MEASURE_MAKEAPRESENT_INFO_BODY_+0", GetID("Destination"), HisLabel, EveryManLabel, KnowledgeLabel, DontLikeLabel, RingLabel)
		
		if Continue == "C" then
			StopMeasure()
		end
	end
	
	-- max 4 presents
	local PresA, PresB, PresC, PresD
	
	-- first two are basic gender. Most love those.
	if DestGender == GL_GENDER_MALE then
		-- weapon. Get Title!
		PresA = "Dagger"
		if DestTitle > 3 and DestTitle < 7 then
			PresA = "Longsword"
		else
			PresA = "Axe"
		end
		
		-- clothing. Get Title!
		PresB = "FarmersClothes"
		if DestTitle > 3 and DestTitle < 7 then
			PresB = "CitizensClothes"
		else
			PresB = "NoblesClothes"
		end
	else
		-- scent
		PresA = "Soap"
		if DestTitle > 3 and DestTitle < 7 then
			PresA = "Perfume"
		else
			PresB =  "FragranceOfHoliness"
		end
		
		-- nice things
		PresB = "Chaplet"
		if DestTitle > 3 and DestTitle < 7 then
			PresA = "SilverRing"
		else
			PresB =  "GoldChain"
		end
	end
	
	local RightStuff = { }
	local RightNum = 0
	local WrongStuff = { }
	local WrongNum = 0
	local CheckPresC = true
	local CheckPresD = true
	
	-- Specific stuff (+100 % gain)
	if CourtingClass == GL_CLASS_PATRON then
		if DestPersonality == 0 then -- baker
			local InsertListRight = { "Cookie", "Wheatbread", "Cake", "BreadRoll", "CreamPie", "Candy" }
			RightNum = 6
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong = { "SmallBeer", "WheatBeer", "Mead", "BoozyBreathBeer", "RoastBeef", "SalmonFilet" }
			WrongNum = 6
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		elseif DestPersonality == 1 then -- innkeeper
			local InsertListRight = { "SmallBeer", "WheatBeer", "Mead", "BoozyBreathBeer", "RoastBeef", "SalmonFilet" }
			RightNum = 6
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong = { "Shellchain", "FriedHerring", "Shellsoup", "Pearlchain" }
			WrongNum = 4
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		elseif DestPersonality == 2 then -- fisher
			local InsertListRight = { "Shellchain", "FriedHerring", "Shellsoup", "Pearlchain" }
			RightNum = 4
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong = { "Wool", "Beef", "Barley", "Wheat", "Leather", "Fruit", "Honey" }
			WrongNum = 7
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		elseif DestPersonality == 3 then -- farmer
			local InsertListRight = { "Wool", "Beef", "Barley", "Wheat", "Leather", "Fruit", "Honey" }
			RightNum = 7
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong = { "Cookie", "Wheatbread", "Cake", "BreadRoll", "CreamPie", "Candy" }
			WrongNum = 6
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		end
			
	elseif CourtingClass == GL_CLASS_ARTISAN then
		if DestPersonality == 0 then -- tailor
			local InsertListRight = { "Cloth", "MoneyBag", "Blanket", "GlovesOfDexterity", "LeatherGloves" }
			RightNum = 5
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong =  { "Tool", "Shortsword", "IronBrachelet", "GemRing", "FullHelmet", "BeltOfMetaphysic" }
			WrongNum = 6
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		elseif DestPersonality == 1 then -- smithy
			local InsertListRight = { "Tool", "Shortsword", "IronBrachelet", "GemRing", "FullHelmet", "BeltOfMetaphysic" }
			RightNum = 6
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong = { "OakwoodRing", "BuildMaterial", "Torch", "WalkingStick", "CrossOfProtection", "RubinStaff" }
			WrongNum = 6
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		elseif DestPersonality == 2 then -- joiner
			local InsertListRight = { "OakwoodRing", "BuildMaterial", "Torch", "WalkingStick", "CrossOfProtection", "RubinStaff" }
			RightNum = 6
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong = { "vase", "bust", "statue", "Blissstone", "Grindingbrick" }
			WrongNum = 5
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		elseif DestPersonality == 3 then -- stonemason
			local InsertListRight = { "vase", "bust", "statue", "Blissstone", "Grindingbrick" }
			RightNum = 5
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong =  { "Cloth", "MoneyBag", "Blanket", "GlovesOfDexterity", "LeatherGloves" }
			WrongNum = 5
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		end
	elseif CourtingClass == GL_CLASS_SCHOLAR then
		if DestPersonality == 0 then -- gravedigger
			local InsertListRight = { "Schadelkerze", "Knochenarmreif", "Pendel", "Spindel", "Robe" }
			RightNum = 5
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong =  { "MiracleCure", "Bandage", "Medicine", "StaffOfAesculap", "Lavender", "PainKiller" }
			WrongNum = 6
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		elseif DestPersonality == 1 then -- medic
			local InsertListRight = { "MiracleCure", "Bandage", "Medicine", "StaffOfAesculap", "Lavender", "PainKiller" }
			RightNum = 6
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong = { "Poem", "AboutTalents1", "ThesisPaper", "AboutTalents2", "Parchment", "Schuldenbrief" }
			WrongNum = 6
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		elseif DestPersonality == 2 then --priest
			local InsertListRight = { "Poem", "AboutTalents1", "ThesisPaper", "AboutTalents2", "Parchment", "Schuldenbrief" }
			RightNum = 6
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong = { "Moonflower", "HerbTea", "DaragnansFragrance", "Stonelily", "CartBooster" }
			WrongNum = 5
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		elseif DestPersonality == 3 then -- alchemist nice
			local InsertListRight = { "Moonflower", "HerbTea", "DaragnansFragrance", "Stonelily", "CartBooster" }
			RightNum = 5
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong =  { "Schadelkerze", "Knochenarmreif", "Pendel", "Spindel", "Robe" }
			WrongNum = 5
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		end
	else
		if DestPersonality == 0 then -- alchemist evil
			local InsertListRight = { "FlowerOfDiscord", "Frogeye", "Spiderleg", "PoisonedCake", "ToadExcrements" }
			RightNum = 5
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong =  { "Salve", "MediPack", "WeaponPoison", "Antidote", "ParalysisPoison", "BlackWidowPoison" }
			WrongNum = 6
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		elseif DestPersonality == 1 then -- medic alternative
			local InsertListRight = { "Salve", "MediPack", "WeaponPoison", "Antidote", "ParalysisPoison", "BlackWidowPoison" }
			RightNum = 6
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong = { "Amulet", "HexerdokumentI", "HexerdokumentII", "pddv", "Hasstirade", "StinkBomb" }
			WrongNum = 6
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		elseif DestPersonality == 2 then -- mean stuff
			local InsertListRight = { "Amulet", "HexerdokumentI", "HexerdokumentII", "pddv", "Hasstirade", "StinkBomb" }
			RightNum = 6
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong = { "Chainmail", "IronCap", "Platemail", "LetherArmor", "FullHelmet" }
			WrongNum = 5
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		elseif DestPersonality == 3 then -- armor stuff
			local InsertListRight = { "Chainmail", "IronCap", "Platemail", "LetherArmor", "FullHelmet" }
			RightNum = 5
			for i=1, RightNum do
				RightStuff[i] = InsertListRight[i]
			end
			
			local InsertListWrong =  { "FlowerOfDiscord", "Frogeye", "Spiderleg", "PoisonedCake", "ToadExcrements" }
			WrongNum = 5
			for i=1, WrongNum do
				WrongStuff[i] = InsertListWrong[i]
			end
		end
	end
	
	-- get the right stuff 
	if Favor >= Rand(100) then
		local RandChoice = Rand(RightNum) + 1
		PresC = RightStuff[RandChoice]
			
		local RandChoice2 = Rand(RightNum) + 1
		PresD = RightStuff[RandChoice2]
			
		-- bad luck
		if PresD == PresC then
			if Rand(2) == 0 then
				-- more random
				local RandChoice3 = Rand(WrongNum) + 1
				PresC = WrongStuff[RandChoice3]
				CheckPresC = false
			else
				-- more random
				local RandChoice3 = Rand(WrongNum) + 1
				PresD = WrongStuff[RandChoice3]
				CheckPresD = false
			end
		end
	else
	-- get the wrong stuff
		local RandChoice = Rand(WrongNum) + 1
		PresC = WrongStuff[RandChoice]
		CheckPresC = false
			
		local RandChoice2 = Rand(WrongNum) + 1
		PresD = WrongStuff[RandChoice2]
		CheckPresD = false
		
		-- good luck
		if PresD == PresC then
			if Rand(2) == 0 then
				-- more random
				local RandChoice3 = Rand(RightNum) + 1
				PresC = RightStuff[RightChoice3]
				CheckPresC = true
			else
				-- more random
				local RandChoice3 = Rand(RightNum) + 1
				PresD = RightStuff[RandChoice3]
				CheckPresD = true
			end
		end
	end

	local ItemTexture1 = "Hud/Items/Item_"..PresA..".tga"
	local Button1 = "@B[0,,%1l,"..ItemTexture1.."]"
	local ItemLabel1 = ItemGetLabel(PresA, true)
	
	local ItemTexture2 = "Hud/Items/Item_"..PresB..".tga"
	local Button2 = "@B[1,,%2l,"..ItemTexture2.."]"
	local ItemLabel2 = ItemGetLabel(PresB, true)
	
	local ItemTexture3 = "Hud/Items/Item_"..PresC..".tga"
	local Button3 = "@B[2,,%3l,"..ItemTexture3.."]"
	local ItemLabel3 = ItemGetLabel(PresC, true)
	
	local ItemTexture4 = "Hud/Items/Item_"..PresD..".tga"
	local Button4 = "@B[3,,%4l,"..ItemTexture4.."]"
	local ItemLabel4 = ItemGetLabel(PresD, true)
	
	local ItemTexture5 = "Hud/Items/Item_JanesRing.tga"
	local Button5 = "@B[4,,%5l,"..ItemTexture5.."]"
	local ItemLabel5 = ItemGetLabel("JanesRing", true)
	
	local Result = InitData("@P"..Button1..
						Button2..
						Button3..
						Button4..
						Button5,
						ms_230_makeapresent_AIDecide,  --AIFunc
						"@L_INTERFACE_PRESENTTEXT_+0",
						"",
						ItemLabel1, ItemLabel2, ItemLabel3,
						ItemLabel4, ItemLabel5)

	if Result == "C" then
		return
	end
	
	local TheItem
	local GoodPresent = true
	
	--check the item
	if Result == 0 then
		TheItem = PresA
	elseif Result == 1 then
		TheItem = PresB
	elseif Result == 2 then
		TheItem = PresC
		GoodPresent = CheckPresC
		CourtingProgress = CourtingProgress * 1.5
	elseif Result == 3 then
		TheItem = PresD
		GoodPresent = CheckPresD
		CourtingProgress = CourtingProgress * 1.5
	elseif Result == 4 then
		TheItem = "JanesRing"
		if CurrentProgress >= (80 - EmpathySkill) then 
			CourtingProgress = 19 + 1 * EmpathySkill
		else
			CourtingProgress = -3
		end
	end
	
	if GetItemCount("", TheItem, INVENTORY_STD) == 0 then
		-- enough space to get one?
		if not CanAddItems("", TheItem, 1, INVENTORY_STD) then
			MsgQuick("", "@L_MEASURE_MAKEAPRESENT_ERROR_NOSPACE_+0")
			StopMeasure()
		end
		
		-- do we have one available?
		local Access, BldID, FoundCount = dyn_HasAccessToItem("", TheItem)
		if Access then
			if GetAliasByID(BldID, "AccessBld") then
				-- send a msg, asking for permission to transport
				local GetItem = MsgBox("", "AccessBld", "@P"..
										"@B[1, @L_REPLACEMENTS_BUTTONS_NEXT_+0]"..
										"@B[C, @L_REPLACEMENTS_BUTTONS_CANCEL_+0]",
										"@L_MEASURE_MakeAPresent_NAME_+0",
										"@L_MEASURE_MAKEAPRESENT_GETITEM_BODY_+0", GetID("AccessBld"), FoundCount )
				
				if GetItem == "C" then
					StopMeasure()
				else
					if RemoveItems("AccessBld", TheItem, 1, INVENTORY_STD) == 1 then
						SetMeasureRepeat(TimeOut)
						AddItems("", TheItem, 1, INVENTORY_STD)
					end
				end
			end
		else
			-- can we buy it at local market?
			if GetNearestSettlement("", "City") then
				CityGetLocalMarket("City", "Market")
				if AliasExists("Market") then
					local PresentCount = GetItemCount("Market", TheItem, INVENTORY_STD)
					if PresentCount > 0 then
						local Price = ItemGetPriceBuy(TheItem, "Market")
						CityGetRandomBuilding("City", GL_BUILDING_CLASS_MARKET, -1, -1, -1, FILTER_IGNORE, "Shop")
						-- send a msg, asking for permission to buy
						local GetItem = MsgBox("", "Shop", "@P"..
										"@B[1, @L_REPLACEMENTS_BUTTONS_NEXT_+0]"..
										"@B[C, @L_REPLACEMENTS_BUTTONS_CANCEL_+0]",
										"@L_MEASURE_MakeAPresent_NAME_+0",
										"@L_MEASURE_MAKEAPRESENT_GETITEM_BODY_+1", GetID("City"), Price)
				
						if GetItem == "C" then
							StopMeasure()
						else
							if RemoveItems("Market", TheItem, 1, INVENTORY_STD) == 1 then
								SetMeasureRepeat(TimeOut)
								AddItems("", TheItem, 1, INVENTORY_STD)
								chr_SpendMoney("", Price, "WaresBought", true)
							end
						end
					end
				end
			end
		end
	end
	
	-- check again, cancel measure here
	if GetItemCount("", TheItem, INVENTORY_STD) == 0 then
		MsgQuick("", "@L_MEASURE_MAKEAPRESENT_ERROR_NOACCESS_+0")
		StopMeasure()
	end
	
	if not GoodPresent then
		if CourtingProgress > 0 then
			CourtingProgress = CourtingProgress * (-1)
		end
	end

	-- The distance between both sims to interact with each other
	local InteractionDistance = 85

	if not ai_StartInteraction("", "Destination", 500, InteractionDistance) then
		StopMeasure()
		return
	end

	SetAvoidanceGroup("", "Destination")
	MoveSetActivity("", "converse")
	MoveSetActivity("Destination", "converse")
	feedback_OverheadActionName("Destination")
	chr_AlignExact("", "Destination", InteractionDistance)

	CreateCutscene("default", "cutscene")
	CutsceneAddSim("cutscene", "")
	CutsceneAddSim("cutscene", "Destination")
	CutsceneCameraCreate("cutscene", "")
	camera_CutscenePlayerLock("cutscene", "")

	local time1, time2
	
	time1 = PlayAnimationNoWait("Owner", "use_object_standing")
	time2 = PlayAnimationNoWait("Destination", "cogitate")
	Sleep(1)
	PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
	CarryObject("", "Handheld_Device/ANIM_Smallsack.nif", false)
	
	Sleep(1)
	CarryObject("", "", false)
	CarryObject("Destination", "Handheld_Device/ANIM_Smallsack.nif", false)
	time2 = PlayAnimationNoWait("Destination", "fetch_store_obj_R")
	Sleep(1)	
	StopAnimation("")
	PlaySound3D("Destination", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
	CarryObject("Destination", "", false)	

	if RemoveItems("", TheItem, 1, INVENTORY_STD) == 0 then
		return
	end
	
	SetMeasureRepeat(TimeOut)
	
	if IsPartyMember("Destination") and not PresentName == "JanesRing" then
		if DynastyIsPlayer("Destination") then
			if GetRemainingInventorySpace("Destination", ItemName[ItemIndex], INVENTORY_STD) > 0 then
				AddItems("Destination", ItemName[ItemIndex], 1, INVENTORY_STD)
			end
		end
	end

	chr_AlignExact("", "Destination", InteractionDistance)

	local WasCourtLover = 0

	-------------------------
	------ Court Lover ------
	-------------------------
	if (SimGetCourtLover("", "CourtLover")) then
		if GetID("CourtLover") == GetID("Destination") then

			WasCourtLover = 1
			local Slap = false

			if VariationFactor <= 0.5 then
				TimeOut = TimeOut * 2
				SetMeasureRepeat(TimeOut)

				camera_CutscenePlayerLock("cutscene", "Destination")

				local DestinationAnimationLength = PlayAnimationNoWait("Destination", "shake_head")
				Sleep(DestinationAnimationLength * 0.4)

				feedback_OverheadCourtProgress("Destination", CourtingProgress)

				MsgSay("Destination", talk_AnswerMissingVariation(SimGetGender("Destination"), GetSkillValue("Destination", RHETORIC)));

			else
				SetMeasureRepeat(TimeOut)
				chr_AlignExact("", "Destination", InteractionDistance)
				local DestinationAnimationLength
				if (CourtingProgress < -5) then
					camera_CutsceneBothLock("cutscene", "Destination")
					PlayAnimationNoWait("", "got_a_slap")
					DestinationAnimationLength = PlayAnimationNoWait("Destination", "give_a_slap")
					Sleep(DestinationAnimationLength * 0.4)
					ModifyFavor = FavorWon * (-1)
					Slap = true
				elseif (CourtingProgress < 1) then
					camera_CutscenePlayerLock("cutscene", "Destination")
					PlayAnimationNoWait("", "talk")
					DestinationAnimationLength = PlayAnimationNoWait("Destination", "shake_head")
					Sleep(DestinationAnimationLength * 0.3)
					ModifyFavor = -5
				else
					ModifyFavor = FavorWon
					camera_CutscenePlayerLock("cutscene", "Destination")
				end

				feedback_OverheadCourtProgress("Destination", CourtingProgress)

				MsgSay("Destination", talk_AnswerCourtingMeasure("MAKE_A_PRESENT", GetSkillValue("Destination", RHETORIC), SimGetGender("Destination"), CourtingProgress));

			end

			-- Add the archieved progress
			if Slap then
				ModifyHP("", -30, true, 10)
				Sleep(0.1)
			end
			chr_ModifyFavor("Destination", "", ModifyFavor)
			AddImpact("Destination", "ReceivedPresent", 1, 8)
			gameplayformulas_CourtingProgress("", CourtingProgress) 
		end
	end

	----------------------------
	------ No Court Lover ------
	----------------------------
	if (WasCourtLover==0) then

		local IsMale = (SimGetGender("Destination") == GL_GENDER_MALE)
		local DestinationRank = SimGetRank("Destination")
		
		if Favor < MinimumFavor then

			-- Set the repeat timer and the favor loss prior to the animations so that the player cannot cancel the measure and try it instantly again
			--chr_ModifyFavor("Destination", "", FavorModify)
			TimeOut = TimeOut * 2
			SetMeasureRepeat(TimeOut)

			if (IsMale) then
				camera_CutscenePlayerLock("cutscene", "Destination")
				PlayAnimationNoWait("Destination", "shake_head")
			else
				camera_CutsceneBothLock("cutscene", "Destination")
				PlayAnimationNoWait("", "got_a_slap")
				PlayAnimationNoWait("Destination", "give_a_slap")
				chr_AlignExact("", "Destination", InteractionDistance)
				
			end
			--MsgSay("Destination", chr_AnswerCourtingMeasure("MAKE_A_PRESENT", GetSkillValue("Destination", RHETORIC), SimGetGender("Destination"), -10));
		else
			SetMeasureRepeat(TimeOut)
			camera_CutscenePlayerLock("cutscene", "Destination")

			if (IsMale) then
				PlayAnimationNoWait("Destination", "bow")
			else
				PlayAnimationNoWait("Destination", "giggle")
			end
			--MsgSay("Destination", chr_AnswerCourtingMeasure("MAKE_A_PRESENT", GetSkillValue("Destination", RHETORIC), SimGetGender("Destination"), 10));

			chr_ModifyFavor("Destination", "", FavorModify)
		end
	end
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	
	if AliasExists("cutscene") then
		DestroyCutscene("cutscene")
	end
	ReleaseAvoidanceGroup("")
	MoveSetActivity("")
	StopAnimation("")
	AlignTo("","")

	if AliasExists("Destination") then
		AlignTo("Destination","")
		MoveSetActivity("Destination")
		SimLock("Destination", 0.4)
	end

end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

