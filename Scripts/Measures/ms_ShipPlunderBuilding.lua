function Run()
	if not AliasExists("Destination") then
		StopMeasure()
		return
	end

	local HasVictimOwner = BuildingGetOwner("Destination", "VictimOwner")

	if HasVictimOwner and DynastyGetTeam("") > 0 and DynastyGetTeam("") == DynastyGetTeam("VictimOwner") then
		StopMeasure()
		return
	end
	
	local MeasureID = GetCurrentMeasureID("")
	local duration = mdata_GetDuration(MeasureID)
	local TimeOut = mdata_GetTimeOut(MeasureID)
	BuildingGetWaterPos("Destination",true,"MovePos")
	if not f_MoveTo("", "MovePos",GL_MOVESPEED_RUN) then
		StopMeasure()
		return
	end
	MeasureSetNotRestartable()
	
	SetProperty("Destination","PlunderInProgress",1)
	
	if GetImpactValue("Destination","buildingburgledtoday")==0 then
		if GetLocatorByName("Destination","bomb1","ParticleSpawnPos1") then
			StartSingleShotParticle("particles/plunder.nif","ParticleSpawnPos1",8,5)
		end
		if GetLocatorByName("Destination","bomb2","ParticleSpawnPos2") then
			StartSingleShotParticle("particles/plunder.nif","ParticleSpawnPos2",7,5)
		end
		feedback_MessageMilitary("Destination","@L_BATTLE_061_PLUNDERBUILDING_MSG_VICTIM_START_HEAD_+0",
						"@L_BATTLE_061_PLUNDERBUILDING_MSG_VICTIM_START_BODY_+0",GetID(""),GetID("Destination"))
	else
		StopMeasure()
		return
	end
	
	PlaySound3DVariation("Destination","measures/plunderbuilding",1)
	PlaySound3DVariation("","Locations/alarm_horn_single",1)
	CommitAction("burgleahouse", "", "Destination", "Destination")
	local EndTime = GetGametime() + duration
	SetData("Time",duration)
	SetData("EndTime",EndTime)
	SetProcessMaxProgress("",duration*10)
	SendCommandNoWait("","Progress")
	SendCommandNoWait("Destination","Progress")
	if HasVictimOwner then
		dyn_SetDiplomacyState("VictimOwner", "", DIP_FOE)
	end
	
	while GetGametime() < EndTime do
		local Damage = 0.1*GetMaxHP("Destination")
		if Damage > GetHP("Destination") then
			Damage = GetHP("Destination")-25
		end
		
		ModifyHP("Destination", -Damage, false)
	
		StartSingleShotParticle("particles/plunder.nif","ParticleSpawnPos1",8,5)
		Sleep(1)
		StartSingleShotParticle("particles/plunder.nif","ParticleSpawnPos2",7,5)
		Sleep(2)
		PlaySound3DVariation("Destination","measures/plunderbuilding",1)
	end
	ResetProcessProgress("")
	ResetProcessProgress("Destination")
	
	feedback_MessageMilitary("Destination","@L_BATTLE_061_PLUNDERBUILDING_MSG_VICTIM_END_HEAD_+0",
						"@L_BATTLE_061_PLUNDERBUILDING_MSG_VICTIM_END_BODY_+0",GetID(""),GetID("Destination"))
	
	
	
	local Money = Plunder("","Destination",99)
	if (Money > 0) then
		AddImpact("Destination","buildingburgledtoday",1,4)
		local Time = MoveSetActivity("","carry")
		Sleep(2)
		CarryObject("","Handheld_Device/ANIM_Bag.nif",false)
		PlaySound3DVariation("","measures/plunderbuilding",1)
		Sleep(Time-2)
		feedback_MessageMilitary("","@L_BATTLE_061_PLUNDERBUILDING_MSG_ACTOR_END_HEAD_+0",
						"@L_BATTLE_061_PLUNDERBUILDING_MSG_ACTOR_END_BODY_+0",GetID("Destination"))
		
		--for the mission
		mission_ScoreCrime("",Money)
		if achievements_isValidSim("", "ROGUE_RAID_BUILDING") then
			UpdateStat("STAT_RAID_BUILDING_MONEY", (GetStat("STAT_RAID_BUILDING_MONEY") or 0) + math.floor(Money))
		end
		SetMeasureRepeat(TimeOut)
	else
		MsgQuick("", "@L_BATTLE_061_PLUNDERBUILDING_FAILURES_+1")
	end
	
	RemoveProperty("Destination", "PlunderInProgress")
	StopMeasure()
	
end

-- -----------------------
-- Progress
-- -----------------------
function Progress()
	while true do
		local Time = GetData("Time")
		local EndTime = GetData("EndTime")
		local CurrentTime = GetGametime()
		CurrentTime = EndTime - CurrentTime
		CurrentTime = Time - CurrentTime
		SetProcessProgress("", CurrentTime*10)
		Sleep(3)
	end
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	ResetProcessProgress("")
	
	if AliasExists("Destination") then
		if HasProperty("Destination","PlunderInProgress") then
			RemoveProperty("Destination","PlunderInProgress")
		end
		ResetProcessProgress("Destination")
		if HasProperty("Destination", "CanEnter_"..GetID("")) then
			RemoveProperty("Destination", "CanEnter_"..GetID(""))
		end
	end
		
	StopAction("burgleahouse","")
	
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2",Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

