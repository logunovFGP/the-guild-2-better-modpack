function Init()
 --needed for caching
end

function LockPick(LockPickerLevel,LockLevel)
	if(LockPickerLevel >= LockLevel) then
		return 1
	end	
	return 0	
end

function CalcBuildProgress(DefaultProgress,Workers)
	return DefaultProgress + Workers
end

function CalcBurnDamageProgress()
	return 1
end

function CalcCartBuyPrice(CartType)
		return 250*(CartType+1) 
end

function CalcCartSellPrice(CartType,HPRelative)
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

		local Class
		if SimGetClass("")==1 then
			Class = "PatronMaster"
		elseif SimGetClass("")==2 then
			Class = "ArtisanMaster"
		elseif SimGetClass("")==3 then
			Class = "ScholarMaster"
		elseif SimGetClass("")==4 then
			Class = "ChiselerMaster"
		else
			return 0
		end
	
		if GetID("")==GetProperty("Guildhouse", Class) then
			if SimGetGender("") == 0 then
				if SimGetClass("")==1 then
					return 1
				elseif SimGetClass("")==2 then
					return 2
				elseif SimGetClass("")==3 then
					return 3
				elseif SimGetClass("")==4 then
					return 4
				end
			else
				if SimGetClass("")==1 then
					return 5
				elseif SimGetClass("")==2 then
					return 6
				elseif SimGetClass("")==3 then
					return 7
				elseif SimGetClass("")==4 then
					return 8
				end
			end
		else
			return 0
		end
	end
	
	return 0
end

function SimIsAlderman()
	if chr_GetAlderman()==GetID("") then
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
		if (GetDatabaseValue(table, id, "name")==name) then
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
			for x=1,tmpVal do
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
			for x=1,tmpVal do
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

	SetProperty("WarChooser","Hostility1",enemyHost1)
	SetProperty("WarChooser","Hostility2",enemyHost2)
	SetProperty("WarChooser","Hostility3",enemyHost3)
	SetProperty("WarChooser","Hostility4",enemyHost4)
		
	return true	
end

function GetEnemyHostilityLevel(Enemy)
	-- Enemy : 1 to 4

	local warchooserid = GetData("#WarChooser")
	GetAliasByID(warchooserid,"WarChooser")

	local enemyHost
	if Enemy == 1 then
		enemyHost = GetProperty("WarChooser","Hostility1")
	elseif Enemy == 2 then
		enemyHost = GetProperty("WarChooser","Hostility2")
	elseif Enemy == 3 then
		enemyHost = GetProperty("WarChooser","Hostility3")
	else
		enemyHost = GetProperty("WarChooser","Hostility4")
	end
		
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
	GetAliasByID(warchooserid,"WarChooser")

	local risk = GetProperty("WarChooser","WarRisk")
		
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

function CheckPublicBuilding(city,building)
	-- return {building level in this city, building level in next city level}

	if not AliasExists(city) then
		return {0, 0}
	else
		local Level = CityGetLevel(city)
		if building == GL_BUILDING_TYPE_GUILDHOUSE then
			if Level==1 then
				return {0, 0}
			elseif Level==2 then
				return {0, 1}
			elseif Level==3 then
				return {1, 2}
			elseif Level==4 then
				return {2, 2}
			elseif Level==5 then
				return {2, 2}
			elseif Level==6 then
				return {2, 2}
			end
			
		elseif building == GL_BUILDING_TYPE_ARSENAL or building == GL_BUILDING_TYPE_SOLDIERPLACE then
			if Level==1 then
				return {0, 0}
			elseif Level==2 then
				return {0, 0}
			elseif Level==3 then
				return {0, 1}
			elseif Level==4 then
				return {1, 2}
			elseif Level==5 then
				return {2, 2}
			elseif Level==6 then
				return {2, 2}
			end
		end
	end
	return {0, 0}
end

function GetCityUpgradeCost(curLvl)
	if curLvl==2 then
		return 10000
	elseif curLvl==3 then
		return 25000
	elseif curLvl==4 then
		return 50000
	elseif curLvl==5 then
		return 100000
	elseif curLvl==6 then
		return 0
	end
end

