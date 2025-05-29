function OnCameraEnable()
	CutsceneHUDShow("", "LetterBoxPanel")
end

function OnCameraDisable()
	CutsceneHUDShow("", "LetterBoxPanel", false)
end

function CleanUp()
end

function Init()
	for i = 0, 2 do
		CutsceneCallThread("", "PrepareInstrument"..i, "Musician"..i)
	end
	CutsceneAddTriggerEvent("", "PlayInstruments", "Musician2Ready", 0, 30)
	CutsceneAddTriggerEvent("", "Continue", "Musician2Ready", 0, 30)
end

function Continue()
	Sleep(20)
	SetData("test", 1)
	CutsceneSetData("owner", "test")
	Sleep(6)

	Count = -1
	repeat
		Count = Count + 1
		CutsceneCallThread("", "Kill", "Musician"..Count)
	until (Count == 2)

	Sleep(1)

	EndCutscene("")
	DestroyCutscene("")
end

function PrepareInstrument0()
	GetInsideBuilding("", "MarryRoom")
	GetLocatorByName("MarryRoom", "Musician0", "MusicianPosition", false)
	f_MoveTo("", "MusicianPosition")
	f_BeginUseLocator("", "MusicianPosition", GL_STANCE_STAND)
end

function PrepareInstrument1()
	CarryObject("", "Handheld_Device/ANIM_Violinestock.nif", false)
	CarryObject("", "Handheld_Device/ANIM_Violine.nif", true)
	GetInsideBuilding("", "MarryRoom")
	GetLocatorByName("MarryRoom", "Musician1", "MusicianPosition", false)
	f_MoveTo("", "MusicianPosition")
	f_BeginUseLocator("", "MusicianPosition", GL_STANCE_STAND)
end

function PrepareInstrument2()
	CarryObject("", "Handheld_Device/ANIM_Violinestock.nif", false)
	CarryObject("", "Handheld_Device/ANIM_Violine.nif", true)
	GetInsideBuilding("", "MarryRoom")
	GetLocatorByName("MarryRoom", "Musician2", "MusicianPosition", false)
	f_MoveTo("", "MusicianPosition")
	f_BeginUseLocator("", "MusicianPosition", GL_STANCE_STAND)
	CutsceneSendEventTrigger("owner", "Musician2Ready")
end

function StartPlaying()
	local Duration = PlayAnimationNoWait("", "play_instrument_03_in")
	Sleep(Duration)
	LoopAnimation("", "play_instrument_03_loop", 30)
end

function StartSinging()
	PlayAnimationNoWait("", "sing_for_peace")
	GetPosition("", "MusicianPosition")
	StartSingleShotParticle("particles/pray_glow.nif", "MusicianPosition", 2, 10)
	Attach3DSound("", "measures/singforpeacefulness/female_songofpeacefulness+0.wav", 1.0)
end

function PlayInstruments()
	for i = 1, 2 do
		CutsceneCallThread("", "StartPlaying", "Musician"..i)
	end

	CutsceneCallThread("", "StartSinging", "Musician0")

	while true do 
		Sleep(0.5)
		CutsceneGetData("owner", "test")
		if GetData("test") == 1 then
			break
		end
	end

	for i = 0, 2 do
		StopAnimation("Musician"..i)
		PlayAnimation("Musician"..i, "play_instrument_03_out")
		CarryObject("Musician"..i, "", false)
		CarryObject("Musician"..i, "", true)
	end
	
end

function Kill()
	Kill("")
end


--PlayAnimationNoWait("","play_instrument_01_in")
--CarryObject("","Handheld_Device/ANIM_Flute.nif",false)
--PlayAnimation("", "play_instrument_01_loop")


--PlayAnimationNoWait("","play_instrument_03_in")
--CarryObject("","Handheld_Device/ANIM_laute.nif",true)
--PlayAnimation("","play_instrument_03_loop")