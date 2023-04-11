function Init()
 --needed for caching
end

function LockPick(LockPickerLevel, LockLevel)
	if (LockPickerLevel >= LockLevel) then
		return 1
	end	
	return 0	
end

function CalcBuildProgress(DefaultProgress, Workers)
	return DefaultProgress + Workers
end

function CalcBurnDamageProgress()
	return 1
end

function CalcCartBuyPrice(CartType)
	return 250*(CartType+1) 
end

function CalcCartSellPrice(CartType, HPRelative)
	local Price = gameplayformulas_CalcCartBuyPrice(CartType)
	Price = Price * HPRelative * 0.75
	return Price
end

-- -----------------------
-- CalcCartRepairPrice
-- -----------------------
function CalcCartRepairPrice(CartType, HPRelative)
	Price = gameplayformulas_CalcCartBuyPrice(CartType)
	Price = Price * (1 - HPRelative)
	return Price
end

function CalcFindRange(ObjectAlias)
	local Level = SimGetLevel(ObjectAlias)
	local Skillvalue = GetSkillValue(ObjectAlias, SECRET_KNOWLEDGE)
	local BaseRange = 1000
	
	return BaseRange * Level + (Skillvalue * 500)
end

function CalcSightRange(ObjectAlias)
	
	if BuildingGetType("Destination") ~= -1 then
		return 1500
	end

	local Level = SimGetLevel(ObjectAlias)
	local Skillvalue = GetSkillValue(ObjectAlias, EMPATHY)
	local BaseRange = 250
	return BaseRange + (Level * 50) + (Skillvalue * 100)
end

function CalcDamage(fWeaponDamage)
	return gameplayformulas_GetDamage("", fWeaponDamage)
end

function GetDamage(SimAlias, fWeaponDamage)
	local AttackValue = GetSkillValue(SimAlias,FIGHTING)
	local Damage = fWeaponDamage + (SimGetLevel(SimAlias) + AttackValue)*0.5
	return Damage	
end

function CalcArmorValue()
	return gameplayformulas_GetArmorValue("")
end

function GetArmorValue(SimAlias)
	local Armor = GetArmor(SimAlias) + GetImpactValue(SimAlias, "FightArmor")
	return Armor	
end

