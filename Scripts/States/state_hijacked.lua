function Init()
	-- SetStateImpact("no_idle")
	SetStateImpact("no_hire")
	SetStateImpact("no_fire")	
	SetStateImpact("no_control")
	SetStateImpact("no_measure_start")	
	SetStateImpact("no_measure_attach")	
	SetStateImpact("no_charge")
	SetStateImpact("no_arrestable")
	SetStateImpact("no_action")
	SetStateImpact("no_attackable")
	SetStateImpact("NoCameraJump")
	SetStateImpact("no_cancel_button")
end

function Run()
	if not GetInsideBuilding("", "Base") then
		return
	end
	
	-- Add xp
	BuildingGetOwner("Base", "BuildingOwner")
	xp_HijackCharacter("BuildingOwner", SimGetLevel(""))
	
	
	local Time = 24
	if GetImpactValue("", "InnocentI") >= 1 and Rand(100) < 75 then
		Time = 12
	end
	
	SimSetBehavior("", "Hijacked")
	feedback_MessageCharacter("Base",
		"@L_THIEF_065_HIJACKCHARACTER_MSG_ACTOR_SUCCESS_HEAD",
		"@L_THIEF_065_HIJACKCHARACTER_MSG_ACTOR_SUCCESS_BODY",GetID(""),GetID("Base"))
	
	local OutTime = (GetGametime() + Time)
	SetProperty("","HijackedEndTime",OutTime)
	
	StartGameTimer(Time)
	if HasProperty("","ForceFree") then
		RemoveProperty("","ForceFree")
	end
	while not CheckGameTimerEnd() do
		Sleep(Rand(9)+2)
		if HasProperty("","ForceFree") then
			break
		end
	end
	
	
end

function CleanUp()
	if HasProperty("","ForceFree") then
		RemoveProperty("","ForceFree")
	end
	
	if SimIsInside("") then
		f_ExitCurrentBuilding("")
	end
	
	SetState("", STATE_HIJACKED, false)
	SetState("", STATE_CUTSCENE, false)
	
	SimResetBehavior("")
	-- can walk home after 24 hours
	if GetHomeBuilding("", "Home") then
		MeasureRun("", "Home", "Walk", true)
	end
end
