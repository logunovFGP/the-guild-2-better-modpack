function OnCameraEnable()
	CutsceneHUDShow("", "LetterBoxPanel")
end

function OnCameraDisable()
	CutsceneHUDShow("", "LetterBoxPanel", false)
end

function CleanUp()
end

function Init()
	GetInsideBuilding("Member", "MarryRoom")
	GetLocatorByName("MarryRoom", "Musician1", "Musician1Position", false)

	Count = -1
	repeat
		Count = Count + 1
		GetEvadePosition("Musician"..Count, 50, "MovePosition")
		f_MoveToNoWait("Musician"..Count, "MovePosition")
		f_MoveTo("Musician"..Count, "Musician1Position")
		f_BeginUseLocator("Musician"..Count, "Musician1Position", GL_STANCE_STAND)
		CutsceneCallThread("", "PrepareInstrument", "Musician"..Count)
	until (Count == 2)

	Sleep(7)

	Count = 0
	repeat
		CutsceneCallThread("", "Kill", "Musician"..Count)
		Count = Count + 1
	until (Count == 2)

	Sleep(1)

	EndCutscene("")
	DestroyCutscene("")
end

function PrepareInstrument()
	Sleep(2)
	PlayAnimationNoWait("", "play_instrument_03_in")
	CarryObject("", "Handheld_Device/ANIM_Violinestock.nif", false)
	CarryObject("", "Handheld_Device/ANIM_Violine.nif", true)
	while true do
		PlayAnimation("","play_instrument_03_loop")
		Sleep(0.5)
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