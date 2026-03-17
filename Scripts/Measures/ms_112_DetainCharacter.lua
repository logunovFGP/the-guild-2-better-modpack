function Run()
	if GetState("Destination", STATE_IMPRISONED) then
		MsgQuick("", "The Destination is already in prison.")
		return
	end

	GetSettlement("Owner", "CityAlias")

	if not CityGetRandomBuilding("CityAlias", -1, GL_BUILDING_TYPE_PRISON, -1, -1, FILTER_IGNORE, "Prison") then
		MsgQuick("", "There is no available prison.")
		return
	end

	if not ai_CreateMutex("CityAlias") then
		return
	end

	local MeasureID = GetCurrentMeasureID("")
	
	GetPosition("CityAlias", "CityPos")
	if GetInsideBuilding("Destination", "CurrentBuilding") then
		GetPosition("CurrentBuilding", "BuildingPos")
		if GetDistance("BuildingPos", "CityPos") > 10000 then
			MsgQuick("", "@L_GENERAL_MEASURES_FAILURES_+23")
			StopMeasure()
		end
	else
		GetPosition("Destination", "DestPos")
		if GetDistance("CityPos", "DestPos") > 10000 then
			MsgQuick("", "@L_GENERAL_MEASURES_FAILURES_+23")
			StopMeasure()
		end
	end
	
	if not ai_StartInteraction("", "Destination", 1000, 100, nil) then
		StopMeasure()
	end

	AlignTo("Owner", "Destination")
	AlignTo("Destination", "Owner")
	Sleep(0.5)

	SimGetServantDynasty("", "ActorDyn")
	
	local found = false
	for i = 0,2 do
		if DynastyGetMember("ActorDyn", i, "Actor") then
			if GetSettlementID("Actor") == GetSettlementID("") then
				if GetImpactValue("Actor", "CommandCityGuard") then -- 227
					found = true
					break
				end
			end
		end
	end		

	SimGetWorkingPlace("", "Workbuilding")
	SetRepeatTimer("Workbuilding", GetMeasureRepeatName(), mdata_GetTimeOut(MeasureID))

	local _Actor = "Actor"

	if not found then
		_Actor = "ActorDyn"
	end

	feedback_MessageCharacter("Destination", "@L_PRIVILEGES_112_DETAINCHARACTER_MSG_VICTIM_HEAD_+0", "@L_PRIVILEGES_112_DETAINCHARACTER_MSG_VICTIM_BODY_+1", GetID(_Actor), GetID("Destination"), GetID("CityAlias"))
	CityAddPenalty("CityAlias", "Destination", PENALTY_PRISON, mdata_GetDuration(MeasureID))
	achievements_Unlock("", "PRIVILEGE_ARREST_SOMEONE")

	LogMessage("@NAO "..GetName("Destination").." is serving a Prison penalty in "..GetName("CityAlias"))

	MeasureRun("", "Destination", "Arrest")

	--[[f_FollowNoWait("Owner", "Destination", GL_MOVESPEED_WALK, 130)

	if GetOutdoorMovePosition(nil, "Prison", "MovePos") then
		if not (f_MoveTo("Destination", "MovePos", GL_MOVESPEED_WALK)) then
			StopMeasure()
			return
		end	
	else
		if not (f_MoveTo("Destination", "Prison", GL_MOVESPEED_WALK)) then
			StopMeasure()
			return
		end
	end

	f_MoveTo("Owner", "Prison", GL_MOVESPEED_WALK, "MoveResult")--]]
end

function CleanUp()
	if GetID("CityAlias") == -1 then
		return
	end
	ai_ReleaseMutex("CityAlias", "")
end

function GetOSHData(MeasureID)
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2",Gametime2Total(mdata_GetTimeOut(MeasureID)))
	OSHSetMeasureRuntime("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+0",Gametime2Total(mdata_GetDuration(MeasureID)))
end