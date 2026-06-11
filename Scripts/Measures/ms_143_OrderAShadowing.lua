-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_143_OrderAShadowing"
----
----	with this measure, the player can send a myrmidon to spy out an sim
----	after 2h the character sheet of the destination will be revealed
----
----	Community Update: a player-ordered shadowing never ended, because the only
----	exit of the loop was the AI-only TimeOut. It now runs on the game timer
----	like the other timed measures and reveals the sheet when the time is up.
----
-------------------------------------------------------------------------------

function Run()
	if not AliasExists("Destination") then
		return
	end
	
	local TimeToShadow = 2
	
	AddImpact("","spying",1,-1)
	
	MsgMeasure("","@L_GENERAL_MEASURES_143_ORDERASHADOWING_ACTION_+0", GetID("Destination"))
	
	
	local WhatToDo
	local SpyTheHouse
	local i
	local k
	local Radius = 2000
	
	local	TimeOut
	TimeOut = GetData("TimeOut")
	if TimeOut then
		TimeOut = GetGametime() + TimeOut
	end
	
	StartGameTimer(TimeToShadow)
	GetDynasty("Destination","DestDynasty")
	local OwnerDyn = GetDynastyID("")
	SendCommandNoWait("","Progress")
	MeasureSetNotRestartable()

	-- shadow until the time is up
	while not CheckGameTimerEnd() do

		if not AliasExists("Destination") then
			break
		end
		
		if TimeOut then
			if TimeOut < GetGametime() then
				break
			end
		end
		
		--what the spy should do
		WhatToDo = Rand(4)
		
		--simply move to the last known position of the victim
		if (WhatToDo == 0) then
			if GetInsideBuilding("Destination","Building") then
				GetOutdoorMovePosition("","Building","OutdoorMovePos")
				f_MoveTo("","OutdoorMovePos",GL_MOVESPEED_RUN,"Victim",500)
			else
				f_MoveTo("","Destination",GL_MOVESPEED_RUN,"Victim",1000)
			end
			AlignTo("","Destination")
			Sleep(1)
			k = Rand(2)
			if (k == 0) then
				PlayAnimation("","watch_for_guard")
			end
		--stand around and cogitate
		elseif (WhatToDo == 1) then
			local Houses = Find("","__F( (Object.GetObjectsByRadius(Building)=="..Radius.."))", "FindResult",1)
			if Houses > 0 then
				GetOutdoorMovePosition("","FindResult","OutdoorMovePos")
				f_MoveTo("","OutdoorMovePos",GL_MOVESPEED_RUN,200)
			end
			
			AlignTo("","Destination")
			Sleep(1)
			k = Rand(2)
			if (k == 0) then
				PlayAnimation("","cogitate")
			end
			
		--stand around and eat
		elseif (WhatToDo == 2) then	
			PlayAnimation("","watch_for_guard")
			
		--move to the home building of the victim 
		elseif (WhatToDo == 3) then
			SpyTheHouse = 1
			if GetHomeBuilding("Destination","VictimsHome") then
				GetOutdoorMovePosition("","VictimsHome","OutdoorMovePos")
				f_MoveTo("","OutdoorMovePos",GL_MOVESPEED_RUN ,"Victim",500)
			
				--start observation
				while (SpyTheHouse == 1) do
					if CheckGameTimerEnd() then
						SpyTheHouse = 0
					else
						WhatToDo = Rand(4)
						--Go around the house
						if (WhatToDo == 0) then
							for i=1, 4 do
								if GetLocatorByName("VictimsHome", "Walledge"..i, "VictimsCorner"..i) then
									f_MoveTo("", "VictimsCorner"..i, GL_MOVESPEED_SNEAK, 50)
								end
								Sleep(1)
								k = Rand(2)
								if (k == 0) then
									PlayAnimation("","watch_for_guard")
								end
							end
						elseif (WhatToDo == 1) then
							if GetLocatorByName("VictimsHome", "Entry1", "VictimsEntry") then
								f_MoveTo("", "VictimsEntry", GL_MOVESPEED_SNEAK, 50)
							end
							Sleep(3)
						--cancel building observation
						else
							SpyTheHouse = 0
						end
					end
				end
			end
		end
	Sleep (5)
	
	end
	
	-- time is up: reveal the character sheet
	if CheckGameTimerEnd() and AliasExists("Destination") then
		GetDynasty("Destination","DestDynasty")
		if not HasProperty("DestDynasty","BeeingShadowedBy"..OwnerDyn) then
			SetProperty("DestDynasty","BeeingShadowedBy"..OwnerDyn,1)
			feedback_MessageCharacter("",
				"@L_GENERAL_MEASURES_143_ORDERASHADOWING_MSG_SUCCESS_HEAD_+0",
				"@L_GENERAL_MEASURES_143_ORDERASHADOWING_MSG_SUCCESS_BODY_+0",GetID(""),GetID("Destination"))
			achievements_Unlock("", "CRIME_ORDER_SHADOWING")
		end
		SetProperty("", "CU_ShadowDone", 1)   -- completed, keep the reveal
	end
	
	StopMeasure()
end

function Progress()
	local MaxProgress = 2 * 10
	SetProcessMaxProgress("",MaxProgress)
	local ProgressStartTime = GetGametime()
	local ProgressEndTime = GetGametime() + 2
	while (GetGametime() < ProgressEndTime) do
		SetProcessProgress("",(GetGametime()-ProgressStartTime)*10)
		Sleep(1)
	end
	
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	StopAnimation("")
	AddImpact("","spying",-1,-1)
	ResetProcessProgress("")

	-- keep the reveal when completed, clear it on early cancel
	local completed = HasProperty("", "CU_ShadowDone")
	if completed then
		RemoveProperty("", "CU_ShadowDone")
	end
	if not completed then
		if AliasExists("Destination") then
			local DestDyn = GetDynasty("Destination","DestDynasty")
			local OwnerDyn = GetDynastyID("")
			if HasProperty("DestDynasty","BeeingShadowedBy"..OwnerDyn) then
				RemoveProperty("DestDynasty","BeeingShadowedBy"..OwnerDyn)
			end
		end
	end

	MsgMeasure("","")
	if SimGetWorkingPlace("","SpyWorkBuilding") then
		f_MoveToNoWait("","SpyWorkBuilding")
	end
end