function SimAttackWithRangeWeapon(SimAlias,DestAlias)
	local Distance = GetDistance(SimAlias,DestAlias)
	local FavorLost = GL_FAVOR_MOD_VERYLARGE

	if IsType(SimAlias, "Sim") then

		if IsType(DestAlias, "Sim") and GetItemCount(SimAlias, "Pistole", INVENTORY_EQUIPMENT)>0 and GetItemCount(SimAlias, "Round", INVENTORY_STD)>0 then
			local time
			--GetSkillValue(SimAlias,"dex")
			
			if Distance>500 then
				f_MoveTo(SimAlias,DestAlias,GL_MOVESPEED_RUN, 500)
			end

			if IsMounted(SimAlias) then
					Unmount(SimAlias)
			end
			if IsMounted(DestAlias) then
					Unmount(DestAlias)
			end
			
			AlignTo(SimAlias,DestAlias)
			Sleep(0.5)
			
			CarryObject(SimAlias,"Handheld_Device/ANIM_gun.nif",false)
			time = PlayAnimationNoWait(SimAlias,"duel_shoot")
			Sleep(time)

			RemoveItems(SimAlias,"Round",1)

			if GetPositionOfSubobject(DestAlias, "Game_Chest_Scale","Game_Chest_Scale") then
				StartSingleShotParticle("particles/bloodsplash.nif", "Game_Chest_Scale", 1, 3.0)
			end
			time = PlayAnimationNoWait(DestAlias,"duel_shoot_gothit")
			PlaySound3D(SimAlias,"Effects/combat_strike_fist/combat_strike_fist+4.wav",1)
			Sleep(0.5)
			
			PlaySound3D(DestAlias,"combat/pain/Hurt_s_01.wav",1)
			ModifyHP(DestAlias,-50,true)
			
			if AliasExists(SimAlias) then
				CarryObject(SimAlias, "", false)
			end

		elseif (IsType(DestAlias, "Sim") or IsType(DestAlias, "Building") or IsType(DestAlias, "Cart")) and GetItemCount(SimAlias, "Sparkingsteel", INVENTORY_EQUIPMENT)>0 and GetItemCount(SimAlias, "Granate", INVENTORY_STD)>0 then
			local time
			--GetSkillValue(SimAlias,"dex")
			
			if IsMounted(DestAlias) then
				Unmount(DestAlias)
			end

			AlignTo(SimAlias, DestAlias)
			Sleep(0.5)
			
			GetPosition(DestAlias, "ParticleSpawnPos")
			PlayAnimationNoWait(SimAlias, "fetch_store_obj_R")
			Sleep(1)
			PlaySound3D(SimAlias,"Locations/wear_clothes/wear_clothes+1.wav", 1.0)
			CarryObject(SimAlias, "Handheld_Device/ANIM_Bomb_02.nif", false)
			time = PlayAnimationNoWait(SimAlias, "throw")
			Sleep(time)

			local fDuration = ThrowObject(SimAlias, DestAlias, "Handheld_Device/ANIM_Bomb_02.nif",0.1,"snowball",0,150,0)
			CarryObject(SimAlias, "", false)
			RemoveItems(SimAlias, "Granate", 1)
			Sleep(fDuration)

			StartSingleShotParticle("particles/Explosion.nif", "ParticleSpawnPos",1,5)
			PlaySound3D(DestAlias, "Effects/combat_bomb_explode/combat_bomb_explode+0.wav", 1.0)
			
			if IsType(DestAlias, "Sim") then
				if Distance > 500 then
					f_MoveTo(SimAlias,DestAlias,GL_MOVESPEED_RUN, 500)
				end
				StartSingleShotParticle("particles/bloodsplash.nif", "ParticleSpawnPos",1,5)	
				PlaySound3D(DestAlias, "combat/pain/Hurt_s_01.wav", 1)
				ModifyFavorToSim(DestAlias, SimAlias, -FavorLost)
			elseif IsType(DestAlias, "Building") then
				if BuildingGetOwner(DestAlias, "BuildingOwner") then
					ModifyFavorToSim("BuildingOwner", SimAlias, -FavorLost)
				end
			end
			
			ModifyHP(DestAlias,-100,true)

			local victims = Find(DestAlias,"__F((Object.GetObjectsByRadius(Sim) == 30)","DestSim", -1)
			for i=0,victims-1 do
				PlaySound3D("DestSim","combat/pain/Hurt_s_01.wav",1)
				ModifyHP("DestSim",-100,true)
				ModifyFavorToSim("DestSim",SimAlias,-FavorLost)
			end

		elseif IsType(DestAlias, "Building") and GetItemCount(SimAlias, "Cannon", INVENTORY_EQUIPMENT)>0 and GetItemCount(SimAlias, "Cannonball", INVENTORY_STD)>0 then
			local time
			--GetSkillValue(SimAlias,"dex")
			GetFleePosition("", DestAlias, 3400, "DestPos")
			f_MoveTo(SimAlias,"DestPos",GL_MOVESPEED_RUN)
			
			AlignTo(SimAlias,DestAlias)
			Sleep(0.5)

			GetPosition(SimAlias,"OwnerPos")
			GetPosition(DestAlias,"TargetPos")
			GfxAttachObject("Cannon", "weapons/Cannon.nif")
			GfxSetPositionTo("Cannon", "OwnerPos")
			Sleep(2)
	
			CarryObject(SimAlias,"Handheld_Device/ANIM_torch.nif",false)
			Sleep(2)
			PlayAnimation(SimAlias,"manipulate_middle_low_r")

			StartSingleShotParticle("particles/cannonshot.nif","OwnerPos",1,4)
			local BuildingLevel = BuildingGetLevel(DestAlias)
			local side = -1
			GetPosition(DestAlias,"BuildingPos")
			
			local OffsetArray = {
				0,400*BuildingLevel,0,1,
				-100,400*BuildingLevel,100,1,
				100,400*BuildingLevel,-100,1,
			}
			
			local fDuration = ThrowObject(SimAlias, "TargetPos", "Outdoor/NewAssets/cannonball.nif",0.1, "CannonBall", OffsetArray[1]*side, OffsetArray[2], OffsetArray[3])
			RemoveItems(SimAlias,"Cannonball",1)
			PlaySound3DVariation(SimAlias,"Effects/combat_cannon_shot",1)
			Sleep(fDuration)	
			StartSingleShotParticle("particles/Explosion.nif","BuildingPos",Rand(2)+1,2)
			PlaySound3D(DestAlias,"Effects/combat_bomb_explode/combat_bomb_explode+0.wav", 1.0)

			local HP = GetHP(DestAlias) / 5
			ModifyHP(DestAlias,-HP,true)

			CarryObject("","",false)
			GfxDetachObject("Cannon")

			if BuildingGetOwner(DestAlias,"BuildingOwner") then
				ModifyFavorToSim("BuildingOwner",SimAlias,(-FavorLost)*2)
			end

			local victims = Find(DestAlias,"__F((Object.GetObjectsByRadius(Sim) == 30)","DestSim", -1)
			for i=0,victims-1 do
				PlaySound3D("DestSim","combat/pain/Hurt_s_01.wav",1)
				ModifyHP("DestSim",-100,true)
				ModifyFavorToSim("DestSim",SimAlias,(-FavorLost)*2)
			end
		end

		--if Distance>500 then
		--	f_MoveTo(SimAlias,DestAlias,GL_MOVESPEED_RUN, 500)
		--end
		if AliasExists(SimAlias) then
			if IsMounted(SimAlias) then
				Unmount(SimAlias)
			end
		end
	end
	
	if AliasExists(DestAlias) then
		if IsType(DestAlias, "Sim") then
			if IsMounted(DestAlias) then
				Unmount(DestAlias)
			end
		end
	end
