function Run()
	if not GetInsideBuilding("", "BankBuilding") then
		StopMeasure()
	end

	if not BuildingGetOwner("BankBuilding", "MyBoss") then
		StopMeasure()
	end

	if not HasProperty("BankBuilding", "BankAccount") then
		MsgBoxNoWait("", "BankBuilding", "@L_OFFERCREDIT_ERROR_TIME_HEAD_+0", "@L_OFFERCREDIT_ERROR_MONEY_BODY_+0")
		StopMeasure()
	end
	
	if not HasProperty("BankBuilding", "OfferCreditNow") then
		SetProperty("BankBuilding", "OfferCreditWorker", GetID(""))
	end

	SetProperty("BankBuilding", "OfferCreditNow", 1)
	
	if HasProperty("BankBuilding", "OfferCreditWorker") then
		local OfferID = GetProperty("BankBuilding", "OfferCreditWorker")
		if GetID("") ~= OfferID then
			MsgBoxNoWait("MyBoss", "BankBuilding", "@L_OFFERCREDIT_ERROR_TIME_HEAD_+0", "@L_OFFERCREDIT_ERROR_EMPLOYEE_BODY_+0")
			StopMeasure()
		end
	end
	
	GetLocatorByName("BankBuilding", "Work3", "ChiefPos")
	f_BeginUseLocator("", "ChiefPos", GL_STANCE_SIT, true)
	
	SetData("IsProductionMeasure", 0)
	SimSetProduceItemID("", -GetCurrentMeasureID(""), -1)
	SetData("IsProductionMeasure", 1)

	while true do
		local CreditSimFilter = "__F((Object.GetObjectsByRadius(Sim) == 10000) AND (Object.HasProperty(WaitForCredit)))"
		local NumCreditSims = Find("", CreditSimFilter, "CreditSim", -1)

		if NumCreditSims < 1 then
			LogMessage("@BANK loan wait with " .. GetName("MyBoss"))
			if Rand(10) == 0 then
				CarryObject("", "Handheld_Device/ANIM_beaker_sit_drink.nif", false)
				PlayAnimation("", "sit_drink")
				CarryObject("", "", false)
			end
			Sleep(5)

		else
			
			SetData("Blocked", 0)

			if not SendCommandNoWait("CreditSim0", "BlockMe") then
				break
			end

			GetLocatorByName("BankBuilding", "wait3", "ClientSit")
			f_BeginUseLocator("CreditSim0", "ClientSit", GL_STANCE_SIT, true)
			MeasureSetNotRestartable()
			SetState("", STATE_DUEL, true)

			local anim = {"sit_talk", "sit_talk_02"}
			local dowhat = PlayAnimationNoWait("CreditSim0", anim[Rand(2)+1])

			MsgSay("CreditSim0", "@L_MEASURE_IDLE_TAKECREDIT_SPRUCH")
					
			local Account = GetProperty("BankBuilding", "BankAccount")

			PlayAnimationNoWait("", "sit_talk")

			if SimGetGender("") == 1 then
				PlaySound3DVariation("","CharacterFX/male_neutral", 1)
			else
				PlaySound3DVariation("","CharacterFX/female_neutral", 1)
			end

			local function checkAccount()
				if Account == nil then return false else return true end
			end
			
			if (checkAccount() == true) then
				if Account >= 200 then
					PlayAnimationNoWait("", "sit_yes")
					local InterestText = 25 + GetSkillValue("", BARGAINING)
					MsgSay("", "@L_MEASURE_IDLE_TAKECREDIT_ANSWER_POSITIVE", InterestText)
					LogMessage("@BANK loan test")
					PlayAnimation("CreditSim0", "sit_yes")
				end
			end

			if (checkAccount() == false) or (Account <= 100) then
				PlayAnimationNoWait("", "sit_no")
				MsgSay("", "@L_MEASURE_IDLE_TAKECREDIT_ANSWER_NEGATIVE")
				if HasProperty("CreditSim0", "WaitForCredit") then
					RemoveProperty("CreditSim0", "WaitForCredit")
				end
			end	
					
			if (checkAccount() == true) then
				if Account >= 200 then
					local Rank = SimGetRank("CreditSim0")
					local CreditChoice = 0
					local Sum = 200
							
					if Rank >= 3 then
						CreditChoice = 2 + Rand(4)
					else
						CreditChoice = Rand(2)
					end

					if IsDynastySim("CreditSim0") then
						CreditChoice = 4 + Rand(2)
					end

					LogMessage("@BANK loan taken0")
							
					local creditOptions = {
					    [1] = {amount = 500, minAccount = 500},
					    [2] = {amount = 1000, minAccount = 1000},
					    [3] = {amount = 2000, minAccount = 2000},
					    [4] = {amount = 5000, minAccount = 5000},
					    [5] = {amount = 10000, minAccount = 10000},
					}

					if CreditChoice == 0 then
					    Sum = 200
					elseif creditOptions[CreditChoice] and Account >= creditOptions[CreditChoice].minAccount then
					    Sum = creditOptions[CreditChoice].amount
					else
					    Sum = 200
					end

					-- re-read the account right before committing: deposits, withdrawals or repayments may have changed it during the talk animations above
					Account = GetProperty("BankBuilding", "BankAccount")
					if Account == nil then
						Account = 0
					end
					if Account < Sum then
						Sum = 200
					end

					if Account >= Sum then
						local Interest 		= 0.25 + (GetSkillValue("",BARGAINING) / 100)
						local InterestText 	= 25 + GetSkillValue("", BARGAINING)

						SetProperty("CreditSim0", "CreditBank" ,GetID("BankBuilding"))
						SetProperty("CreditSim0", "CreditSum", Sum)
						SetProperty("CreditSim0", "CreditInterest", Interest)
						CreateScriptcall("OrderCredit_End", 24, "Measures/ms_OrderCredit.lua", "ReturnCredit", "CreditSim0", "MyBoss")

						if GetProperty("BankBuilding","MsgTake") == 1 then
							MsgNewsNoWait("MyBoss", "CreditSim0", "", "building", -1, "@L_MEASURE_OfferCredit_HEAD_+0", "@L_MEASURE_OfferCredit_BODY_+0", GetID("CreditSim0"), GetID("BankBuilding"), Sum, InterestText)
						end

						LogMessage("@BANK loan taken")

						MoveSetActivity("CreditSim0", "")
						SetProperty("BankBuilding", "BankAccount", (Account-Sum))
						CreditMoney("CreditSim0", Sum, "Bank")
						SatisfyNeed("CreditSim0", 9, 1)
					end
				end
			end

			f_EndUseLocator("CreditSim0", "ClientSit", GL_STANCE_STAND)
			SetData("Blocked", 1)
			Sleep(8)
			SetState("", STATE_DUEL, false)
			SetState("CreditSim0", STATE_DUEL, false)
		end
	end
	StopMeasure()
