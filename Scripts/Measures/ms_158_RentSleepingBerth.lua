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
	if GetImpactValue("", "GoodDream") > 0 or GetImpactValue("", "BadDream") >0 then
		MsgBoxNoWait("", "", "@L_GENERAL_ERROR_HEAD_+0", "@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+2", GetID(""))
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
	SetData("Duration", HasToSleep)
	local WasSick = false
	
	if GetImpactValue("", "Sickness") >0 then
		WasSick = true
	end
	
	local CurrentHP = GetHP("")
	local MaxHP = GetMaxHP("")
	local ToHeal = MaxHP - CurrentHP
	local HealPerTic = ToHeal / (duration * 12)
	local StartTime = GetGametime()
	
	SetData("StartTime", StartTime)
	
	local EndTime = GetGametime() + HasToSleep
	
	while GetGametime() < EndTime do
		
		Sleep(5)
		-- increase the hp
		if GetHP("") < MaxHP then
			ModifyHP("", HealPerTic, false)
			PlaySound3DVariation("", "measures/gotosleep", 0.8)
		end
	end

	-- Cure some diseases
	if WasSick == true then
		if GetImpactValaue("", "HerbTea") > 0 then -- herb tea helps
			local CheckDisease = { "Cold", "Sprain", "BurnWound", "Influenza", "Pneumonia", "Pox", "BlackDeath", "Fracture" }
			local SleepBonus = GetImpactValue("", "SleepBonusI")
	
			for i=1, 7 do
				if GetImpactValue("", CheckDisease[i]) > 0 then
					if CheckDisease[i] == "Cold" then
						diseases_Cold("", false)
					else
						if SleepBonus > 0 then
							if CheckDisease[i] == "Sprain") then
								diseases_Sprain("", false)
							elseif CheckDisease[i] == "BurnWound" then
								diseases_BurnWound("", false)
							elseif CheckDisease[i] == "Influenza" then
								diseases_Influenza("", false)
							elseif CheckDisease[i] == "Pneumonia" then
								diseases_Pneumonia("", false)
							elseif CheckDisease[i] == "Pox" then
								diseases_Pox("", false)
							elseif CheckDisease[i] == "BlackDeath" then
								diseases_BlackDeath("", false)
							elseif CheckDisease[i] == "Fracture" then
								diseases_Fracture("", false)
							end
						end
					end
				end
			end
		else -- no tea? then healing is random at 66 % (tavern value)
			if Rand(100) > 33 then
				if GetImpactValue("", "Cold") > 0 then
					diseases_Cold("", false)
				end
					
				if GetImpactValue("", "Sprain") > 0 then
					diseases_Sprain("", false)
				end
					
				if GetImpactValue("", "Influenza") > 0 then
					diseases_Influenza("", false)
				end
			end
		end
								
		-- good dream bonus in best house
		if GetImpactValue("Tavern", "BestHouseBoost") > 0 then
			if SimGetClass("") == 1 then
				AddImpact("", "constitution",1,12)
				AddImpact("", "empathy",1,12)
				AddImpact("", "bargaining",1,12)
			elseif SimGetClass("") == 2 then
				AddImpact("", "constitution",1,12)
				AddImpact("", "dexterity",1,12)
				AddImpact("", "craftsmanship",1,12)
			elseif SimGetClass("") == 3 then
				AddImpact("", "charisma",1,12)
				AddImpact("", "rhetoric",1,12)
				AddImpact("", "secret_knowledge",1,12)
			elseif SimGetClass("") == 4 then
				AddImpact("", "constitution",1,12)
				AddImpact("", "fighting",1,12)
				AddImpact("", "shadow_arts",1,12)
			end
			
			if Rand(100) > 90 then -- better chance in best tavern
				AddImpact("", "LifeExpanding", 1, -1)
			end
			
			chr_GainXP("", Factor)
			AddImpact("", "GoodDream", 1, 12)
		end
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
	feedback_OverheadComment("Owner")
end

function GetOSHData(MeasureID)
	OSHSetMeasureCost("@L_INTERFACE_HEADER_+6",150)
end