end

function SimIsGuildmaster()

	if not GetSettlement("", "City") then
		return 0
	end

	if HasProperty("City", "Guildhall") then
		local gh = GetProperty("City", "Guildhall")
		if not GetAliasByID(gh, "Guildhouse") then
			return 0
		end

		local list = {"Patron","Artisan","Scholar","Chiseler"}
		local Sim = "void"
		local found = false
		for i = 1,4 do
			if SimGetClass("") == i then
				Sim = list[i].."Master"
				found = true
			end
		end

		if found ~= true then 
			return 0
		end
	
		if GetID("") == GetProperty("Guildhouse", Sim) then
			for i = 1,4 do 
				if SimGetClass("") == i then
					if SimGetGender("") == 0 then
						return i
					else
						return i+4
					end
				end
			end

		else
			return 0
		end
	end
	
	return 0
end

function SimIsAlderman()
	if chr_GetAlderman() == GetID("") then
		if SimGetGender("") == 0 then
			return 1
		else
			return 2
		end
	else
		return 0
	end
end

function GetDatabaseIdByName(table, name)
	local id = 1
	while id<1000 do
		if (GetDatabaseValue(table, id, "name") == name) then
			break
		else
			id = id + 1
		end
	end
	return id
end

function GetTotalOfficeIncome(city)
	local citylvl = CityGetLevel(city)
	local highestlvl = CityGetHighestOfficeLevel(city)
	local officecount = 0
	local costs = 0
	local id = 1
	local OfficeNameLabel = ""
	local officelabel = ""

	for o=1, highestlvl do
		officecount = CityGetOfficeCountAtLevel(city, o)
		for i=0, officecount-1 do
			if CityGetOffice(city, o, i, "office") then
				if OfficeGetHolder("office", "holder") then
					OfficeNameLabel = OfficeGetTextLabel("office")
					local a,b = string.find(OfficeNameLabel, "_CHARACTERS_3_OFFICES_NAME_")
					officelabel = string.sub(OfficeNameLabel, b+1 , string.len(OfficeNameLabel)-3)

					id = 1
					while id<37 do
						if (GetDatabaseValue("Offices", id, "title") == officelabel) then
							costs = costs + GetDatabaseValue("Offices", id, "income")
							break
						else
							id = id + 1
						end
					end
				end
			end
		end
	end

	return costs
end

function ChangeWarRisk(Value)
	local warchooserid = GetData("#WarChooser")
	GetAliasByID(warchooserid,"WarChooser")
	local WarRiskVal = GetProperty("WarChooser","WarRisk")
	
	WarRiskVal = WarRiskVal + Value
	
	if WarRiskVal > 100 then
		SetProperty("WarChooser","WarRisk",100)
	elseif WarRiskVal < 1 then
		SetProperty("WarChooser","WarRisk",1)
	else
		SetProperty("WarChooser","WarRisk",WarRiskVal)
	end
	
	return true	
end