end

function BlockMe()
	while GetData("Blocked") ~= 1 do
		Sleep(0.8)
		SetState("", STATE_DUEL, true)
	end
	if HasProperty("", "WaitForCredit") then
		RemoveProperty("", "WaitForCredit")
	end
	Sleep(1)
	f_ExitCurrentBuilding("")
	if GetState("", STATE_DUEL) then
		SetState("", STATE_DUEL, false)
	end
	SimResetBehavior("")
end

function CleanUp()
	SetData("Blocked", 1)
	if GetInsideBuilding("", "BankBuilding") then
		if HasProperty("BankBuilding", "OfferCreditNow") then
			RemoveProperty("BankBuilding", "OfferCreditNow")
		end
		if HasProperty("BankBuilding" ,"OfferCreditWorker") then
			RemoveProperty("BankBuilding", "OfferCreditWorker")
		end
	end
	if AliasExists("CreditSim0") then
		if GetState("CreditSim0", STATE_DUEL) then
			SetState("CreditSim0", STATE_DUEL, false)
		end
	end
	SetState("", STATE_DUEL, false)
	StopAnimation("")
	CarryObject("", "", false)
	CarryObject("", "", true)
	MoveSetStance("", GL_STANCE_STAND)
	MoveSetActivity("", "")
	f_EndUseLocator("", "ChiefPos", GL_STANCE_STAND)
end

function GetOSHData(MeasureID)
	mdata_ShowTalentOSH(MeasureID)
end
