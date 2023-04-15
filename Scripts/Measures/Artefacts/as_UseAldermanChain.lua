-------------------------------------------------------------------------------
----
----	OVERVIEW "as_UseAldermanChain"
----
----	with this artifact, the player can increase the favour to other characters
----	in range
----
-------------------------------------------------------------------------------

function Run()

	if GetImpactValue("", "jewellery") > 0 then
		MsgQuick("", "@L_GENERAL_MEASURES_JEWELLERY_FAILURES_+0", GetID(""))
		StopMeasure()
	end

	if IsStateDriven() then
		
		local ItemName = "AldermanChain"
		if GetItemCount("", ItemName, INVENTORY_STD) == 0 then

			GetSettlement("", "my_settlement")

			CityGetRandomBuilding("my_settlement", -1, GL_BUILDING_TYPE_GUILDHOUSE, -1, -1, FILTER_IGNORE, "guildhouse")
			if not f_MoveTo("", "guildhouse") then
				return false
			end

			MeasureRun("", nil, "BuyAldermanChain")
		end
	end

	local MeasureID = GetCurrentMeasureID("")
	local duration = mdata_GetDuration(MeasureID)
	local TimeOut = mdata_GetTimeOut(MeasureID)

	--play animation
	local Time
	Time = PlayAnimationNoWait("", "use_object_standing")
	Sleep(1)
	PlaySound3D("", "Locations/wear_clothes/wear_clothes+1.wav", 1.0)
	Sleep(1)
	
	if RemoveItems("", "AldermanChain", 1) > 0 then	
		SetMeasureRepeat(TimeOut)
		AddImpact("", "jewellery", 1, duration)
		SetState("", STATE_JEWELLERY, true)

		SetProperty("", "jewellery", 8)
		
		chr_GainXP("", GetData("BaseXP"))
	end
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2",Gametime2Total(mdata_GetTimeOut(MeasureID)))
	--active time:
	OSHSetMeasureRuntime("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+0",Gametime2Total(mdata_GetDuration(MeasureID)))
end

function CleanUp()
end