function ChangeEnemyHostility(Enemy,Value)
	-- Enemy : 1 to 4
	-- Value : have to be a positive value

	local warchooserid = GetData("#WarChooser")
	GetAliasByID(warchooserid,"WarChooser")
	local enemyHost1 = GetProperty("WarChooser","Hostility1")
	local enemyHost2 = GetProperty("WarChooser","Hostility2")
	local enemyHost3 = GetProperty("WarChooser","Hostility3")
	local enemyHost4 = GetProperty("WarChooser","Hostility4")

	local tmpVal
	local enemyRand

	if Enemy == 1 then

		tmpVal = enemyHost1 - Value
		if tmpVal < 1 then
			tmpVal = Value - enemyHost1
		end
		enemyHost1 = enemyHost1 - tmpVal
		if tmpVal > 0 then
			for x=1,tmpVal do
				enemyRand = Rand(3) + 1
				if enemyRand == 1 then
					if enemyHost2 > 96 then
						tmpVal = tmpVal + 1
					else
						enemyHost2 = enemyHost2 + 1
					end
				elseif enemyRand == 2 then
					if enemyHost3 > 96 then
						tmpVal = tmpVal + 1
					else
						enemyHost3 = enemyHost3 + 1
					end
				else
					if enemyHost4 > 96 then
						tmpVal = tmpVal + 1
					else
						enemyHost4 = enemyHost4 + 1
					end
				end
			end
		end

	elseif Enemy == 2 then
		tmpVal = enemyHost2 - Value
		if tmpVal < 1 then
			tmpVal = Value - enemyHost2
		end
		enemyHost2 = enemyHost2 - tmpVal
		if tmpVal > 0 then
			for x=1,tmpVal do
				enemyRand = Rand(3) + 1
				if enemyRand == 1 then
					if enemyHost1 > 96 then
						tmpVal = tmpVal + 1
					else
						enemyHost1 = enemyHost1 + 1
					end
				elseif enemyRand == 2 then
					if enemyHost3 > 96 then
						tmpVal = tmpVal + 1
					else
						enemyHost3 = enemyHost3 + 1
					end
				else
					if enemyHost4 > 96 then
						tmpVal = tmpVal + 1
					else
						enemyHost4 = enemyHost4 + 1
					end
				end
			end
		end

	elseif Enemy == 3 then
		tmpVal = enemyHost3 - Value
		if tmpVal < 1 then
			tmpVal = Value - enemyHost3
		end
		enemyHost3 = enemyHost3 - tmpVal
		if tmpVal > 0 then
			for x=1, tmpVal do
				enemyRand = Rand(3) + 1
				if enemyRand == 1 then
					if enemyHost1 > 96 then
						tmpVal = tmpVal + 1
					else
						enemyHost1 = enemyHost1 + 1
					end
				elseif enemyRand == 2 then
					if enemyHost2 > 96 then
						tmpVal = tmpVal + 1
					else
						enemyHost2 = enemyHost2 + 1
					end
				else
					if enemyHost4 > 96 then
						tmpVal = tmpVal + 1
					else
						enemyHost4 = enemyHost4 + 1
					end
				end
			end
		end

	elseif Enemy == 4 then
		
		tmpVal = enemyHost4 - Value
		
		if tmpVal < 1 then
			tmpVal = Value - enemyHost4
		end
		
		enemyHost4 = enemyHost4 - tmpVal
		
		if tmpVal > 0 then
			for x=1, tmpVal do
				enemyRand = Rand(3) + 1
				if enemyRand == 1 then
					if enemyHost1 > 96 then
						tmpVal = tmpVal + 1
					else
						enemyHost1 = enemyHost1 + 1
					end
				elseif enemyRand == 2 then
					if enemyHost2 > 96 then
						tmpVal = tmpVal + 1
					else
						enemyHost2 = enemyHost2 + 1
					end
				else
					if enemyHost3 > 96 then
						tmpVal = tmpVal + 1
					else
						enemyHost3 = enemyHost3 + 1
					end
				end
			end
		end
	end

	SetProperty("WarChooser", "Hostility1", enemyHost1)
	SetProperty("WarChooser", "Hostility2", enemyHost2)
	SetProperty("WarChooser", "Hostility3", enemyHost3)
	SetProperty("WarChooser", "Hostility4", enemyHost4)
		
	return true	
end

function GetEnemyHostilityLevel(Enemy)
	-- Enemy : 1 to 4

	local warchooserid = GetData("#WarChooser")
	GetAliasByID(warchooserid, "WarChooser")
	local enemyHost
	
	enemyHost = GetProperty("WarChooser", "Hostility"..Enemy)
		
	if enemyHost < 3 then
		return 0
	elseif enemyHost < 10 then
		return 1
	elseif enemyHost < 20 then
		return 2
	elseif enemyHost < 40 then
		return 3
	elseif enemyHost < 75 then
		return 4
	else
		return 5
	end

	return 0
end

function GetWarRiskLevel()
	
	local warchooserid = GetData("#WarChooser")
	GetAliasByID(warchooserid, "WarChooser")

	local risk = GetProperty("WarChooser", "WarRisk")
		
	if risk < 5 then
		return 0
	elseif risk < 15 then
		return 1
	elseif risk < 30 then
		return 2
	elseif risk < 60 then
		return 3
	elseif risk < 85 then
		return 4
	else
		return 5
	end

	return 0
end

function CheckDistance(Sim,Victim)
	local Dist = 0
	local MaxDist = 5000

	Dist = GetDistance(Sim, Victim)
	if Dist < MaxDist then
		return 1
	end
	return 0	
end

function GetMaxFavByDiffForAttack()
	local Difficulty = ScenarioGetDifficulty()

	if Difficulty == 0 then
		return 60
	elseif Difficulty == 1 then
		return 55
	elseif Difficulty == 2 then
		return 45
	elseif Difficulty == 3 then
		return 35
	else
		return 30
	end
