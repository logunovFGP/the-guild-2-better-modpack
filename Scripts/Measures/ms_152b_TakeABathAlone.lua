-- -----------------------
-- Run
-- -----------------------
function Run()

	if IsStateDriven() then
		
		if not f_MoveTo("", "Destination", GL_MOVESPEED_RUN) then
			return
		end
		
		if GetInsideBuilding("", "Tavern") then
			if not (GetID("Destination") == GetID("Tavern")) then
				return
			end
		else
			return
		end
	end
	
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	local OverallPrice = 350
	
	-- Stop a possibly following courtlover from following
	if SimGetCourtLover("", "CourtLover") then
		chr_StopFollowing("CourtLover", "")
	end
	
	local Money = GetMoney("")
	if Money < OverallPrice then
		MsgBox("", "", "","@L_GENERAL_ERROR_HEAD_+0", "@L_TAVERN_152_TAKEABATH_FAILURES_+1", OverallPrice)
		return false
	end
	
	if not GetInsideBuilding("", "Tavern") then
		return false
	end		
	
	-----------------------------------------
	------ Check bath free and reserve ------
	-----------------------------------------
	if not GetLocatorByName("Tavern", "Bath1", "BathPosition") then
		MsgQuick("", "_TAVERN_152_TAKEABATH_FAILURES_+0", GetID("Tavern"))
		return false
	end
	
	if HasProperty("Tavern", "BathInUse") then
		MsgQuick("", "_TAVERN_152_TAKEABATH_FAILURES_+0", GetID("Tavern"))
		return false
	else
		SetProperty("Tavern", "BathInUse", 1)
	end	

	-- Go to the bath
	f_MoveTo("", "BathPosition")
	if not f_BeginUseLocator("", "BathPosition", GL_STANCE_STAND, true) then
		return false
	end
	
	SetData("Bathing", 1)

	local MaxHP = GetMaxHP("")
	local ToHeal = 0.15 * MaxHP
	local Progress = 0
	
	SetMeasureRepeat(TimeOut)
	
	-- Pay if the tavern does not belong to the owners dynasty
	if GetDynastyID("Tavern") ~= GetDynastyID("") then
		if not chr_SpendMoney("", OverallPrice, "CostSocial") then
			MsgQuick("", "_TAVERN_152_TAKEABATH_FAILURES_+0", GetID("Tavern"))
			return
		end
		CreditMoney("Tavern", OverallPrice "Offering")
	end

	-- Bathing
	GfxStartParticle("Steam", "particles/bath_steam.nif", "BathPosition", 2.5)
	
	PlaySound3DVariation("", "measures/takeabath_alone", 1)
	Sleep(2)
	
	while(Progress < 5) do
		PlaySound3DVariation("", "measures/takeabath_alone", 1)
		Sleep(2)
		if GetHP("") < MaxHP then
			ModifyHP("", ToHeal)
		end
		Progress = Progress +1
		Sleep(0.5)
	end

	GfxStopParticle("Steam")
	
	if GetFreeLocatorByName("Tavern", "Stroll", 1, 5, "EndPos") then
		f_MoveTo("", "EndPos")
	end
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()

	if AliasExists("Tavern") then
		RemoveProperty("Tavern", "BathInUse")
	end

	if AliasExists("Steam") then
		GfxStopParticle("Steam")
	end
	StopAnimation("")
end

-- -----------------------
-- GetOSHData
-- -----------------------
function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
	OSHSetMeasureCost("@L_INTERFACE_HEADER_+6", 350) -- check OverallPrice!
end

