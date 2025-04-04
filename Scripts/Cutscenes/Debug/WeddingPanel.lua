function Start()

	GetSettlement("#MAIN", "Settlement")
	GetPosition("#MAIN", "Position")
	CutsceneAddSim("", "#MAIN")

	CutsceneCameraCreate("", "Position")
	CutsceneCameraSetRelativePosition("", "CameraPortrait", "#MAIN")

	local Destination = Find("#MAIN", "__F((Object.GetObjectsByRadius(Sim) == 2000)", "DestSim", -1)

	CarryObject("DestSim", "", false)
	CarryObject("DestSim", "", true)

	AlignTo("#MAIN", "DestSim")
	AlignTo("DestSim", "#MAIN")

	Sleep(1)

	GetPosition("DestSim", "ParticleSpawnPos")
	PlayAnimationNoWait("#MAIN", "fetch_store_obj_R")
	Sleep(1)
	PlaySound3D("#MAIN","Locations/wear_clothes/wear_clothes+1.wav", 1.0)
	CarryObject("#MAIN", "Handheld_Device/ANIM_Scythe.nif", false)

	PlayAnimationNoWait("#MAIN", "throw")
	Sleep(2.1)
	local fDuration = ThrowObject("#MAIN", "DestSim", "Handheld_Device/ANIM_Scythe.nif", 0.0005, "", 0, 150, 0)

	CutsceneCameraSetRelativePosition("", "Totale", "#MAIN")
	CutsceneCameraBlend("", fDuration, 1)
	CutsceneCameraSetRelativePosition("", "Totale", "DestSim")

	Sleep(1.8)

	CarryObject("#MAIN", "", false)
	CarryObject("DestSim", "Handheld_Device/ANIM_Scythe.nif", false)

	StartSingleShotParticle("particles/Explosion.nif", "ParticleSpawnPos", 1, 5)
	PlaySound3D("#MAIN", "Effects/combat_bomb_explode/combat_bomb_explode+0.wav", 1.0)

	Sleep(5)
	
	--CarryObject("","Handheld_Device/weapons/Cannon.nif",true)
	--GfxAttachObject("#MAIN", "weapons/Cannon.nif")
	
	--GfxAttachObject("Cannon", "weapons/Cannon.nif")
	--GfxSetPositionTo("Cannon", "OwnerPos")

	CutsceneShowCharacterPanel("",true)

	EndCutscene("")
end

function OnCameraEnable()
	CutsceneHUDShow("","LetterBoxPanel")
end

function OnCameraDisable()
	CutsceneHUDShow("","LetterBoxPanel", false)
end

function CleanUp()
end