end

function BlockMusicForConcert(force)
	SetData("#BlockMusicForConcert",force)
	if force==1 then
		StartHighPriorMusic(39, true)
	end
end

function StartHighPriorMusic(event, val)
	if GetData("#BlockMusicForConcert")==nil or GetData("#BlockMusicForConcert")==0 then
		if val then
			StartHighPriorMusic(event, val)
		else
			StartHighPriorMusic(event)
		end
	end
end



function GetCityUpgradeCost(curLvl)
	if curLvl == 2 then
		return 10000
	elseif curLvl == 3 then
		return 25000
	elseif curLvl == 4 then
		return 50000
	elseif curLvl == 5 then
		return 100000
	elseif curLvl == 6 then
		return 0
	end
end

function CheckMoneyForTreatment(SimAlias)

	if not IsPartyMember(SimAlias) then
		return 1
	end

	local Costs = 0
	local found = false

	for i = 1,9 do
		if GetImpactValue(SimAlias,allDiseases[i]:getName()) and GetImpactValue(SimAlias,allDiseases[i]:getName())==1 then
			Costs = allDiseases[i]:getCost()
			found = true
			break
		end
	end

	if found ~= true then 
		if GetHPRelative(SimAlias) < 0.99 then
			Costs = GetMaxHP(SimAlias)-GetHP(SimAlias)
		else
			return 0
		end
	end
	
	if Costs > GetMoney(SimAlias) then
		return 0
	else
		return 1
	end
end

function checkBuildingNoRoom(building)
-- checks if the building is of a type which has no room
local list = {GL_BUILDING_TYPE_FARM,GL_BUILDING_TYPE_ROBBER,GL_BUILDING_TYPE_MINE,GL_BUILDING_TYPE_RANGERHUT,GL_BUILDING_TYPE_MERCENARY,GL_BUILDING_TYPE_TOWER,GL_BUILDING_TYPE_PIRATESNEST,GL_BUILDING_TYPE_JUGGLER,GL_BUILDING_TYPE_FISHINGHUT,GL_BUILDING_TYPE_WAREHOUSE,GL_BUILDING_TYPE_MILL,GL_BUILDING_TYPE_FRUITFARM}
	for i = 1,12 do
		if BuildingGetType(building) == list[i] then 
			return 1
		else
			return 0
		end
	end
end

function GetImperialLevelPoints(FameLevel)
	local list = {GL_IMPERIAL_FAME_POINTS_KNOWN,GL_IMPERIAL_FAME_POINTS_NOTED,GL_IMPERIAL_FAME_POINTS_RESPECTED,GL_IMPERIAL_FAME_POINTS_LIKED,GL_IMPERIAL_FAME_POINTS_FAMOUS}
	return list[FameLevel]
end

---------------------------------------------------------------------------
-- These functions are referenced by the Dynasty Overview HUD and my not be removed
---------------------------------------------------------------------------
function GetFameDynasty()
	if IsDynastySim("") and GetDynasty("", "family") then
		return dyn_GetFameLevel("")
	else
		return -1
	end
end

function GetFameSim()
	return dyn_GetFameLevel("")
end

function GetImpFameSim()
	return dyn_GetImperialFameLevel("")
end

function GetImpFameDynasty()
	if IsDynastySim("") and GetDynasty("", "family") then
		return dyn_GetImperialFameLevel("")
	else
		return -1
	end
end
---------------------------------------------------------------------------


-------------------------
-- Important dynasties + players referencing for AI scripts
-- IDs saved in properties at the scenario
-------------------------
function GetImportantDynastiesCount()
	GetScenario("World")
	local DynastyCount = GetProperty("World", "ImportantDynCount") or 1
	
	return DynastyCount
end

function GetRandomImportantDynasty()
	GetScenario("World")
	local DynastyCount = GetProperty("World", "ImportantDynCount") or 1
	local DynArray = {}
	
	if DynastyCount > 0 then
		for i=1, DynastyCount do
			local DynID = GetProperty("World", "ImportantDyn"..i) or 0
			DynArray[i] = DynID
		end
	end
	
	local Random = Rand(DynastyCount) + 1
	return DynArray[Random]
end

function SaveImportantDynasty(DynAlias)
	local DynID = GetID(DynAlias)
	GetScenario("World")
	local DynastyCount = GetProperty("World", "ImportantDynCount") or 0
	local NewCount = DynastyCount + 1
	
	SetProperty("World", "ImportantDynCount", NewCount)
	SetProperty("World", "ImportantDyn"..NewCount, DynID)
end

