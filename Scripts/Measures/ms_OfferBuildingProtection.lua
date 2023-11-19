function AIInitPressProtMoneyVictim()

	GetDynasty("Destination", "VictimDyn")
	local v = BuildingGetLevel("Destination")
	local p = 500 * v
	local kivermog = GetMoney("VictimDyn")

	if DynastyGetDiplomacyState("", "VictimDyn") > DIP_NEUTRAL  then
		if DynastyGetDiplomacyState("", "VictimDyn") == DIP_NAP then
			p = 400 * v -- low price for not attack
		elseif DynastyGetDiplomacyState("", "VictimDyn") == DIP_ALLIANCE then
			p = 250 * v -- lower price for allied
		end
	end
	
	if ((kivermog / 100) * 50) < p then
	    return "C"
	end

	if Rand(100) > 20 then
		return "O"
	else
		return "C"
	end

end

function Run()
	
	if not GetDynasty("Destination", "VictimDyn") then 
		StopMeasure()
	end

	if DynastyGetDiplomacyState("","VictimDyn") < DIP_NEUTRAL then
		MsgQuick("","@L_MEASURE_OFFERBUILDINGPROTECTION_FAIL_+0")
		StopMeasure()
	end
	
	if HasProperty("Destination", "RobberProtected") then
		MsgQuick("", "@L_MEASURE_OFFERBUILDINGPROTECTION_FAIL_+1")
		StopMeasure()
	end
	
	if not SimGetWorkingPlace("", "MyRobberCamp") then
		StopMeasure()
	end
	
	if not BuildingGetOwner("MyRobberCamp","MrRobber") then
		StopMeasure()
	end
		
	local value = BuildingGetLevel("Destination")
	local price = 500 * value
	
	if DynastyGetDiplomacyState("", "VictimDyn") > DIP_NEUTRAL  then
        if DynastyGetDiplomacyState("", "VictimDyn") == DIP_NAP then
            price = 400 * value -- low price for not attack
        elseif DynastyGetDiplomacyState("", "VictimDyn") == DIP_ALLIANCE then
            price = 250 * value -- lower price for allied
        end
	end
	
	if GetMoney("VictimDyn") < price then
	    MsgQuick("", "@L_MEASURE_OFFERBUILDINGPROTECTION_FAIL_+2")
	    StopMeasure()
	end
	
	--move to house
	if not GetOutdoorMovePosition("", "Destination", "DoorPos") then
		StopMeasure()
	end
	if not f_MoveTo("", "DoorPos", GL_MOVESPEED_RUN) then
		StopMeasure()
	end
	
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	local iMyDynID = GetDynastyID("")
	local iVictimID = GetID("Destination")
	SetProperty("Destination", "RobberProtected", iMyDynID)


	BuildingGetOwner("MyRobbercamp","MrRobber")
	BuildingGetOwner("Destination","MrProtectionMoney")
	local OwnerID = GetID("MrRobber")
		
	if GetDynastyID("Destination") ~= GetDynastyID("") then -- message to the victim, if the "victim" is not our own dynasty
       
		--waits for 1 hour
		local result = MsgNews("Destination","Destination","@P"..
				"@B[O,@L_MEASURE_OFFERBUILDINGPROTECTION_SAY_+0]"..
				"@B[C,@L_MEASURE_OFFERBUILDINGPROTECTION_SAY_+1]",
				ms_offerbuildingprotection_AIInitPressProtMoneyVictim,"default",1,
				"@L_MEASURE_OFFERBUILDINGPROTECTION_HEAD_+0",
				"@L_MEASURE_OFFERBUILDINGPROTECTION_BODY_+0", 
				GetID("MrRobber"),GetID("Destination"), preis)
		
		if result=="O" then
			--wants to pay
			feedback_MessageCharacter("",
				"@L_MEASURE_OFFERBUILDINGPROTECTION_HEAD_+1",
				"@L_MEASURE_OFFERBUILDINGPROTECTION_BODY_+1",
				GetID("Destination"), price)
      	    
			SetMeasureRepeat(TimeOut)
			SetProperty("", "TotalMoney", price)
			SetProperty("", "RobberProtecting", iVictimID)
			SetState("", STATE_GUARDING, true)
			StopMeasure()
		else
			--doesnt wanna pay
			feedback_MessageCharacter("",
				"@L_MEASURE_OFFERBUILDINGPROTECTION_HEAD_+2",
				"@L_MEASURE_OFFERBUILDINGPROTECTION_BODY_+2",
				GetID("MrProtectionMoney"), GetID("Destination"))
			
			-- cancel measure
			RemoveProperty("Destination", "RobberProtected")
			StopMeasure()
		end
	else   -- if it is our own dynasty, we want to protect our building for free without getting a notification
		SetMeasureRepeat(TimeOut)
		SetProperty("", "TotalMoney", price)
		SetProperty("", "RobberProtecting", iVictimID)
		SetState("", STATE_GUARDING, true)
	end
end

function CleanUp()

end

function GetOSHData(MeasureID)
	--active time:
	OSHSetMeasureRuntime("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+0", 12)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end

