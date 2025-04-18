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
	SetStateImpact("no_cancel_button")
end

function Run()
	LogMessage("@NAO STATE_IMPRISONED RUN with " .. GetName(""))

	if not GetInsideBuilding("", "Prison") then
		return
	end
	
	if not GetSettlement("Prison", "City") then
		return
	end

	local Time = 0

	if CityGetPenalty("City", "", PENALTY_PRISON, true, "Penalty") then
		Time = PenaltyGetPrisonTime("Penalty")
		if Time <= 0 then
			return
		end
	elseif CityGetPenalty("City", "", PENALTY_FUGITIVE, true, "Penalty") then
		Time = 48
	end

	if HasProperty("", "GettingTortured") then
		RemoveProperty("", "GettingTortured")
	end
	
	if GetImpactValue("", "InnocentI") >= 1 and Rand(100) < 75 then
		Time = 12
	end

	LogMessage("@NAO "..GetName("").." is imprisoned for this duration: " .. Time)

	feedback_MessageCharacter("Owner",
		"@L_PENALTY_PRISON_ARRIVED_HEAD_+0",
		"@L_PENALTY_PRISON_ARRIVED_BODY_+0", GetID("Owner"))

	SetProcessMaxProgress("", Time)

	local CellNumber = Rand(2) + 1
	local Data = {"A", "B"}

	SetData("CellNumber", CellNumber)

	if not HasProperty("", "Imprisoned") then
		GetLocatorByName("Prison", "Cell1A", "Cell1Sound")
		GetLocatorByName("Prison", "Cell2A", "Cell2Sound")
		SetProperty("", "Imprisoned", 1)
		PlaySound3DVariation("Cell"..CellNumber.."Sound", "Effects/door_open", 1)
		SetRoomAnimationTime("Prison", "", "U_CellDoor_"..Data[CellNumber], 0)
		StartRoomAnimation("Prison", "", "U_CellDoor_"..Data[CellNumber])
		Sleep(1.2)
		StopRoomAnimation("Prison", "", "U_CellDoor_"..Data[CellNumber])
		GetLocatorByName("Prison", "Entry"..CellNumber.."TeleportPos", "CellTeleportPos")
		f_MoveTo("", "CellTeleportPos")
		LoopAnimation("", "walk", -1)
		GetLocatorByName("Prison", "Entry"..CellNumber.."TeleportTargetPos", "CellTeleportTargetPos")
		SimBeamMeUp("", "CellTeleportTargetPos", false)
		StopAnimation("")
		StartRoomAnimation("Prison", "", "U_CellDoor_"..Data[CellNumber])
		Sleep(1.1)
		PlaySound3DVariation("Cell1Sound", "Effects/door_close", 1)
		StopRoomAnimation("Prison", "", "U_CellDoor_"..Data[CellNumber])
		SetRoomAnimationTime("Prison","", "U_CellDoor_"..Data[CellNumber], 0)
	end

	local StartTime = GetGametime()
	local EndTime = StartTime + Time
	local OldTime = Time

	while GetGametime() < EndTime do
		LogMessage("@NAO STATE_IMPRISONED "..GetName("").." -> In While Loop ("..GetGametime().."/"..EndTime..")")

		state_imprisoned_RunIdleAction(CellNumber)

		if not AliasExists("Penalty") then
			break
		end
		Time = PenaltyGetPrisonTime("Penalty")
		SetProcessProgress("", GetGametime() - StartTime)
		if Time ~= OldTime then
			EndTime = StartTime + Time
			SetProcessMaxProgress("", Time)
			OldTime = Time
		end
	end

	if HasProperty("", "Imprisoned") then
		StartRoomAnimation("Prison","","U_CellDoor_"..Data[CellNumber])
		Sleep(1.2)
		StopRoomAnimation("Prison", "", "U_CellDoor_"..Data[CellNumber])
		SetRoomAnimationTime("Prison", "", "U_CellDoor_"..Data[CellNumber], 0)
		GetLocatorByName("Prison", "Cell"..CellNumber.."TeleportPos", "CellTeleportPos")
		f_MoveTo("", "CellTeleportPos")
		GetLocatorByName("Prison", "Cell"..CellNumber.."TeleportTargetPos", "CellTeleportTargetPos")
		SimBeamMeUp("", "CellTeleportTargetPos", false)
		StopAnimation("")
		RemoveProperty("", "Imprisoned")
		PlaySound3DVariation("Cell"..CellNumber.."Sound", "Effects/door_open", 1)
		StartRoomAnimation("Prison", "", "U_CellDoor_"..Data[CellNumber])
		Sleep(1.1)
		PlaySound3DVariation("Cell"..CellNumber.."Sound", "Effects/door_close", 1)
		StopRoomAnimation("Prison", "", "U_CellDoor_"..Data[CellNumber])
		SetRoomAnimationTime("Prison", "", "U_CellDoor_"..Data[CellNumber], 0)
		f_ExitCurrentBuilding("")
	end

	if CityGetPenalty("City", "", PENALTY_UNKNOWN, true, "Penalty") then
		PenaltyFinish("Penalty")
		feedback_MessageCharacter("Owner",
			"@L_PENALTY_FREE_HEAD_+0",
			"@L_PENALTY_PRISON_RELEASED_BODY_+0", GetID("Owner"))
		if GetHomeBuilding("", "Home") then
			MeasureRun("", "Home", "Walk", true)
		end
	end