function GetPlayerCount()
	GetScenario("World")
	local PlayerCount = GetProperty("World", "PlayerCount") or 1
	
	return PlayerCount
end

function GetRandomPlayer()
	GetScenario("World")
	local PlayerCount = GetProperty("World", "PlayerCount") or 1
	local PlayerArray = {}
	
	if PlayerCount > 0 then
		for i=1, PlayerCount do
			local DynID = GetProperty("World", "PlayerDyn"..i) or 0
			PlayerArray[i] = DynID
		end
	end
	
	local Random = Rand(PlayerCount) + 1
	return PlayerArray[Random]
end

function SavePlayerDynasty(DynAlias)
	local DynID = GetID(DynAlias)
	GetScenario("World")
	local PlayerCount = GetProperty("World", "PlayerCount") or 0
	local NewCount = PlayerCount + 1
	
	SetProperty("World", "PlayerCount", NewCount)
	SetProperty("World", "PlayerDyn"..NewCount, DynID)
end

--------------------------

-------------------------
-- Courting progress Rework
-- Allows changes in calculation and even additions to courting measures
-------------------------
function GetCourtingProgress(SimAlias, Destination, MeasureID)
	
	local Skill = 0
	local Class = SimGetClass(Destination)
	LogMessage("GetCourtingProgress Class = "..Class)
	if Class == 0 then
		if HasProperty(Destination, "FakeClass") then
			Class = GetProperty(Destination, "FakeClass")
		else
			Class = Rand(4) + 1
			SetProperty(Destination, "FakeClass", Class)
		end
	end
	
	local BaseValue = gameplayformulas_GetCourtingMeasureValue(MeasureID, Class)
	local VariationMod = gameplayformulas_GetCourtingMeasureVariation(MeasureID, Destination, Class) or 1
	local CourtingDiff = GetProperty(Destination, "CourtDiff") or 1
	
	LogMessage(GetName(SimAlias).." wants to court "..GetName(Destination).." with Class "..Class)
	
	if CourtingDiff < 1 then
		if CourtingDiff < 0.5 then
			CourtingDiff = 0.5
		else
			CourtingDiff = 0.75
		end
	end
	
	local MeasureData = {
					[460] = RHETORIC, -- StartDialog (talk) with Ictiv
					[530] = CHARISMA,  -- Flirt with Dr.Kulid357
					[540] = CHARISMA, -- Hug Erilambus
					[570] = EMPATHY, -- Kiss Fajeth
					[1520] = CHARISMA, -- Bathing with Craftgeeking
					[1530] = RHETORIC, -- Bewitching (sweat talking) Kodeks
					[2300] = EMPATHY, -- Make a Present to VSX
					[2310] = RHETORIC, -- Compliment ThreeOfMe
					[2320] = DEXTERITY -- Dancing with drouz
					}
					
	Skill = MeasureData[MeasureID]
	
	local SkillMod = GetSkillValue(SimAlias, Skill)
	local TitleDiff = GetNobilityTitle(SimAlias) - GetNobilityTitle(Destination)
	local FavorBonus = 0
	local Favor = GetFavorToSim(Destination, SimAlias)
	
	if Favor > 50 then
		FavorBonus = math.ceil(Favor/10)
	end
	
	LogMessage("FavorBonus is "..FavorBonus)
	LogMessage("BaseValue is "..BaseValue)
	LogMessage("SkillMod is "..SkillMod)
	local RandomVal = Rand(6) - Rand(6)
	LogMessage("RandomVal is "..RandomVal)
	LogMessage("TitleDiff is "..TitleDiff)
	LogMessage("CourtingDiff is "..CourtingDiff)
	LogMessage("VariationMod is "..VariationMod)
	
	local Progress = math.floor((((BaseValue * SkillMod + RandomVal) / CourtingDiff) + FavorBonus + TitleDiff) * VariationMod)
	return Progress
end

