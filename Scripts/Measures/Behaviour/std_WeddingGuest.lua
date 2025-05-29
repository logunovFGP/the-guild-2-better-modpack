-------------------------------------------------------------------------------
----
----	OVERVIEW "behavior_prewedding.lua"
----
-------------------------------------------------------------------------------

function Run()
	LogMessage("@NAO Behavior:Prewedding() -> " .. GetName(""))
	CarryObject("",rezrzerzer,false)
end

-----------------------
--      FUNCTIONS
-----------------------

function TalkToAnySim()
	LogMessage("@NAO Behavior:Prewedding() -> "..GetName("").." TalkToAnySim")
	-- Sim is already engaged in a discussion.
	if not HasProperty("", "isBusy") then
		SetProperty("", "isBusy", 0)
	end

	if GetProperty("", "isBusy") == 0 then 
		
		GetInsideBuilding("", "#WEDDING_CHAPEL")
		BuildingFindSimByProperty("#WEDDING_CHAPEL", "BUILDING_NPC", 11, "#PRIEST")
		BuildingGetInsideSimList("#WEDDING_CHAPEL", "tmp")
		ListRemove("tmp", "#PRIEST")
		ListRemove("tmp", "#MAIN")
		ListRemove("tmp", "#COURTED")
		ListGetElement("tmp", Rand(ListSize("tmp")), "Interlocutor")

		if (GetProperty("Interlocutor", "isBusy") == 0) and (GetProperty("Interlocutor", "WEDDING_GUEST") == 1) and (GetState("Interlocutor", STATE_DEAD) == false) and (GetInsideBuildingID("") == GetInsideBuildingID("Interlocutor")) and (GetID("") ~= GetID("Interlocutor")) and DynastyIsAI("Interlocutor") then
			SetProperty("", "isBusy", 1)
			SetProperty("Interlocutor", "isBusy", 1)
			MoveStop("Interlocutor")
			f_WeakMoveTo("", "Interlocutor", GL_MOVESPEED_WALK, 128)
			AlignTo("", "Interlocutor")
			AlignTo("Interlocutor", "")
			LoopAnimation("", "talk", -1)
			MsgSay("", "@L_ATTENDOFFICE_TEXT2_QUESTION")
			StopAnimation("")
			LoopAnimation("Interlocutor", "talk", -1)
			MsgSay("Interlocutor", "@L_ATTENDOFFICE_TEXT2_ANSWER")
			StopAnimation("Interlocutor")
			AlignTo("Interlocutor")
			GetFleePosition("", "Interlocutor", Rand(100)+300, "Position")
			f_WeakMoveTo("", "Position")
			SetProperty("Interlocutor", "isBusy", 0)
			SetProperty("", "isBusy", 0)
		end

	end
end