end

function RunIdleAction(Cell)


		local Action = Rand(4)
		local Data = {"A", "B"}
		LogMessage("@NAO #W RunIdleAction with " .. GetName("") .. ", Action is " .. Action .. " and Cell is " .. Cell)

		if AliasExists("Prison") then
			if GetHP("Prison") < 1 then
				feedback_MessageCharacter("Owner",
					"@L_PRISON_TRAGICALLY_ACCIDENT_MSG_VICTIM_HEAD_+0",
					"@L_PRISON_TRAGICALLY_ACCIDENT_MSG_VICTIM_BODY_+0", GetID("Owner"))
				ModifyHP("", -GetMaxHP(""), false)
				return
			end
		end

		if (Action == 0) then
			if GetFreeLocatorByName("Prison", "Cell"..Cell..Data[Cell], -1, -1, "CellPos1"..Cell) then
				SetData("BlockedCell", "CellPos1"..Cell)
				BlockLocator("","CellPos1"..Cell)
			 	f_MoveTo("", "CellPos1"..Cell)
				Sleep(1)
				MoveSetStance("",GL_STANCE_SITGROUND)
				MsgSayNoWait("","@L_PRISON_1_ARREST_MONOLOGUE")
				Sleep(28)
				MoveSetStance("",GL_STANCE_STAND)
				Sleep(6)
				ReleaseLocator("","CellPos1"..Cell)
			end
			if GetFreeLocatorByName("Prison", "Cell"..Cell.."B",-1,-1, "CellPos2"..Cell) then
				SetData("BlockedCell","CellPos2"..Cell)
				BlockLocator("","CellPos2"..Cell)
				f_MoveTo("", "CellPos2"..Cell)
				Sleep(1)
				MoveSetStance("",GL_STANCE_KNEEL)
				Sleep(8)
				PlayAnimationNoWait("","knee_pray")
				MsgSayNoWait("","@L_PRISON_1_ARREST_PACING")
				Sleep(10)
				MoveSetStance("",GL_STANCE_STAND)
				Sleep(6)
				ReleaseLocator("","CellPos2"..Cell)				
			end
			if GetFreeLocatorByName("Prison", "Cell"..Cell.."C",-1,-1, "CellPos3"..Cell) then
				SetData("BlockedCell","CellPos3"..Cell)
				BlockLocator("","CellPos3"..Cell)
				f_MoveTo("", "CellPos3"..Cell)
				Sleep(1)
				PlayAnimationNoWait("","cheer_01")
				MsgSay("","@L_PRISON_1_ARREST_VERBAL_AGGRO")
				Sleep(5)
				PlayAnimationNoWait("","cheer_01")
				MsgSay("","@L_PRISON_1_ARREST_VERBAL_AGGRO")
				Sleep(1)
				ReleaseLocator("","CellPos3"..Cell)
			end
			--when in cell 1 do
			if (GetFreeLocatorByName("Prison", "Cell"..Cell.."D",-1,-1, "CellPos4"..Cell) and (Cell == 1)) then
				SetData("BlockedCell","CellPos4"..Cell)
				BlockLocator("","CellPos4"..Cell)
				f_MoveTo("", "CellPos4"..Cell)
				Sleep(1)
				PlayAnimationNoWait("","threat")
				MoveSetStance("",GL_STANCE_SITGROUND)
				MsgSayNoWait("","@L_PRISON_1_ARREST_VERBAL_AGGRO")
				Sleep(15)
				MoveSetStance("",GL_STANCE_STAND)
				Sleep(6)
				PlayAnimationNoWait("","threat")
				MsgSay("","@L_PRISON_1_ARREST_VERBAL_AGGRO")
				Sleep(4)
				ReleaseLocator("","CellPos4"..Cell)
			end

		elseif (Action == 1) then
			if GetFreeLocatorByName("Prison", "Cell"..Cell.."C",-1,-1, "CellPos5"..Cell) then
				SetData("BlockedCell","CellPos5"..Cell)
				BlockLocator("","CellPos5"..Cell)
				f_MoveTo("", "CellPos5"..Cell)
				Sleep(1)
				MoveSetStance("",GL_STANCE_CROUCH)
				MsgSayNoWait("","@L_PRISON_1_ARREST_CROUCH")
				Sleep(6)
				MsgSayNoWait("","@L_PRISON_1_ARREST_CROUCH")
				Sleep(15)
				MoveSetStance("",GL_STANCE_STAND)
				Sleep(6)
				ReleaseLocator("","CellPos5"..Cell)
			end
			if GetFreeLocatorByName("Prison", "Cell"..Cell.."A",-1,-1, "CellPos6"..Cell) then
				SetData("BlockedCell","CellPos6"..Cell)
				BlockLocator("","CellPos6"..Cell)
				f_MoveTo("", "CellPos6"..Cell)
				Sleep(1)
				MoveSetStance("",GL_STANCE_SITGROUND)
				MsgSayNoWait("","@L_PRISON_1_ARREST_MONOLOGUE")
				Sleep(28)
				MsgSayNoWait("","@L_PRISON_1_ARREST_MONOLOGUE")
				Sleep(28)
				MoveSetStance("",GL_STANCE_STAND)
				Sleep(6)
				ReleaseLocator("","CellPos6"..Cell)
			end

		elseif (Action == 2) then
			if GetFreeLocatorByName("Prison", "Cell"..Cell.."Sleep",-1,-1, "CellPos7"..Cell) then
				SetData("BlockedCell","CellPos7"..Cell)
				BlockLocator("","CellPos7"..Cell)
				f_MoveTo("", "CellPos7"..Cell)
				Sleep(1)
				PlayAnimationNoWait("","talk")
				MsgSay("","@L_PRISON_1_ARREST_PACING")
				Sleep(4)
				MoveSetStance("",GL_STANCE_LAY)
				Sleep(20)
				MoveSetStance("",GL_STANCE_STAND)
				Sleep(6)
				ReleaseLocator("","CellPos7"..Cell)
			end

		elseif (Action == 3) then
			if GetFreeLocatorByName("Prison", "Cell"..Cell.."B",-1,-1, "CellPos8"..Cell) then
				SetData("BlockedCell","CellPos8"..Cell)
				BlockLocator("","CellPos8"..Cell)
				f_MoveTo("", "CellPos8"..Cell)
				PlayAnimationNoWait("","talk")
				MsgSay("","@L_PRISON_1_ARREST_PACING")
				-- Stroll("",200,10)
				Sleep(3)
				PlayAnimationNoWait("","talk")
				MsgSay("","@L_PRISON_1_ARREST_PACING")
				-- Stroll("",200,5)
				Sleep(2)
				PlayAnimation("","cogitate")
				Sleep(1)
				-- Stroll("",200,10)
				ReleaseLocator("","CellPos8"..Cell)
			end

		elseif (Action == 4) then
			if GetFreeLocatorByName("Prison", "Cell"..Cell.."B",-1,-1, "CellPos9"..Cell) then
				SetData("BlockedCell","CellPos9"..Cell)
				BlockLocator("","CellPos9"..Cell)
				f_MoveTo("", "CellPos9"..Cell)
				Sleep(1)
				MoveSetStance("",GL_STANCE_SITGROUND)
				MsgSayNoWait("","@L_PRISON_1_ARREST_MONOLOGUE")
				Sleep(25)
				MsgSayNoWait("","@L_PRISON_1_ARREST_MONOLOGUE")
				Sleep(25)
				MoveSetStance("",GL_STANCE_STAND)
				Sleep(6)
				ReleaseLocator("","CellPos9"..Cell)
			end
			f_Stroll("",200,10)
			if GetFreeLocatorByName("Prison", "Cell"..Cell.."C",-1,-1, "CellPos10"..Cell) then
				SetData("BlockedCell","CellPos10"..Cell)
				BlockLocator("","CellPos10"..Cell)
				f_MoveTo("", "CellPos10"..Cell)
				Sleep(1)
				MoveSetStance("",GL_STANCE_SITGROUND)
				Sleep(14)
				MoveSetStance("",GL_STANCE_STAND)
				Sleep(6)
				ReleaseLocator("","CellPos10"..Cell)
			end
		end

		Sleep(1)
end

function CleanUp()
	ResetProcessProgress("")
	SimResetBehavior("")
	SetState("", STATE_IMPRISONED, false)
	SetState("", STATE_CUTSCENE, false)
	SetState("", STATE_CAPTURED, false)
	if HasProperty("", "Imprisoned") then
		local CellNumber = GetData("CellNumber")
		if not CellNumber then
			CellNumber = 1
		end
		GetLocatorByName("Prison", "Cell"..CellNumber.."TeleportTargetPos", "CellTeleportTargetPos")
		SimBeamMeUp("", "CellTeleportTargetPos", false)
		StopAnimation("")		
		if not HasProperty("", "GettingTortured") then	
			f_ExitCurrentBuilding("")
		end
		RemoveProperty("", "Imprisoned")
	end
	if HasData("BlockedCell") then
		ReleaseLocator("", GetData("BlockedCell"))
	end
	RemoveProperty("", "CellNumber")
end