function GetCourtingMeasureValue(MeasureID, Class)
	
	-- get effectiveness of the courting measure based on destination class (or fake class for unemployed)
	local MeasureData = {
					[460] = { patron = 1, craftsman = 1.5, scholar = 2, rogue = 0.5, npc = 0 }, -- StartDialog (talk)
					[530] = { patron = 2, craftsman = 2, scholar = 2, rogue = 2, npc = 0 },  -- Flirt 
					[540] = { patron = 3, craftsman = 3, scholar = 2, rogue = 3, npc = 0 }, -- Hug
					[570] = { patron = 4, craftsman = 3, scholar = 2, rogue = 4, npc = 0 }, -- Kiss
					[1520] = { patron = 5, craftsman = 4, scholar = 2.5, rogue = 5, npc = 0 }, -- Bathing
					[1530] = { patron = 4, craftsman = 3, scholar = 5, rogue = 2.5, npc = 0 }, -- Bewitching (sweat talking)
					[2300] = { patron = 2, craftsman = 1.5, scholar = 3, rogue = 1.5, npc = 0 }, -- Make a Present
					[2310] = { patron = 1, craftsman = 2, scholar = 3, rogue = 1, npc = 0 }, -- Compliment
					[2320] = { patron = 4, craftsman = 3, scholar = 4, rogue = 2, npc = 0 } -- Dancing
					}
	local Value = 0
	
	if Class == GL_CLASS_PATRON then
		Value = MeasureData[MeasureID].patron
	elseif Class == GL_CLASS_ARTISAN then 
		Value = MeasureData[MeasureID].craftsman
	elseif Class == GL_CLASS_SCHOLAR then
		Value = MeasureData[MeasureID].scholar
	elseif Class == GL_CLASS_CHISELER then
		Value = MeasureData[MeasureID].rogue
	else
		Value = MeasureData[MeasureID].npc
	end

	return Value
end

function GetCourtingMeasureVariation(MeasureID, Destination, Class)
	
	local Factor = 1
	local ImpactVal = 0
	
	local ClassData = {
				[GL_CLASS_PATRON] = 1,
				[GL_CLASS_ARTISAN] = 0.5,
				[GL_CLASS_SCHOLAR] = 0.25,
				[GL_CLASS_CHISELER] = 0.5
				}
	
	local v = {
		[460] = 'Talk',
		[530] = 'Flirt',
		[540] = 'Hug',
		[570] = 'Kiss',
		[1520] = 'Bath',
		[1530] = 'Bewitch',
		[2300] = 'Present',
		[2310] = 'Compliment',
		[2320] = 'Dance'
	}

	local VariationClass = ClassData[Class] or 0

	ImpactVal = GetImpactValue(Destination, "Received"..v[MeasureID])*VariationClass
	
	Factor = Factor - ImpactVal
	
	if Class == GL_CLASS_SCHOLAR and Factor < 0.3 then
		Factor = 0.3
	end
	
	return Factor
end

function CourtingProgress(SimAlias, Value)
	local OldProgress = SimGetProgress(SimAlias)
	local NewProgress = OldProgress + Value
	
	if NewProgress > 99 then
		NewProgress = 100
	end
	
	SimSetProgress(SimAlias, NewProgress)
end

-------------------------
-- City related functions
-------------------------

function IncreaseInfectionCountCity(Alias)
	if GetSettlement(Alias, "City") then
		for i = 1, 9 do 		
			if GetImpactValue(Alias,allDiseases[i].getName()) == 1 then
				chr_IncrementInfectionCount(allDiseases[i].getName().."Infected", "City")
			end
		end
	end
end

function DecreaseInfectionCountCity(Alias)
	if GetSettlement(Alias, "City") then
		for i = 1, 9 do 		
			if GetImpactValue(Alias,allDiseases[i].getName()) and GetImpactValue(Alias,allDiseases[i].getName()) == 1 then
				chr_DecrementInfectionCount(allDiseases[i].getName().."Infected", "City")
			end
		end
	end
end

function CityGetRandomDynastyID(CityAlias)
	local DynID = 0
	local Families = CityGetBuildings(CityAlias, GL_BUILDING_CLASS_LIVINGROOM, -1, -1, -1, FILTER_HAS_DYNASTY, "Residence")
	
	if Families > 1 then
		local Choice = Rand(Families)
		if GetDynasty("Residence"..Choice, "RandomDyn") then
			DynID = GetID("RandomDyn")
		end
	end
	
	return DynID
end

function CityGetRandomDynastyMember(CityAlias, OnlyParty, OnlyValid)
	
	local MyID = 0
	
	if OnlyParty then
		CityGetDynastyCharList(CityAlias, "DynMember_List") -- all dynasty members in parties, beginning with the players and coloured dyns
		local lsize = ListSize("DynMember_List")
		for i=1, 5 do
			local RandomMember = Rand(lsize)
			ListGetElement("DynMember_List", lsize, "DynMember")
			if OnlyValid then
				if f_SimIsValid("DynMember") then
					CopyAlias("DynMember", "ChooseMe")
				end
			else
				CopyAlias("DynMember", "ChooseMe")
			end
			
			if AliasExists("ChooseMe") then
				MyID = GetID("ChooseMe")
				break
			end
		end
		
		return MyID
	else
		local DynID = gameplayformulas_CityGetRandomDynastyID(CityAlias) or 0 -- only gets dynasties with a residence in that city
		
		if DynID > 0 then
			
			local FamilyCount = DynastyGetFamilyMemberCount("RandomDyn") -- this gets all family members and not just party members
			local Choice = 1
					
			if FamilyCount > 1 then
				Choice = Rand(FamilyCount) + 1
			end
					
			if DynastyGetFamilyMember("RandomDyn", Choice, "MemberAlias") then
				if OnlyValid then
					if not f_SimIsValid("MemberAlias") then
						return 0
					else
						MyID = GetID("MemberAlias") or 0
					end
				end
			end
		end

		return MyID
	end
