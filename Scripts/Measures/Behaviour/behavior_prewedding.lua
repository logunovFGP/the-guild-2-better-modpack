-------------------------------------------------------------------------------
----
----	OVERVIEW "behavior_prewedding.lua"
----
-------------------------------------------------------------------------------

Include("Cutscenes/WeddingCeremony.lua")

-- -----------------------
-- Run
-- -----------------------

function Run()
	LogMessage(GetName("") .. "is in PreWedding.lua")

	if DynastyIsAI("") then
		LogMessage(GetName("") .. " is supposedly blocked in exclusive measure for wedding.")
		BlockChar("")
		ForbidMeasure("", "BuyNobilityTitle", EN_BOTH)
		AllowMeasure("","StartDialog",EN_PASSIVE)
		AllowMeasure("","BribeCharacter",EN_BOTH)
		AllowMeasure("","MakeACompliment",EN_BOTH)
		AllowMeasure("","Flirt",EN_BOTH)
		AllowMeasure("","UsePoem",EN_BOTH)
		AllowMeasure("","UseCake",EN_PASSIVE)
		AllowMeasure("","MakeAPresent",EN_PASSIVE)

		while not (SimGetCutscene("", "cutscene") == true) do
			if HasProperty("","#WEDDING_FORCED") then
				Sleep(1)
			else
				behavior_prewedding_TalkToAnySim()
				Sleep(Rand(5)+1)
			end
		end

		SimSetBehavior("", "")
		SimResetBehavior("")
		return

	end
end

-----------------------
--      FUNCTIONS
-----------------------

function TalkToAnySim()
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