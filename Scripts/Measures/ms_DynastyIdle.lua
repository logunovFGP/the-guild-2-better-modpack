function Run()
	
	chr_CheckHome("") -- make sure we have a home
	
	-- special behavior banned
	if GetImpactValue("", "banned") == 1 then
		MeasureRun("", nil, "DynastyBanned")
		return
	end
	
	-- Do nothing once in a while
	local DoNothing = GetProperty("", "_DO_NOTHING_TIME") or 0
	if DoNothing > 0 then
		RemoveProperty("", "_DO_NOTHING_TIME")
		DoNothing = Gametime2Realtime(DoNothing)
		Sleep(DoNothing)
	end 
	
	-- cleanup moveset
	if GetImpactValue("", "Sickness") < 1 then
		MoveSetActivity("")
	end	
	
	-- check for treatment need
	if chr_NeedsTreatment("") then
		if gameplayformulas_CheckMoneyForTreatment("") == 1 then
			if ReadyToRepeat("", "ai_VisitDoc") then
				idlelib_VisitDoc()
			end
		end
	end
	
	-- check again. If still true, go to the market
	if chr_NeedsTreatment("") then
		idlelib_Illness()
		SetProperty("", "_DO_NOTHING_TIME", 4)
		return
	end
	
	--Sleep at night?
	local currentGameTime = math.mod(GetGametime(),24)
	if (currentGameTime >23 or currentGameTime < 4) then
		idlelib_GoSleep()
		SetProperty("", "_DO_NOTHIING_TIME", 1)
		return
	end
	
	-- WIP 
	
	local	Value = Rand(80)
	
	if Value < 10 then
	  idlelib_GoTownhall()
	elseif Value < 15 then
		idlelib_GoToRandomPosition()
	elseif Value < 30 then
	  if DynastyGetRandomBuilding("",8,111,"Schlossie") then
			idlelib_DinnerAtEstate()
		else
		  idlelib_SitDown()
		end
	elseif Value < 35 then
	  if IsPartyMember("") then
			idlelib_CheckInsideStore()
		else
		  idlelib_BuySomethingAtTheMarket(Rand(2)+1)
		end
	elseif Value < 40 then
-- ******** THANKS TO KINVER ********
		local checkBOK = false
		if HasProperty("", "TimeBank") then
			local gtime = GetProperty("", "TimeBank")
			if gtime < GetGametime() then
				checkBOK = true
			end
		else
			checkBOK = true
		end

		if not HasProperty("","SchuldenGeb") and Rand(5)==0  then
			idlelib_TakeACredit()
		elseif HasProperty("","SchuldenGeb") and (Rand(5)>2) and (checkBOK) then
			idlelib_ReturnACredit()
		end
-- **********************************
	elseif Value < 60 then
	  local zufall = Rand(100)
		if zufall > 85 then
		  if Rand(2) == 0 then
			  idlelib_BeADrunkChamp()
			else
				idlelib_BeADiceChamp()
			end
		else
			idlelib_DoNothing()
		end
	elseif Value < 70 then
		idlelib_UseCocotte()
	elseif Value < 80 then
		idlelib_CollectWater()
	else
	  if SimGetClass("") == 4 then
		  idlelib_GoToDivehouse()
		else
		  if Rand(3) == 1 then
				idlelib_GoToDivehouse()
			else
		    idlelib_GoToTavern()
			end
		end
	end
end