function CheckMoneyForTreatment(SimAlias)

	if not IsPartyMember(SimAlias) then
		return 1
	end

	local Costs = 0
	
	if GetImpactValue(SimAlias,"Sprain")==1 then
		Costs = diseases_GetTreatmentCost("Sprain")
	elseif GetImpactValue(SimAlias,"Cold")==1 then
		Costs = diseases_GetTreatmentCost("Cold")
	elseif GetImpactValue(SimAlias,"Influenza")==1 then
		Costs = diseases_GetTreatmentCost("Influenza")
	elseif GetImpactValue(SimAlias,"BurnWound")==1 then
		Costs = diseases_GetTreatmentCost("BurnWound")
	elseif GetImpactValue(SimAlias,"Pox")==1 then
		Costs = diseases_GetTreatmentCost("Pox")
	elseif GetImpactValue(SimAlias,"Pneumonia")==1 then
		Costs = diseases_GetTreatmentCost("Pneumonia")
	elseif GetImpactValue(SimAlias,"Blackdeath")==1 then
		Costs = diseases_GetTreatmentCost("Blackdeath")
	elseif GetImpactValue(SimAlias,"Fracture")==1 then
		Costs = diseases_GetTreatmentCost("Fracture")
	elseif GetImpactValue(SimAlias,"Caries")==1 then
		Costs = diseases_GetTreatmentCost("Caries")
	elseif GetHPRelative(SimAlias) < 0.99 then
		Costs = GetMaxHP(SimAlias)-GetHP(SimAlias)
	else
		return 0
	end
		
	local Money = GetMoney(SimAlias)
	
	if Costs > Money then
		return 0
	else
		return 1
	end
end

function CheckImperialOfficer()

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
				if dyn_GetImperialFameLevel("Sim"..e) > 2 then
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
				SimFameArray[SimArrayCount] = dyn_GetImperialFame("Candidate"..i)
			end
		end
	end

	local ImperialWinner
	local ImperialFame = -1
			
	if SimArrayCount > 0 then
		for x=1, SimArrayCount do
			if SimFameArray[x]~=nil and SimFameArray[x] > ImperialFame then
				ImperialFame = SimFameArray[x]
				ImperialWinner = x
			end
		end
		
		-- goodbye old officer
		local OldImperialOfficer = chr_GetImperialOfficer()
		if OldImperialOfficer > 0 then
			GetAliasByID(OldImperialOfficer, "Old")
			dyn_AddImperialFame("Old", 1)
			RemoveProperty("Old", "ImperialOfficer")
		end						
				
		SetData("#ImperialOfficer", 0)
		
		-- welcome new man
		if GetAliasByID(SimArray[ImperialWinner], "New") then
			SetProperty("New", "ImperialOfficer", 1)
			SetData("#ImperialOfficer", SimArray[ImperialWinner])

			local label = "@L_IMPERIAL_OFFICER"
			local gender = ""

			if SimGetGender("New") == GL_GENDER_MALE then
				label = label.."_MALE_+1"
				gender = gender.."MALE"
			else
				label = label.."_FEMALE_+1"
				gender = gender.."MALE"
			end

			GetScenario("scenario")
			local mapid = GetProperty("scenario", "mapid")
			local lordlabel = "@L_SCENARIO_LORD_"..GetDatabaseValue("maps", mapid, "lordship").."_+0"

			GetSettlement("New", "settlement")
			local fameleveldyn = "@L_IMPERIAL_FAME_DYNASTY_+"..dyn_GetImperialFameLevel("New")

			MsgNewsNoWait("All", "New", "", "politics", -1,
							"@L_IMPERIAL_OFFICER_"..gender.."_+0",
							"@L_CHECKIMPERIALOFFICER_BODY_+0",
							GetYear(), GetID("New"), GetID("settlement"), label, fameleveldyn, dyn_GetImperialFame("New"), lordlabel)

		end
	else
		SetData("#ImperialOfficer", 0)
	end
end

function checkBuildingNoRoom(building)
-- checks if the building is of a type which has no room
	if (BuildingGetType(building) == GL_BUILDING_TYPE_FARM) or (BuildingGetType(building) == GL_BUILDING_TYPE_ROBBER) or
			(BuildingGetType(building) == GL_BUILDING_TYPE_MINE) or (BuildingGetType(building) == GL_BUILDING_TYPE_RANGERHUT) or
			(BuildingGetType(building) == GL_BUILDING_TYPE_CASTLE) or (BuildingGetType(building) == GL_BUILDING_TYPE_TOWER) or 
			(BuildingGetType(building) == GL_BUILDING_TYPE_PIRATESNEST) or (BuildingGetType(building) == GL_BUILDING_TYPE_JUGGLER) or 
			(BuildingGetType(building) == GL_BUILDING_TYPE_FISHINGHUT) or (BuildingGetType(building) == GL_BUILDING_TYPE_WAREHOUSE) or
			(BuildingGetType(building) == GL_BUILDING_TYPE_MILL) or (BuildingGetType(building) == GL_BUILDING_TYPE_FRUITFARM) then
		return 1
	else
		return 0
	end
