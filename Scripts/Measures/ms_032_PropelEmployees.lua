-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_032_PropelEmployees"
----
----	with this measure the player can propel the employees in one of his
----	workshops. The employee's productivity is increased while their loyalty
----	is lowed.
----
-------------------------------------------------------------------------------

function Run()

	local MeasureID = GetCurrentMeasureID("")
	local duration = mdata_GetDuration(MeasureID)
	local TimeOut = mdata_GetTimeOut(MeasureID)
	
	if not GetInsideBuilding("", "Building") then
		if AliasExists("Destination") then
			if f_MoveTo("", "Destination", GL_MOVESPEED_RUN, false) then
				CopyAlias("Destination", "Building")
			else
				return
			end
		else
			return
		end
	end
	
	MeasureSetStopMode(STOP_CANCEL)
	
	local Count = BuildingGetWorkerCount("Building")
	local Found = 0
	
	-- change the check from GetInsideBuilding to SimIsWorkingTime to make it possible to use this measure on outside workers at farms/mines/etc.
	local Alias
	if BuildingIsWorkingTime("Building") then
		for number=0, Count-1 do
			Alias = "Worker"..Found
			if BuildingGetWorker("Building", number, Alias) then
				if SimIsWorkingTime(Alias) then
					Found = Found + 1
				end
			end
		end
	end
	
	if Found == 0 then
		MsgQuick("", "@L_GENERAL_MEASURES_032_PROPELEMPLOYEES_FAILURES_+0", GetID("Building"))
		return
	end

	-- move player character to propel position
	if not GetLocatorByName("Building", "Propel", "PropelPosition") then
		GetLocatorByName("Building", "work_01", "PropelPosition")
	end
	
	if not AliasExists("PropelPosition") then
		return
	end

	f_MoveTo("", "PropelPosition")
	MeasureSetNotRestartable()
	
	local LoyaltyLoss
	local Rhetoric = GetSkillValue("", RHETORIC)

	if (Rhetoric < 2) then
		LoyaltyLoss = -15
	elseif (Rhetoric < 4) then
		LoyaltyLoss = -12
	elseif (Rhetoric < 6) then
		LoyaltyLoss = -9
	elseif (Rhetoric < 8) then
		LoyaltyLoss = -6
	else
		LoyaltyLoss = -3
	end
	
	for number=0, Found-1 do
		Alias = "Worker"..number
		if SimPauseWorking(Alias) then
			SendCommandNoWait(Alias, "Listen")
		end
	end
	
	AlignTo("", "Worker0")
	Sleep(1)

	-- play the animation for the player character
	PlayAnimationNoWait("", "propel")

	MsgSay("", "@L_GENERAL_MEASURES_032_PROPELEMPLOYEES_STATEMENT")

	-- boost the productivity
	local Boost = 0.20 + (GetSkillValue("", CRAFTSMANSHIP)*0.05)
	local BoostDuration = duration * GetImpactValue("", "PropelSpeedupTime")*0.01 -- ability
	LoyaltyLoss = math.floor(LoyaltyLoss * 0.01 * GetImpactValue("", "PropelFavorMalus")) -- ability
	
	for number=0, Found-1 do
		Alias = "Worker"..number
		if LoyaltyLoss ~= 0 then
			AnimTime = PlayAnimationNoWait(Alias, "devotion")
			chr_ModifyFavor(Alias, "Owner", LoyaltyLoss)
		end
		
		AddImpact(Alias, "Productivity", Boost, BoostDuration)	
	end
	
	SetMeasureRepeat(TimeOut)
	Sleep(0.5)
	local XPAmount = GetData("BaseXP")
	XPAmount = XPAmount * Count
	chr_GainXP("", XPAmount)
	Sleep(0.5)
	StopMeasure()
end

function Listen()
	-- simplified this logic to make it possible to propel on farms or alchemist huts if the workers are outside building
	AlignTo("", "Owner")
	while true do
		Sleep(42)
	end
end

function CleanUp()
	StopAnimation("")
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
	--active time:
	OSHSetMeasureRuntime("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+0", Gametime2Total(mdata_GetDuration(MeasureID)))
end

