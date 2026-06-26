function Run()
	CopyAlias("", "Bank")
	BuildingGetOwner("", "BankChief")

	local OwnerCash = GetMoney("BankChief")
	OwnerCash = math.floor(OwnerCash)

	LogMessage("@BANK GetMoney('BankChief') -> " .. OwnerCash)

	if OwnerCash < 100 and not HasProperty("Bank", "BankAccount") then
		if BuildingGetAISetting("Bank", "Produce_Selection") < 0 then
			MsgBoxNoWait("BankChief", "", "@L_OFFERCREDIT_ERROR_TIME_HEAD_+0", "@L_MEASURE_ORDERCREDIT_FAIL_+0")
		end
		StopMeasure()
	end
	
	if not HasProperty("Bank", "MsgTake") then
		local props = { "MsgTake", "MsgReturn", "MsgKeep", "MsgCollect" }
		for _, prop in helpfuncs_myipairs(props) do
			SetProperty("Bank", prop, 1)
		end
	end

	local MoneyTiers = {
	    {threshold = 10000, min = 2500, med = 5000, big = 10000},
	    {threshold = 5000,  min = 1000, med = 2500, big = 5000},
	    {threshold = 2000,  min = 500,  med = 1000, big = 2000},
	    {threshold = 1000,  min = 300,  med = 500,  big = 1000},
	    {threshold = 500,   min = 200,  med = 300,  big = 500},
	    {threshold = 250,   min = 150,  med = 200,  big = 250},
	    {threshold = 100,   min = 100,  med = 100,  big = 100},
	}

	local Money = { Minimum = 0, Medium = 0, Large = 0, Invest = 0 }

	for _, tier in helpfuncs_myipairs(MoneyTiers) do
	    if OwnerCash >= tier.threshold then
	        Money.Minimum = tier.min
	        Money.Medium  = tier.med
	        Money.Large   = tier.big
	        break
	    end
	end

	local Strings, Account = { Deposit = "", Buttons = "", Body = "" }, 0
	local Credit

	if HasProperty("Bank", "BankAccount") then
		Strings.Buttons 	= "@B[4,@L_MEASURE_ORDERCREDIT_STUFF_+3]@B[5,@L_MEASURE_ORDERCREDIT_STUFF_+5]@B[7,@L_MEASURE_ORDERCREDIT_STUFF_+6]@B[8,@L_MEASURE_ORDERCREDIT_STUFF_+7]"
		Strings.Body	 	= "@L_MEASURE_ORDERCREDIT_BODY_+1"
		Account 			= GetProperty("Bank", "BankAccount")
	else
		Strings.Body = "@L_MEASURE_ORDERCREDIT_BODY_+0"
	end

	local SimAlias

	local TakeLoanSimCount 		= 0
	local StolenLoanSimCount 	= 0
	local RentMoney 			= 0
	local BankName 				= GetID("")
	local GBankMoney 			= 0
	local GStolenMoney 			= 0

	local TotalSimCount = ScenarioGetObjects("cl_Sim", 9999, "SimAr")

	for i = 0, TotalSimCount - 1 do
		SimAlias = "SimAr"..i
		if HasProperty(SimAlias, "CreditBank") and BankName == GetProperty(SimAlias, "CreditBank") then
			GBankMoney = 0
			GStolenMoney = 0
			if HasProperty(SimAlias, "CreditSum") then
				TakeLoanSimCount = TakeLoanSimCount + 1
				GBankMoney = GetProperty(SimAlias, "CreditSum")
			elseif HasProperty(SimAlias, "StolenSum") then
				StolenLoanSimCount = StolenLoanSimCount +1
				GStolenMoney = GetProperty(SimAlias, "StolenSum")
			end
			RentMoney = RentMoney + GBankMoney + GStolenMoney
		end
	end

	Strings.Deposit = "@B[1,@L_MEASURE_ORDERCREDIT_STUFF_+0]@B[2,@L_MEASURE_ORDERCREDIT_STUFF_+1]@B[3,@L_MEASURE_ORDERCREDIT_STUFF_+2]"

	
	if not IsStateDriven() then
		Credit = MsgNews(
			"",
			"",
			"@P".. Strings.Deposit .. Strings.Buttons .."@B[6,@L_MEASURE_ORDERCREDIT_STUFF_+4]",
			ms_ordercredit_aidecide,
			"intrigue",
			-1,
			"@L_MEASURE_ORDERCREDIT_HEAD_+0",
			Strings.Body,
			Money.Minimum, Money.Medium, Money.Large, Account, TakeLoanSimCount, RentMoney, StolenLoanSimCount)
	else
		Credit = ms_ordercredit_aidecide()
	end
	
	if Credit == "C" then
		StopMeasure()
	end

	local Decision = {Money.Minimum, Money.Medium, Money.Large}

	if Credit < 4 then
		Money.Invest = Decision[Credit]
	end

	if Credit == 4 then
		Money.Invest = GetProperty("Bank", "BankAccount")
		local Payout_Amount, Payout_Message = {math.floor(Money.Invest * 0.2), math.floor(Money.Invest * 0.5), Money.Invest}

		if not IsStateDriven() then
			Payout_Message = MsgNews("","","@P"..
								"@B[0,"..Payout_Amount[1].."]"..
								"@B[1,"..Payout_Amount[2].."]"..
								"@B[2,"..Payout_Amount[3].."]"..
								"@B[3,@L_MEASURE_ORDERCREDIT_STUFF_+4]",
								ms_ordercredit_Payout,
								"production",-1,"@L_MEASURE_ORDERCREDIT_PAYOUT_HEAD_+0",
								"@L_MEASURE_ORDERCREDIT_PAYOUT_BODY_+0")
		else
			Payout_Message = ms_ordercredit_Payout()
		end

		if (Payout_Message ~= "C") and (Payout_Message ~= 3) then
			-- re-read the account: repayments may have arrived while the dialog was open
			local Account = 0
			if HasProperty("Bank", "BankAccount") then
				Account = GetProperty("Bank", "BankAccount")
			end
			local Payout = Payout_Amount[Payout_Message+1]
			if Payout_Message == 2 or Payout > Account then
				Payout = Account
			end
			CreditMoney("BankChief", Payout, "Credit")
			SetProperty("Bank", "BankAccount", (Account - Payout))
		end
		StopMeasure()
		
	elseif Credit == 5 then
		Money.Invest = GetProperty("Bank", "BankAccount")
		CreditMoney("BankChief", Money.Invest, "Credit")
		RemoveProperty("Bank", "BankAccount")
		StopMeasure()

	elseif Credit == 6 or Credit == "C" then
		StopMeasure()

	elseif Credit == 7 then
	    local msgProps = {
	        Take 	= GetProperty("Bank", "MsgTake"),
	        Return 	= GetProperty("Bank", "MsgReturn"),
	        Keep 	= GetProperty("Bank", "MsgKeep"),
	        Collect = GetProperty("Bank", "MsgCollect")
	    }
	    
	    local function getLabel(value)
	        return value == 1 and "@L_MEASURE_ORDERCREDIT_MESSAGES_ON_+0" or "@L_MEASURE_ORDERCREDIT_MESSAGES_OFF_+0"
	    end

	    local msgLabels = {
	        Take 	= getLabel(msgProps.Take),
	        Return 	= getLabel(msgProps.Return),
	        Keep 	= getLabel(msgProps.Keep),
	        Collect = getLabel(msgProps.Collect)
	    }
	    
	    local Messages = MsgNews("","","@P"..
	                        "@B[0,@L_MEASURE_ORDERCREDIT_MESSAGES_BUTTON_+0]"..
	                        "@B[1,@L_MEASURE_ORDERCREDIT_MESSAGES_BUTTON_+1]"..
	                        "@B[2,@L_MEASURE_ORDERCREDIT_MESSAGES_BUTTON_+2]"..
	                        "@B[3,@L_MEASURE_ORDERCREDIT_MESSAGES_BUTTON_+3]"..
	                        "@B[4,@L_MEASURE_ORDERCREDIT_MESSAGES_BUTTON_+4]"..
	                        "@B[5,@L_MEASURE_ORDERCREDIT_MESSAGES_BUTTON_+5]"..
	                        "@B[6,@L_MEASURE_ORDERCREDIT_STUFF_+4]",0,"intrigue",-1,
	                        "_MEASURE_ORDERCREDIT_MESSAGES_HEAD_+0",
	                        "_MEASURE_ORDERCREDIT_MESSAGES_BODY_+0",
	                        msgLabels.Take, msgLabels.Return, msgLabels.Keep, msgLabels.Collect)
	    
	    if Messages ~= "C" then
		    if Messages >= 0 and Messages <= 3 then
		        local propNames = {"Take", "Return", "Keep", "Collect"}
		        local propName = propNames[Messages + 1]  
		        local newValue = msgProps[propName] == 1 and 0 or 1
		        SetProperty("Bank", "Msg" .. propName, newValue)
		    elseif Messages == 4 then
		        for _, name in helpfuncs_myipairs({"Take", "Return", "Keep", "Collect"}) do
		            SetProperty("Bank", "Msg" .. name, 0)
		        end
		    elseif Messages == 5 then
		        for _, name in helpfuncs_myipairs({"Take", "Return", "Keep", "Collect"}) do
		            SetProperty("Bank", "Msg" .. name, 1)
		        end
		    end
		end

	    StopMeasure()

	elseif Credit == 8 then
	    local function safeGetProperty(propName, defaultValue)
	        return HasProperty("Bank", propName) and GetProperty("Bank", propName) or defaultValue
	    end

	    local balance = {
	        ReturnCount 	= safeGetProperty("BalanceReturnCount", 0),
	        Return 			= safeGetProperty("BalanceReturn", 0),
	        ReturnCollect 	= safeGetProperty("BalanceReturnCollect", 0)
	    }
	    
	    local balanceReturnFactor = balance.ReturnCount > 0 and balance.Return/balance.ReturnCount or 0

	    MsgBox("","","","@L_MEASURE_ORDERCREDIT_BALANCE_HEAD_+0",
	           "@L_MEASURE_ORDERCREDIT_BALANCE_BODY_+0", 
	           balance.ReturnCount,
	           balance.Return,
	           balance.ReturnCollect,
	           balanceReturnFactor)
	end		
	
	if Money.Invest > 0 then
		SpendMoney("BankChief", Money.Invest, "Credit")
		if HasProperty("Bank", "BankAccount") then
			local BankAccount = GetProperty("Bank","BankAccount")
			Money.Invest = Money.Invest + BankAccount
		end
		SetProperty("Bank", "BankAccount", Money.Invest)
	end

	StopMeasure()
