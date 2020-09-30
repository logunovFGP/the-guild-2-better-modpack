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
	
--	local Result = MsgNews("","","@P"..
--				"@B[1,@L_REPLACEMENTS_BUTTONS_JA_+0]"..
--				"@B[C,@L_REPLACEMENTS_BUTTONS_NEIN_+0]",
--				ms_158_rentsleepingberth_AIDecision,  --AIFunc
--				"building", --MessageClass
--				2, --TimeOut
--				"@L_MEASURE_RentSleepingBerth_NAME_+0",
--				"@L_GENERAL_MEASURES_158_RENTSLEEPINGBERTH_MSG_BODY_+0",
--				Price)
--	if Result == "C" then
--		StopMeasure()
--	end

	-- Not sleepy?
	if GetImpactValue("","GoodDream")>0 or GetImpactValue("","BadDream")>0 then
		MsgQuick("","@L_GENERAL_MEASURES_010_GOTOSLEEP_FAILURES_+2", GetID(""))
		StopMeasure()
	end
	
	-- check both sleeping berths
	if not GetFreeLocatorByName("Tavern", "Berth", 1, 2, "SleepingBerth") then	
		MsgQuick("","@L_TAVERN_158_RENTSLEEPINGBERTH_FAILURES_+1", GetID("Tavern"))
		return
	end

	if GetDynastyID("")~=GetDynastyID("Tavern") then
		if not SpendMoney("", Price, "CostSocial") then
			MsgQuick("","@L_TAVERN_158_RENTSLEEPINGBERTH_FAILURES_+0",Price)
			StopMeasure()
		end
		CreditMoney("Tavern", Price, "RentABerth")
		-- for the balance
		local OldBalance = 0
		if HasProperty("Tavern", "BalanceSleepingFee") then
			OldBalance = GetProperty("Tavern", "BalanceSleepingFee")
		end
		SetProperty("Tavern", "BalanceSleepingFee", (OldBalance+Price))
	end

	-- go to the berth
	f_BeginUseLocator("", "SleepingBerth", GL_STANCE_LAY, true)
		
	-- sleep
	
	local	HasToSleep = 6
	if GetImpactValue("","SleepRecoverBonus")>0 then
		HasToSleep = HasToSleep - ((GetImpactValue("","SleepRecoverBonus")*0.01)*HasToSleep)
	end
	SetData("Duration", HasToSleep)
	
	if GetImpactValue("","Sickness")>0 then
		HasToSleep = HasToSleep * 2
	end

	local CurrentHP = GetHP("")
	local MaxHP = GetMaxHP("")
	local ToHeal = MaxHP - CurrentHP
	local HealPerTic = ToHeal / (HasToSleep * 10)
	
	local CurrentTime = GetGametime()
	SetData("StartTime", CurrentTime)
	local EndTime = CurrentTime + HasToSleep
	-- increase the hp due to the recover factor for the tavern
	while GetGametime() < EndTime do
		
		Sleep(5)
		
		if GetHP("") < MaxHP then
			ModifyHP("", HealPerTic,false)
			PlaySound3DVariation("","measures/gotosleep",0.8)
		end
		
	end
	
	-- end sleeping

	f_EndUseLocator("", "SleepingBerth", GL_STANCE_STAND)
	
	if IsPartyMember() then
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
	
	local Time = GetGametime()
	local Start = Time
	if HasData("StartTime") and GetData("StartTime")~=nil then
		Start = GetData("StartTime")
	else
		return
	end
	local duration = 6
	if HasData("Duration") and GetData("Duration")~=nil then
		duration = GetData("Duration")
	else
		return
	end
	
	local Factor = (Time - Start) / duration
	if Factor>1 then
		Factor = 1
	elseif Factor<0.05 then
		return
	end
	
	Factor=Factor*Factor*100
		
	local HeavySleep = SimHasAbility("",32)  --Deep Sleep ability
	
	BuildingGetOwner("Tavern","TheOwner")  -- Owner has the best house ability?
	local BestHouse = SimHasAbility("TheOwner",16)
	
	-- Cure Cold, Sprain and Influenza
	if GetImpactValue("","Sickness")>0 and Factor>Rand(100) then
		diseases_Cold("",false)
		diseases_Sprain("",false)
		diseases_Influenza("",false)
		if HeavySleep == true then  -- Deep sleep ability?
			diseases_Pneumonia("",false)
		end
	end	
	
	local SleepBonus=3

	if HeavySleep == true then
		Factor=Factor+20
		SleepBonus=5
	elseif BestHouse == true then
		Factor=Factor+20
	end
	if (Factor-20)>Rand(100) then
		if SimGetClass("")==1 then
			AddImpact("","constitution",1,12)
			AddImpact("","empathy",1,12)
			AddImpact("","bargaining",1,12)
		elseif SimGetClass("")==2 then
			AddImpact("","constitution",1,12)
			AddImpact("","dexterity",1,12)
			AddImpact("","craftsmanship",1,12)
		elseif SimGetClass("")==3 then
			AddImpact("","charisma",1,12)
			AddImpact("","rhetoric",1,12)
			AddImpact("","secret_knowledge",1,12)
		elseif SimGetClass("")==4 then
			AddImpact("","constitution",1,12)
			AddImpact("","fighting",1,12)
			AddImpact("","shadow_arts",1,12)
		end
		if Rand(100)>96 then
			AddImpact("","LifeExpanding",SleepBonus,-1)
		elseif Rand(4)>2 then
			AddImpact("","Resist",1,SleepBonus*Factor/50)
			AddImpact("","ResistDream",1,SleepBonus*Factor/50)
		else
			chr_GainXP("",Factor)
		end
		AddImpact("","GoodDream",1,12)
	else 
		chr_GainXP("",Factor)
		AddImpact("","BadDream",1,12)
	end
end

function GetOSHData(MeasureID)
	
	OSHSetMeasureCost("@L_INTERFACE_HEADER_+6",150)
end

