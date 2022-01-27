function Run()
end

function OnLevelUp()
end

function Setup()

	BuildingGetCity("", "City")
	
	if (gameplayformulas_CheckPublicBuilding("City", GL_BUILDING_TYPE_GUILDHOUSE)[1] > 0) then
		SetProperty("City", "Guildhall", GetID(""))
		MeasureRun("", nil, "GuildTrading")
	end
end

function PingHour()

	BuildingGetCity("", "City")
	
	if (gameplayformulas_CheckPublicBuilding("City", GL_BUILDING_TYPE_GUILDHOUSE)[1] > 0) then
		if not HasProperty("City", "Guildhall") then
			SetProperty("City", "Guildhall", GetID(""))
		end
		
		guildhouse_CheckGuildElders()
		
		if GetRound() > 0 then
			local currentGameTime = math.mod(GetGametime(), 24)
			if (currentGameTime == 15) or ((currentGameTime > 15) and (currentGameTime < 16)) then
				guildhouse_CheckGuildMasters()
			end
		end
			
		if GetCurrentMeasureName("") ~= "GuildTrading" then
			MeasureRun("", nil, "GuildTrading")
		end
	end
	
	guildhouse_CheckSimsInside()
end

function CheckGuildElders()

	local ElderList = { "Patron", "Artisan", "Scholar", "Chiseler" }
	local ElderName = ""
	local Model = { 930, 931, 932, 933 }
	
	for i=1, 4 do
		ElderName = ElderList[i]

		if GetProperty("", ElderName.."Elder") == nil then
			GetLocatorByName("", ElderName.."Elder", "SpawnPos"..i)
			SimCreate(Model[i], "", "SpawnPos"..i, "Elder")
		end
		
		if SimGetGender("Elder") == GL_GENDER_MALE then
			local name = GetName("Elder")
			local y,z = string.find(name, " ")
			local newlastname = string.sub(name, 1 , y)
			SimSetFirstname("Elder", "@L_GUILDHOUSE_ELDER_MALE_+0")
			SimSetLastname("Elder", newlastname)
		else
			local name = GetName("Elder")
			local y,z = string.find(name, " ")
			local newlastname = string.sub(name, 1 , y)
			SimSetFirstname("Elder", "@L_GUILDHOUSE_ELDER_FEMALE_+0")
			SimSetLastname("Elder", newlastname)
		end
		
		SimSetAge("Elder", 65)
		SetState("Elder", STATE_TOWNNPC, true)
		SimSetBehavior("Elder", "GuildElder")
		SetProperty("", ElderName.."Elder", GetID("Elder"))
	end
end

