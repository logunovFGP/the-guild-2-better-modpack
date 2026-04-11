-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_041_BribeCharacter"
----
----	with this measure the player can bribe an other character to increase
----	the favour of his victim
----
-------------------------------------------------------------------------------


function Init()
	
	if not ReadyToRepeat("dynasty", "HasBribed_"..GetDynastyID("Destination")) then
		-- message the player
		MsgBoxNoWait("", "Destination", "@L_GENERAL_ERROR_HEAD_+0", "@L_INTRIGUE_041_BRIBECHARACTER_FAILURES_+1", GetID("Destination"))
		SetRepeatTimer("dynasty", "AI_Bribe", 1)
		StopMeasure()
	end
	
	local Money = chr_GetBribeAmount("Destination") -- base value
	local Choice1 = Money * 0.33
	local Choice2 = Money * 0.66
	local Choice3 = Money
	
	Money = 50*math.floor(Money/50)
	
	local Button1 = "@B[1,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_CHOICE_+0,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_CHOICE_+0,Hud/Buttons/btn_Money_Small.tga]"
	local Button2 = "@B[2,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_CHOICE_+1,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_CHOICE_+1,Hud/Buttons/btn_Money_Medium.tga]"
	local Button3 = "@B[3,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_CHOICE_+2,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_CHOICE_+2,Hud/Buttons/btn_Money_Large.tga]"
	
	if GetMoney("Owner") < Choice1 then
		MsgQuick("", "@L_INTRIGUE_041_BRIBECHARACTER_FAILURES_+0", Choice1, GetID("Destination"))
		StopMeasure()
	elseif GetMoney("") < Choice2 then
		Button2 = ""
		Button3 = ""
	elseif GetMoney("") < Choice3 then
		Button3 = ""
	end
	
	local result = InitData("@P"..
					Button1..
					Button2..
					Button3,
					ms_041_bribecharacter_AIInitBribe,
					"@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_HEAD_+0",
					"@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_BODY_+0",
					GetID("Destination"), Choice1, Choice2, Choice3)

	if result == 1 then
		SetData("TFBribe", Choice1)
		SetData("FavorGain", GL_FAVOR_MOD_GREATER) -- 15
	elseif result == 2 then
		SetData("TFBribe", Choice2)
		SetData("FavorGain", GL_FAVOR_MOD_LARGE) -- 20
	elseif result == 3 then
		SetData("TFBribe", Choice3)
		SetData("FavorGain", GL_FAVOR_MOD_VERYLARGE) -- 25
	elseif result == "C" then
		SetRepeatTimer("dynasty", "AI_Bribe", 2)
	end
end

function AIInitBribe()
	--AI decides how much money to spend
	
	local Money = chr_GetBribeAmount("Destination") -- base value
	local Choice1 = Money * 0.25
	local Choice2 = Money * 0.5
	local Choice3 = Money
	local MyMoney = GetMoney("Destination") - 1000
	local Favor = GetFavorToSim("Destination", "Owner")
	local SpendFactor = 3
	GetDynasty("Destination", "AI_Dyn")
	local PersonalityCheck= ai_MakeDecision("AI_Dyn", "ambition", 0, "greed", 0)
	
	if MyMoney < Choice3 then
		SpendFactor = 2 
	elseif MyMoney < Choice2 then 
		SpendFactor = 1
	elseif MyMoney < Choice1 then
		return "C"
	end
	
	if not PersonalityCheck then
		SpendFactor = SpendFactor - 1
	end
	
	if SpendFactor < 1 then
		return "C"
	else
		return SpendFactor
	end
end

function AIDecision()
	
	--AI accept or decline money
	local Money = 0 + GetData("TFBribe")
	local Favor = GetFavorToSim("Destination", "Owner")
	GetDynasty("Destination", "AI_Dyn")
	local AcceptMod = 0
	
	if Favor >= 60 then
		AcceptMod = AcceptMod + 10
	elseif Favor < 40 then
		AcceptMod = AcceptMod - 20
	end
	
	local MyMoney = GetMoney("Destination")
	if Money > MyMoney then
		AcceptMod = AcceptMod + 20
	elseif Money > (MyMoney / 2) then
		AcceptMod = AcceptMod + 10
	elseif Money < (MyMoney / 10) then
		AcceptMod = AcceptMod - 20
	end
	
	local result = ai_MakeDecision("AI_Dyn", "bribes", AcceptMod) 
	
	if result then
		return 1
	else
		return 2
	end
end

