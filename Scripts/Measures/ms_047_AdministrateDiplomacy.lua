-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_047_AdministrateDiplomacy.lua"
----
----	With this measure the player can change the diplomatic status, 
----	can make requests, demands, gifts or send diplomatic messages
----
----	This measure has been greatly reworked by Fajeth
----
----	Note: AI will use scriptcalls instead, using the 
----	AI scripts
-------------------------------------------------------------------------------

function CanDiplo(DestID)
	local Day = math.floor(GetGametime() / 24)
	local Count = 0
	if HasProperty("dynasty", "DIP_Day_"..DestID) and GetProperty("dynasty", "DIP_Day_"..DestID) == Day then
		if HasProperty("dynasty", "DIP_Count_"..DestID) then
			Count = GetProperty("dynasty", "DIP_Count_"..DestID)
		end
	end
	return Count < GL_DIPLO_MAX_PER_DAY
end

function RecordDiplo(DestID)
	local Day = math.floor(GetGametime() / 24)
	local Count = 0
	if HasProperty("dynasty", "DIP_Day_"..DestID) and GetProperty("dynasty", "DIP_Day_"..DestID) == Day then
		if HasProperty("dynasty", "DIP_Count_"..DestID) then
			Count = GetProperty("dynasty", "DIP_Count_"..DestID)
		end
	end
	SetProperty("dynasty", "DIP_Day_"..DestID, Day)
	SetProperty("dynasty", "DIP_Count_"..DestID, Count + 1)
end

