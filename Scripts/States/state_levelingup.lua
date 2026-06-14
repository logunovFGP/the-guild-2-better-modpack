-------------------------------------------------------------------------------
----
----	OVERVIEW "state_levelingup"
----
----	With this state a building is leveled up
----
-------------------------------------------------------------------------------

-- -----------------------
-- Init
-- -----------------------
function Init()
	SetStateImpact("no_upgrades")
	SetStateImpact("upgrading")	
end

-- -----------------------
-- Run
-- -----------------------
function Run()
	local MovingBuilding = GetState("", STATE_MOVING_BUILDING)
	
	if MovingBuilding then
		SetState("", STATE_MOVING_BUILDING, false)
	end

	local	Proto = GetProperty("", "LevelUpProto")
	if not Proto then
		return
	end
	AddImpact("", "LevelingUp", 1, -1)
	
	local OldProto = BuildingGetProto("")
	local TotalTime = GetDatabaseValue("Buildings", Proto, "buildtime") - GetDatabaseValue("Buildings", OldProto, "buildtime") + 1
	if TotalTime < 1 then
		TotalTime = 1
	end
	
	local 	H4x0r = GetSettingNumber("DEBUG", "DisableBuildtime", 0)
	if (H4x0r==1) then
		TotalTime = 0.01 
	end
	Attach3DSound("", "measures/ms_BuildHouse_s_01.wav", 1.0)
	local MaxTotalTime = Gametime2Realtime(TotalTime)
	
	SetProcessMaxProgress("", MaxTotalTime)
	SetProcessProgress("", 0)
	
	RemoveProperty("", "LevelUpProto")
	GetPosition("", "FinalPos")
	local xfin2, yfin2, zfin2 = PositionGetVector("")
	local xfin, yfin, zfin = PositionGetVector("FinalPos")

	local ProgressAdd = 0
	local type, level, nenner, gebBez = bld_BauStuff(BuildingGetType(""), (BuildingGetLevel("")+1),"")
	LogMessage("State_levelingup: Building: "..type)
	gebBez = gebBez + 1
	nenner = 4
	if type~="" then
		local x = GfxAttachObject("Geruest1","buildings/Baugerueste/"..type.."/"..level.."/"..gebBez..".nif")
		GfxSetPosition("Geruest1",xfin,yfin,zfin,true)
		SetProperty("", "CurrentGeruest", 1)
		gebBez = gebBez + 1
	end

	if not GetDynasty("", "BuildingDynasty") then
		AddImpact("", "BauArbeiter", 3, -1)
	else
		AddImpact("", "BauArbeiter", 0, -1)
		CopyAlias("", "Des")
		--MeasureRun("BuildingDynasty", "", "BauZusatzMeasure", true)
		MeasureCreate("BauMeasure")
		MeasureStart("BauMeasure", "BuildingDynasty", "Des", "BauZusatzMeasure", true)
	end

	if (H4x0r==0) then	
		Sleep(4)
	end
	
	local TimeToUpgrade = 0
	local tries = 0
	while(TimeToUpgrade < MaxTotalTime) do
		ProgressAdd = GetImpactValue("", "BauArbeiter")
		
		if tries > 30 and ProgressAdd < 1 then
			ProgressAdd = 1
		end		
		TimeToUpgrade = TimeToUpgrade + ProgressAdd
		
		-- attach scaffolding
		if type~="" then
			if TimeToUpgrade >= ((MaxTotalTime / nenner ) * 1) and TimeToUpgrade < ((MaxTotalTime / nenner ) * 2) and GetProperty("", "CurrentGeruest") ~= 2 then
				GfxDetachObject("Geruest1")
				GfxAttachObject("Geruest2","buildings/Baugerueste/"..type.."/"..level.."/"..gebBez..".nif")
				GfxSetPosition("Geruest2", xfin, yfin, zfin, true)
				SetProperty("", "CurrentGeruest", 2)
				gebBez = gebBez + 1
			elseif TimeToUpgrade >= ((MaxTotalTime / nenner ) * 2) and TimeToUpgrade < ((MaxTotalTime / nenner ) * 3) and GetProperty("", "CurrentGeruest") ~= 3 then
				GfxDetachObject("Geruest2")
				GfxAttachObject("Geruest3","buildings/Baugerueste/"..type.."/"..level.."/"..gebBez..".nif")
				GfxSetPosition("Geruest3", xfin, yfin, zfin, true)
				SetProperty("", "CurrentGeruest", 3)
			end
			
			if nenner == 6 then
				gebBez = gebBez + 1
				if TimeToUpgrade >= ((MaxTotalTime / nenner ) * 3) and GetProperty("", "CurrentGeruest") ~= 4 then
					GfxDetachObject("Geruest3")
					GfxAttachObject("Geruest4","buildings/Baugerueste/"..type.."/"..level.."/"..gebBez..".nif")
					GfxSetPosition("Geruest4", xfin, yfin, zfin, true)
					SetProperty("", "CurrentGeruest", 4)
				end
			end
		end

		Sleep(1)
		SetProcessProgress("", TimeToUpgrade)
		tries = tries + 1
	end

	ShowBuildingFlags("", false)
	LogMessage("@BILU STATE ID: <" .. GetID("") .. "> Name: <" .. GetName("") .. "> Proto: <" .. Proto .. ">")
	-- there's different models for residences, choose a random model each time
	if BuildingGetType("") == GL_BUILDING_TYPE_RESIDENCE then
		Proto = state_levelingup_GetRandomResidenceModel("")
	end
	BuildingInternalLevelUp("", Proto)
	ShowBuildingFlags("", true)
	
	if AliasExists("Geruest4") then
		GfxDetachObject("Geruest4")
	elseif AliasExists("Geruest3") then
		GfxDetachObject("Geruest3")
	end	
	
	local label = "@L_BUILDING_LEVELUP_HEAD"
	
	if Rand(2) == 0 then
		label = "@L_BUILDING_UPGRADE_BUILD_HEAD_+0"
	end
	
	BuildingGetOwner("", "Builder")	
	feedback_MessageWorkshop("",
		label,
		"@L_BUILDING_LEVELUP_BODY_+0", GetID(""))
	
	if MovingBuilding then
		SetState("", STATE_MOVING_BUILDING, true)
	end		
	
end


function GetRandomResidenceModel(BuildingAlias)
	local Check
	local CurrentLevel = BuildingGetLevel(BuildingAlias) + 1
	if CurrentLevel == 1 then -- verylow
		Check = Rand(2)
		if Check == 0 then
			return 440
		else
			return 681
		end	

	elseif CurrentLevel == 2 then -- low
		Check = Rand(5)
		if Check == 0 then
			return 441
		elseif Check == 1 then
			return 655
		elseif Check == 2 then
			return 656
		elseif Check == 3 then
			return 657
		else
			return 682
		end

	elseif CurrentLevel == 3 then -- lowmed
		Check = Rand(3)
		if Check == 0 then
			return 442
		elseif Check == 1 then
			return 658
		else
			return 659
		end

	elseif CurrentLevel == 4 then -- med
		Check = Rand(3)
		if Check == 0 then
			return 443
		elseif Check == 1 then
			return 683
		else
			return 684
		end
	else
		return 444 -- Residence5
	end
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	ResetProcessProgress("")
	Detach3DSound("")
	RemoveImpact("", "LevelingUp", 1, -1)
	RemoveImpact("", "BauArbeiter")
	SetState("", STATE_LEVELINGUP, false)	
end