end

function Payout()
	return 1 
end

function ReturnCredit()
	
	local Choice = 25
	local ReturnBank = 0
	if not HasProperty("","CreditBank") then
		StopMeasure()
		return
	else
		ReturnBank = GetProperty("","CreditBank")
	end
	
	if not GetAliasByID(ReturnBank, "Bank") then
		StopMeasure()
		return
	end
	
	if not HasProperty("","CreditSum") or not HasProperty("","CreditInterest") then
		StopMeasure()
		return
	end

	local CreditSum = GetProperty("","CreditSum")
	local Interest = GetProperty("","CreditInterest")
	local ReturnCredit = math.floor(CreditSum*(1+Interest))
	local Plus = ReturnCredit - CreditSum
	local ReturnTime = 24
	if HasProperty("","ReturnTime") then
		ReturnTime = GetProperty("","ReturnTime")
	end

	if not AliasExists("Bank") then
		return
	end

	-- the account may have been emptied/closed while the loan was out
	local Account = 0
	if HasProperty("Bank","BankAccount") then
		Account = GetProperty("Bank","BankAccount")
	end
	local MyMoney = GetMoney("")
	if not BuildingGetOwner("Bank","MyBoss") then
		StopMeasure()
	end
	local BalanceReturnCount = 0
	if HasProperty("Bank","BalanceReturnCount") then
		BalanceReturnCount = GetProperty("Bank","BalanceReturnCount")
	end
	local BalanceReturn = 0
	if HasProperty("Bank","BalanceReturn") then
		BalanceReturn = GetProperty("Bank","BalanceReturn")
	end
	
	if DynastyIsAI("MyBoss") then
		Choice = 10
	elseif BuildingGetAISetting("Bank", "Produce_Selection")>0 then
		Choice = 0
	end
	
	if Rand(100)>=Choice then
		-- Return
		RemoveProperty("","CreditBank")
		RemoveProperty("","CreditSum")
		RemoveProperty("","CreditInterest")
		
		if HasProperty("","OldSum") then
			RemoveProperty("","OldSum")
		end
		
		if HasProperty("","ReturnTime") then
			RemoveProperty("","ReturnTime")
		end
		
		if IsDynastySim("") then
			SpendMoney("",ReturnCredit,"Credit")
		end
		
		SetProperty("Bank","BankAccount",(Account+CreditSum))
		SetProperty("Bank","BalanceReturnCount",(BalanceReturnCount+1))
		SetProperty("Bank","BalanceReturn", (BalanceReturn+Plus))
		
		CreditMoney("MyBoss",Plus,"Credit")
		local ExtraMsg = "@L_MEASURE_IDLE_RETURNCREDIT_SPRUCH"
		if GetProperty("Bank","MsgReturn")==1 then
			MsgNewsNoWait("MyBoss","","","building",-1,"@L_MEASURE_OfferCredit_HEAD_+1",
					"@L_MEASURE_OfferCredit_BODY_+1",GetID(""),GetID("Bank"),CreditSum,ReturnCredit,ReturnTime, ExtraMsg)
		end
	else
		-- Keep it, haha!
		if GetProperty("Bank","MsgKeep")==1 then
			MsgNewsNoWait("MyBoss","","","intrigue",-1,"@L_MEASURE_OfferCredit_KEEPIT_HEAD_+0",
					"@L_MEASURE_OfferCredit_KEEPIT_BODY_+0",GetID(""),GetID("Bank"),CreditSum,ReturnCredit)
		end
		SetProperty("","OldSum", CreditSum)
		SetProperty("","StolenSum",ReturnCredit)
		if HasProperty("Bank","StolenCount") then
			local StolenCount = GetProperty("Bank","StolenCount")
			SetProperty("Bank","StolenCount",(StolenCount+1))
		else
			SetProperty("Bank","StolenCount",1)
		end
		RemoveProperty("","CreditSum")
	end
	
	StopMeasure()
	
end

function aidecide()
	BuildingGetOwner("Bank", "BankChief")

	local cash = GetMoney("BankChief")

	local DecideValue

	if not HasProperty("Bank","BankAccount") then
		if cash > 10000 then
			DecideValue = 3
		elseif cash > 5000 then
			DecideValue = 2+Rand(2)
		else
			DecideValue = 1+Rand(2)
		end
	else
		local Lmoney = GetProperty("Bank","BankAccount")
		DecideValue = "C"
		if Lmoney < 10000 then
			if cash >= 2000 and cash > (Lmoney+1000) then
				DecideValue = 1+Rand(3)
			elseif cash <500 or Lmoney > (cash+1000) then
				DecideValue = 4
			end
		end
	end
	return DecideValue
end

function CleanUp()
	if AliasExists("Actor") then
		if HasProperty("Actor", "SpecialMeasureDestination") then
			RemoveProperty("Actor", "SpecialMeasureDestination")
		end
		if HasProperty("Actor", "SpecialMeasureId") then
			RemoveProperty("Actor", "SpecialMeasureId")
		end
		if HasProperty("Actor", "AIDecideNow") then
			RemoveProperty("Actor", "AIDecideNow")
		end
		RemoveAlias("Actor")
	end
end