function Init() -- this is called before Run

	-- We need the Owner because this measure is now a building-measure
	if IsGUIDriven() then
		if not BuildingGetOwner("", "MyBoss") then
			MsgBoxNoWait("dynasty", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_NOOWNER_BODY_+0")
			return false
		end
	else
		CopyAlias("", "MyBoss")
	end
	
	if not AliasExists("Destination") then
		StopMeasure()
	end

	if DynastyIsPlayer("") then
		
		-- target badge
		local TargetBadge = dyn_GetFlagLabel("Destination")
		
		local LetterBtn = ""
		if DynastyIsPlayer("Destination") then
			LetterBtn = "@B[7,@L_MP_LETTER_BUTTON]"
		end

		-- First we need to choose what we want to do
		local Selection = MsgBox("MyBoss", "Destination", "@P"..
								"@B[1,@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_+0]"..
								"@B[6,@L_MEASURE_ADMINISTRATE_DIPLOMACY_SPECIAL_+0]"..
								"@B[2,@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_+0]"..
								"@B[4,@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_+0]"..
								"@B[3,@L_MEASURE_ADMINISTRATE_DIPLOMACY_GIFT_+0]"..
								"@B[5,@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_+0]"..
								LetterBtn,
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_SELECTION_HEAD_+0",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_SELECTION_BODY_+0", GetID("Destination"), TargetBadge)
	
		SetData("Choice", Selection)
	end
end

function Run()

	if not AliasExists("Destination") then
		StopMeasure()
	end
	
	GetDynasty("Destination", "TargetDyn")

	local Selection = GetData("Choice")
	local result = 0
	
	if Selection == 1 then -- change status
		-- not in team mode
		if DynastyGetTeam("MyBoss") > 0 and DynastyGetTeam("MyBoss") == DynastyGetTeam("Destination") then
			MsgBoxNoWait("MyBoss", "Destination","@L_GENERAL_ERROR_HEAD_+0", "@L_MEASURE_AdministrateDiplomacy_FAILURE_TEAM_+0")
			StopMeasure()
		else
			-- player ask for status
			if DynastyIsPlayer("") then 
				ms_047_administratediplomacy_Status()
			end
			
			-- confirm your choice
			result = GetData("InitResult")
			if result == 0 then -- feud
				ms_047_administratediplomacy_ConfirmFeud()
			elseif result == 1 then -- neutral
				ms_047_administratediplomacy_ConfirmNeutral()
			elseif result == 2 then -- NAP
				ms_047_administratediplomacy_ConfirmNAP()
			elseif result == 3 then -- Alliance
				ms_047_administratediplomacy_ConfirmAlliance()
			end
		end
		
	elseif Selection == 2 then -- message to raise/lower favor (not with enemies)
		ms_047_administratediplomacy_Message()
	elseif Selection == 3 then -- gift for allies
		ms_047_administratediplomacy_Gift()
	elseif Selection == 4 then -- demand for non-allies
		ms_047_administratediplomacy_RequestEnemies()
	elseif Selection == 5 then -- request for allies
		ms_047_administratediplomacy_RequestAllies()
	elseif Selection == 6 then -- check for grudges and fondness, rivals, allies and foes
		ms_047_administratediplomacy_SpecialCheck()
	elseif Selection == 7 then -- open the native free-text letter composer for this player
		if GetLocalPlayerDynasty("LocalDyn") and GetDynasty("", "ActorDyn") and GetID("LocalDyn") == GetID("ActorDyn") then
			GetDynasty("Destination", "LetterTarget")
			OpenLetterComposer("LetterTarget")
		end
	end
end

function Status()
	-- Change the status
	
	--- target badge
	local TargetBadge = dyn_GetFlagLabel("Destination")
	
	-- timout for changing status multiple times
	local DestID = GetDynastyID("Destination")
	if not ms_047_administratediplomacy_CanDiplo(DestID) then
		MsgBoxNoWait("MyBoss", "Destination",
				"@L_GENERAL_ERROR_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ERROR_COOLDOWN", GetID("Destination"), TargetBadge)
		StopMeasure()
	end
	
	local CState = DynastyGetDiplomacyState("Destination", "MyBoss")
	local Buttons = ""
	
	-- some measures don't allow us to change status
	local MinState = DynastyGetMinDiplomacyState("MyBoss", "Destination")
	local MaxState = DynastyGetMaxDiplomacyState("MyBoss", "Destination")
	
	if MinState < 0 or MaxState < 0 then
		StopMeasure()
	end
	
	local	Count = 0
	
	-- add only the buttons you can use
	for i=0, 3 do
		if i >= MinState and i <= MaxState and i ~= CState then
			if i == 0 then
				Buttons = Buttons.."@B[0,,@LHostility,Hud/Buttons/btn_034_ArmCharacter.tga]"
			elseif i == 1 then
				Buttons = Buttons.."@B[1,,@LNeutral,Hud/Buttons/btn_030_GuardObject.tga]"			
			elseif i == 2 then
				Buttons = Buttons.."@B[2,,@LNAP,Hud/Buttons/btn_015_ReclaimField.tga]"
			elseif i == 3 then
				Buttons = Buttons.."@B[3,,@LAlliance,Hud/Buttons/btn_047_Administrate_Diplomacy.tga]"
			end
			Count = Count + 1
		end
	end
	
	if Count < 2 then
		-- error
		StopMeasure()
	end

	local result = InitData("@P"..Buttons, 1, "@LAdministrateDiplomacySheet", "")
	
	if result == "C" then
		StopMeasure()
	end
	
	SetData("InitResult", result)
end

function Message()
	-- send a message to gain or reduce favor
	
	-- target badge
	local TargetBadge = dyn_GetFlagLabel("Destination")
	-- own badge
	local MyBadge = dyn_GetFlagLabel("MyBoss")
	
	-- timout for multiple messages
	local DestID = GetDynastyID("Destination")
	if not ms_047_administratediplomacy_CanDiplo(DestID) then
		MsgBoxNoWait("MyBoss", "Destination",
				"@L_GENERAL_ERROR_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ERROR_COOLDOWN", GetID("Destination"), TargetBadge)
		StopMeasure()
	end
	
	local CState = DynastyGetDiplomacyState("Destination", "MyBoss")
	
	-- you can't send messages to foes
	if CState == DIP_FOE then
		MsgBoxNoWait("MyBoss", "Destination",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_ERROR_FOE", GetID("Destination"), TargetBadge)
		StopMeasure()
	end
	
	-- buttons
	local result = 0
	if HasData("InitResult") then
		result = GetData("InitResult") -- the AI: 0 respect, 1 taunt
	end
	if IsGUIDriven() then
		result = InitData("@P".."@B[0,,@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_NICE_BTN,hud/buttons/btn_MakeACompliment.tga]"..
					"@B[1,,@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_MEAN_BTN,hud/buttons/btn_039_blackmailCharacter.tga]",
					1, "@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_BODY_+0", GetID("Destination"), TargetBadge)
	end
	
	-- your message depends on the skills of the building owner
	local Skill = GetSkillValue("MyBoss", RHETORIC)
	local ResultLabel = ""
	local RhetLabel = "LOW"
	local Favor = 0
	 
	if Skill < 4 then
		Favor = GL_FAVOR_MOD_TINY + Rand(GL_FAVOR_MOD_VERYSMALL)
	elseif Skill <7 then
		Favor = GL_FAVOR_MOD_SMALL + Rand(GL_FAVOR_MOD_SMALL)
		RhetLabel = "MEDIUM"
	elseif Skill <10 then
		Favor = GL_FAVOR_MOD_NORMAL + Rand(GL_FAVOR_MOD_NORMAL)
		RhetLabel = "HIGH"
	else
		Favor = GL_FAVOR_MOD_GREATER + Rand(GL_FAVOR_MOD_GREATER)
		RhetLabel = "PERFECT"
	end
		
	if result == 0 then
		ResultLabel = "NICE"
	elseif result == 1 then
		ResultLabel = "MEAN"
		Favor = Favor*(-1)
	else
		StopMeasure()
	end
	
	ms_047_administratediplomacy_RecordDiplo(DestID)
	dyn_ModifyFavor("MyBoss", "Destination", (Favor)) -- use dyn_ModifyFavor because there's no animations
	MsgBoxNoWait("MyBoss", "Destination",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_"..ResultLabel.."_SEND_"..RhetLabel, GetID("Destination"), TargetBadge)
					
	-- Message the destination
	MsgNewsNoWait("Destination","MyBoss","","politics",-1,
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_RECEIVE_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_"..ResultLabel.."_RECEIVE_"..RhetLabel, GetID("MyBoss"), MyBadge)
end

function Gift()
	
	-- target badge
	local TargetBadge = dyn_GetFlagLabel("Destination")
	-- own badge
	local MyBadge = dyn_GetFlagLabel("MyBoss")
	
	local CState = DynastyGetDiplomacyState("Destination", "MyBoss")
	
	if CState ~= DIP_ALLIANCE then
		-- error - only allies get gifts
		MsgBoxNoWait("MyBoss", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ERROR_GIFT_+0")
		StopMeasure()
	end
	
	local MyMoney = GetMoney("dynasty")
	
	local VeryLow = math.floor(MyMoney*0.15)
	local Low = math.floor(MyMoney*0.3)
	local Medium = math.floor(MyMoney*0.45)
	local High = math.floor(MyMoney*0.6)
	local VeryHigh = math.floor(MyMoney*0.75)
	local Amount = 0
	
	-- how much money do you want to send?
	local GiftResult = InitData("@P".."@B[0,"..VeryLow..",,hud/items/Item_goldlow.tga]"..
					"@B[1,"..Low..",,hud/items/Item_goldlowmed.tga]"..
					"@B[2,"..Medium..",,hud/items/Item_goldmed.tga]"..
					"@B[3,"..High..",,hud/items/Item_goldmedhigh.tga]"..
					"@B[4,"..VeryHigh..",,hud/items/Item_goldveryhigh.tga]",
					1,"@L_MEASURE_ADMINISTRATE_DIPLOMACY_GIFT_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_GIFT_BODY_+0", GetID("Destination"))
	if HasData("InitResult") and not IsGUIDriven() then
		GiftResult = GetData("InitResult") -- the AI: 0..4, smallest to largest
	end
	
	if GiftResult == 0 then
		Amount = VeryLow
	elseif GiftResult == 1 then
		Amount = Low
	elseif GiftResult == 2 then
		Amount = Medium
	elseif GiftResult == 3 then
		Amount = High
	elseif GiftResult == 4 then
		Amount = VeryHigh
	else
		StopMeasure()
	end
	
	chr_SpendMoney("MyBoss", Amount, "CostBribes")
	chr_CreditMoney("Destination", Amount, "IncomeBribes")
	
	-- message to the destination
	MsgNewsNoWait("Destination", "MyBoss", "", "politics", -1,
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_GIFT_RECEIVE_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_GIFT_RECEIVE_BODY", GetID("MyBoss"), Amount, MyBadge)
		
	if DynastyIsAI("Destination") then
		-- reaction for AI
		local AnswerTime = 0.1
		CreateScriptcall("Answer_Gift", AnswerTime, "Measures/ms_047_AdministrateDiplomacy.lua", "AnswerGift", "MyBoss", "Destination", Amount, TargetBadge)
	end
end

function AnswerGift(Amount)
	-- AI sends a message depending on how useful the gift is
	
	-- target badge
	local TargetBadge = dyn_GetFlagLabel("Destination")
	
	local DesMoney = GetMoney("Destination")
	local AmountPercent = (Amount*100) / DesMoney
	
	if AmountPercent < 25 then -- no positive effect
		MsgNewsNoWait("", "Destination", "", "politics", -1, "@L_MEASURE_ADMINISTRATE_DIPLOMACY_GIFT_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_GIFT_NEUTRAL", GetID("Destination"), TargetBadge)
	elseif AmountPercent >= 25 and AmountPercent < 70 then -- small effect
		dyn_ModifyFavor("Destination", "", GL_FAVOR_MOD_SMALL)
		MsgNewsNoWait("", "Destination", "", "politics", -1, "@L_MEASURE_ADMINISTRATE_DIPLOMACY_GIFT_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_GIFT_POSITIVE", GetID("Destination"), TargetBadge)
	else -- big effect
		dyn_ModifyFavor("Destination", "", GL_FAVOR_MOD_LARGE)
		MsgNewsNoWait("", "Destination", "", "politics", -1, "@L_MEASURE_ADMINISTRATE_DIPLOMACY_GIFT_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_GIFT_GRATEFUL", GetID("Destination"), TargetBadge)
	end
end

function RequestAllies()

	-- target badge
	local TargetBadge = dyn_GetFlagLabel("Destination")
	-- own badge
	local MyBadge = dyn_GetFlagLabel("MyBoss")
	
	local DestID = GetDynastyID("Destination")
	local resultReq
	
	if not ms_047_administratediplomacy_CanDiplo(DestID) then
		MsgBoxNoWait("MyBoss", "Destination",
				"@L_GENERAL_ERROR_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ERROR_COOLDOWN", GetID("Destination"), TargetBadge)
		StopMeasure()
	end

	local CState = DynastyGetDiplomacyState("Destination", "MyBoss")
	
	if CState ~= DIP_ALLIANCE then
		-- error - only allies answer requests
		MsgBoxNoWait("MyBoss", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ERROR_REQUEST_+0")
		StopMeasure()
	end
	
	local DesMoney = GetMoney("Destination")
	local Amount = math.floor(DesMoney*0.1)
	
	if DynastyIsPlayer("") then
		resultReq = MsgBox("MyBoss", "Destination", "@P"..
				"@B[1,@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_MONEY_BTN_+0]"..
				"@B[2,@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_ATTACK_BUILDING_BTN_+0]"..
				"@B[C,@L_MEASURE_ORDERCREDIT_STUFF_+4]",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_GENERAL_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_GENERAL_BODY_+0", GetID("Destination"))
	else
		resultReq = 1
	end
	
	if resultReq == 1 then 
		ms_047_administratediplomacy_RecordDiplo(DestID)
		-- Can I have some money?
		MsgBoxNoWait("MyBoss", "Destination", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_MONEY_BTN_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_MONEY_BODY_+0", GetID("Destination"), TargetBadge)
	
		-- message to the destination if player
		if DynastyIsPlayer("Destination") then
			MsgNewsNoWait("Destination", "MyBoss", "", "politics", -1,
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_RECEIVE_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_RECEIVE_MONEY_BODY_+0", GetID("MyBoss"), MyBadge)
		else
			local AnswerTime = 0.15
			CreateScriptcall("Answer_Request", AnswerTime, "Measures/ms_047_AdministrateDiplomacy.lua", "AnswerRequest", "MyBoss", "Destination", Amount)
		end
	elseif resultReq == 2 then
		
		-- please attack my enemy!
		
		local NumOfEnemies = dyn_GetEnemyCounter("MyBoss")
		local EnemyID
		local EnemyButton = ""
		
		if dyn_GetEnemies("MyBoss") == 0 then
			-- you have no enemies!
			MsgBoxNoWait("MyBoss","","@L_GENERAL_ERROR_HEAD_+0","@L_MEASURE_ADMINISTRATE_DIPLOMACY_ERROR_REQUEST_NOENEMIES_+0")
			StopMeasure()
		end
		
		-- my enemies
		local FoundEnemies = 0
		for i=0, NumOfEnemies-1 do
			local FoundID = GetProperty("dynasty","EnemyNo"..i)
			if FoundID > 0 then
				GetAliasByID(FoundID, "EnemyAlias"..i)
				FoundEnemies = FoundEnemies + 1
				EnemyButton = EnemyButton.."@B["..FoundEnemies..","..GetName("EnemyAlias"..i).."]"
				SetData("EnemyNo"..FoundEnemies, "EnemyAlias"..i)
			end
		end
		
		local EnemyResult = MsgBox("MyBoss","Destination","@P"..
							EnemyButton,
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_ATTACK_ENEMY_HEAD_+0",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_ATTACK_ENEMY_BODY_+0", GetID("Destination"))
		
		if EnemyResult == "C" then
			StopMeasure()
		else
			for i=1, FoundEnemies do
				if EnemyResult==i then
					CopyAlias((GetData("EnemyNo"..i)), "EnemyDyn")
					break
				end
			end
		end
		
		if not AliasExists("EnemyDyn") then
			StopMeasure()
		end
		
		local EnemyBadgeID = DynastyGetFlagNumber("EnemyDyn") + 29
		local EnemyBadge = "@L$S[20"..EnemyBadgeID.."]"
		if DynastyIsShadow("EnemyDyn") then
			EnemyBadge = "@L$S[2045]"
		end
		
		-- select a random building for the AI attack
		if not DynastyGetRandomBuilding("EnemyDyn", GL_BUILDING_CLASS_WORKSHOP, -1, "EnemyBuilding") then
			-- no buildings found
			local BossID = dyn_GetValidMember("EnemyDyn")
			GetAliasByID(BossID, "Enemy")
			MsgBoxNoWait("MyBoss", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ERROR_REQUEST_NOBUILDINGS_+0", GetID("Enemy"), EnemyBadge)
			StopMeasure()
		end
		
		-- get the owner or boss
		if not BuildingGetOwner("EnemyBuilding", "Enemy") then
			local BossID = dyn_GetValidMember("EnemyDyn")
			GetAliasByID(BossID, "Enemy")
		end
		
		-- all fine? then set the cooldown
		ms_047_administratediplomacy_RecordDiplo(DestID)
		
		-- Send a message to human players or calc AI reaction
		if DynastyIsPlayer("Destination") then
			MsgNewsNoWait("Destination", "MyBoss", "", "politics", -1,
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_RECEIVE_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_RECEIVE_ATTACK_BUILDING_BODY_+0", GetID("MyBoss"), GetID("EnemyBuilding"), EnemyBadge, MyBadge)
		else
			-- AI reaction
			GetDynasty("Destination", "DesDyn")
			-- for some reason we lose the Alias "MyBoss" at this point so save it to data
			SetData("MyBoss", GetID("MyBoss"))
			
			local BuildingDip = DynastyGetDiplomacyState("Destination", "Enemy")
			local Help = 0
			local EnemySettlement = GetSettlementID("EnemyBuilding")
			local AllySettlement = GetSettlementID("Destination")
			
			-- need same settlement as target
			if EnemySettlement ~= AllySettlement then
				-- get the lost Alias
				local BossID = GetData("MyBoss")
				GetAliasByID(BossID,"MyBoss")
			
				MsgBoxNoWait("MyBoss","Destination",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD_+0",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ATTACK_BUILDING_NO_SETTLEMENT_+0", GetID("Destination"), GetID("EnemyBuilding"))
				StopMeasure()
			end
			
			-- get the lost Alias
			local BossID = GetData("MyBoss")
			GetAliasByID(BossID, "MyBoss")
			
			if BuildingDip == DIP_FOE then
				-- yes
				Help = 1
			elseif BuildingDip >= DIP_NAP then
				-- no cause diplomatics
				MsgNewsNoWait("MyBoss","Destination","","politics",-1,
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ATTACK_BUILDING_NO_DIPLO_+0", GetID("Destination"), GetID("Enemy"))
				StopMeasure()
			else
				if ai_DynastyCalcThreat >=3 then
					-- no, too dangerous
					MsgNewsNoWait("MyBoss", "Destination", "", "politics", -1,
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ATTACK_BUILDING_NO_THREAT_+0", GetID("Destination"), GetID("Enemy"))
					StopMeasure()
				else
					-- yes
					Help = 1
				end
			end
			
			-- check what we can do
			local TotalFound = 0
			local MyrmCount = DynastyGetWorkerCount("DesDyn", GL_PROFESSION_MYRMIDON)
			
			for i=0, MyrmCount-1 do
				if DynastyGetWorker("DesDyn", GL_PROFESSION_MYRMIDON, i, "CHECKME") then
					if SimIsWorkingTime("CHECKME") then
						if GetState("CHECKME", STATE_IDLE) then
							CopyAlias("CHECKME", "MEMBER"..TotalFound )
							TotalFound = TotalFound + 1
						else
							SimStopMeasure("CHECKME")
							CopyAlias("CHECKME", "MEMBER"..TotalFound )
							TotalFound = TotalFound + 1
						end
					end
				end
			end
	
			if TotalFound > 0 then
				Help = 2 -- we can send thugs to bomb it
				local random = Rand(TotalFound)
				if not CopyAlias("MEMBER"..random, "Thug") then
					Help = 1 -- something went wrong
				end
			end
		
			-- ToDO: More possibilities?
			
			-- Send the answer
			if Help == 1 then 
				-- we want to help, but we can't
				MsgNewsNoWait("MyBoss", "EnemyBuilding", "", "politics", -1,
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ATTACK_BUILDING_NO_SORRY_+0", GetID("Destination"), GetID("EnemyBuilding"))
				StopMeasure()
			elseif Help == 2 then
				-- okay, we send a thug to bomb the building.
				if DynastyGetWorker("DesDyn", GL_PROFESSION_MYRMIDON, 0, "Thug") then
					MsgNewsNoWait("MyBoss", "EnemyBuilding", "", "politics", -1,
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ATTACK_BUILDING_YES_BOMB_+0", GetID("Destination"), GetID("EnemyBuilding"))
				else
					-- we want to help, but we can't
					MsgNewsNoWait("MyBoss", "EnemyBuilding", "", "politics", -1,
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ATTACK_BUILDING_NO_SORRY_+0", GetID("Destination"), GetID("EnemyBuilding"))
					StopMeasure()
				end
				
				SimStopMeasure("Thug")
				MeasureRun("Thug", "EnemyBuilding", "OrderASabotage_Bomb")
			end
		end
	end
end

function AnswerRequest(Amount)
	-- only help allies with low money
	GetDynasty("Destination", "DestinationDyn")
	GetDynasty("", "AskerDyn")
	local Money = GetMoney("AskerDyn")
	local Title = GetNobilityTitle("")
	local OurTitle = GetNobilityTitle("Destination")
	
	if Money > Title*3500 then
		MsgNewsNoWait("", "Destination", "", "politics", -1, "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_MONEY_NO_NEED", GetID("Destination"))
		return
	end
	
	-- only send money if we have enough
	if GetMoney("Destination") > 2500*OurTitle then
		-- 66% chance to accept
		if Rand(3) > 0 then
			--yes
			MsgNewsNoWait("", "Destination", "", "politics", -1, "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_MONEY_YES", GetID("Destination"), Amount)
			chr_SpendMoney("Destination", Amount, "CostBribes")
			chr_CreditMoney("", Amount, "IncomeBribes")
			dyn_ModifyFavor("Destination", "", -GL_FAVOR_MOD_SMALL)
		else
			-- no
			MsgNewsNoWait("", "Destination", "", "politics", -1, "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_MONEY_NO", GetID("Destination"))
		end
	else
		-- no
		MsgNewsNoWait("", "Destination", "", "politics", -1, "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_MONEY_NO_LOWMONEY", GetID("Destination"))
	end
end

function RequestEnemies()
	
	-- target badge
	local TargetBadge = dyn_GetFlagLabel("Destination")
	
	-- Do you really want to demand money from the target? You will lose some favor
	local DestID = GetDynastyID("Destination")
	
	if not ms_047_administratediplomacy_CanDiplo(DestID) then
		MsgBoxNoWait("MyBoss","Destination",
				"@L_GENERAL_ERROR_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ERROR_COOLDOWN", GetID("Destination"), TargetBadge)
		StopMeasure()
	end
	
	-- you cant make demands on feud
	local CState = DynastyGetDiplomacyState("Destination", "MyBoss")
	
	if CState == DIP_FOE then
		MsgBoxNoWait("MyBoss", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ERROR_REQUEST_ENEMIES_+0", TargetBadge)
		StopMeasure()
	end
	
	local DesMoney = GetMoney("Destination")
	local ReqFactor = 0.35
	
	-- factor goes down the more money destination has
	if DesMoney > 2500 and DesMoney < 10000 then
		ReqFactor = 0.3
	elseif DesMoney >= 10000 and DesMoney < 20000 then
		ReqFactor = 0.25
	elseif DesMoney >= 20000 and DesMoney < 40000 then
		ReqFactor = 0.2
	elseif DesMoney >= 40000 and DesMoney < 80000 then
		ReqFactor = 0.1
	else
		ReqFactor = 0.05
	end
	
	local ReqMoney = math.floor(DesMoney*ReqFactor)
	local RequestResult = MsgBox("MyBoss", "MyBoss", "@P"..
					"@B[1, @L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
					"@B[C, @L_MEASURE_ORDERCREDIT_STUFF_+4]",
					"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_ENEMIES_HEAD_+0",
					"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_ENEMIES_BODY_+0", GetID("Destination"), ReqMoney, TargetBadge)
					
	if RequestResult == 1 then
		ms_047_administratediplomacy_RecordDiplo(DestID)
		dyn_ModifyFavor("Destination", "MyBoss", (-GL_FAVOR_MOD_NORMAL))
		CreateScriptcall("Answer_RequestEnemies", 0.15, "Measures/ms_047_AdministrateDiplomacy.lua", "AnswerRequestEnemies", "MyBoss", "Destination", ReqMoney)
	else
		StopMeasure()
	end
end

function AnswerRequestEnemies(ReqMoney)
	-- Will the destination pay?
	
	GetDynasty("Destination", "DestinationDyn")
	GetDynasty("", "AskerDyn")
	
	local AskerID = GetID("AskerDyn")
	local IsRival = ai_DynastyCheckForRival("DestinationDyn", "AskerDyn")
	local Threat = ai_DynastyCalcThreat("Destination", "")
	
	-- chance to accept
	local cta = 0
	
	if Threat == 0 then
		cta = 0
	elseif Threat == 1 then
		cta = 20
	elseif Threat == 2 then
		cta = 40
	elseif Threat == 3 then
		cta = 60
	elseif Threat == 4 then
		cta = 80
	end
	
	-- no rival
	if IsRival > 0 then
		MsgNewsNoWait("", "Destination", "", "politics", -1, "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ENEMIES_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ENEMIES_RIVAL", GetID("Destination"))
		dyn_ModifyFavor("Destination", "MyBoss", (-GL_FAVOR_MOD_SMALL)) -- small loss
	else
		if cta > Rand(100) then
			-- accept
			MsgNewsNoWait("", "Destination", "", "politics", -1, "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ENEMIES_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ENEMIES_YES", GetID("Destination"), ReqMoney)
			dyn_ModifyFavor("Destination", "MyBoss", GL_FAVOR_MOD_SMALL) -- small bonus
			chr_SpendMoney("Destination", ReqMoney, "CostBribes")
			chr_CreditMoney("", ReqMoney, "IncomeBribes")
		else
			-- decline
			MsgNewsNoWait("", "Destination", "", "politics", -1, "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ENEMIES_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ENEMIES_NO", GetID("Destination"), ReqMoney)
			dyn_ModifyFavor("Destination", "MyBoss", (-GL_FAVOR_MOD_LARGE)) -- huge loss
		end
	end
end

function ConfirmFeud()
	-- Do you really want to declare war?

	-- target badge
	local TargetBadge = dyn_GetFlagLabel("Destination")
	-- own badge
	local MyBadge = dyn_GetFlagLabel("MyBoss")
	
	local result
	
	if DynastyIsPlayer("") then
		result = MsgBox("MyBoss", "MyBoss", "@P"..
					"@B[1,@L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
					"@B[C,@L_MEASURE_ORDERCREDIT_STUFF_+4]",
					"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CONFIRM_HEAD_+0",
					"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CONFIRM_FOE_BODY_+0", GetID("Destination"), TargetBadge)
	else
		result = 1
	end
		
	if result == 1 then 
		--Yes, declare war
		local DestID = GetDynastyID("Destination")
		ms_047_administratediplomacy_RecordDiplo(DestID) -- count toward the per-day limit
			
		MsgBoxNoWait("MyBoss", "Destination",
					"@LDIPLOMATIC_STATE_CHANGED_HEAD",
					"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CHANGED_FOE_+0", GetID("Destination"), TargetBadge)
						
		if DynastyIsPlayer("Destination") then
			-- send a message to the destination
			MsgNewsNoWait("Destination","MyBoss","","politics",-1,
						"@LDIPLOMATIC_STATE_CHANGED_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CHANGED_FOE_DESTINATION_+0", GetID("MyBoss"), MyBadge)
		end
			
		-- write an answer to the player if destination is AI
		if DynastyIsAI("Destination") and DynastyIsPlayer("MyBoss") then
			local AnswerTime = 0.1
			local Status = "FOE"
			CreateScriptcall("Answer_Diplomacy", AnswerTime, "Measures/ms_047_AdministrateDiplomacy.lua", "AnswerLetter", "MyBoss", "Destination", Status)
		else	
			
			-- set the new status and favor
			dyn_SetDiplomacyState("Destination", "MyBoss", DIP_FOE) -- handles also dyn_RemoveAlly and dyn_AddEnemy 
			DynastyForceCalcDiplomacy("MyBoss")
			SetFavorToDynasty("Destination", "MyBoss", 0)
		end
	else
		StopMeasure()
	end
end

function ConfirmNeutral()
	SetData("Offer", "NEUTRAL")
	local result
	local CState = DynastyGetDiplomacyState("Destination", "MyBoss")
	-- Do you really want a neutral agreement?
	
	-- target badge
	local TargetBadge = dyn_GetFlagLabel("Destination")
	-- own badge
	local MyBadge = dyn_GetFlagLabel("MyBoss")
	
	if DynastyIsPlayer("") then
		result = MsgBox("MyBoss","Destination","@P"..
					"@B[1,@L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
					"@B[C,@L_MEASURE_ORDERCREDIT_STUFF_+4]",
					"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CONFIRM_HEAD_+0",
					"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CONFIRM_NEUTRAL_BODY_+0", GetID("Destination"), TargetBadge)
	else
		result = 1
	end
						
	if result == 1 then
	
		local DestID = GetDynastyID("Destination")
		ms_047_administratediplomacy_RecordDiplo(DestID) -- count toward the per-day limit
		
		-- check if we downgrade the status. No agreement needed then
		if CState > DIP_NEUTRAL then
				
			MsgBoxNoWait("MyBoss", "Destination",
						"@LDIPLOMATIC_STATE_CHANGED_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CHANGED_NEUTRAL_+0", GetID("Destination"), TargetBadge)
								
			if DynastyIsPlayer("Destination") then
				-- send a message to the destination
				MsgNewsNoWait("Destination", "MyBoss", "", "politics", -1,
						"@LDIPLOMATIC_STATE_CHANGED_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CHANGED_NEUTRAL_DESTINATION_+0", GetID("MyBoss"), MyBadge)
			end			
			
			-- write an answer to the player if destination is AI
			if DynastyIsAI("Destination") and DynastyIsPlayer("MyBoss") then
				local Status = "NEUTRAL"
				local AnswerTime = 0.1
				CreateScriptcall("Answer_Diplomacy", AnswerTime, "Measures/ms_047_AdministrateDiplomacy.lua", "AnswerLetter", "MyBoss", "Destination", Status)
			else
				-- set the new status and favor here
				dyn_SetDiplomacyState("Destination", "MyBoss", DIP_NEUTRAL)
				DynastyForceCalcDiplomacy("MyBoss")
				if GetFavorToDynasty("MyBoss", "Destination") > 50 then
					SetFavorToDynasty("MyBoss", "Destination", 50)
				end
			end
		else
		
			-- we need to save the ID here because the MyBoss-Alias gets lost after AIDecision
			SetData("MyBossID", (GetID("MyBoss")))
			SetData("MyDestID", (GetID("Destination")))
			
			-- we have a feud and I want to end it. Hopefully destination agrees
			-- send a message to the destination and ask
			
			local MsgTimeOut = 1 --60sec wait-time to answer
			local DestResult = MsgNews("Destination", "MyBoss",
								"@B[A,@L_FAMILY_2_COHABITATION_BIRTH_BAPTISM_BTN_+1]"..
								"@B[C,@L_ROBBER_134_PRESSPROTECTIONMONEY_ACTION_MSG_VICTIM_BTN_+1]",
								ms_047_administratediplomacy_AIDecision,  --AIFunc
								"politics", --MessageClass
								MsgTimeOut, --TimeOut
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_HEAD_+0",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_NEUTRAL_BODY",
								GetID("MyBoss"), GetID("Destination"), MyBadge)
				
			if DestResult == "C" then
				-- get the saved IDs
				local MyBoss = GetData("MyBossID")
				local Destination = GetData("MyDestID")
				GetAliasByID(MyBoss, "MyBoss")
				GetAliasByID(Destination, "Destination")
				
				--decline
				-- if player declines, he will lose favor
				if DynastyIsPlayer("Destination") then
					dyn_ModifyFavor("Destination", "", -GL_FAVOR_MOD_NORMAL)
				end
			
				local ReasonToDecline = 0
				if HasData("ReasonToDecline") then
					ReasonToDecline = GetData("ReasonToDecline")
				end
						
				if ReasonToDecline == 0 then -- No! I don't like you. This option is always called for players.
					MsgBoxNoWait("MyBoss", "Destination",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_DECLINE_HEAD_+0",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_DECLINE_BODY", GetID("Destination"), TargetBadge)
				elseif ReasonToDecline == 1 then -- I don't fear you
					MsgBoxNoWait("MyBoss", "Destination",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_DECLINE_HEAD_+0",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_DECLINE_NOTHREAT_BODY", GetID("Destination"), TargetBadge)
				elseif ReasonToDecline == 2 then -- I will accept if you listen to my demands
					local ConfirmDemand = MsgBox("MyBoss", "Destination", "@P"..
											"@B[1,@L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
											"@B[C,@L_MEASURE_ORDERCREDIT_STUFF_+4]",
											"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_DECLINE_HEAD_+0",
											"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_DECLINE_DEMAND_BODY", GetID("Destination"), TargetBadge)
					local Status = "NEUTRAL"
				
					if ConfirmDemand == 1 then
						ms_047_administratediplomacy_Demand(Status)
					end
				end
				StopMeasure()
			else
				-- get the saved IDs
				local MyBoss = GetData("MyBossID")
				local Destination = GetData("MyDestID")
				GetAliasByID(MyBoss, "MyBoss")
				GetAliasByID(Destination, "Destination")
				
				--accepted
				MsgBoxNoWait("MyBoss", "Destination",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_ACCEPT_NEUTRAL_HEAD_+0",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_ACCEPT_NEUTRAL_BODY_+0", GetID("Destination"), TargetBadge)
	
				if GetFavorToDynasty("MyBoss","Destination") < 45 then
					SetFavorToDynasty("MyBoss", "Destination", 45)
				end
				
				dyn_SetDiplomacyState("Destination","MyBoss", DIP_NEUTRAL)
				DynastyForceCalcDiplomacy("MyBoss")
			end
		end
	else
		StopMeasure()
	end
end

function ConfirmNAP()
	
	local result
	local CState = DynastyGetDiplomacyState("Destination", "MyBoss")
	SetData("Offer", "NAP")
	-- Do you really want a NAP?
	 
	-- target badge
	local TargetBadge = dyn_GetFlagLabel("Destination")
	-- own badge
	local MyBadge = dyn_GetFlagLabel("MyBoss")
	
	if DynastyIsPlayer("") then
		result = MsgBox("MyBoss", "Destination", "@P"..
				"@B[1,@L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
				"@B[C,@L_MEASURE_ORDERCREDIT_STUFF_+4]",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CONFIRM_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CONFIRM_NAP_BODY_+0", GetID("Destination"), TargetBadge)
	else
		result = 1
	end
						
	if result == 1 then
	
		local DestID = GetDynastyID("Destination")
		ms_047_administratediplomacy_RecordDiplo(DestID) -- count toward the per-day limit
		
		-- check if we downgrade the status. No agreement needed then
		if CState > DIP_NAP then
				
			MsgBoxNoWait("MyBoss", "Destination",
						"@LDIPLOMATIC_STATE_CHANGED_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CHANGED_NAP_+0", GetID("Destination"), TargetBadge)
								
			if DynastyIsPlayer("Destination") then
				-- send a message to the destination
				MsgNewsNoWait("Destination", "MyBoss", "", "politics", -1,
							"@LDIPLOMATIC_STATE_CHANGED_HEAD",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CHANGED_NAP_DESTINATION_+0", GetID("MyBoss"), MyBadge)
			end			
			
			-- write an answer to the player if destination is AI
			if DynastyIsAI("Destination") and DynastyIsPlayer("MyBoss") then
				local Status = "NAP"
				local AnswerTime = 0.1
				CreateScriptcall("Answer_Diplomacy", AnswerTime, "Measures/ms_047_AdministrateDiplomacy.lua", "AnswerLetter", "MyBoss", "Destination", Status)
			else
				-- set the new status and favor here
				dyn_SetDiplomacyState("Destination", "MyBoss", DIP_NAP)
				DynastyForceCalcDiplomacy("MyBoss")
				if GetFavorToDynasty("MyBoss", "Destination") > 60 then
					SetFavorToDynasty("MyBoss", "Destination", 60)
				end
			end
				
		else
			-- send a message to the destination and ask
			
			local VariableMessage -- different messsage if we want to end a feud
			if CState == DIP_FOE then
				VariableMessage = "@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_NAP_BODY"
			else
				VariableMessage = "@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_NAP_BODY"
			end
			
			-- we need to save the ID here because the MyBoss-Alias gets lost after AIDecision
			SetData("MyBossID", (GetID("MyBoss")))
			SetData("MyDestID", (GetID("Destination")))
			
			local MsgTimeOut = 1 --60sec wait-time to answer
			local DestResult = MsgNews("Destination", "MyBoss",
								"@B[A,@L_FAMILY_2_COHABITATION_BIRTH_BAPTISM_BTN_+1]"..
								"@B[C,@L_ROBBER_134_PRESSPROTECTIONMONEY_ACTION_MSG_VICTIM_BTN_+1]",
								ms_047_administratediplomacy_AIDecision,  --AIFunc
								"politics", --MessageClass
								MsgTimeOut, --TimeOut
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_NAP_HEAD_+0",
								VariableMessage,
								GetID("MyBoss"), GetID("Destination"), MyBadge)
				
	
			if DestResult == "C" then
				-- get the saved IDs
				local MyBoss = GetData("MyBossID")
				local Destination = GetData("MyDestID")
				GetAliasByID(MyBoss, "MyBoss")
				GetAliasByID(Destination, "Destination")
				
				--decline
				-- if player declines, he will lose favor
				
				if DynastyIsPlayer("Destination") then
					dyn_ModifyFavor("Destination", "", -GL_FAVOR_MOD_NORMAL)
				end
				
				local ReasonToDecline = 0
				if HasData("ReasonToDecline") then
					ReasonToDecline = GetData("ReasonToDecline")
				end
				
				-- different messages if foe or neutral
				if CState == DIP_FOE then
					if ReasonToDecline == 0 then -- No! I don't like you. This option is always called for players.
						MsgBoxNoWait("MyBoss", "Destination",
									"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_DECLINE_HEAD_+0",
									"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_DECLINE_BODY", GetID("Destination"), TargetBadge)
					elseif ReasonToDecline == 1 then -- I don't fear you
						MsgBoxNoWait("MyBoss", "Destination",
									"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_DECLINE_HEAD_+0",
									"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_DECLINE_NOTHREAT_BODY", GetID("Destination"), TargetBadge)
					else -- I will not accept anything unless you pay me some gold
						local ConfirmDemand = MsgBox("MyBoss", "Destination", "@P"..
											"@B[1,@L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
											"@B[C,@L_MEASURE_ORDERCREDIT_STUFF_+4]",
											"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_DECLINE_HEAD_+0",
											"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_DECLINE_DEMAND_BODY", GetID("Destination"), TargetBadge)
						local Status = "NAP"
				
						if ConfirmDemand == 1 then
							ms_047_administratediplomacy_Demand(Status)
						else
							StopMeasure()
						end
					end
				else
					if ReasonToDecline == 0 then -- No! I don't like you. This option is always called for players.
						MsgBoxNoWait("MyBoss", "Destination",
									"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_NAP_DECLINE_HEAD_+0",
									"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_NAP_DECLINE_BODY", GetID("Destination"), TargetBadge)
					elseif ReasonToDecline == 1 then -- I don't fear you
						MsgBoxNoWait("MyBoss", "Destination",
									"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_NAP_DECLINE_HEAD_+0",
									"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_NAP_DECLINE_NOTHREAT_BODY", GetID("Destination"), TargetBadge)
					else -- I will not accept anything unless you pay me some gold
						local ConfirmDemand = MsgBox("MyBoss", "Destination","@P"..
											"@B[1,@L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
											"@B[C,@L_MEASURE_ORDERCREDIT_STUFF_+4]",
											"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_NAP_DECLINE_HEAD_+0",
											"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_NAP_DECLINE_DEMAND_BODY", GetID("Destination"), TargetBadge)
						local Status = "NAP"
				
						if ConfirmDemand == 1 then
							ms_047_administratediplomacy_Demand(Status)
						end
					end
					StopMeasure()
				end
			else
				--accepted
				
				-- get the saved IDs
				local MyBoss = GetData("MyBossID")
				local Destination = GetData("MyDestID")
				GetAliasByID(MyBoss, "MyBoss")
				GetAliasByID(Destination, "Destination")
				
				-- different messages if current state was feud
				if CState == DIP_FOE then
					MsgBoxNoWait("MyBoss", "Destination",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_ACCEPT_NAP_HEAD_+0",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ENDFEUD_ACCEPT_NAP_BODY_+0", GetID("Destination"), TargetBadge)
				else
					MsgBoxNoWait("MyBoss", "Destination",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_NAP_ACCEPT_HEAD_+0",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_NAP_ACCEPT_BODY", GetID("Destination"), TargetBadge)
				end
			
				if GetFavorToDynasty("MyBoss", "Destination") <50 then
					SetFavorToDynasty("MyBoss", "Destination", 50)
				end
				
				dyn_SetDiplomacyState("Destination", "MyBoss", DIP_NAP)
				DynastyForceCalcDiplomacy("MyBoss")
			end
		end
	else	
		StopMeasure()
	end
end

function ConfirmAlliance()
	local CState = DynastyGetDiplomacyState("Destination", "MyBoss")
	local result
	SetData("Offer", "ALLIANCE")
	-- Do you really want an Alliance?
	 
	-- target badge
	local TargetBadge = dyn_GetFlagLabel("Destination")
	-- own badge
	local MyBadge = dyn_GetFlagLabel("MyBoss")
	
	if DynastyIsPlayer("") then
		result = MsgBox("MyBoss", "Destination", "@P"..
				"@B[1,@L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
				"@B[C,@L_MEASURE_ORDERCREDIT_STUFF_+4]",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CONFIRM_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_CONFIRM_ALLIANCE_BODY_+0", GetID("Destination"), TargetBadge)
	else
		result = 1
	end
						
	if result == 1 then
		
		local DestID = GetDynastyID("Destination")
		ms_047_administratediplomacy_RecordDiplo(DestID) -- count toward the per-day limit
		
		-- send a message to the destination and ask
		
		-- we need to save the ID here because the MyBoss-Alias gets lost after AIDecision
		SetData("MyBossID", (GetID("MyBoss")))
		SetData("MyDestID", (GetID("Destination")))
		
		local MsgTimeOut = 1 --60sec wait-time to answer
		local DestResult = MsgNews("Destination", "MyBoss",
							"@B[A,@L_FAMILY_2_COHABITATION_BIRTH_BAPTISM_BTN_+1]"..
							"@B[C,@L_ROBBER_134_PRESSPROTECTIONMONEY_ACTION_MSG_VICTIM_BTN_+1]",
							ms_047_administratediplomacy_AIDecision,  --AIFunc
							"politics", --MessageClass
							MsgTimeOut, --TimeOut
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_HEAD_+0",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_BODY",
							GetID("MyBoss"), GetID("Destination"), MyBadge)
	
		if DestResult == "C" then
			--decline
			-- get the saved IDs
				local MyBoss = GetData("MyBossID")
				local Destination = GetData("MyDestID")
				GetAliasByID(MyBoss, "MyBoss")
				GetAliasByID(Destination, "Destination")
				
			-- if player declines, he will lose favor
				
			if DynastyIsPlayer("Destination") then
				dyn_ModifyFavor("Destination", "", -GL_FAVOR_MOD_NORMAL)
			end
				
			local ReasonToDecline = 0
			if HasData("ReasonToDecline") then
				ReasonToDecline = GetData("ReasonToDecline")
			end
				
			if ReasonToDecline == 0 then -- No! I don't like you. This option is always called for players.
				MsgBoxNoWait("MyBoss", "Destination",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_DECLINE_HEAD_+0",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_DECLINE_BODY", GetID("Destination"), TargetBadge)
			elseif ReasonToDecline == 1 then -- I don't fear you
				MsgBoxNoWait("MyBoss","Destination",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_DECLINE_HEAD_+0",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_DECLINE_NOTHREAT_BODY", GetID("Destination"), TargetBadge)
			elseif ReasonToDecline == 3 then -- You are a rival, i will not ally with you
				GetDynasty("MyBoss", "MyDyn")
				GetDynasty("Destination", "DestDyn")
				local RivalID = 0
				if HasData("RivalID") then
					RivalID = GetData("RivalID")
				else
					RivalID = ai_DynastyCheckForRival("DestDyn", "MyDyn")
				end
				GetAliasByID(RivalID, "RivalAlias")
				
				if IsType("RivalAlias", "Sim") then -- political ambitions
					
					MsgBoxNoWait("MyBoss", "Destination",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_DECLINE_HEAD_+0",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_DECLINE_RIVAL_SIM_BODY", GetID("Destination"), RivalID, TargetBadge)
				else -- same building
					MsgBoxNoWait("MyBoss","Destination",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_DECLINE_HEAD_+0",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_DECLINE_RIVAL_BUILDING_BODY", GetID("Destination"), RivalID, TargetBadge)
				end
			else -- I will not accept anything unless you pay me some gold
				local ConfirmDemand = MsgBox("MyBoss", "Destination", "@P"..
										"@B[1,@L_MEASURE_TAKEOVERBID_BUTTON_YES_+0]"..
										"@B[C,@L_MEASURE_ORDERCREDIT_STUFF_+4]",
										"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_DECLINE_HEAD_+0",
										"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_DECLINE_DEMAND_BODY", GetID("Destination"), TargetBadge)
				local Status = "ALLIANCE"
				
				if ConfirmDemand == 1 then
					ms_047_administratediplomacy_Demand(Status)
				end
			end
			StopMeasure()
		else
			-- get the saved IDs
				local MyBoss = GetData("MyBossID")
				local Destination = GetData("MyDestID")
				GetAliasByID(MyBoss, "MyBoss")
				GetAliasByID(Destination, "Destination")
				
			--accepted
			MsgBoxNoWait("MyBoss", "Destination",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_ACCEPT_HEAD_+0",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_ALLIANCE_ACCEPT_BODY", GetID("Destination"), TargetBadge)
	
			if GetFavorToDynasty("MyBoss", "Destination") < 75 then
				SetFavorToDynasty("MyBoss", "Destination", 75)
			end
			
			dyn_SetDiplomacyState("Destination", "MyBoss", DIP_ALLIANCE)
			DynastyForceCalcDiplomacy("MyBoss")
			StopMeasure()
		end
	else
		StopMeasure()
	end
end

function AIDecision()
	-- Is the AI going to accept my offer?
	--LogMessage("Self is "..GetName(""))
	--LogMessage("MyBoss is "..GetName("MyBoss"))
	--LogMessage("Destination is "..GetName("Destination"))
	local CState = DynastyGetDiplomacyState("Destination", "MyBoss")
	local OfferedState = GetData("Offer")
	
	if not GetDynasty("Destination", "DestinationDyn") then
		return "A"
	end
	
	if not GetDynasty("MyBoss", "AskerDyn") then
		return "A"
	end
	
	local DesiredState = ai_DynastyGetBestDiplomacyState("Destination", "MyBoss")
	local CurrentFavor = GetFavorToDynasty("AskerDyn", "DestinationDyn")
	local MinFavor = 0
	local IsRival = ai_DynastyCheckForRival("DestinationDyn", "AskerDyn")
	local RivalAllowed = true
	local Threat = ai_DynastyCalcThreat("Destination", "MyBoss")
	local MinThreat = 0
	
	if not AliasExists("Destination") then
		LogMessage("Diplomacy: Destination missing")
	end
	
	if not AliasExists("MyBoss") then
		LogMessage("Diplomacy: MyBoss missing")
	end
	
	if OfferedState == "ALLIANCE" then
		MinFavor = 70
		MinThreat = 2
		RivalAllowed = false
	elseif OfferedState == "NAP" then
		MinFavor = 45
		MinThreat = 1
	elseif OfferedState == "NEUTRAL" then
		MinFavor = 35
		MinThreat = 0
	end
	
	if OfferedState == DesiredState then
		return "A" --yes
	elseif OfferedState == "NEUTRAL" and DesiredState == "NAP" then
		return "A"
	else 
		if RivalAllowed or IsRival == 0 then
			if CurrentFavor >= MinFavor then
				if DesiredState ~= "ALLIANCE" then -- special thoughts about alliances
					if CurrentFavor < 90 then
						if Threat >= MinThreat then
							SetData("ReasonToDecline", 2) -- I will make a demand
							return "C" -- no
						else
							SetData("ReasonToDecline", 1) -- You are not dangerous enough
							return "C"
						end
					else
						return "A" -- okay, we have an friendship already, let's make it official
					end
				else
					if Threat >= MinThreat then
						SetData("ReasonToDecline", 2) -- I will make a demand
						return "C" -- no
					else
						SetData("ReasonToDecline", 1) -- You are not dangerous enough
						return "C"
					end
				end
			else
				SetData("ReasonToDecline", 0) -- I don't like you
				return "C" -- no
			end
		else
			SetData("RivalID", IsRival)
			SetData("ReasonToDecline", 3) -- rival
			return "C" -- no 
		end
	end
end

function AnswerLetter(NewState)
	-- You downgraded our relation. Our reaction is either positive (1) or negative (2). This is purely RP though
	
	GetDynasty("Destination", "DynastyAlias")
	GetDynasty("", "MyDyn")
	
	local CState = DynastyGetDiplomacyState("Destination", "")
	local Reaction = 0
	local DipStatus
	local MinFavor = 0
	local MaxFavor = 0
	local CurrentFavor = GetFavorToDynasty("MyDyn", "DynastyAlias")
	
	if NewState == "FOE" then
		DipStatus = DIP_FOE
	elseif NewState == "NEUTRAL" then
		DipStatus = DIP_NEUTRAL
		MinFavor = 35
		MaxFavor = 50
	elseif NewState == "NAP" then
		DipStatus = DIP_NAP
		MinFavor = 45
		MaxFavor = 60
	end
	
	if ai_DynastyGetBestDiplomacyState("DynastyAlias","MyDyn") == NewState then
		Reaction = 1 -- positive reaction
	else
		Reaction = 2 -- negative reaction
	end
	
	-- set the new status and favor here
	dyn_SetDiplomacyState("", "Destination", DipStatus)
	DynastyForceCalcDiplomacy("")

	if CurrentFavor < MinFavor then
		SetFavorToDynasty("MyDyn", "DynastyAlias", MinFavor)
	elseif CurrentFavor > MaxFavor then
		SetFavorToDynasty("MyDyn", "DynastyAlias", MaxFavor)
	end
	
	if NewState == "FOE" then
		if Reaction == 1 then
			MsgNewsNoWait("", "Destination", "", "politics", -1, "@LDIPLOMATIC_STATE_CHANGED_HEAD", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_FOE_POSITIVE", GetID("MyBoss"))
		else
			MsgNewsNoWait("", "Destination", "", "politics", -1, "@LDIPLOMATIC_STATE_CHANGED_HEAD", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_FOE_NEGATIVE", GetID("MyBoss"))
		end
	elseif NewState == "NEUTRAL" then
		if Reaction == 1 then
			MsgNewsNoWait("", "Destination", "", "politics", -1, "@LDIPLOMATIC_STATE_CHANGED_HEAD", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_NEUTRAL_POSITIVE", GetID("MyBoss"))
		else
			MsgNewsNoWait("", "Destination", "", "politics", -1, "@LDIPLOMATIC_STATE_CHANGED_HEAD", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_NEUTRAL_NEGATIVE", GetID("MyBoss"))
		end
	elseif NewState == "NAP" then
		if Reaction == 1 then
			MsgNewsNoWait("", "Destination", "", "politics", -1, "@LDIPLOMATIC_STATE_CHANGED_HEAD", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_NAP_POSITIVE", GetID("MyBoss"))
		else
			MsgNewsNoWait("", "Destination", "", "politics", -1, "@LDIPLOMATIC_STATE_CHANGED_HEAD", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_NAP_NEGATIVE", GetID("MyBoss"))
		end
	end
end

function Demand(RequestedState)
	-- to end our feud we demand you to...
	
	-- get the saved IDs
	local MyBoss = GetData("MyBossID")
	local Destination = GetData("MyDestID")
	GetAliasByID(MyBoss, "MyBoss")
	GetAliasByID(Destination, "Destination")
	
	local CState = DynastyGetDiplomacyState("Destination", "MyBoss")
	
	local MoneyToPay = 0
	local MyCash = GetMoney("MyBoss")
	local DestCash = GetMoney("Destination")
	local HasEnemy = 0
	local NewDip
	
	local MinFavor = 0
	local MaxFavor = 0
	
	if RequestedState == "NEUTRAL" then
		MoneyToPay = 2500 + (math.floor(DestCash*0.1)) + (math.floor(MyCash*0.05))
		NewDip = DIP_NEUTRAL
		MinFavor = 30
		MaxFavor = 50
			
	elseif RequestedState == "NAP" then
		MoneyToPay = 5000 + (math.floor(DestCash*0.1)) + (math.floor(MyCash*0.05))
		if DynastyGetDiplomacyState("MyBoss","Destination") == DIP_FOE then
			MoneyToPay = MoneyToPay*2
		end
		NewDip = DIP_NAP
		MinFavor = 40
		MaxFavor = 60
		
	elseif RequestedState == "ALLIANCE" then
		MoneyToPay = 7500 + (math.floor(DestCash*0.2)) + (math.floor(MyCash*0.1))
		NewDip = DIP_ALLIANCE
		MinFavor = 75
		MaxFavor = 100
	end
	
	-- alternative make war with my enemy
	
	-- get all relevant dynasties and data
	
	local DesEnemyCounter = dyn_GetEnemyCounter("Destination")
	
	GetDynasty("MyBoss", "MyDyn")
	GetDynasty("Destination", "DestDyn")
	
	local MyCityID = GetSettlementID("MyBoss")
	local CurrentFavor = GetFavorToDynasty("MyBoss", "DestDyn")
	
	-- check all enemies of Destination and see if MyBoss can help
	for i=1, DesEnemyCounter do
		if HasProperty("DestDyn", "EnemyNo"..i) and GetProperty("DestDyn", "EnemyNo"..i) > 0 then
			local FoundID = GetProperty("DestDyn", "Enemy"..i)
			if GetAliasByID(FoundID, "EnemyDyn") then
				local BossID = dyn_GetValidMember("EnemyDyn")
				if GetAliasByID(BossID, "EnemyBoss") then
					if DynastyGetDiplomacyState("MyDyn", "EnemyDyn") < DIP_NAP then
						if GetSettlementID("EnemyBoss") == MyCityID then
							-- calc threat-level. 2/3/4 means we need assistance
							if ai_DynastyCalcThreat("Destination", "EnemyBoss") >= 2 then
								CopyAlias("EnemyBoss", "EnemyAlias")
								break
							end
						end
					end
				end
			end
		end
	end
	
	if AliasExists("EnemyAlias") then
		HasEnemy = 1
		SetData("DemandEnemy", (GetID("EnemyAlias")))
	end
	
	if HasEnemy == 0 then
		-- No enemy, we want money
		local accept = MsgBox("MyBoss", "Destination", "@P"..
						"@B[1,@L_FAMILY_2_COHABITATION_BIRTH_BAPTISM_BTN_+1]"..
						"@B[C,@L_ROBBER_134_PRESSPROTECTIONMONEY_ACTION_MSG_VICTIM_BTN_+1]",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_MESSAGE_HEAD_+0",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_MESSAGE_"..RequestedState.."_BODY",
						GetID("Destination"), MoneyToPay)
		
		if accept == "C" then
			StopMeasure()
		elseif accept == 1 then
			if GetMoney("MyBoss") >= MoneyToPay then
				chr_SpendMoney("MyBoss", MoneyToPay, "CostBribes")
				chr_CreditMoney("Destination", MoneyToPay, "IncomeBribes")
				
				-- set the new status and favor here
				dyn_SetDiplomacyState("MyBoss", "Destination", NewDip)
				DynastyForceCalcDiplomacy("MyBoss")

				if CurrentFavor < MinFavor then
					SetFavorToDynasty("MyBoss","DestDyn", MinFavor)
				elseif CurrentFavor > MaxFavor then
					SetFavorToDynasty("MyBoss","DestDyn", MaxFavor)
				end
				
				MsgBoxNoWait("MyBoss", "Destination",
						"@LDIPLOMATIC_STATE_CHANGED_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_CHANGED_"..RequestedState.."_+0", GetID("Destination"))
			else
				MsgBoxNoWait("MyBoss", "Destination",
						"@LDIPLOMATIC_DEMAND_FAILED_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_FAILED_BODY_+0", GetID("Destination"))
				StopMeasure()
			end
		end
	else	
		-- you can make war with our enemy or pay us the gold
		local Choice = MsgBox("MyBoss","EnemyAlias","@P"..
							"@B[1,@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_MESSAGE_CHOICE_MONEY]"..
							"@B[2,@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_MESSAGE_CHOICE_WAR]"..
							"@B[C,@L_ROBBER_134_PRESSPROTECTIONMONEY_ACTION_MSG_VICTIM_BTN_+1]",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_MESSAGE_HEAD_+0",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_MESSAGE_CHOICE_BODY",
							GetID("Destination"), MoneyToPay, GetID("EnemyAlias"))
		
		if Choice == "C" then
			StopMeasure()
		elseif Choice == 1 then
			if GetMoney("MyBoss") >= MoneyToPay then
				chr_SpendMoney("MyBoss", MoneyToPay, "CostBribes")
				chr_CreditMoney("Destination", MoneyToPay, "IncomeBribes")
				
				-- set the new status and favor here
				dyn_SetDiplomacyState("MyBoss", "DestDyn", NewDip)
				DynastyForceCalcDiplomacy("MyBoss")
				
				if CurrentFavor < MinFavor then
					SetFavorToDynasty("MyBoss", "DestDyn", MinFavor)
				elseif CurrentFavor > MaxFavor then
					SetFavorToDynasty("MyBoss", "DestDyn", MaxFavor)
				end
				
				MsgBoxNoWait("MyBoss", "Destination",
						"@LDIPLOMATIC_STATE_CHANGED_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_CHANGED_"..RequestedState.."_+0", GetID("Destination"))
			else
				MsgBoxNoWait("MyBoss", "Destination",
						"@LDIPLOMATIC_DEMAND_FAILED_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_FAILED_BODY_+0", GetID("Destination"))
				StopMeasure()
			end
		elseif Choice == 2 then
			-- set the new status and favor here
			dyn_SetDiplomacyState("MyDyn", "DestDyn", NewDip)

			if CurrentFavor < MinFavor then
				SetFavorToDynasty("MyDyn", "DestDyn", MinFavor)
			elseif CurrentFavor > MaxFavor then
				SetFavorToDynasty("MyDyn", "DestDyn", MaxFavor)
			end
			
			-- set the favor to the enemy
			SetFavorToDynasty("EnemyAlias", "MyDyn", 0)
			dyn_SetDiplomacyState("MyDyn", "EnemyAlias", DIP_FOE)
			DynastyForceCalcDiplomacy("MyDyn")
			
			if DynastyIsPlayer("EnemyAlias") then
				-- send a message to the enemy
				MsgNewsNoWait("EnemyAlias", "MyBoss", "", "politics", -1,
						"@LDIPLOMATIC_STATE_CHANGED_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_CHANGED_FOE_DESTINATION_WAR_+0", GetID("MyBoss"), GetID("Destination"))
			end
			
			MsgBoxNoWait("MyBoss", "Destination",
						"@LDIPLOMATIC_STATE_CHANGED_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_MESSAGE_ACCEPTED_WAR_FOR_"..RequestedState.."_+0", GetID("EnemyAlias"), GetID("Destination"))
			StopMeasure()
		else
			StopMeasure()
		end
	end
end

function SpecialCheck()
	-- get infos
	
	-- target badge
	local TargetBadge = dyn_GetFlagLabel("Destination")
	
	local MyDynID = GetID("dynasty")
	
	local Enemies = dyn_GetEnemies("Destination") or 0
	local Allies =  dyn_GetAllies("Destination") or 0
	local IsRival = ai_DynastyCheckForRival("TargetDyn", "dynasty") or 0
	local Grudges = GetProperty("TargetDyn", "Fondness"..MyDynID) or 0
	local Fondness = GetProperty("TargetDyn", "Grudge"..MyDynID) or 0
	local Counter = 0
	local Threat = ai_DynastyCalcThreat("Destination", "MyBoss") or 0
	local Favor = GetFavorToDynasty("MyBoss", "Destination")
	local State = DynastyGetDiplomacyState("Destination", "MyBoss")
	local Label = ""
	
	if Grudges > Fondness then
		Counter = Grudges
	elseif Fondness > Grudges then
		Counter = Fondness
	end
	
	if State == 0 then
		Label = "@LHostility"
	elseif State == 1 then
		Label = "@LNeutral"
	elseif State == 2 then
		Label = "@LNAP"
	else
		Label = "@LAlliance"
	end
		
	local GrudgeLabel = "@L_MEASURE_ADMINISTRATE_DIPLOMACY_SPECIAL_LABEL_GRUDGE_+0"
	if Fondness > 0 then
		GrudgeLabel = "@L_MEASURE_ADMINISTRATE_DIPLOMACY_SPECIAL_LABEL_FONDNESS_+0"
	end
	
	local ThreatLabel = "@L_MEASURE_ADMINISTRATE_DIPLOMACY_SPECIAL_LABEL_THREAT_+"..Threat
	local RivalLabel = "@L_MEASURE_ADMINISTRATE_DIPLOMACY_SPECIAL_LABEL_RIVAL_+0"
	
	if IsRival > 0 then
		GetAliasByID(IsRival, "ReasonRival")
		if IsType("ReasonRival", "Sim") then
			RivalLabel = "@L_MEASURE_ADMINISTRATE_DIPLOMACY_SPECIAL_LABEL_RIVAL_+1"
		else
			RivalLabel = "@L_MEASURE_ADMINISTRATE_DIPLOMACY_SPECIAL_LABEL_RIVAL_+2"
		end
	else
		CopyAlias("Destination", "ReasonRival") -- this is only for parsing
	end
	
	MsgBoxNoWait("dynasty", "Destination", 
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_SPECIAL_+0", 
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_SPECIAL_BODY_+0", GetID("Destination"), TargetBadge, Favor, Enemies, Allies, GrudgeLabel, Counter, ThreatLabel, RivalLabel, GetID("ReasonRival"), Label)
end

function CleanUp()
end
