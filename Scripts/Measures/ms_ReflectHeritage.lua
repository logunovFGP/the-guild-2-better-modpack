function Run()

	if not GetInsideBuilding("","CurrentBuilding") then
		StopMeasure()
		return
	end

	if not GetLocatorByName("CurrentBuilding", "Sit1", "SitPos") then
		StopMeasure()
		return
	end

	CreateCutscene("default","cutscene")
	CutsceneAddSim("cutscene","")
	CutsceneCameraCreate("cutscene","")

	if not f_BeginUseLocator("","SitPos",GL_STANCE_SIT,true) then
		RemoveAlias("SitPos")
		StopMeasure()
		return
	end

	camera_CutscenePlayerLockSit("cutscene","","TalkSit-Front-Far")
	Sleep(2)

	PlayAnimationNoWait("","sit_idle")
	Sleep(1.5)

	PlayAnimationNoWait("","sit_talk")
	MsgSay("","@L_REFLECTHERIT_MUSING_+0")

	CutsceneCameraBlend("cutscene", 2.5, 2)
	camera_CutscenePlayerLockSit("cutscene","","TalkSit-Left-Far")
	PlayAnimationNoWait("","sit_talk_02")
	MsgSayNoWait("","@L_REFLECTHERIT_MUSING_+1")
	Sleep(5)

	CutsceneCameraBlend("cutscene", 2.0, 2)
	camera_CutscenePlayerLockSit("cutscene","","TalkSit-Front-Far")

	PlayAnimationNoWait("","sit_yes")
	Sleep(2)

	PlayAnimationNoWait("","sit_talk_short")
	MsgSay("","@L_REFLECTHERIT_MUSING_+2")

	local pleasurePalace = ms_reflectheritage_CheckPleasurePalace()

	if pleasurePalace then
		ms_reflectheritage_PlaySuccessScene()
	else
		ms_reflectheritage_PlayFailScene()
	end

	DestroyCutscene("cutscene")

	f_EndUseLocator("","SitPos",GL_STANCE_STAND)
	Sleep(1)

	StopMeasure()
end

function PlayFailScene()

	CutsceneCameraBlend("cutscene", 1.5, 2)
	camera_CutscenePlayerLockSit("cutscene","","TalkSit-Front-Near")
	Sleep(1.5)

	PlayAnimationNoWait("","sit_no")
	Sleep(1.5)

	local failLine = Rand(3)
	PlayAnimationNoWait("","sit_talk_short")
	if failLine == 0 then
		MsgSay("","@L_REFLECTHERIT_FAIL_+0")
	elseif failLine == 1 then
		MsgSay("","@L_REFLECTHERIT_FAIL_+1")
	else
		MsgSay("","@L_REFLECTHERIT_FAIL_+2")
	end

	CutsceneCameraBlend("cutscene", 2.0, 2)
	camera_CutscenePlayerLock("cutscene","","Far_HCenterYLeft")
	Sleep(2)

	GetPosition("SitPos","ParticlePos")
	StartSingleShotParticle("particles/pray_glow.nif","ParticlePos", 3, 1)
	Sleep(3)
end

function PlaySuccessScene()

	CutsceneCameraBlend("cutscene", 1.5, 2)
	camera_CutscenePlayerLockSit("cutscene","","TalkSit-Front-Near")
	Sleep(1.5)

	PlayAnimationNoWait("","sit_yes")
	Sleep(1.5)

	PlayAnimationNoWait("","sit_talk")
	MsgSay("","@L_REFLECTHERIT_SUCCESS_+0")

	CutsceneCameraBlend("cutscene", 2.0, 2)
	camera_CutscenePlayerLockSit("cutscene","","TalkSit-Right-Far")
	Sleep(2)

	PlayAnimationNoWait("","sit_cheer")
	Sleep(2)

	CutsceneCameraBlend("cutscene", 2.0, 2)
	camera_CutscenePlayerLockSit("cutscene","","TalkSit-Front-Far")
	PlayAnimationNoWait("","sit_talk_02")
	MsgSayNoWait("","@L_REFLECTHERIT_SUCCESS_+1")
	Sleep(5)

	PlayAnimationNoWait("","sit_laugh")
	Sleep(2)

	PlayAnimationNoWait("","sit_talk")
	MsgSay("","@L_REFLECTHERIT_SUCCESS_+2")
	Sleep(1)

	CutsceneCameraBlend("cutscene", 2.0, 2)
	camera_CutscenePlayerLock("cutscene","","Far_HCenterYLeft")
	Sleep(2)

	GetPosition("SitPos","ParticlePos")
	StartSingleShotParticle("particles/miracle.nif","ParticlePos", 1, 1)
	Sleep(0.5)
	StartSingleShotParticle("particles/pray_glow.nif","ParticlePos", 10, 2)
	Sleep(1)
	StartSingleShotParticle("particles/levelup.nif","ParticlePos", 3, 1)
	Sleep(2)

	achievements_Unlock("", "MISC_PLEASURE_PALACE")

	Sleep(3)
end

function CheckPleasurePalace()

	if BuildingGetLevel("CurrentBuilding") < 3 then
		return false
	end

	if GetNobilityTitle("") < 15 then
		return false
	end

	if SimGetOfficeLevel("") ~= 7 then
		return false
	end

	if not GetDynasty("", "ppDyn") then
		return false
	end
	if GetMoney("ppDyn") < 5000000 then
		return false
	end

	local guardCount = 0
	local wCount = BuildingGetWorkerCount("CurrentBuilding")
	for gi = 0, wCount - 1 do
		if BuildingGetWorker("CurrentBuilding", gi, "ppGuard") then
			if SimGetProfession("ppGuard") == 74 then
				guardCount = guardCount + 1
			end
		end
	end
	if guardCount < 4 then
		return false
	end

	local castleUpgrades = {805,806,6110,6113,6115,6126,6127,6437,6438,6439,802,804,807,808,6117,6128,6440,6441,6442,6443,796,797,798,799,801,6119,6129,6444,6445,6446,6447}
	for i = 1, 31 do
		if not BuildingHasUpgrade("CurrentBuilding", castleUpgrades[i]) then
			return false
		end
	end

	return true
end

function CleanUp()
	DestroyCutscene("cutscene")

	if AliasExists("SitPos") then
		f_EndUseLocator("","SitPos",GL_STANCE_STAND)
	end
	CarryObject("","",false)
	StopAnimation("")
end
