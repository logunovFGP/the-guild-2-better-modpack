-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_041_BribeCharacter"
----
----	with this measure the player can bribe an other character to increase
----	the favour of his victim
----
-------------------------------------------------------------------------------


function Init()

	GetDynasty("Destination", "dynasty")
	
	if GetImpactValue("Destination", "OfficeTimer") > 0 and ImpactGetMaxTimeleft("Destination", "OfficeTimer") < 2 then
		return
	end
	
	local Money = chr_GetBribeAmount("Destination") -- base value
	local Choice1 = Money * 0.25
	local Choice2 = Money * 0.5
	local Choice3 = Money
	
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
	
	MsgMeasure("", "")
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
		SetData("FavorGain", GL_FAVOR_MOD_SMALL) -- 5
	elseif result == 2 then
		SetData("TFBribe", Choice2)
		SetData("FavorGain", GL_FAVOR_MOD_NORMAL) -- 10
	elseif result == 3 then
		SetData("TFBribe", Choice3)
		SetData("FavorGain", GL_FAVOR_MOD_LARGE) -- 20
	end
end

function AIInitBribe()
	--AI decides how much money to spend
	local OwnerMoney = GetMoney("Owner")
	local DestMoney = GetMoney("Destination")
	local Favor = GetFavorToSim("Destination", "Owner")
	local SpendFactor = 0
	
	if OwnerMoney < DestMoney then
		SpendFactor = SpendFactor + 1
	end
	
	if Favor < 50 then
		SpendFactor = SpendFactor + 1
	end
	
	if OwnerMoney < DestMoney * 0.05 then
		if SpendFactor > 1 then
			SpendFactor = 1
		end
		
	elseif OwnerMoney < DestMoney * 0.1 then
		if SpendFactor > 2 then
			SpendFactor = 2
		end
	end
	
	if SpendFactor == 2 then
		return 3	
	elseif SpendFactor == 1 then
		return 2
	else
		return 1
	end
end

function AIDecision()
	
	--AI accept or decline money
	local Money = 0 + GetData("TFBribe")
	local DestMoney = GetMoney("Destination") / 10
	local Favor = GetFavorToSim("Destination","Owner")
	local RhetoricSkill = GetSkillValue("",RHETORIC)
	local FavorFactor = ((Money / DestMoney) * 100) + Favor + RhetoricSkill
	
	if FavorFactor < 50 then
		return 2
	else
		return 1
	end
end

function Run()

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
	CommitAction("bribe", "Owner", "Owner", "Destination")
	--PlayAnimationNoWait("Destination","cogitate")
	PlayAnimation("", "watch_for_guard")
	
	local time1
	local time2
	time1 = PlayAnimationNoWait("Owner", "use_object_standing")
	time2 = PlayAnimationNoWait("Destination", "cogitate")
	Sleep(1)
	PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
	CarryObject("", "Handheld_Device/ANIM_Smallsack.nif", false)
	
	Sleep(1)
	CarryObject("", "", false)
	CarryObject("Destination", "Handheld_Device/ANIM_Smallsack.nif",false)
	time2 = PlayAnimationNoWait("Destination", "fetch_store_obj_R")
	Sleep(1)
	StopAnimation("")
	PlaySound3D("Destination", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
	CarryObject("Destination", "", false)	
	
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
	local Index
	local ReplacementLabel
	if not DynastyIsPlayer("Destination") then
		camera_CutsceneBothLock("cutscene", "Destination")
	end
	
	if Result == 1 then --accept money
		Index = MsgSay("Destination", "@L_INTRIGUE_041_BRIBECHARACTER_SPEAK_SUCCESS")
		ReplacementLabel = "_INTRIGUE_041_BRIBECHARACTER_SPEAK_SUCCESS_+"..Index
		
		--do the financial stuff
		chr_SpendMoney("", Money, "CostBribes", true)
		Sleep(1)
		chr_RecieveMoney("Destination", Money, "IncomeBribes")
		
		--for the mission
		mission_ScoreCrime("Destination", Money)
		
		PlaySound3D("", "Effects/coins_to_moneybag+0.wav", 1.0)
		Sleep(1)
		
		--do the favor stuff
		chr_ModifyFavor("Destination", "", ModifyFavor)
		chr_GainXP("", GetData("BaseXP"))
		
		--show message
		MsgNewsNoWait("", "Destination", "", "intrigue", -1,
					"@L_INTRIGUE_041_BRIBECHARACTER_MSG_SUCCESS_HEAD_+0",
					"@L_INTRIGUE_041_BRIBECHARACTER_MSG_SUCCESS_BODY_+0", ReplacementLabel, GetID("Destination"))
		
	else	--decline money
		Index = MsgSay("Destination", "@L_INTRIGUE_041_BRIBECHARACTER_SPEAK_FAILED")
		ReplacementLabel = "_INTRIGUE_041_BRIBECHARACTER_SPEAK_FAILED_+"..Index
		
		--do the favor stuff
		chr_ModifyFavor("Destination", "", -GL_FAVOR_MOD_SMALL)
		
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
	if AliasExists("cutscene") then
		DestroyCutscene("cutscene")
	end
	StopAction("bribe", "Owner")
end
