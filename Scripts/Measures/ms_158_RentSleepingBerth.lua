-- -----------------------
-- Run
-- -----------------------
function Run()

	-- get the tavern
	if not GetInsideBuilding("", "Tavern") then
		return
	end

	local MyDynastyID = GetDynastyID("")
	local Money = GetMoney("")
	local Price = 150
	
	-- Not sleepy?
	if GetImpactValue("", "GoodDream") > 0 or GetImpactValue("", "VeryGoodDream") > 0 or GetImpactValue("", "BadDream") >0 then
		if IsPartyMember("") then
			MsgBoxNoWait("", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+2", GetID(""))
		end
		return
	end
	
	-- check both sleeping berths
	if not GetFreeLocatorByName("Tavern", "Berth", 1, 2, "SleepingBerth") then
		if IsPartyMember("") then
			MsgBoxNoWait("", "Tavern", "@L_GENERAL_ERROR_HEAD_+0", "@L_TAVERN_158_RENTSLEEPINGBERTH_FAILURES_+1", GetID("Tavern"))
		end
		return
	end
	
	-- spend money if not same dynasty
	if GetDynastyID("") ~= GetDynastyID("Tavern") then
		if not chr_SpendMoney("", Price, "CostSocial") then
			if IsPartyMember("") then
				MsgBoxNoWait("", "Tavern", "@L_GENERAL_ERROR_HEAD_+0",  "@L_TAVERN_158_RENTSLEEPINGBERTH_FAILURES_+0", Price)
			end
			return
		end

		CreditMoney("Tavern", Price, "RentABerth")
		-- for the balance
	--	local OldBalance = 0
	--	if HasProperty("Tavern", "BalanceSleepingFee") then
	--		OldBalance = GetProperty("Tavern", "BalanceSleepingFee")
	--	end
	--	SetProperty("Tavern", "BalanceSleepingFee", (OldBalance+Price))
	end

	-- go to the berth
	f_BeginUseLocator("", "SleepingBerth", GL_STANCE_LAY, true)
		
	-- sleep
	local HasToSleep = 4 -- 2 hours faster than at home
	SetData("Duration", HasToSleep)
	local WasSick = false
	
	if GetImpactValue("", "Sickness") >0 then
		WasSick = true
	end
	
	local CurrentHP = GetHP("")
	local MaxHP = GetMaxHP("")
	local ToHeal = MaxHP - CurrentHP
	local HealPerTic = ToHeal / (HasToSleep * 12)
	local StartTime = GetGametime()
	local MaxProgress = HasToSleep * 10
	SetProcessMaxProgress("", MaxProgress)
	SetData("StartTime", StartTime)
	local EndTime = GetGametime() + HasToSleep
	
	while GetGametime() < EndTime do
		
		Sleep(5)
		SetProcessProgress("", (GetGametime()-StartTime)*10)
		-- increase the hp
		if GetHP("") < MaxHP then
			ModifyHP("", HealPerTic, false)
			PlaySound3DVariation("", "measures/gotosleep", 0.8)
		end
	end

	-- Cure some diseases
	if WasSick then
		if GetImpactValaue("", "HerbTea") > 0 then -- herb tea helps
			local CheckDisease = { "Cold", "Sprain", "BurnWound", "Influenza", "Pneumonia", "Pox", "BlackDeath", "Fracture" }
			local SleepBonus = GetImpactValue("", "SleepBonusI")
	
			for i=1, 7 do
				if GetImpactValue("", CheckDisease[i]) > 0 then
					if CheckDisease[i] == "Cold" then
						Cold.cureSim("")
					else
						if SleepBonus > 0 then
							if CheckDisease[i] == "Sprain" then
								Sprain.cureSim("")
							elseif CheckDisease[i] == "BurnWound" then
								BurnWound.cureSim("")
							elseif CheckDisease[i] == "Influenza" then
								Influenza.cureSim("")
							elseif CheckDisease[i] == "Pneumonia" then
								Pneumonia.cureSim("")
							elseif CheckDisease[i] == "Pox" then
								Pox.cureSim("")
							elseif CheckDisease[i] == "BlackDeath" then
								Blackdeath.cureSim("")
							elseif CheckDisease[i] == "Fracture" then
								Fracture.cureSim("")
							end
						end
					end
				end
			end
		else -- no tea? then healing is random at 66 % (tavern value)
			if Rand(100) > 33 then
				if GetImpactValue("", "Cold") > 0 then
					Cold.cureSim("")
				end
					
				if GetImpactValue("", "Sprain") > 0 then
					Sprain.cureSim("")
				end
					
				if GetImpactValue("", "Influenza") > 0 then
					Influenza.cureSim("")
				end
			end
		end
	end
	
	-- good dream bonus in best house
	local BoostValue = 1
	if GetImpactValue("Tavern", "BestHouseBoost") > 0 then
		AddImpact("", "VeryGoodDream", 1, 12)
		BoostValue = 2
	else
		AddImpact("", "GoodDream", 1, 12)
	end
	
	if SimGetClass("") == 1 then
		AddImpact("", "constitution", BoostValue, 12)
		AddImpact("", "empathy", BoostValue, 12)
		AddImpact("", "bargaining", BoostValue, 12)
	elseif SimGetClass("") == 2 then
		AddImpact("", "constitution", BoostValue, 12)
		AddImpact("", "dexterity", BoostValue, 12)
		AddImpact("", "craftsmanship", BoostValue, 12)
	elseif SimGetClass("") == 3 then
		AddImpact("", "charisma", BoostValue, 12)
		AddImpact("", "rhetoric", BoostValue, 12)
		AddImpact("", "secret_knowledge", BoostValue, 12)
	elseif SimGetClass("") == 4 then
		AddImpact("", "constitution", BoostValue, 12)
		AddImpact("", "fighting", BoostValue, 12)
		AddImpact("", "shadow_arts", BoostValue, 12)
	end
			
	-- end sleeping
	f_EndUseLocator("", "SleepingBerth", GL_STANCE_STAND)
	
	if IsPartyMember("") then
		feedback_MessageCharacter("","@L_GENERAL_MEASURES_010_GOTOSLEEP_WAKEUP_HEAD",
							"@L_GENERAL_MEASURES_010_GOTOSLEEP_WAKEUP_BODY", GetID("Owner"))
	end
end

function AIDecision()
	return "O"
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	if AliasExists("SleepingBerth") then
		f_EndUseLocator("", "SleepingBerth", GL_STANCE_STAND)
	end
	
	ResetProcessProgress("")
	feedback_OverheadComment("Owner")
end

function GetOSHData(MeasureID)
	OSHSetMeasureCost("@L_INTERFACE_HEADER_+6",150)
end