end

function CityCheckImportantBuilding(CityAlias, BuildingType, BuildingLevel)
	--LogMessage("Check for Type "..BuildingType.." in "..GetName(CityAlias).." at level "..BuildingLevel)
	
	if BuildingLevel == 1 then
		if not CityGetRandomBuilding(CityAlias, -1, BuildingType, 1, -1, FILTER_IGNORE, "BuildingExists") then
			if not CityGetRandomBuilding(CityAlias, -1, BuildingType, 2, -1, FILTER_IGNORE, "BuildingExists") then
				CityGetRandomBuilding(CityAlias, -1, BuildingType, 3, -1, FILTER_IGNORE, "BuildingExists")
			end
		end
	elseif BuildingLevel == 2 then
		if not CityGetRandomBuilding(CityAlias, -1, BuildingType, 2, -1, FILTER_IGNORE, "BuildingExists") then
			CityGetRandomBuilding(CityAlias, -1, BuildingType, 1, -1, FILTER_IGNORE, "BuildingExists")
		end
	elseif BuildingLevel == 3 then
		CityGetRandomBuilding(CityAlias, -1, BuildingType, 3, -1, FILTER_IGNORE, "BuildingExists")
	end
	
	if AliasExists("BuildingExists") then
		return true
	else
		return false
	end
end

function CityCheckImportantOwner(CityAlias, BuildingType, BuildingLevel)
	--LogMessage("Check for Owner for Type "..BuildingType.." in "..GetName(CityAlias).." at level "..BuildingLevel)
	
	if BuildingLevel == 1 then
		if not CityGetRandomBuilding(CityAlias, -1, BuildingType, 1, -1, FILTER_HAS_DYNASTY, "BuildingExists") then
			if not CityGetRandomBuilding(CityAlias, -1, BuildingType, 2, -1, FILTER_HAS_DYNASTY, "BuildingExists") then
				CityGetRandomBuilding(CityAlias, -1, BuildingType, 1, -1, FILTER_HAS_DYNASTY, "BuildingExists")
			end
		end
	elseif BuildingLevel == 2 then
		if not CityGetRandomBuilding(CityAlias, -1, BuildingType, 2, -1, FILTER_HAS_DYNASTY, "BuildingExists") then
			CityGetRandomBuilding(CityAlias, -1, BuildingType, 1, -1, FILTER_HAS_DYNASTY, "BuildingExists")
		end
	elseif BuildingLevel == 3 then
		CityGetRandomBuilding(CityAlias, -1, BuildingType, 3, -1, FILTER_HAS_DYNASTY, "BuildingExists")
	end
	
	if AliasExists("BuildingExists") then
		return true
	else
		return false
	end
end

function CityCheckHospital(CityAlias, Disease, NeedOwner)
	local HospitalLevel = {1, 1, 1, 2, 2, 3, 3, 3, 3 }
	local result = false

	for i = 1, 9 do 		
		if Disease == allDiseases[i].getName() then
			if NeedOwer then 
				result = gameplayformulas_CityCheckImportantOwner(CityAlias, GL_BUILDING_TYPE_HOSPITAL, HospitalLevel[i])
			else
				result = gameplayformulas_CityCheckImportantBuilding(CityAlias, GL_BUILDING_TYPE_HOSPITAL, HospitalLevel[i])
			end
			break
		end
	end

	return result
end

function CalcIllnessHazard(SimAlias, Disease)

	local BaseHazard = { 50, 50, 60, 30, 70, 0, 0, 0, 80 }
	local Hazard = 0

	for i = 1, 9 do
		if Disease == allDiseases[i].getName() then
			if BaseHazard[i] > 0 then
				Hazard = BaseHazard[i]
				
				-- age of Sim
				local Age = SimGetAge(SimAlias)
				if Age >= 65 then
					Hazard = Hazard + 20
				elseif Age >= 55 then
					Hazard = Hazard + 15
				elseif Age >= 45 then
					Hazard = Hazard + 10
				elseif Age >= 35 then
					Hazard = Hazard + 5
				end
				
				-- high consti protects you from infections
				local Constitution = GetSkillValue("", CONSTITUTION) * 5
				Hazard = Hazard - Constitution
			end
			break
		end
	end
	
	return Hazard
end