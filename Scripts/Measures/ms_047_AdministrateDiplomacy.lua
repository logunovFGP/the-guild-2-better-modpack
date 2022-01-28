-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_AdministrateDiplomacy.lua"
----
----	With this measure the player can change the diplomatic status, 
----	can make requests, demands, gifts or send diplomatic messages
----
----	This measure has been greatly reworked by Fajeth
----
----	Note: AI will use scriptcalls instead, using the 
----	AI scripts found in: ac_AdministrateDiplomacy.lua
-------------------------------------------------------------------------------

function Init() -- this is called before Run

	-- We need the Owner because this measure is now a building-measure
	if not BuildingGetOwner("", "MyBoss") then
		MsgBoxNoWait("dynasty", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_MEASURE_ADMINISTRATE_DIPLOMACY_NOOWNER_BODY_+0")
		return false
	end
	
	if not AliasExists("Destination") then
		StopMeasure()
	end

	if DynastyIsPlayer("") then
		-- your badge
		local BadgeID = DynastyGetFlagNumber("dynasty") + 29
		local Badge = "@L$S[20"..BadgeID.."]"
		
		-- First we need to choose what we want to do
		local Selection = MsgBox("MyBoss", "Destination", "@P"..
								"@B[1,@L_MEASURE_ADMINISTRATE_DIPLOMACY_STATUS_+0]"..
								"@B[6,@L_MEASURE_ADMINISTRATE_DIPLOMACY_SPECIAL_+0]"..
								"@B[2,@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_+0]"..
								"@B[4,@L_MEASURE_ADMINISTRATE_DIPLOMACY_DEMAND_+0]"..
								"@B[3,@L_MEASURE_ADMINISTRATE_DIPLOMACY_GIFT_+0]"..
								"@B[5,@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_+0]",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_SELECTION_HEAD_+0",
								"@L_MEASURE_ADMINISTRATE_DIPLOMACY_SELECTION_BODY_+0", GetID("Destination"), Badge)
	
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
				ms_administratediplomacy_Status()
			end
			
			-- confirm your choice
			result = GetData("InitResult")
			if result == 0 then -- feud
				ms_administratediplomacy_ConfirmFeud()
			elseif result == 1 then -- neutral
				ms_administratediplomacy_ConfirmNeutral()
			elseif result == 2 then -- NAP
				ms_administratediplomacy_ConfirmNAP()
			elseif result == 3 then -- Alliance
				ms_administratediplomacy_ConfirmAlliance()
			end
		end
		
	elseif Selection == 2 then -- message to raise/lower favor (not with enemies)
		ms_administratediplomacy_Message()
	elseif Selection == 3 then -- gift for allies
		ms_administratediplomacy_Gift()
	elseif Selection == 4 then -- demand for non-allies
		ms_administratediplomacy_RequestEnemies()
	elseif Selection == 5 then -- request for allies
		ms_administratediplomacy_RequestAllies()
	elseif Selection == 6 then -- check for grudges and fondness
		ms_administratediplomacy_SpecialCheck()
	end
end

function Status()
	-- Change the status
	
	-- target badge
	local TargetBadgeID = DynastyGetFlagNumber("TargetDyn") + 29
	local TargetBadge = "@L$S[20"..BadgeID.."]"
	
	-- timout for changing status multiple times
	local DestID = GetDynastyID("Destination")
	if not ReadyToRepeat("dynasty", "DIP_"..DestID) then
		MsgBoxNoWait("MyBoss", "Destination",
				"@L_GENERAL_ERROR_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ERROR_COOLDOWN", GetID("Destination"), TargetBadge)
		StopMeasure()
	end
	
	local CState = DynastyGetDiplomacyState("Destination","MyBoss")
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

	local result = InitData("@P"..Buttons, 1,"@LAdministrateDiplomacySheet", "")
	
	if result == "C" then
		StopMeasure()
	end
	
	SetRepeatTimer("dynasty", "DIP_"..DestID, 20) -- wait 20 hours for the next
	SetData("InitResult", result)
end

function Message()
	-- send a message to gain or reduce favor
	
	-- target badge
	local TargetBadgeID = DynastyGetFlagNumber("TargetDyn") + 29
	local TargetBadge = "@L$S[20"..BadgeID.."]"
	-- own badge
	local BadgeID = DynastyGetFlagNumber("dynasty") + 29
	local Badge = "@L$S[20"..BadgeID.."]"
	
	-- timout for multiple messages
	local DestID = GetDynastyID("Destination")
	if not ReadyToRepeat("dynasty", "DIP_"..DestID) then
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
	
	SetRepeatTimer("dynasty", "DIP_"..DestID, 20)
	dyn_ModifyFavor("MyBoss", "Destination", (Favor)) -- use dyn_ModifyFavor because there's no animations
	MsgBoxNoWait("MyBoss", "Destination",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_"..ResultLabel.."_SEND_"..RhetLabel, GetID("Destination"), TargetBadge)
					
	-- Message the destination
	MsgNewsNoWait("Destination","MyBoss","","politics",-1,
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_RECEIVE_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_MESSAGE_"..ResultLabel.."_RECEIVE_"..RhetLabel, GetID("MyBoss"), Badge)
end

function Gift()
	
	-- target badge
	local TargetBadgeID = DynastyGetFlagNumber("TargetDyn") + 29
	local TargetBadge = "@L$S[20"..BadgeID.."]"
	-- own badge
	local BadgeID = DynastyGetFlagNumber("dynasty") + 29
	local Badge = "@L$S[20"..BadgeID.."]"
	
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
	CreditMoney("Destination", Amount, "IncomeBribes")
	
	-- message to the destination
	MsgNewsNoWait("Destination", "MyBoss", "", "politics", -1,
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_GIFT_RECEIVE_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_GIFT_RECEIVE_BODY", GetID("MyBoss"), Amount, Badge)
		
	if DynastyIsAI("Destination") then
		-- reaction for AI
		local AnswerTime = 0.1
		CreateScriptcall("Answer_Gift", AnswerTime, "Measures/ms_AdministrateDiplomacy.lua", "AnswerGift", "MyBoss", "Destination", Amount, TargetBadge)
	end
end

function AnswerGift(Amount)
	-- AI sends a message depending on how useful the gift is
	
	-- target badge
	GetDynasty("Destination", "TargetDyn")
	local TargetBadgeID = DynastyGetFlagNumber("TargetDyn") + 29
	local TargetBadge = "@L$S[20"..BadgeID.."]"
	
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
	local TargetBadgeID = DynastyGetFlagNumber("TargetDyn") + 29
	local TargetBadge = "@L$S[20"..BadgeID.."]"
	-- own badge
	local BadgeID = DynastyGetFlagNumber("dynasty") + 29
	local Badge = "@L$S[20"..BadgeID.."]"
	
	local DestID = GetDynastyID("Destination")
	local resultReq
	
	if not ReadyToRepeat("dynasty", "DIP_"..DestID) then
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
		SetRepeatTimer("dynasty", "DIP_"..DestID, 20)
		-- Can I have some money?
		MsgBoxNoWait("MyBoss","Destination","@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_MONEY_BTN_+0","@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_MONEY_BODY_+0",GetID("Destination"))
	
		-- message to the destination if player
		if DynastyIsPlayer("Destination") then
			MsgNewsNoWait("Destination","MyBoss","","politics",-1,
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_RECEIVE_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_RECEIVE_MONEY_BODY_+0",GetID("MyBoss"))
		else
			local AnswerTime = 0.15
			CreateScriptcall("Answer_Request",AnswerTime,"Measures/ms_AdministrateDiplomacy.lua","AnswerRequest","MyBoss","Destination",Amount)
		end
	elseif resultReq == 2 then
		
		-- please attack my enemy!
		
		local NumOfEnemies = f_DynastyGetNumOfEnemies("MyBoss")
		local EnemyID
		local EnemyButton = ""
		
		if NumOfEnemies == 0 then
			-- you have no enemies!
			MsgBoxNoWait("MyBoss","","@L_GENERAL_ERROR_HEAD_+0","@L_MEASURE_ADMINISTRATE_DIPLOMACY_ERROR_REQUEST_NOENEMIES_+0")
			StopMeasure()
		end
		
		-- my enemies
		for i=0, NumOfEnemies-1 do
			local FoundID = GetProperty("dynasty","Enemy_"..i)
			GetAliasByID(FoundID,"EnemyAlias_"..i)
			EnemyButton = EnemyButton.."@B["..i..","..GetName("EnemyAlias_"..i).."]"
			SetData("Enemy_"..i,"EnemyAlias_"..i)
		end
		
		local EnemyResult = MsgBox("MyBoss","Destination","@P"..
				EnemyButton,
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_ATTACK_ENEMY_HEAD_+0",
				"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_ATTACK_ENEMY_BODY_+0",GetID("Destination"))
		
		if EnemyResult == "C" then
			StopMeasure()
		else
			for i=0, NumOfEnemies-1 do
				if EnemyResult==i then
					CopyAlias((GetData("Enemy_"..i)),"EnemyDyn")
					break
				end
			end
		end
		
		if not AliasExists("EnemyDyn") then
			StopMeasure()
		end
		
		-- select a random building for the AI attack
		if not DynastyGetRandomBuilding("EnemyDyn",2,-1,"EnemyBuilding") then
			-- no buildings found
			local BossID = dyn_GetValidMember("EnemyDyn")
			GetAliasByID(BossID, "Enemy")
			MsgBoxNoWait("MyBoss","","@L_GENERAL_ERROR_HEAD_+0","@L_MEASURE_ADMINISTRATE_DIPLOMACY_ERROR_REQUEST_NOBUILDINGS_+0",GetID("Enemy"))
			StopMeasure()
		end
		
		-- get the owner or boss
		
		if not BuildingGetOwner("EnemyBuilding","Enemy") then
			local BossID = dyn_GetValidMember("EnemyDyn")
			GetAliasByID(BossID, "Enemy")
		end
		
		-- all fine? then set the cooldown
		SetRepeatTimer("dynasty", "DIP_"..DestID, 20)
		
		-- Send a message to human players or calc AI reaction
		if DynastyIsPlayer("Destination") then
			MsgNewsNoWait("Destination","MyBoss","","politics",-1,
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_RECEIVE_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_REQUEST_RECEIVE_ATTACK_BUILDING_BODY_+0",GetID("MyBoss"),GetID("EnemyBuilding"))
		else
			-- AI reaction
			GetDynasty("Destination","DesDyn")
			-- for some reason we lose the Alias "MyBoss" at this point so save it to data
			SetData("MyBoss",GetID("MyBoss"))
			
			local BuildingDip = DynastyGetDiplomacyState("Destination","Enemy")
			local ThreatEnemy =  ai_DynastyCalcThreat("DesDyn","EnemyDyn")
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
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ATTACK_BUILDING_NO_SETTLEMENT_+0",GetID("Destination"),GetID("EnemyBuilding"))
				StopMeasure()
			end
			
			-- get the lost Alias
			local BossID = GetData("MyBoss")
			GetAliasByID(BossID,"MyBoss")
			
			if BuildingDip == DIP_FOE then
				-- yes
				Help = 1
			elseif BuildingDip >=DIP_NAP then
				-- no cause diplomatics
				MsgNewsNoWait("MyBoss","Destination","","politics",-1,
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ATTACK_BUILDING_NO_DIPLO_+0",GetID("Destination"),GetID("Enemy"))
				StopMeasure()
			else
				if ThreatEnemy >= 3 then
					-- no, too dangerous
					MsgNewsNoWait("MyBoss","Destination","","politics",-1,
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ATTACK_BUILDING_NO_THREAT_+0",GetID("Destination"),GetID("Enemy"))
					StopMeasure()
				else
					-- yes
					Help = 1
				end
			end
			
			-- check what we can do
			local TotalFound = 0
			local MyrmCount = DynastyGetWorkerCount("DesDyn", GL_PROFESSION_MYRMIDON)
			
			for i=0,MyrmCount-1 do
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
	
			if TotalFound >0 then
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
				MsgNewsNoWait("MyBoss","EnemyBuilding","","politics",-1,
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ATTACK_BUILDING_NO_SORRY_+0",GetID("Destination"),GetID("EnemyBuilding"))
				StopMeasure()
			elseif Help == 2 then
				-- okay, we send a thug to bomb the building.
				if DynastyGetWorker("DesDyn", GL_PROFESSION_MYRMIDON,0,"Thug") then
					MsgNewsNoWait("MyBoss","EnemyBuilding","","politics",-1,
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD",
							"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ATTACK_BUILDING_YES_BOMB_+0",GetID("Destination"),GetID("EnemyBuilding"))
				else
					-- we want to help, but we can't
					MsgNewsNoWait("MyBoss","EnemyBuilding","","politics",-1,
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_HEAD",
						"@L_MEASURE_ADMINISTRATE_DIPLOMACY_ANSWER_REQUEST_ATTACK_BUILDING_NO_SORRY_+0",GetID("Destination"),GetID("EnemyBuilding"))
					StopMeasure()
				end
				
				SimStopMeasure("Thug")
				MeasureRun("Thug", "EnemyBuilding", "OrderASabotage_Bomb")
			end
		end
	end
end

