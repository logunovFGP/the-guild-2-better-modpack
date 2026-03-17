function Run()
end

function OnLevelUp()
end

function Setup()

	BuildingGetCity("", "City")
	SetProperty("City", "Guildhall", GetID(""))
	guildhouse_CheckGuildElders()
	MeasureRun("", nil, "GuildTrading")
end

function PingHour()

	BuildingGetCity("", "City")
	if not HasProperty("City", "Guildhall") then
		SetProperty("City", "Guildhall", GetID(""))
	end
		
	if GetRound() > 0 then
		local currentGameTime = math.mod(GetGametime(), 24)
		if currentGameTime == 12 then
			guildhouse_CheckGuildMasters()
		end
	end
			
	if GetCurrentMeasureName("") ~= "GuildTrading" then
		MeasureRun("", nil, "GuildTrading")
	end
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

	local MasterList = {"PatronMaster", "ArtisanMaster", "ScholarMaster", "ChiselerMaster"}
	local CheckMaster = ""
	local PatronMasterID, ArtisanMasterID, ScholarMasterID, ChiselerMasterID, CheckMasterID
	
	--add fame to last Master & remove property
	for i=1, 4 do
		CheckMaster = MasterList[i]
		CheckMasterID = GetProperty("", CheckMaster)
		
		if CheckMasterID ~= nil then
			if GetAliasByID(CheckMasterID, "OldMaster") and not GetState("OldMaster", STATE_DEAD) then
				dyn_AddFame("OldMaster", 1)
				RemoveProperty("OldMaster", CheckMaster)
			end
		end
	end

	local PlayerCity = false
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
	
	BuildingGetCity("", "city")		
	local BuildingCount = CityGetBuildings("city", GL_BUILDING_CLASS_WORKSHOP, -1, -1, -1, FILTER_HAS_DYNASTY, "Building")
	
	-- check all buildings of the city
	for i=0, BuildingCount-1 do
		Alias = "Building"..i
		BuildingLvl = BuildingGetLevel(Alias) * BuildingGetLevel(Alias)
		local BuildCharClass = BuildingGetCharacterClass(Alias)
		
		if BuildingGetOwner(Alias, "Sim") and (GetSettlementID("Sim") == GetID("city")) then
			
			if not PlayerCity and DynastyIsPlayer("Sim") then
				PlayerCity = true
			end
			
			local SimFame = dyn_GetFame("Sim") or 0
			
			-- ## Patron Class ##
			if BuildCharClass == GL_CLASS_PATRON then
				if ArrayCountPatron > 0 then -- we have patrons in the list. Check the list
					for u=1, ArrayCountPatron do
						local CheckArray = ArrayPatron[u]
						
						if CheckArray ~= nil and GetID("Sim") == CheckArray then -- already in the array? Add BuildingLvl to the points
							tmpPoints = PointArrayPatron[u] + BuildingLvl
							PointArrayPatron[u] = tmpPoints
							break
						end
							
						if u == ArrayCountPatron then -- last in the last and no break yet? Then add the new guy
							ArrayPatron[(u+1)] = GetID("Sim")
							tmpPoints = BuildingLvl + SimFame
							PointArrayPatron[(u+1)] = tmpPoints
							ArrayCountPatron = ArrayCountPatron + 1
							break
						end
					end
				else -- no list yet, then go ahead!
					ArrayPatron[1] = GetID("Sim")
					tmpPoints = BuildingLvl + SimFame
					PointArrayPatron[1] = tmpPoints
					ArrayCountPatron = ArrayCountPatron + 1
				end
					
			-- ## Craftsman (Artisan) Class ##
			elseif BuildCharClass == GL_CLASS_ARTISAN then
				if ArrayCountArtisan > 0 then -- we have artisans in the list. Check the list
					for u=1, ArrayCountArtisan do
						local CheckArray = ArrayArtisan[u]
						if CheckArray ~= nil and GetID("Sim") == CheckArray then -- already in the array? Add BuildingLvl to the points
							tmpPoints = PointArrayArtisan[u] + BuildingLvl
							PointArrayArtisan[u] = tmpPoints
							break
						end
							
						if u == ArrayCountArtisan then -- last in the last and no break yet? Then add the new guy
							ArrayArtisan[(u+1)] = GetID("Sim")
							tmpPoints = BuildingLvl + SimFame
							PointArrayArtisan[(u+1)] = tmpPoints
							ArrayCountArtisan = ArrayCountArtisan + 1
							break
						end
					end
				else -- no list yet, then go ahead!
					ArrayArtisan[1] = GetID("Sim")
					tmpPoints = BuildingLvl + SimFame
					PointArrayArtisan[1] = tmpPoints
					ArrayCountArtisan = ArrayCountArtisan + 1
				end
						
			-- ## Scholar Class ##
			elseif BuildCharClass == GL_CLASS_SCHOLAR then
				if ArrayCountScholar > 0 then -- we have scholars in the list. Check the list
					for j=1, ArrayCountScholar do
						local CheckArray = ArrayScholar[j]
						if CheckArray ~= nil and GetID("Sim") == CheckArray then -- already in the array? Add BuildingLvl to the points
							tmpPoints = PointArrayScholar[j] + BuildingLvl
							PointArrayScholar[j] = tmpPoints
							break
						end
							
						if j == ArrayCountScholar then -- last in the last and no break yet? Then add the new guy
							ArrayScholar[(j+1)] = GetID("Sim")
							tmpPoints = BuildingLvl + SimFame
							PointArrayScholar[(j+1)] = tmpPoints
							ArrayCountScholar = ArrayCountScholar + 1
							break
						end
					end
				else -- no list yet, then go ahead!
					ArrayScholar[1] = GetID("Sim")
					tmpPoints = BuildingLvl + SimFame
					PointArrayScholar[1] = tmpPoints
					ArrayCountScholar = ArrayCountScholar + 1
				end
				
			-- ## Rogue (Chiseler) Class ##
			elseif BuildCharClass == GL_CLASS_CHISELER then
				if ArrayCountChiseler > 0 then -- we have chiselers in the list. Check the list
					for j=1, ArrayCountChiseler do
						local CheckArray = ArrayChiseler[j]
						if CheckArray ~= nil and GetID("Sim") == CheckArray then -- already in the array? Add BuildingLvl to the points
							tmpPoints = PointArrayChiseler[j] + BuildingLvl
							PointArrayChiseler[j] = tmpPoints
							break
						end
							
						if j == ArrayCountChiseler then -- last in the last and no break yet? Then add the new guy
							ArrayChiseler[(j+1)] = GetID("Sim")
							tmpPoints = BuildingLvl + SimFame
							PointArrayChiseler[(j+1)] = tmpPoints
							ArrayCountChiseler = ArrayCountChiseler + 1
							break
						end
					end
				else -- no list yet, then go ahead!
					ArrayChiseler[1] = GetID("Sim")
					tmpPoints = BuildingLvl + SimFame
					PointArrayChiseler[1] = tmpPoints
					ArrayCountChiseler = ArrayCountChiseler + 1
				end
			end
		end
	end
	
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
	
	-- ## Send Messages ##
	
	-- PatronLabel[1], PatronName[2],  ArtisanLabel[3], ArtisanName[4],
	-- ScholarLabel[5], ScholarName[6], ChiselerLabel[7], ChiselerName[8],
	-- PatronFlag[9], ArtisanFlag[10], ScholarFlag[11], ChiselerFlag[12]
	local textArray = {"", "", "", "", "", "", "", "", "", "", "", "" }
	local Gender, GenderLabel
	local GenderArray = { "FEMALE", "MALE"}
	local NewYear = GetYear()
	SetProperty("", "year", NewYear)
	
	for w=1, 4 do -- send messages to all 4 winners
		if w == 1 then -- patron
			if ArrayPatron[WinnerPatron] ~= nil then
				GetAliasByID(ArrayPatron[WinnerPatron], "Winner")
				SetProperty("Winner", "PatronMaster", GetID("city"))
			
				if DynastyIsShadow("Winner") then
					textArray[9] = "@L$S[2045]"
				else
					GetDynasty("Winner", "Dyn")
					-- show the badge (flag)
					local tmpflag = DynastyGetFlagNumber("Dyn") + 29
					textArray[9] = "@L$S[20"..tmpflag.."]"
				end
				
				Gender = SimGetGender("Winner") + 1
				GenderLabel = GenderArray[Gender]
				textArray[1] = "@L_GUILDHOUSE_MASTERLIST_PATRON_"..GenderLabel.."_+0"
				textArray[2] = GetName("Winner")
				
				feedback_MessagePolitics("Winner", "@L_GUILDHOUSE_MASTERLIST_PLAYER_HEAD_+0", 
									"@L_GUILDHOUSE_MASTERLIST_PLAYER_"..GenderLabel.."_+0", GetID("city"), 
									GetID("Winner"), NewYear, "@L_GUILDHOUSE_MASTERLIST_PATRON_"..GenderLabel.."_+0")
				achievements_Unlock("Winner", "POLITICS_GUILDMASTER")
				
			else
				textArray[1] = "@L_GUILDHOUSE_MASTERLIST_PATRON_MALE_+0"
				textArray[2] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			end
			
		elseif w == 2 then -- artisan
			if ArrayArtisan[WinnerArtisan] ~= nil then
				GetAliasByID(ArrayArtisan[WinnerArtisan], "Winner")
				SetProperty("Winner", "ArtisanMaster", GetID("city"))
			
				if DynastyIsShadow("Winner") then
					textArray[10] = "@L$S[2045]"
				else
					GetDynasty("Winner", "Dyn")
					-- show the badge (flag)
					local tmpflag = DynastyGetFlagNumber("Dyn") + 29
					textArray[10] = "@L$S[20"..tmpflag.."]"
				end
				
				Gender = SimGetGender("Winner") + 1
				GenderLabel = GenderArray[Gender]
				textArray[3] = "@L_GUILDHOUSE_MASTERLIST_ARTISAN_"..GenderLabel.."_+0"
				textArray[4] = GetName("Winner")
				
				feedback_MessagePolitics("Winner", "@L_GUILDHOUSE_MASTERLIST_PLAYER_HEAD_+0", 
									"@L_GUILDHOUSE_MASTERLIST_PLAYER_"..GenderLabel.."_+0", GetID("city"), 
									GetID("Winner"), NewYear, "@L_GUILDHOUSE_MASTERLIST_ARTISAN_"..GenderLabel.."_+0")
				achievements_Unlock("Winner", "POLITICS_GUILDMASTER")
				
			else
				textArray[3] = "@L_GUILDHOUSE_MASTERLIST_ARTISAN_MALE_+0"
				textArray[4] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			end
			
		elseif w == 3 then -- scholar
			if ArrayScholar[WinnerScholar] ~= nil then
				GetAliasByID(ArrayScholar[WinnerScholar], "Winner")
				SetProperty("Winner", "ScholarMaster", GetID("city"))
			
				if DynastyIsShadow("Winner") then
					textArray[11] = "@L$S[2045]"
				else
					GetDynasty("Winner", "Dyn")
					-- show the badge (flag)
					local tmpflag = DynastyGetFlagNumber("Dyn") + 29
					textArray[11] = "@L$S[20"..tmpflag.."]"
				end
				
				textArray[5] = "@L_GUILDHOUSE_MASTERLIST_SCHOLAR_"..GenderLabel.."_+0"
				textArray[6] = GetName("Winner")
			
				Gender = SimGetGender("Winner") + 1
				GenderLabel = GenderArray[Gender]
				feedback_MessagePolitics("Winner", "@L_GUILDHOUSE_MASTERLIST_PLAYER_HEAD_+0", 
									"@L_GUILDHOUSE_MASTERLIST_PLAYER_"..GenderLabel.."_+0", GetID("city"), 
									GetID("Winner"), NewYear, "@L_GUILDHOUSE_MASTERLIST_SCHOLAR_"..GenderLabel.."_+0")
				achievements_Unlock("Winner", "POLITICS_GUILDMASTER")
				
			else
				textArray[5] = "@L_GUILDHOUSE_MASTERLIST_SCHOLAR_MALE_+0"
				textArray[6] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			end
			
		else -- chiseler
			if ArrayChiseler[WinnerChiseler] ~= nil then
				GetAliasByID(ArrayChiseler[WinnerChiseler], "Winner")
				SetProperty("Winner", "ChiselerMaster", GetID("city"))
			
				if DynastyIsShadow("Winner") then
					textArray[12] = "@L$S[2045]"
				else
					GetDynasty("Winner", "Dyn")
					-- show the badge (flag)
					local tmpflag = DynastyGetFlagNumber("Dyn") + 29
					textArray[12] = "@L$S[20"..tmpflag.."]"
				end
				
				textArray[7] = "@L_GUILDHOUSE_MASTERLIST_CHISELER_"..GenderLabel.."_+0"
				textArray[8] = GetName("Winner")
			
				Gender = SimGetGender("Winner") + 1
				GenderLabel = GenderArray[Gender]
		
				feedback_MessagePolitics("Winner", "@L_GUILDHOUSE_MASTERLIST_PLAYER_HEAD_+0", 
									"@L_GUILDHOUSE_MASTERLIST_PLAYER_"..GenderLabel.."_+0", GetID("city"), 
									GetID("Winner"), NewYear, "@L_GUILDHOUSE_MASTERLIST_CHISELER_"..GenderLabel.."_+0")
				achievements_Unlock("Winner", "POLITICS_GUILDMASTER")
				
			else
				textArray[7] = "@L_GUILDHOUSE_MASTERLIST_CHISELER_MALE_+0"
				textArray[8] = "@L_GUILDHOUSE_MASTERLIST_NO_ENTRY_+0"
			end
		end
	end

	if PlayerCity then
		MsgNewsNoWait("All", "", "", "politics", -1, "@L_GUILDHOUSE_MASTERLIST_HEAD_+0",
					"@L_GUILDHOUSE_MASTERLIST_BODY_+0", GetID("city"), NewYear, 
					textArray[1], textArray[2], textArray[3], textArray[4], textArray[5], textArray[6], 
					textArray[7], textArray[8], textArray[9], textArray[10], textArray[11], textArray[12])
	end
end
