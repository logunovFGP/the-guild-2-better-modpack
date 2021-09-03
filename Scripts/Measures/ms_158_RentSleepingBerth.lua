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
	-- hier muss noch der Preis anhand der Preisangabe des Wirtes errechnen
	local Price = 150
	

	-- Not sleepy?
	if GetImpactValue("","GoodDream")>0 or GetImpactValue("","BadDream") >0 then
		MsgQuick("", "@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+2", GetID(""))
		StopMeasure()
	end
	
	-- check both sleeping berths
	if not GetFreeLocatorByName("Tavern", "Berth", 1, 2, "SleepingBerth") then	
		MsgQuick("", "@L_TAVERN_158_RENTSLEEPINGBERTH_FAILURES_+1", GetID("Tavern"))
		return
	end

	if GetDynastyID("") ~= GetDynastyID("Tavern") then
		if not chr_SpendMoney("", Price, "CostSocial") then
			MsgQuick("", "@L_TAVERN_158_RENTSLEEPINGBERTH_FAILURES_+0", Price)
			StopMeasure()
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
	
	local HasToSleep = 6
	if GetImpactValue("", "SleepRecoverBonus") >0 then
		HasToSleep = 3.5
	end

	SetData("Duration", HasToSleep)
	
	local WasSick = false
	if GetImpactValue("", "Sickness") >0 then
		WasSick = true
	end
	
	local HeavySleep = SimHasAbility("", 32)  --Deep Sleep ability
	local CurrentHP = GetHP("")
	local MaxHP = GetMaxHP("")
	local ToHeal = MaxHP - CurrentHP
	local HealPerTic = ToHeal / (HasToSleep * 10)
	if HeavySleep then
		HealPerTic = HealPerTic*1.5
	end
	local StartTime = GetGametime()
	SetData("StartTime", StartTime)

	local EndTime = GetGametime() + HasToSleep
	
	-- increase the hp due to the recover factor for the tavern
	while GetGametime() < EndTime do
		
		Sleep(5)
		
		if GetHP("") < MaxHP then
			ModifyHP("", HealPerTic, false)
			PlaySound3DVariation("", "measures/gotosleep", 0.8)
		end
	end

	-- Cure Cold, Sprain and maybe Influenza
	if WasSick == true then
		diseases_Cold("", false)
		diseases_Sprain("", false)
		if HeavySleep then
			diseases_Influenza("", false)
			if Rand(3) > 0 then
				diseases_Pneumonia("", false)
			end
		else
			if Rand(3) > 0 then
				diseases_Influenza("", false)
			end
		end
	end
	
	-- end sleeping

	f_EndUseLocator("", "SleepingBerth", GL_STANCE_STAND)
	
	if IsPartyMember("") then
		feedback_MessageCharacter("",
								"@L_GENERAL_MEASURES_010_GOTOSLEEP_WAKEUP_HEAD",
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
	feedback_OverheadComment("Owner")
	
	-- get the tavern
	if not GetInsideBuilding("", "Tavern") then
		return
	end

	local duration = 6	

	if HasData("Duration") and GetData("Duration") ~= nil then
		duration = GetData("Duration")
	end

	local start
	
	if HasData("StartTime") and GetData("StartTime") ~= nil then
		start = GetData("StartTime")
	end
	
	if start == nil or start == false then
	 	return
	end

	local Factor = 1
	if GetGametime() < start+duration then
		-- check how long you sleeped before canceling it
		Factor = (GetGametime() - start) / duration
		
	

		if Factor > 1 then
			Factor = 1
		elseif Factor < 1 then
			return
		end
	
		Factor=Factor*Factor*100
			
		local HeavySleep = SimHasAbility("", 32)  --Deep Sleep ability
		
		BuildingGetOwner("Tavern","TheOwner")  -- Owner has the best house ability?
		local BestHouse = SimHasAbility("TheOwner", 16)
		
		local SleepBonus = 3
	
		if HeavySleep then
			Factor = Factor+20
			SleepBonus = 5
		elseif BestHouse then
			Factor = Factor+20
		end
	
		if (Factor-20) > Rand(100) then
			if SimGetClass("") == 1 then
				AddImpact("", "constitution", 1, 12)
				AddImpact("", "empathy", 1, 12)
				AddImpact("", "bargaining", 1, 12)
			elseif SimGetClass("") == 2 then
				AddImpact("", "constitution", 1, 12)
				AddImpact("", "dexterity", 1, 12)
				AddImpact("", "craftsmanship", 1, 12)
			elseif SimGetClass("") == 3 then
				AddImpact("", "charisma", 1, 12)
				AddImpact("", "rhetoric", 1, 12)
				AddImpact("", "secret_knowledge", 1, 12)
			elseif SimGetClass("") == 4 then
				AddImpact("", "constitution", 1, 12)
				AddImpact("", "fighting", 1, 12)
				AddImpact("", "shadow_arts", 1, 12)
			end
	
			if Rand(100) > 96 then
				AddImpact("", "LifeExpanding", SleepBonus, -1)
			elseif Rand(4) > 2 then
				AddImpact("", "Resist", 1, SleepBonus*Factor/50)
				AddImpact("", "ResistDream", 1, SleepBonus*Factor/50)
			else
				chr_GainXP("", Factor)
			end
			AddImpact("", "GoodDream", 1, 12)
		else 
			chr_GainXP("", Factor)
			AddImpact("", "BadDream", 1, 12)
		end
	end
end

function GetOSHData(MeasureID)
	OSHSetMeasureCost("@L_INTERFACE_HEADER_+6",150)
end

