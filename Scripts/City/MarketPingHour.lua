
function GameStart()

	if not GetSettlement("", "City") then
		return 0
	end
	
	if CityIsKontor("City") then
		return 0
	end
	
	local Level = CityGetLevel("City")
	marketpinghour_CheckResources(Level)
	
	-- initialize some other items at game start
	marketpinghour_CheckItem(Level, "FlowerOfDiscord", 1, 3)
	marketpinghour_CheckItem(Level, "Perfume", 4, 8)
	marketpinghour_CheckItem(Level, "CartBooster", 4, 10)
	marketpinghour_CheckItem(Level, "AboutTalents1", 3, 9)
	marketpinghour_CheckItem(Level, "Poem", 1, 2)
	marketpinghour_CheckItem(Level, "CamouflageCloak", 1, 3)
	marketpinghour_CheckItem(Level, "GlovesOfDexterity", 0, 2)
	marketpinghour_CheckItem(Level, "MoneyBag", 1, 3)
	marketpinghour_CheckItem(Level, "WalkingStick",2, 6)
	marketpinghour_CheckItem(Level, "BeltOfMetaphysic",0, 1)
	marketpinghour_CheckItem(Level, "Mead", 4, 8)
	marketpinghour_CheckItem(Level, "Cake", 2, 4)
	marketpinghour_CheckItem(Level, "Antidote", 2, 4)
	marketpinghour_CheckItem(Level, "Dagger", 2, 4)
	marketpinghour_CheckItem(Level, "SilverRing", 4, 8)
	marketpinghour_CheckItem(Level, "FarmersClothes", 4, 8)
	
	economy_CalcNeedsForMarket("City")
	economy_CalcSalesForMarket("City")
end


function PingHour()
	marketpinghour_RemoveItemMarket()
	
	if math.mod(GetGametime(), 3) == 2 then -- at 2, 5, 8, 11, ...
		if GetSettlement("", "City") then
			local Level = CityGetLevel("City")
			marketpinghour_CheckResources(Level)
		end
	end
	
	if math.mod(GetGametime(), 24) == 5 and GetSettlement("", "City") then -- at 5am
		economy_CalcNeedsForMarket("City")
		economy_CalcSalesForMarket("City")
	end
end

function CheckResources(CityLevel)
	local Difficulty = ScenarioGetDifficulty() -- easy 0, 1, 2, 3, 4 hard
	-- Easy, Very easy: always
	--    Normal: 12 - 6 = 6 rounds
	--      Hard: 12 - 9 = 3 rounds
	-- Very hard: 12 - 12 = 0 rounds
	local AddMissing = Difficulty < 2 or GetRound() < 12 - (3 * Difficulty)
	
	-- woodcutter
	marketpinghour_CheckItem(CityLevel, "Charcoal", 4, 12, AddMissing)
	marketpinghour_CheckItem(CityLevel, "Oakwood", 4, 12, AddMissing)
	marketpinghour_CheckItem(CityLevel, "Pinewood", 4, 12, AddMissing)
	marketpinghour_CheckItem(CityLevel, "Fungi", 4, 12, AddMissing)
	-- mine
	marketpinghour_CheckItem(CityLevel, "Iron", 4, 12, AddMissing)
	marketpinghour_CheckItem(CityLevel, "Silver", 4, 12, AddMissing)
	-- farm
	marketpinghour_CheckItem(CityLevel, "Wool", 4, 12, AddMissing)
	marketpinghour_CheckItem(CityLevel, "Wheat", 4, 12, AddMissing)
	marketpinghour_CheckItem(CityLevel, "Barley", 4, 12, AddMissing)
	marketpinghour_CheckItem(CityLevel, "Leather", 4, 12, AddMissing)
	-- orchard
	marketpinghour_CheckItem(CityLevel, "Fruit", 4, 12, AddMissing)
	marketpinghour_CheckItem(CityLevel, "Honey", 4, 12, AddMissing)
	-- miller
	marketpinghour_CheckItem(CityLevel, "WheatFlour", 4, 12, AddMissing)
	marketpinghour_CheckItem(CityLevel, "BarleyFlour", 4, 12, AddMissing)
	-- other	
	marketpinghour_CheckItem(CityLevel, "Dye", 4, 12, AddMissing)

	GetScenario("World")
	if HasProperty("World","seamap") then
		marketpinghour_CheckItem(CityLevel, "Herring", 4, 12, AddMissing)
		marketpinghour_CheckItem(CityLevel, "Salmon", 2, 4, AddMissing)
	else
		marketpinghour_CheckItem(CityLevel, "Herring", 6, 18, AddMissing)
		marketpinghour_CheckItem(CityLevel, "Salmon", 3, 6, AddMissing)
	end