end

function GetImperialLevelPoints(FameLevel)
	local Points = 0
	
	if FameLevel == 1 then
		Points = GL_IMPERIAL_FAME_POINTS_KNOWN
	elseif FameLevel == 2 then
		Points = GL_IMPERIAL_FAME_POINTS_NOTED
	elseif FameLevel == 3 then
		Points = GL_IMPERIAL_FAME_POINTS_RESPECTED
	elseif FameLevel == 4 then
		Points = GL_IMPERIAL_FAME_POINTS_LIKED
	elseif FameLevel == 5 then
		Points = GL_IMPERIAL_FAME_POINTS_FAMOUS
	end
	
	return Points
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
-- Important dynasties + players referencing
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
	local BaseValue = gameplayformulas_GetCourtingMeasureValue(MeasureID, Class)
	local VariationMod = gameplayformulas_GetCourtingMeasureVariation(MeasureID, Destination)
	
	if MeasureID == 530 then -- Flirt 
		Skill = CHARISMA
	elseif MeasureID == 540 then -- Hug
		Skill = CHARISMA
	elseif MeasureID == 570 then -- Kiss
		Skill = EMPATHY
	elseif MeasureID == 2300 then -- Make A Present
		Skill = EMPATHY
	elseif MeasureID == 2310 then -- Compliment
		Skill = RHETORIC
	elseif MeasureID == 2320 then -- Dancing
		Skill = DEXTERITY
	elseif MeasureID == 1520 then -- Bathing
		Skill = CHARISMA
	elseif MeasureID == 1530 then -- Bewitching
		Skill = RHETORIC
	elseif MeasureID == 460 then -- Dialog
		Skill = EMPATHY
	end
	
	local SkillMod = GetSkillValue(SimAlias, Skill)
	local TitleDiff = GetNobilityTitle(SimAlias) - GetNobilityTitle(Destination)
	
	local Progress = math.floor((BaseValue*SkillMod + Rand(5) - Rand(5) + TitleDiff) * VariationMod)
	return Progress
end

function GetCourtingMeasureValue(MeasureID, Class)
	
	local Value = 0
	local ClassValue = {}
	
	if MeasureID == 530 then -- Flirt
		ClassValue = { 1, 1, 2, 1, 0, 0 }
		Value = ClassValue[Class]
	elseif MeasureID == 540 then -- Hug
		ClassValue = { 3, 2, 1, 2, 0, 0 }
		Value = ClassValue[Class]
	elseif MeasureID == 570 then -- Kiss
		ClassValue = { 3, 2, 1, 3, 0, 0 }
		Value = ClassValue[Class]
	elseif MeasureID == 2300 then -- Make A Present
		ClassValue = { 1.5, 1, 2, 0.5, 0, 0 }
		Value = ClassValue[Class]
	elseif MeasureID == 2310 then -- Compliment
		ClassValue = { 1, 0.5, 2, 0.5, 0, 0 }
		Value = ClassValue[Class]
	elseif MeasureID == 2320 then -- Dancing
		ClassValue = { 3, 2, 3, 1, 0, 0 }
		Value = ClassValue[Class]
	elseif MeasureID == 1520 then -- Bathing
		ClassValue = { 3, 2, 1, 3, 0, 0 }
		Value = ClassValue[Class]
	elseif MeasureID == 1530 then -- Bewitching
		ClassValue = { 3, 1, 1, 2, 0, 0 }
		Value = ClassValue[Class]
	elseif MeasureID == 460 then -- Dialog
		ClassValue = { 0.5, 1, 2, 0.25, 0, 0 }
		Value = ClassValue[Class]
	end
	
	return Value
end

