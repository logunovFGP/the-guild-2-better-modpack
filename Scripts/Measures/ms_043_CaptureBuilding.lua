-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_043_CaptureBuilding"
----
----	with this measure the player can capture a building
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()	
	
	if not AliasExists("Destination") then
		StopMeasure()
	end

	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	if GetState("", STATE_FIGHTING) then
		return
	end
	
	if BuildingGetClass("Destination") == 2 then
		if not CanBuildWorkshop("dynasty") then
			MsgQuick("dynasty", "@L_GENERAL_MEASURES_FAILURES_+24", GetMaxWorkshopCount("dynasty"))
			return
		end
	end
	
	local Class	= BuildingGetCharacterClass("Destination")
	local Count = DynastyGetMemberCount("dynasty")

	for Number = 0, Count-1 do
		if DynastyGetMember("dynasty", Number, "Member") then
			if Class == GL_CLASS_NONE or Class == SimGetClass("Member") then
				if BuildingCanBeOwnedBy("Destination", "Member") then
					CopyAlias("Member", "NewOwner")
					break;
				end
			end
		end
	end
	
	if not AliasExists("NewOwner") then
		MsgQuick("dynasty", "@L_GENERAL_MEASURES_043_CAPTUREBUILDING_FAILURES_+0", GetID("Destination"))
		return
	end
	
	if not f_MoveTo("", "Destination", GL_MOVESPEED_RUN) then
		GetOutdoorMovePosition("", "Destination", "MovePos")
		if not f_MoveTo("", "Destination", GL_MOVESPEED_RUN) then
			StopMeasure()
		end
	end
	
	if GetImpactValue("Destination", "BoobyTrap") > 0 then
		RemoveImpact("Destination", "BoobyTrap")
		GetPosition("", "ParticleSpawnPos")
		PlaySound3D("", "fire/Explosion_01.wav", 1.0)
		StartSingleShotParticle("particles/Explosion.nif", "ParticleSpawnPos", 1,5)
		ModifyHP("",-(0.5*GetMaxHP("")), true)
		CommitAction("explosion", "", "Destination", "Destination")
		StopMeasure()
	end
	
	CopyAlias("Destination", "InsideBuilding")
	SetData("Success", "0")
	
	if not (SimGetWorkingPlace("", "WorkBuilding")) then
		MsgQuick("", "@L_BATTLE_043_CAPTUREBUILDING_FAILURES_+0")
		return	
	end
	
	if not (BuildingGetOwner("WorkBuilding", "AttackerOwner")) then
		MsgQuick("", "@L_BATTLE_043_CAPTUREBUILDING_FAILURES_+1")
		return	
	end
	
	if not (BuildingGetOwner("InsideBuilding","OldBuildingOwner")) then
		MsgQuick("", "@L_BATTLE_043_CAPTUREBUILDING_FAILURES_+1")
		return
	end
	
	if not SendCommandNoWait("", "ChangeFlags") then
		MsgQuick("", "@L_BATTLE_043_CAPTUREBUILDING_FAILURES_+2")
	end

	CommitAction("attackbuilding", "", "OldBuildingOwner", "OldBuildingOwner")
	CarryObject("", "Handheld_Device/ANIM_Flag.nif", false)
	
	LoopAnimation("", "capture_building", 30)
	CarryObject("", "", false)
	
	Sleep (5)
	
	if not (BuildingBuy("InsideBuilding", "NewOwner", BM_CAPTURE)) then
		MsgQuick("", "@L_BATTLE_043_CAPTUREBUILDING_FAILURES_+3")
		return
	end
	
	AddImpact("InsideBuilding", "recentlycaptured", 1, 12)
	SetProperty("InsideBuilding", "Captured", 1)
	SetRepeatTimer("dynasty", GetMeasureRepeatName2("CaptureBuilding"), TimeOut)
	SetMeasureRepeat(TimeOut)
	
	if GetImpactValue("Destination", "messagesent") == 0 then
		SetData("Success", "1")
		AddImpact("Destination","messagesent", 1, 1)
	
		MsgNewsNoWait("OldBuildingOwner", "", "", "military", -1,
			"@L_BATTLE_043_CAPTUREBUILDING_MSG_VICTIM_HEAD_+0",
			"@L_BATTLE_043_CAPTUREBUILDING_MSG_VICTIM_BODY_+0", GetID(""), GetID("InsideBuilding"))
		
		MsgNewsNoWait("", "", "", "military", -1,
			"@L_BATTLE_043_CAPTUREBUILDING_MSG_ACTOR_HEAD_+0",
			"@L_BATTLE_043_CAPTUREBUILDING_MSG_ACTOR_BODY_+0", GetID("InsideBuilding"))
		
		-- clear all eventual workers and ppl out of the building
		
		--for the mission
		local MissionMoney = chr_GetBootyCount("InsideBuilding",INVENTORY_STD) + chr_GetBootyCount("InsideBuilding",INVENTORY_SELL)
		MissionMoney = MissionMoney + BuildingGetValue("InsideBuilding")
		mission_ScoreCrime("", MissionMoney)
		
		-- Add xp
		SimGetWorkingPlace("", "WorkingPlace")
		BuildingGetOwner("WorkingPlace", "SimOwner")	
		xp_CaptureBuilding("SimOwner", GetData("BaseXP"), BuildingGetLevel("InsideBuilding"))
		achievements_Unlock("SimOwner", "CRIME_CAPTURE_BUILDING")
		Evacuate("InsideBuilding", true)
	end
	StopMeasure()