end

function CheckItem(CityLevel, Item, MinCount, MaxCount, AddMissing)
	AddMissing = AddMissing or true 
	local Wanted = MinCount + Rand(5) + math.floor((MaxCount - MinCount)*CityLevel/5)
	local Count = GetItemCount("", Item, INVENTORY_STD)
	if Count < Wanted then
		AddItems("", Item, Wanted - Count, INVENTORY_STD)
	end
end


function RemoveItemMarket()
	if not GetSettlement("", "City") then
		return 0
	end
	
	if CityIsKontor("City") then
		return 0
	end

 local chance, Name, Baseprice, Sellprice
 local Reducevalue = Rand(6)
 local item = {
		"Barleybread", "Cookie", "Wheatbread", "Cake", "BreadRoll", "CreamPie", "Candy",
		"vase", "GrainPap", "SmallBeer", "SalmonFilet", "WheatBeer", "Mead", "RoastBeef",
		"BoozyBreathBeer", "GhostlyFog", "Tool", "Dagger", "SilverRing", "Shortsword", "IronBrachelet",
		"GemRing", "BeltOfMetaphysic", "GoldChain", "Longsword", "IronCap", "Chainmail",
		"FullHelmet", "Platemail", "OakwoodRing", "BuildMaterial", "Torch", "WalkingStick",
		"Mace", "CrossOfProtection", "RubinStaff", "Axe", "Cloth", "MoneyBag", "Blanket",
		"FarmersClothes", "LeatherArmor", "CitizensClothes", "GlovesOfDexterity", "NoblesClothes",
		"CamouflageCloak", "LeatherGloves", "HerbTea", "Perfume", "DartagnansFragrance",
		"DrFaustusElixir", "FragranceOfHoliness", "FlowerOfDiscord", "ToadExcrements", 
		"Toadslime", "CartBooster", "BoobyTrap", "Housel", "Poem", "Chaplet", "AboutTalents1",
		"LetterOfIndulgence", "LetterFromRome", "ThesisPaper", "AboutTalents2", "Shellchain", 
		"FriedHerring", "Shellsoup", "SmokedSalmon", "StinkBomb", "Pearlchain", "Bandage",
		"Soap", "MiracleCure", "Salve", "Medicine", "StaffOfAesculap", "Mixture", "MediPack",
		"PainKiller","WeaponPoison", "Antidote", "ParalysisPoison", "BlackWidowPoison", "Amulet",
		"Hasstirade", "Handwerksurkunde", "Kamm", "Holzzapfen", "Beschlag", "Stonerotary",
		"bust", "statue", "Blissstone", "Optigold", "Optisilber", "Optieisen", "Goldveryhigh",
		"Goldmedhigh", "Goldlowmed", "Urkunde", "Schuldenbrief", "HexerdokumentII", 
		"HexerdokumentI", "Schadelkerze", "Dye", "Knochenarmreif", "Pendel", "Spindel",
		"Voodo", "Robe", "Pddv"
		}
 
	for i=0, 114 do
	Name = item[i]

		if (Name ~= nil) then
		Baseprice = ItemGetBasePrice(Name)
		NewBaseprice = Baseprice - math.floor((Baseprice / 100 * 10))
		Sellprice = ItemGetPriceSell(Name, "") 
			if Sellprice < NewBaseprice then
			RemoveItems ("", Name, Reducevalue, INVENTORY_STD)
			end 

		end
	end
end