function Run()
	if DynastyIsPlayer("") then
		SetRichPresence("state", "Bribery")
	end
	if not HasData("TFBribe") then
		if IsStateDriven() then
			ms_041_bribecharacter_Init();
		end
		if not HasData("TFBribe") then
			StopMeasure()
		end
	end

	--how far the Destination can be to start this action
	local MaxDistance = 1000
	--how far from the destination, the owner should stand while reading the letter from rome
	local ActionDistance = 80
	--how long message for destination will be displayed
	local MsgTimeOut = 0.25 --15 sekunden
	
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)

	--run to destination and start action at MaxDistance
	if not ai_StartInteraction("", "Destination", MaxDistance, ActionDistance, nil) then
		StopMeasure()
	end
	
	--get money 
	local Money = GetData("TFBribe") or 0
	local ModifyFavor = GetData("FavorGain") or 0
	
	if not DynastyIsPlayer("Destination") then
		CreateCutscene("default", "cutscene")
		CutsceneAddSim("cutscene", "")
		CutsceneAddSim("cutscene", "Destination")
		CutsceneCameraCreate("cutscene", "")		
		camera_CutsceneBothLock("cutscene", "")
	end
	
	--do visual stuff
	PlayAnimation("", "watch_for_guard")
	
	local time1, time2
	time1 = PlayAnimationNoWait("Owner", "use_object_standing")
	time2 = PlayAnimationNoWait("Destination", "cogitate")
	Sleep(1)
	PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
	CarryObject("", "Handheld_Device/ANIM_Smallsack.nif", false)
	
	Sleep(1)
	CarryObject("", "", false)
	
	GetDynasty("", "MyDyn")
	SetRepeatTimer("MyDyn", GetMeasureRepeatName(), TimeOut)

	--display decision message for destination
	local Result = MsgNews("Destination","",
				"@B[1,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_VICTIM_BUTTON_+0]"..
				"@B[2,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_VICTIM_BUTTON_+1]",
				ms_041_bribecharacter_AIDecision,  --AIFunc
				"intrigue", --MessageClass
				MsgTimeOut, --TimeOut
				"@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_VICTIM_HEAD_+0",
				"@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_VICTIM_BODY_+0",
				GetID(""), Money)
	
	local Index, ReplacementLabel
	
	if not DynastyIsPlayer("Destination") then
		camera_CutsceneBothLock("cutscene", "Destination")
	end
	
	if Result == 1 then --accept money
		
		CarryObject("Destination", "Handheld_Device/ANIM_Smallsack.nif", false)
		time2 = PlayAnimationNoWait("Destination", "fetch_store_obj_R")
		Sleep(1)
		StopAnimation("")
		PlaySound3D("Destination", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
		CarryObject("Destination", "", false)	
		
		-- set the destination specific timeout
		SetRepeatTimer("dynasty", "HasBribed_"..GetDynastyID("Destination"), 12)
		
		Index = MsgSay("Destination", "@L_INTRIGUE_041_BRIBECHARACTER_SPEAK_SUCCESS")
		ReplacementLabel = "_INTRIGUE_041_BRIBECHARACTER_SPEAK_SUCCESS_+"..Index
		
		--do the financial stuff
		chr_SpendMoney("", Money, "CostBribes", true)
		Sleep(0.5)
		chr_RecieveMoney("Destination", Money, "IncomeBribes")
		
		--for the mission
		mission_ScoreCrime("Destination", Money)
		
		Sleep(1)
		
		--do the favor stuff
		chr_ModifyFavor("Destination", "", ModifyFavor)
		if achievements_isValidSim("Owner", "CRIME_BRIBE") then
			UpdateStat("STAT_BRIBE_MONEY", (GetStat("STAT_BRIBE_MONEY") or 0) + math.floor(Money))
		end
		chr_GainXP("", GetData("BaseXP"))
		
		--show message
		MsgNewsNoWait("", "Destination", "", "intrigue", -1,
					"@L_INTRIGUE_041_BRIBECHARACTER_MSG_SUCCESS_HEAD_+0",
					"@L_INTRIGUE_041_BRIBECHARACTER_MSG_SUCCESS_BODY_+0", ReplacementLabel, GetID("Destination"))
		
	else	--decline money
		
		PlayAnimationNoWait("Destination", "propel")
		
		Index = MsgSay("Destination", "@L_INTRIGUE_041_BRIBECHARACTER_SPEAK_FAILED")
		ReplacementLabel = "_INTRIGUE_041_BRIBECHARACTER_SPEAK_FAILED_+"..Index
		
		--do the favor stuff
		chr_ModifyFavor("Destination", "", -GL_FAVOR_MOD_SMALL)
		
		-- give evidence
		local EvidenceID = 4
		AddEvidence("Destination", "", "Destination", EvidenceID, "")
		
		--show message
		MsgNewsNoWait("", "Destination", "", "intrigue", -1,
					"@L_INTRIGUE_041_BRIBECHARACTER_MSG_FAILED_HEAD_+0",
					"@L_INTRIGUE_041_BRIBECHARACTER_MSG_FAILED_BODY_+0", ReplacementLabel, GetID("Destination"))
	end
end


function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

function CleanUp()
	if DynastyIsPlayer("") then
		SetRichPresence("state", "")
	end
	if AliasExists("cutscene") then
		DestroyCutscene("cutscene")
	end
	StopAction("bribe", "Owner")
end