function CheckGuildMasters()

	local MasterList = {"Patron", "Artisan", "Scholar", "Chiseler"}
	local MasterName = ""
	local PatronMaster, ArtisanMaster, ScholarMaster, ChiselerMaster, MasterID
	
	--add fame to last Master
	for i=1, 4 do
		MasterName = MasterList[i]
		MasterID = GetProperty("", MasterName.."Master")
		
		if MasterID ~= nil then
			if GetAliasByID(MasterID, "CheckMaster") and not GetState("CheckMaster", STATE_DEAD) then
				dyn_AddFame("CheckMaster", 1)
				RemoveProperty("CheckMaster", MasterName.."Master")
			end
		end
	end

	local year = GetYear()
	local Alias, BuildingLvl, tmpPoints, BuildingCharacterClass
	local ArrayPatron = {}
	local PointArrayPatron = {}
	local ArrayCountPatron = 0
	local ArrayArtisan = {}
	local PointArrayArtisan = {}
	local ArrayCountArtisan = 0
	local ArrayScholar = {}
	local PointArrayScholar = {}
	local ArrayCountScholar = 0
	local ArrayChiseler = {}
	local PointArrayChiseler = {}
	local ArrayCountChiseler = 0
	local PlayerCity = false
	BuildingGetCity("", "city")		
	local BuildingCount = CityGetBuildings("city", GL_BUILDING_CLASS_WORKSHOP, -1, -1, -1, FILTER_IGNORE, "Building")
	
	-- check all buildings of the city
	for i=0, BuildingCount-1 do
		Alias = "Building"..i
		BuildingLvl = BuildingGetLevel(Alias)
		BuildCharClass = BuildingGetCharacterClass(Alias)
		
		if BuildingGetOwner(Alias, "Sim") and (GetSettlementID("Sim") == GetID("city")) then
			
			if DynastyIsPlayer("Sim") and not PlayerCity then
				PlayerCity = true
			end
			
			local num = 1
			if not HasProperty("Sim", "GuildFame") then
				SetProperty("Sim", "GuildFame", 0)
			end
			
			local SimFame = 0 + GetProperty("Sim", "GuildFame")
			while num < 100 do
	
				if BuildCharClass == GL_CLASS_PATRON then
					if ArrayPatron[num] == GetID("Sim") then
					-- found SimID in the Array. Only add additional BuildingLvl to the points
						tmpPoints = PointArrayPatron[num] + BuildingLvl
						PointArrayPatron[num] = tmpPoints
						break
					elseif ArrayPatron[num] == nil then
					-- SimID not found - add it to the array + add family fame and sim fame once to the points
						ArrayPatron[num] = GetID("Sim")
						tmpPoints = BuildingLvl + dyn_GetFame("Sim") + SimFame
						PointArrayPatron[num] = tmpPoints
						ArrayCountPatron = ArrayCountPatron + 1
						break
					end
					
				elseif BuildCharClass == GL_CLASS_ARTISAN then
					if ArrayPatron[num] == GetID("Sim") then
					-- found SimID in the Array. Only add additional BuildingLvl to the points
						tmpPoints = PointArrayPatron[num] + BuildingLvl
						PointArrayPatron[num] = tmpPoints
						break
					elseif ArrayPatron[num] == nil then
					-- SimID not found - add it to the array + add family fame once to the points
						ArrayPatron[num] = GetID("Sim")
						tmpPoints = BuildingLvl + dyn_GetFame("Sim") + SimFame
						PointArrayPatron[num] = tmpPoints
						ArrayCountPatron = ArrayCountPatron + 1
						break
					end
				elseif BuildCharClass == GL_CLASS_SCHOLAR then
					if ArrayPatron[num] == GetID("Sim") then
					-- found SimID in the Array. Only add additional BuildingLvl to the points
						tmpPoints = PointArrayPatron[num] + BuildingLvl
						PointArrayPatron[num] = tmpPoints
						break
					elseif ArrayPatron[num] == nil then
					-- SimID not found - add it to the array + add family fame once to the points
						ArrayPatron[num] = GetID("Sim")
						tmpPoints = BuildingLvl + dyn_GetFame("Sim") + SimFame
						PointArrayPatron[num] = tmpPoints
						ArrayCountPatron = ArrayCountPatron + 1
						break
					end
				elseif BuildCharClass == GL_CLASS_CHISELER then
					if ArrayPatron[num] == GetID("Sim") then
					-- found SimID in the Array. Only add additional BuildingLvl to the points
						tmpPoints = PointArrayPatron[num] + BuildingLvl
						PointArrayPatron[num] = tmpPoints
						break
					elseif ArrayPatron[num] == nil then
					-- SimID not found - add it to the array + add family fame once to the points
						ArrayPatron[num] = GetID("Sim")
						tmpPoints = BuildingLvl + dyn_GetFame("Sim") + SimFame
						PointArrayPatron[num] = tmpPoints
						ArrayCountPatron = ArrayCountPatron + 1
						break
					end
				end
				num = num + 1
			end
		end
	end
	
	SetProperty("", "year", year)
	
	-- get the winners
	local WinnerPatron -- Winner index
	local PointsPatron = 0
	local WinnerArtisan 
	local PointsArtisan = 0
	local WinnerScholar 
	local PointsScholar = 0
	local WinnerChiseler
	local PointsChiseler = 0
	
	-- Patron
	if ArrayCountPatron > 0 then
		for x = 1, ArrayCountPatron do
			if PointArrayPatron[x] > PointsPatron then
				PointsPatron = PointArrayPatron[x]
				WinnerPatron = x
			end
		end
		SetProperty("", "PatronMaster", ArrayPatron[WinnerPatron])
	else
		SetProperty("", "PatronMaster", 0)
	end

	-- Artisan
	if ArrayCountArtisan > 0 then
		for x = 1, ArrayCountArtisan do
			if PointArrayArtisan[x] > PointsArtisan then
				PointsArtisan = PointArrayArtisan[x]
				WinnerArtisan = x
			end
		end
		SetProperty("", "ArtisanMaster", ArrayArtisan[WinnerArtisan])
	else
		SetProperty("", "ArtisanMaster", 0)
	end
	
	-- Scholar
	if ArrayCountScholar > 0 then
		for x = 1, ArrayCountScholar do
			if PointArrayScholar[x] > PointsScholar then
				PointsScholar = PointArrayScholar[x]
				WinnerScholar = x
			end
		end
		SetProperty("", "ScholarMaster", ArrayScholar[WinnerScholar])
	else
		SetProperty("", "ScholarMaster", 0)
	end
	
	-- Chiseler
	if ArrayCountChiseler > 0 then
		for x = 1, ArrayCountChiseler do
			if PointArrayChiseler[x] > PointsChiseler then
				PointsChiseler = PointArrayChiseler[x]
				WinnerChiseler = x
			end
		end
		SetProperty("", "ChiselerMaster", ArrayChiseler[WinnerChiseler])
	else
		SetProperty("", "ChiselerMaster", 0)
	end
	
	-- PatronLabel[1], PatronName[2],  ArtisanLabel[3], ArtisanName[4],
	-- ScholarLabel[5], ScholarName[6], ChiselerLabel[7], ChiselerName[8],
	-- PatronFlag[9], ArtisanFlag[10], ScholarFlag[11], ChiselerFlag[12]
	local textArray = {"", "", "", "", "", "", "", "", "", "", "", "" }
	local LabelArray = { "PATRON", "ARTISAN", "SCHOLAR", "CHISELER" }
	local ClassLabel, Gender, GenderLabel
	local GenderArray = { "FEMALE", "MALE"}
	
	for w=1, 4 do -- send messages to all 4 winners
		if w == 1 then -- patron
			ClassLabel = LabelArray[GL_CLASS_PATRON]
			if ArrayPatron[WinnerPatron] ~= nil then
				GetAliasByID(ArrayPatron[WinnerPatron], "Winner")
				SetProperty("Winner", MasterList[w].."Master", GetID("city"))
			
				if DynastyIsShadow("Winner") then
					textArray[9] = "@L$S[2045]"
				else
					GetDynasty("Winner", "Dyn")
					-- show the badge (flag)
					local tmpflag = DynastyGetFlagNumber("Dyn") + 29
					textArray[9] = "@L$S[20"..tmpflag.."]"
				end
				
				textArray[2] = GetName("Winner")
			
				Gender = SimGetGender("Winner") + 1
				GenderLabel = GenderArray[Gender]
				textArray[1] = "@L_GUILDHOUSE_MASTERLIST_"..ClassLabel.."_"..GenderLabel.."_+0"
				feedback_MessagePolitics("Winner", "@L_GUILDHOUSE_MASTERLIST_PLAYER_HEAD_+0", 
									"@L_GUILDHOUSE_MASTERLIST_PLAYER_"..GenderLabel.."_+0", GetID("city"), 
									ArrayPatron[WinnerPatron], GetYear(), "@L_GUILDHOUSE_MASTERLIST_"..ClassLabel.."_"..GenderLabel.."_+0")
				
			else
				textArray[1] = "@L_GUILDHOUSE_MASTERLIST_"..ClassLabel.."_MALE_+0"
				textArray[2] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			end
		elseif w == 2 then -- artisan
			ClassLabel = LabelArray[GL_CLASS_ARTISAN]
			if ArrayArtisan[WinnerArtisan] ~= nil then
				GetAliasByID(ArrayArtisan[WinnerArtisan], "Winner")
				SetProperty("Winner", MasterList[w].."Master", GetID("city"))
			
				if DynastyIsShadow("Winner") then
					textArray[10] = "@L$S[2045]"
				else
					GetDynasty("Winner", "Dyn")
					-- show the badge (flag)
					local tmpflag = DynastyGetFlagNumber("Dyn") + 29
					textArray[10] = "@L$S[20"..tmpflag.."]"
				end
				
				textArray[4] = GetName("Winner")
				ClassLabel = LabelArray[w]
			
				Gender = SimGetGender("Winner") + 1
				GenderLabel = GenderArray[Gender]
				textArray[3] = "@L_GUILDHOUSE_MASTERLIST_"..ClassLabel.."_"..GenderLabel.."_+0"
				feedback_MessagePolitics("Winner", "@L_GUILDHOUSE_MASTERLIST_PLAYER_HEAD_+0", 
									"@L_GUILDHOUSE_MASTERLIST_PLAYER_"..GenderLabel.."_+0", GetID("city"), 
									ArrayArtisan[WinnerArtisan], GetYear(), "@L_GUILDHOUSE_MASTERLIST_"..ClassLabel.."_"..GenderLabel.."_+0")
				
			else
				textArray[3] = "@L_GUILDHOUSE_MASTERLIST_"..ClassLabel.."_MALE_+0"
				textArray[4] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			end
		elseif w == 3 then -- scholar
			ClassLabel = LabelArray[GL_CLASS_SCHOLAR]
			if ArrayScholar[WinnerScholar] ~= nil then
				GetAliasByID(ArrayScholar[WinnerScholar], "Winner")
				SetProperty("Winner", MasterList[w].."Master", GetID("city"))
			
				if DynastyIsShadow("Winner") then
					textArray[11] = "@L$S[2045]"
				else
					GetDynasty("Winner", "Dyn")
					-- show the badge (flag)
					local tmpflag = DynastyGetFlagNumber("Dyn") + 29
					textArray[11] = "@L$S[20"..tmpflag.."]"
				end
				
				textArray[6] = GetName("Winner")
				ClassLabel = LabelArray[w]
			
				Gender = SimGetGender("Winner") + 1
				GenderLabel = GenderArray[Gender]
				textArray[5] = "@L_GUILDHOUSE_MASTERLIST_"..ClassLabel.."_"..GenderLabel.."_+0"
				feedback_MessagePolitics("Winner", "@L_GUILDHOUSE_MASTERLIST_PLAYER_HEAD_+0", 
									"@L_GUILDHOUSE_MASTERLIST_PLAYER_"..GenderLabel.."_+0", GetID("city"), 
									ArrayScholar[WinnerScholar], GetYear(), "@L_GUILDHOUSE_MASTERLIST_"..ClassLabel.."_"..GenderLabel.."_+0")
				
			else
				textArray[5] = "@L_GUILDHOUSE_MASTERLIST_"..ClassLabel.."_MALE_+0"
				textArray[6] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			end
		else -- chiseler
			ClassLabel = LabelArray[GL_CLASS_CHISELER]
			if ArrayChiseler[WinnerChiseler] ~= nil then
				GetAliasByID(ArrayChiseler[WinnerChiseler], "Winner")
				SetProperty("Winner", MasterList[w].."Master", GetID("city"))
			
				if DynastyIsShadow("Winner") then
					textArray[12] = "@L$S[2045]"
				else
					GetDynasty("Winner", "Dyn")
					-- show the badge (flag)
					local tmpflag = DynastyGetFlagNumber("Dyn") + 29
					textArray[12] = "@L$S[20"..tmpflag.."]"
				end
				
				textArray[8] = GetName("Winner")
				ClassLabel = LabelArray[w]
			
				Gender = SimGetGender("Winner") + 1
				GenderLabel = GenderArray[Gender]
				textArray[7] = "@L_GUILDHOUSE_MASTERLIST_"..ClassLabel.."_"..GenderLabel.."_+0"
				feedback_MessagePolitics("Winner"..w, "@L_GUILDHOUSE_MASTERLIST_PLAYER_HEAD_+0", 
									"@L_GUILDHOUSE_MASTERLIST_PLAYER_"..GenderLabel.."_+0", GetID("city"), 
									ArrayChiseler[WinnerChiseler], GetYear(), "@L_GUILDHOUSE_MASTERLIST_"..ClassLabel.."_"..GenderLabel.."_+0")
				
			else
				textArray[7] = "@L_GUILDHOUSE_MASTERLIST_"..ClassLabel.."_MALE_+0"
				textArray[8] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			end
		end
	end

	if PlayerCity then
		MsgNewsNoWait("All", "", "", "politics", -1, "@L_GUILDHOUSE_MASTERLIST_HEAD_+0",
					"@L_GUILDHOUSE_MASTERLIST_BODY_+0", GetID("city"), GetYear(), 
					textArray[1], textArray[2], textArray[3], textArray[4], textArray[5], textArray[6], 
					textArray[7], textArray[8], textArray[9], textArray[10], textArray[11], textArray[12])
	end
end

function CheckSimsInside()
	
	local forceexit = false
	BuildingGetCity("", "City")
	
	if (gameplayformulas_CheckPublicBuilding("City", GL_BUILDING_TYPE_GUILDHOUSE)[1] == 0) then
		forceexit = true
	end

	BuildingGetInsideSimList("","SimList")

	local SimCnt = ListSize("SimList")

	for i=0, SimCnt - 1 do
		ListGetElement("SimList",i,"Sim")
		
		if forceexit then
			if not GetState("Sim", STATE_TOWNNPC) then
				f_ExitCurrentBuilding("Sim")
			end
			
		elseif (DynastyIsAI("Sim") and not(GetState("Sim", STATE_TOWNNPC))) then
			if GetCurrentMeasurePriority("Sim") < 2 then
				f_ExitCurrentBuilding("Sim")
			end
		end
	end
end