end

-- -----------------------
-- ChangeFlags
-- -----------------------
function ChangeFlags()
	StopAction("attackbuilding", "")
	if (BuildingGetFlag("InsideBuilding", "FlagObject", 1)) then
		local bFlag2 = BuildingGetFlag("InsideBuilding", "FlagObject2", 2)
		local bFlag3 = BuildingGetFlag("InsideBuilding", "FlagObject3", 3)
		if (GetDynasty("", "AttackerDynasty")) then 
			--down

			if AliasExists("FlagObject2") then
				GfxMoveToPositionNoWait("FlagObject2", 0, -65, 0, 15, false)
			end
			if AliasExists("FlagObject3") then
				GfxMoveToPositionNoWait("FlagObject3", 0, -65, 0, 15, false)
			end
			if AliasExists("FlagObject") then
				GfxMoveToPosition("FlagObject", 0, -65, 0, 15, false)
			end
			
			--change color
			if AliasExists("FlagObject2") then
				BuildingSetFlagColor("InsideBuilding", "AttackerDynasty", 2)
			end
			if AliasExists("FlagObject3") then
				BuildingSetFlagColor("InsideBuilding", "AttackerDynasty", 3)
			end
			if AliasExists("FlagObject") then
				BuildingSetFlagColor("InsideBuilding", "AttackerDynasty")
			end

			--up
			if AliasExists("FlagObject2") then
				GfxMoveToPositionNoWait("FlagObject2", 0, 65, 0, 15, false)
			end
			if AliasExists("FlagObject3") then
				GfxMoveToPositionNoWait("FlagObject3", 0, 65, 0, 15, false)
			end	
			if AliasExists("FlagObject") then
				GfxMoveToPosition("FlagObject", 0, 65, 0, 15, false)
			end
		end
	end
	
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	StopAction("explosion", "")
	local bSuccess	= GetData("Success")
	if not (bSuccess == 1) then
		if AliasExists("OldBuildingOwner") then
			if (GetDynasty("OldBuildingOwner", "OldDynasty")) then 
				BuildingSetFlagColor("InsideBuilding", "OldDynasty", 1)
				BuildingSetFlagColor("InsideBuilding", "OldDynasty", 2)
				BuildingSetFlagColor("InsideBuilding", "OldDynasty", 3)
				if AliasExists("FlagObject") then
					GfxSetPosition("FlagObject", 0, 0, 0, true)
				end
				if AliasExists("FlagObject2") then
					GfxSetPosition("FlagObject2", 0, 0, 0, true)
				end
				if AliasExists("FlagObject3") then
					GfxSetPosition("FlagObject3", 0, 0, 0, true)
				end
				CarryObject("","",false)
			end
		end
	end
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2",Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