function GetCourtingMeasureVariation(MeasureID, Destination)
	local Factor = 1
	local ImpactVal = 0
	local Class = SimGetClass(Destination)
	local VariationClass
	
	if Class == GL_CLASS_PATRON then
		VariationClass = 1
	elseif Class == GL_CLASS_ARTISAN then
		VariationClass = 0.5
	elseif Class == GL_CLASS_SCHOLAR then
		VariationClass = 0.25
	else
		VariationClass = 0.5
	end
	
	if MeasureID == 530 then -- Flirt
		ImpactVal = GetImpactValue(Destination, "ReceivedFlirt")*VariationClass
	elseif MeasureID == 540 then -- Hug
		ImpactVal = GetImpactValue(Destination, "ReceivedHug")*VariationClass
	elseif MeasureID == 570 then -- Kiss
		ImpactVal = GetImpactValue(Destination, "ReceivedKiss")*VariationClass
	elseif MeasureID == 2300 then -- Make A Present
		ImpactVal = GetImpactValue(Destination, "ReceivedPresent")*VariationClass
	elseif MeasureID == 2310 then -- Compliment
		ImpactVal = GetImpactValue(Destination, "ReceivedCompliment")*(VariationClass*0.5)
	elseif MeasureID == 2320 then -- Dancing
		ImpactVal = GetImpactValue(Destination, "ReceivedDance")*VariationClass
	elseif MeasureID == 1520 then -- Bathing
		ImpactVal = GetImpactValue(Destination, "ReceivedBath")*VariationClass
	elseif MeasureID == 1530 then -- Bewitching
		ImpactVal = GetImpactValue(Destination, "ReceivedBewitch")*VariationClass
	elseif MeasureID == 460 then -- Dialog
		ImpactVal = GetImpactValue(Destination, "ReceivedTalk")*VariationClass
	end
	
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

function IncreaseInfectionCountCity(Alias)
	if GetSettlement(Alias, "City") then
		if GetImpactValue(Alias, "Sprain") == 1 then
			chr_IncrementInfectionCount("SprainInfected", "City")
		elseif GetImpactValue(Alias, "Cold") == 1 then
			chr_IncrementInfectionCount("ColdInfected", "City")
		elseif GetImpactValue(Alias, "Influenza") == 1 then
			chr_IncrementInfectionCount("InfluenzaInfected", "City")
		elseif GetImpactValue(Alias, "BurnWound") == 1 then
			chr_IncrementInfectionCount("BurnWoundInfected", "City")
		elseif GetImpactValue(Alias, "Pox") == 1 then
			chr_IncrementInfectionCount("PoxInfected", "City")
		elseif GetImpactValue(Alias, "Pneumonia") == 1 then
			chr_IncrementInfectionCount("PneumoniaInfected", "City")
		elseif GetImpactValue(Alias, "Blackdeath") == 1 then
			chr_IncrementInfectionCount("BlackdeathInfected", "City")
		elseif GetImpactValue(Alias, "Fracture") == 1 then
			chr_IncrementInfectionCount("FractureInfected", "City")
		elseif GetImpactValue(Alias, "Caries") == 1 then
			chr_IncrementInfectionCount("CariesInfected", "City")
		end
	end
end

function DecreaseInfectionCountCity(Alias)
	if GetSettlement(Alias, "City") then
		if GetImpactValue(Alias, "Sprain") == 1 then
			chr_DecrementInfectionCount("SprainInfected", "City")
		elseif GetImpactValue(Alias, "Cold") == 1 then
			chr_DecrementInfectionCount("ColdInfected", "City")
		elseif GetImpactValue(Alias, "Influenza") == 1 then
			chr_DecrementInfectionCount("InfluenzaInfected", "City")
		elseif GetImpactValue(Alias, "BurnWound") == 1 then
			chr_DecrementInfectionCount("BurnWoundInfected", "City")
		elseif GetImpactValue(Alias, "Pox") == 1 then
			chr_DecrementInfectionCount("PoxInfected", "City")
		elseif GetImpactValue(Alias, "Pneumonia") == 1 then
			chr_DecrementInfectionCount("PneumoniaInfected", "City")
		elseif GetImpactValue(Alias, "Blackdeath") == 1 then
			chr_DecrementInfectionCount("BlackdeathInfected", "City")
		elseif GetImpactValue(Alias, "Fracture") == 1 then
			chr_DecrementInfectionCount("FractureInfected", "City")
		elseif GetImpactValue(Alias, "Caries") == 1 then
			chr_DecrementInfectionCount("CariesInfected", "City")
		end
	end
end