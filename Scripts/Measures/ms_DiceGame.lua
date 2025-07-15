function Init()
	
	-- check for divehouse with "gablingtable"
	if not GetInsideBuilding("", "Inside") then
		if not chr_FindInterestingWorkshop("", GL_BUILDING_TYPE_DIVEHOUSE, "gablingtable", 1500, 12000, "Divehouse") then
			StopMeasure()
		end
	else
		if BuildingGetType("Inside") ~= GL_BUILDING_TYPE_DIVEHOUSE then
			f_ExitCurrentBuilding("")
			if not chr_FindInterestingWorkshop("", GL_BUILDING_TYPE_DIVEHOUSE, "gablingtable", 1500, 12000, "Divehouse") then
				StopMeasure()
			end
		else
			CopyAlias("Inside", "Divehouse")
		end
	end
	
	if not AliasExists("Divehouse") then
		StopMeasure()
	end
	
	-- check for available opponents
	BuildingGetInsideSimList("Divehouse", "InsideList")
	local ListSize = ListSize("InsideList")
	local Found = 0	
	local BestOpponentSum = 0 
	
	-- check for potential players
	if ListSize > 0 then
		for i=0, ListSize-1 do
			ListGetElement("InsideList", i, "SimToCheck")
			if (GetState("SimToCheck", STATE_IDLE) or GetCurrentMeasureName("SimToCheck") == "AssignToServiceDivehouse") and f_SimIsValid("SimToCheck") and GetDynastyID("SimToCheck") ~= GetDynastyID("") then
				local Budget = chr_GetBudget("SimToCheck", 2)
				if IsDynastySim("SimToCheck") and Budget > GetMoney("SimToCheck") * 0.5 then
					Budget = GetMoney("SimToCheck") * 0.5
				end
				if Budget > BestOpponentSum then
					CopyAlias("SimToCheck", "Opponent")
					BestOpponentSum = Budget
				end
			end
		end
	end
	
	if BestOpponentSum < 200 or not AliasExists("Opponent") then
		MsgQuick("", "@L_MEASURE_DICEGAME_NOOPPONENT_+0")
		StopMeasure()
	end

	local cash = GetMoney("") 	
	
	if cash < 100 then
		MsgQuick("", "@L_MEASURE_DICEGAME_NOMONEY_+0")
		StopMeasure()
	end
	
	if DynastyIsAI("") then
		ms_dicegame_InitAI(BestOpponentSum)
		return
	end
		
	local intro, rules
	repeat
		intro = MsgBox("", false, "@P"..
					"@B[A,@L_HPFZ_WS_STUFF_+8]"..
					"@B[B,@L_HPFZ_WS_STUFF_+9]"..
					"@B[C,@L_HPFZ_WS_STUFF_+10]",
					"@L_HPFZ_WS_KOPF_+0",
					"@L_HPFZ_WS_RUMPF_+0")
						
		if intro == "A" then
			rules = MsgBox("", false, "@P"..
						"@B[B,@L_HPFZ_WS_STUFF_+9]"..
						"@B[C,@L_HPFZ_WS_STUFF_+10]",
						"@L_HPFZ_WS_KOPF_+6",
						"@L_HPFZ_WS_RUMPF_+6")
		end
				
		if intro == "C" or rules == "C" then
			StopMeasure()
		end
		
	until intro == "B" or rules == "B"
	
	local Check = MsgBox("", false, "@P"..
					"@B[B,@L_HPFZ_BLACKJACK_SPRUCH_+3]"..
					"@B[C,@L_HPFZ_WS_STUFF_+10]",
					"@L_HPFZ_WS_KOPF_+6",
					"@L_MEASURE_DICEGAME_OPPONENT_CHECK_BODY_+0", GetID("Divehouse"), GetID("Opponent"), BestOpponentSum)
		
	if Check == "C" then
		StopMeasure()
	end
	
	if cash > BestOpponentSum then
		cash = BestOpponentSum
	end
	
	local Choice1 = cash * 0.25
	local Choice2 = cash * 0.50
	local Choice3 = cash
	local raise = cash * 0.15
	local ChoiceSum = 0
	
	local Button1 = "@B[1,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_CHOICE_+0,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_CHOICE_+0,Hud/Buttons/btn_Money_Small.tga]"
	local Button2 = "@B[2,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_CHOICE_+1,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_CHOICE_+1,Hud/Buttons/btn_Money_Medium.tga]"
	local Button3 = "@B[3,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_CHOICE_+2,@L_INTRIGUE_041_BRIBECHARACTER_SCREENPLAY_ACTOR_CHOICE_+2,Hud/Buttons/btn_Money_Large.tga]"
	
	local percent = InitData("@P"..
					Button1..
					Button2..
					Button3,
					-1,
					"@L_HPFZ_WS_KOPF_+0",
					"@L_HPFZ_WS_RUMPF_+8", GetID(""), Choice1, Choice2, Choice3)
	
	if percent == 1 then
		ChoiceSum = Choice1
	elseif percent == 2 then
		ChoiceSum = Choice2
	elseif percent == 3 then
		ChoiceSum = Choice3
	else
		StopMeasure()
	end
	
	if not chr_SpendMoney("", ChoiceSum, "misc") then
		MsgQuick("", "@L_MEASURE_DICEGAME_NOMONEY_+0")
		StopMeasure()
	end
	
	-- cash out 10% for the pub
	local Share = math.ceil(ChoiceSum * 0.1)
	chr_CreditMoney("Divehouse", Share, "misc") 
	
	ChoiceSum = ChoiceSum - Share
	
	ShowOverheadSymbol("", false, true, 0, "-%1t", ChoiceSum)
	SetData("Jackpod", ChoiceSum)
	SetData("RaiseCost", raise)
end

function Run()

	--block the opponent 
	SetData("Blocked", 0)
	if not SendCommandNoWait("Opponent", "BlockMe") then
		LogMessage("Dicegame: Cant block opponent")
		StopMeasure()
	end
	
	GetFreeLocatorByName("Divehouse", "diceceo", -1, -1, "CeoPos")
	f_MoveToNoWait("Opponent", "CeoPos", GL_MOVESPEED_WALK)
	GetFreeLocatorByName("Divehouse", "DicePlayer", -1, -1, "SitPos")
	f_BeginUseLocator("Owner", "SitPos", GL_STANCE_STAND, true)
	f_BeginUseLocator("Opponent", "CeoPos", GL_STANCE_STAND, true)
	
	local MeasureID = GetCurrentMeasureID("")
	local TimeOut = mdata_GetTimeOut(MeasureID)
	SetMeasureRepeat(TimeOut)
	
	local cash = GetMoney("")
	local raise = GetData("RaiseCost")
	local OpponentSum
	
	local StartGame = InitData("@P"..
						"@B[A,,,hpfzextra/dices/dice_highlighted_ques.tga]", ms_dicegame_AIConfirm,
						"@L_HPFZ_WS_STUFF_+0",
						"")
						
	local roll1 = ms_dicegame_Roll()
	ms_dicegame_DiceRun(1, roll1)

	local roll2 = ms_dicegame_Roll()
	ms_dicegame_DiceRun(1, roll2)
	
	local roll3 = ms_dicegame_Roll()
	ms_dicegame_DiceRun(1, roll3)
	
	-- animation
	PlaySound3D("", "measures/shake_dices/shake_dices+0.wav", 1.0)
	local ani = PlayAnimationNoWait("", "manipulate_middle_low_r")
	Sleep(ani-1)
	PlaySound3D("", "measures/throw_dices/throw_dices+0.wav", 1.0)
	
	local Result1 = InitData("@P"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll1..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll2..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll3..".tga]", ms_dicegame_AIConfirm,
						"@L_HPFZ_WS_STUFF_+1",
						"")	

	if GetData("Sum") == 17 then -- lucky 17!
		ms_dicegame_siebz(3)
	elseif GetData("Sum") > 17 then -- bad luck!
		ms_dicegame_PayOut(4)
	end	
	
	local EndRound1, EndRound2, EndRound3, EndRound4
	
	if DynastyIsAI("") then
		local CurrentSum = GetData("Sum")
		if CurrentSum <= 12 then
			EndRound1 = "raise"
		else
			EndRound1 = "Exit"
		end
	else
	
		EndRound1 = MsgBox("", false, "@P"..
						"@B[raise,@L_HPFZ_WS_EINSATZ_+0,]"..
						"@B[Exit,@L_HPFZ_WS_EINSATZ_+3,]",
						"@L_HPFZ_WS_KOPF_+1",
						"@L_HPFZ_WS_RUMPF_+1", raise, GetData("Sum"))
	end
	
	if EndRound1 == "Exit" then
		-- animation
		PlaySound3D("Opponent", "measures/shake_dices/shake_dices+0.wav", 1.0)
		local ani = PlayAnimationNoWait("Opponent", "manipulate_middle_low_r")
		Sleep(ani-1)
		PlaySound3D("Opponent", "measures/throw_dices/throw_dices+0.wav", 1.0)
	   	OpponentSum = ms_dicegame_Xroll(3)
		local result = ms_dicegame_Calculation()
		
		ms_dicegame_Payout(result)
		return
	else
		local success = ms_dicegame_Raise(raise)
		if not success then -- raise failed due to a lack of money
			-- animation
			PlaySound3D("Opponent", "measures/shake_dices/shake_dices+0.wav", 1.0)
			local ani = PlayAnimationNoWait("Opponent", "manipulate_middle_low_r")
			Sleep(ani-1)
			PlaySound3D("Opponent", "measures/throw_dices/throw_dices+0.wav", 1.0)
			OpponentSum = ms_dicegame_Xroll(3)
			local result = ms_dicegame_Calculation()
			
			ms_dicegame_Payout(result)
			return
		end
	end
	
	-- next round
	local roll4 = ms_dicegame_Roll()
	ms_dicegame_DiceRun(1, roll4)
	
	PlaySound3D("", "measures/shake_dices/shake_dices+0.wav", 1.0)
	local ani = PlayAnimationNoWait("", "manipulate_middle_low_r")
	Sleep(ani-1)
	PlaySound3D("", "measures/throw_dices/throw_dices+0.wav", 1.0)
	
	local Result2 = InitData("@P"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll1..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll2..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll3..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll4..".tga]", ms_dicegame_AIConfirm,
						"@L_HPFZ_WS_STUFF_+3",
						"")
	
	if GetData("Sum") == 17 then -- lucky 17!
		ms_dicegame_siebz(4)
	elseif GetData("Sum") > 17 then -- bad luck!
		ms_dicegame_PayOut(4)
	end	
	
	if DynastyIsAI("") then
		local CurrentSum = GetData("Sum")
		if CurrentSum <= 12 then
			EndRound2 = "raise"
		else
			EndRound2 = "Exit"
		end
	else
		EndRound2 = MsgBox("", false, "@P"..
						"@B[raise,@L_HPFZ_WS_EINSATZ_+0,]"..
						"@B[Exit,@L_HPFZ_WS_EINSATZ_+3,]",
						"@L_HPFZ_WS_KOPF_+1",
						"@L_HPFZ_WS_RUMPF_+1", raise, GetData("Sum"))
	end
	
	if EndRound2 == "Exit" then
		-- animation
		PlaySound3D("Opponent", "measures/shake_dices/shake_dices+0.wav", 1.0)
		local ani = PlayAnimationNoWait("Opponent", "manipulate_middle_low_r")
		Sleep(ani-1)
		PlaySound3D("Opponent", "measures/throw_dices/throw_dices+0.wav", 1.0)
	   	OpponentSum = ms_dicegame_Xroll(4)
		local result = ms_dicegame_Calculation()
		
		ms_dicegame_Payout(result)
		return
	else
		local success = ms_dicegame_Raise(raise)
		if not success then -- raise failed due to a lack of money
			-- animation
			PlaySound3D("Opponent", "measures/shake_dices/shake_dices+0.wav", 1.0)
			local ani = PlayAnimationNoWait("Opponent", "manipulate_middle_low_r")
			Sleep(ani-1)
			PlaySound3D("Opponent", "measures/throw_dices/throw_dices+0.wav", 1.0)
			OpponentSum = ms_dicegame_Xroll(4)
			local result = ms_dicegame_Calculation()
			
			ms_dicegame_Payout(result)
			return
		end
	end

	local roll5 = ms_dicegame_Roll()
	ms_dicegame_DiceRun(1, roll5)
	
	PlaySound3D("", "measures/shake_dices/shake_dices+0.wav", 1.0)
	local ani = PlayAnimationNoWait("", "manipulate_middle_low_r")
	Sleep(ani-1)
	PlaySound3D("", "measures/throw_dices/throw_dices+0.wav", 1.0)
	
	local Result3 = InitData("@P"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll1..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll2..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll3..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll4..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll5..".tga]", ms_dicegame_AIConfirm,
						"@L_HPFZ_WS_STUFF_+4",
						"")	

	if GetData("Sum") == 17 then
		ms_dicegame_siebz(5)
	elseif GetData("Sum") > 17 then
		ms_dicegame_Payout(4)
	end	
	
	if DynastyIsAI("") then
		local CurrentSum = GetData("Sum")
		if CurrentSum <= 12 then
			EndRound3 = "raise"
		else
			EndRound3 = "Exit"
		end
	else
		EndRound3 = MsgBox("", false, "@P"..
						"@B[raise,@L_HPFZ_WS_EINSATZ_+0,]"..
						"@B[Exit,@L_HPFZ_WS_EINSATZ_+3,]",
						"@L_HPFZ_WS_KOPF_+1",
						"@L_HPFZ_WS_RUMPF_+1", raise, GetData("Sum"))
	end
	
	if EndRound3 == "Exit" then
		-- animation
		PlaySound3D("Opponent", "measures/shake_dices/shake_dices+0.wav", 1.0)
		local ani = PlayAnimationNoWait("Opponent", "manipulate_middle_low_r")
		Sleep(ani-1)
		PlaySound3D("Opponent", "measures/throw_dices/throw_dices+0.wav", 1.0)
	   	OpponentSum = ms_dicegame_Xroll(5)
		local result = ms_dicegame_Calculation()
		
		ms_dicegame_Payout(result)
		return
	else
		local success = ms_dicegame_Raise(raise)
		if not success then -- raise failed due to a lack of money
			-- animation
			PlaySound3D("Opponent", "measures/shake_dices/shake_dices+0.wav", 1.0)
			local ani = PlayAnimationNoWait("Opponent", "manipulate_middle_low_r")
			Sleep(ani-1)
			PlaySound3D("Opponent", "measures/throw_dices/throw_dices+0.wav", 1.0)
			OpponentSum = ms_dicegame_Xroll(5)
			local result = ms_dicegame_Calculation()
			
			ms_dicegame_Payout(result)
			return
		end
	end
	
	-- final round
	local roll6 = ms_dicegame_Roll()
	ms_dicegame_DiceRun(1, roll6)
	
	PlaySound3D("", "measures/shake_dices/shake_dices+0.wav", 1.0)
	local wfallen = PlayAnimationNoWait("", "manipulate_middle_low_r")
	Sleep(wfallen-1)
	PlaySound3D("", "measures/throw_dices/throw_dices+0.wav", 1.0)
	
	if DynastyIsAI("") then
		local CurrentSum = GetData("Sum")
		if CurrentSum <= 12 then
			EndRound4 = "raise"
		else
			EndRound4 = "Exit"
		end
	else
		EndRound4 = InitData("@P"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll1..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll2..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll3..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll4..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll5..".tga]"..
						"@B[A,,@L_HPFZ_WS_STUFF_+2,hpfzextra/dices/dice_highlighted_"..roll6..".tga]", ms_dicegame_AIConfirm,
						"@L_HPFZ_WS_STUFF_+5",
						"")
	end
	
	if GetData("Sum") == 17 then
		ms_dicegame_siebz(6)
	elseif GetData("Sum") > 17 then
		ms_dicegame_Payout(4)
	end
	
	-- animation
	PlaySound3D("Opponent", "measures/shake_dices/shake_dices+0.wav", 1.0)
	local ani = PlayAnimationNoWait("Opponent", "manipulate_middle_low_r")
	Sleep(ani-1)
	PlaySound3D("Opponent", "measures/throw_dices/throw_dices+0.wav", 1.0)
	OpponentSum = ms_dicegame_Xroll(6)
	local result = ms_dicegame_Calculation()
	
	ms_dicegame_Payout(result)
end

function siebz(d)

	local ResultX = MsgBox("", false, "@P"..
						"@B[Exit,@L_HPFZ_WS_EINSATZ_+3,]",
						"@L_HPFZ_WS_KOPF_+1",
						"@L_HPFZ_WS_RUMPF_+9", GetData("Sum"))
	
	local OpponentSum = ms_dicegame_Xroll(d)
	local result = ms_dicegame_Calculation()
	ms_dicegame_Payout(result)
end

function Xroll(DiceCount)

	local XDice = ""
	local PlayerTotalRoll, XTotalRoll
	
	local Xroll1 = ms_dicegame_Roll()
	ms_dicegame_DiceRun(2, Xroll1)
	XDice = XDice.."@B[X,,@L_HPFZ_WS_STUFF_+6,hpfzextra/dices/dice_"..Xroll1..".tga]"
	
	local Xroll2 = ms_dicegame_Roll()
	ms_dicegame_DiceRun(2, Xroll2)
	XDice = XDice.."@B[X,,@L_HPFZ_WS_STUFF_+6,hpfzextra/dices/dice_"..Xroll2..".tga]"
	
	local Xroll3 = ms_dicegame_Roll()
	ms_dicegame_DiceRun(2, Xroll3)
	XDice = XDice.."@B[X,,@L_HPFZ_WS_STUFF_+6,hpfzextra/dices/dice_"..Xroll3..".tga]"

	PlayerTotalRoll = GetData("Sum")
	XTotalRoll = GetData("XSum")
	
	if XTotalRoll > PlayerTotalRoll and XTotalRoll <= 17 then
		local Gegnerwurf = InitData("@P"..XDice, -1, "@L_HPFZ_WS_STUFF_+7", "")
		return 3
	end
	
	if DiceCount >= 4 then
		local Xroll4 = ms_dicegame_Roll()
		ms_dicegame_DiceRun(2, Xroll4)
		XDice = XDice.."@B[X,,@L_HPFZ_WS_STUFF_+6,hpfzextra/dices/dice_"..Xroll4..".tga]"
	end

	PlayerTotalRoll = GetData("Sum")
	XTotalRoll = GetData("XSum")
	
	if XTotalRoll > PlayerTotalRoll and XTotalRoll <= 17 then
		local Gegnerwurf = InitData("@P"..XDice, -1, "@L_HPFZ_WS_STUFF_+7", "")
		return 3
	end
	
	if DiceCount >= 5 then
		local Xroll5 = ms_dicegame_Roll()
		ms_dicegame_DiceRun(2, Xroll5)
		XDice = XDice.."@B[X,,@L_HPFZ_WS_STUFF_+6,hpfzextra/dices/dice_"..Xroll5..".tga]"	
	end

	PlayerTotalRoll = GetData("Sum")
	XTotalRoll = GetData("XSum")
	
	if XTotalRoll > PlayerTotalRoll and XTotalRoll <= 17 then
		local Gegnerwurf = InitData("@P"..XDice, -1, "@L_HPFZ_WS_STUFF_+7", "")
		return 3
	end
	
	if DiceCount == 6 then
		local Xroll6 = ms_dicegame_Roll()
		ms_dicegame_DiceRun(2, Xroll6)
		XDice = XDice.."@B[X,,@L_HPFZ_WS_STUFF_+6,hpfzextra/dices/dice_"..Xroll6..".tga]"	
	end

	PlayerTotalRoll = GetData("Sum")
	XTotalRoll = GetData("XSum")
	
	if XTotalRoll > PlayerTotalRoll and XTotalRoll <= 17 then
		local Gegnerwurf = InitData("@P"..XDice, -1, "@L_HPFZ_WS_STUFF_+7", "")
		return 3
	end
	
	local Gegnerwurf = InitData("@P"..XDice, -1, "@L_HPFZ_WS_STUFF_+7", "")
	return
end

function Raise(add)

	local pod = GetData("Jackpod")
	if not chr_SpendMoney("", add, "misc") then
		MsgQuick("", "@L_MEASURE_DICEGAME_NOMONEY_+0")
		return false
	else
		ShowOverheadSymbol("", false, true, 0, "-%1t", add)
		-- 10% for divehouse
		local Share = add * 0.1
		chr_CreditMoney("Divehouse", Share, "misc")
		add = add - Share
		SetData("Jackpod", add+pod)	
		return true
	end
end

function Calculation()

	local PlayerSum = GetData("Sum")
	local XSum = GetData("XSum")

	if PlayerSum == XSum then
		return 1
	end

	if (17 - PlayerSum) < (17 - XSum) or (17 - XSum) < 0 then
		return 2
	end

	if (17 - PlayerSum) > (17 - XSum) or (17 - PlayerSum) < 0 then
		return 3
	end
end

function Payout(code)
	SetData("Blocked", 1)
	local Payout = GetData("Jackpod")

	if code == 1 then -- draw
		if DynastyIsPlayer("") then 
			MsgBox("", false, "", "@L_HPFZ_WS_KOPF_+2",
				"@L_HPFZ_WS_RUMPF_+2", GetData("Sum"))
		end
				
		chr_CreditMoney("", Payout, "Offering")
		ShowOverheadSymbol("", false, true, 0, "%1t", Payout)
	elseif code == 2 then -- Player win
		
		chr_UseBudget("Opponent", Payout, 2)
		
		if IsDynastySim("Opponent") then
		
			if not HasProperty("Divehouse", "WorstDicePlayer") then
				local winnername = GetName("Opponent")
				SetProperty("Divehouse", "WorstDicePlayer", winnername)
				SetProperty("Divehouse", "WorstDicePott", Payout)
			else
				local altwinner = GetProperty("Divehouse", "WorstDicePott")
				if Payout >= altwinner then
					local winnername = GetName("Opponent")
					SetProperty("Divehouse", "WorstDicePlayer", winnername)
					SetProperty("Divehouse", "WorstDicePott", Payout)
				end
			end
		
			MsgNewsNoWait("Opponent", "Opponent", "", "intrigue", -1, "@L_HPFZ_WS_KOPF_+5", "@L_MEASURE_DICEGAME_OPPONENT_LOSE_BODY_+0", GetID("Opponent"), GetID("Divehouse"), GetID(""), Payout)
		end
		Payout = Payout*2
		if DynastyIsPlayer("") then 
			MsgBox("", false, "", "@L_HPFZ_WS_KOPF_+3",
				"@L_HPFZ_WS_RUMPF_+3", GetData("Sum"), GetData("XSum"), Payout)
		end
		
		chr_CreditMoney("", Payout, "Offering")
		ShowOverheadSymbol("", false, true, 0,"%1t", Payout)
		
		if not HasProperty("Divehouse" ,"BestDicePlayer") then
			local winnername = GetName("")
			SetProperty("Divehouse", "BestDicePlayer", winnername)
			SetProperty("Divehouse", "BestDicePott", Payout)
		else
			local altwinner = GetProperty("Divehouse", "BestDicePott")
			if payout >= altwinner then
				local winnername = GetName("")
				SetProperty("Divehouse", "BestDicePlayer", winnername)
				SetProperty("Divehouse", "BestDicePott", Payout)
			end
		end
		
		Sleep(0.5)
		chr_GainXP("", GL_EXP_GAIN_RARE)
		chr_GainXP("Opponent", GL_EXP_GAIN_HIGH_RISK) 
	elseif code == 4 then -- lose because too high
		if DynastyIsPlayer("") then 
			MsgBox("", false, "", "@L_HPFZ_WS_KOPF_+5",
				"@L_HPFZ_WS_RUMPF_+5", Payout)
		end
		
		chr_UseBudget("Opponent", -Payout, 2)
		
		if IsDynastySim("Opponent") then
			MsgNewsNoWait("Opponent", "Opponent", "", "intrigue", -1, "@L_HPFZ_WS_KOPF_+0", "@L_MEASURE_DICEGAME_OPPONENT_WON_BODY_+0", GetID("Opponent"), GetID("Divehouse"), GetID(""), Payout)
		end
		
		if not HasProperty("Divehouse", "WorstDicePlayer") then
			local winnername = GetName("")
			SetProperty("Divehouse", "WorstDicePlayer", winnername)
			SetProperty("Divehouse", "WorstDicePott", Payout)
		else
			local altwinner = GetProperty("Divehouse", "WorstDicePott")
			if Payout >= altwinner then
				local winnername = GetName("")
				SetProperty("Divehouse", "WorstDicePlayer", winnername)
				SetProperty("Divehouse", "WorstDicePott", Payout)
			end
		end
	else -- lose because worse
		if DynastyIsPlayer("") then 
			MsgBox("", false, "", "@L_HPFZ_WS_KOPF_+4",
				"@L_HPFZ_WS_RUMPF_+4", GetData("XSum"), GetData("Sum"), Payout)
		end
		
		chr_UseBudget("Opponent", -Payout, 2)
		
		if IsDynastySim("Opponent") then
			MsgNewsNoWait("Opponent", "Opponent", "", "intrigue", -1, "@L_HPFZ_WS_KOPF_+0", "@L_MEASURE_DICEGAME_OPPONENT_WON_BODY_+0", GetID("Opponent"), GetID("Divehouse"), GetID(""), Payout)
		end
		
		if not HasProperty("Divehouse", "WorstDicePlayer") then
			local winnername = GetName("")
			SetProperty("Divehouse", "WorstDicePlayer", winnername)
			SetProperty("Divehouse", "WorstDicePott", Payout)
		else
			local altwinner = GetProperty("Divehouse", "WorstDicePott")
			if Payout >= altwinner then
				local winnername = GetName("")
				SetProperty("Divehouse", "WorstDicePlayer", winnername)
				SetProperty("Divehouse", "WorstDicePott", Payout)
			end
		end
	end
	StopMeasure()
end

function DiceRun(key, roll)

	if key == 1 then
		if GetData("Sum") then
			local oldSum = GetData("Sum")
			local newSum = oldSum + roll
			SetData("Sum", newSum)
		else
			SetData("Sum", roll)
		end
	end
		
	if key == 2 then -- for the opponent
		if GetData("XSum") then
			local XoldSum = GetData("XSum")
			local XnewSum = XoldSum + roll
			SetData("XSum", XnewSum)
		else
			SetData("XSum", roll)
		end
	end
end

function Roll()
	return Rand(6)+1
end

function CleanUp()
	SetData("Blocked", 1)
	f_EndUseLocator("Owner", "DicePlayer", GL_STANCE_STAND)
	if AliasExists("Opponent") then
		SetState("Opponent", STATE_DUEL, false)
		f_EndUseLocator("Opponent", "CeoPos", GL_STANCE_STAND)
	end
end

function BlockMe()
	local MaxTimer = math.mod(GetGametime(), 24) + 1 -- prevents exploit blocking
	
	while GetData("Blocked") ~=1 do
		Sleep(3)
		if not GetState("", STATE_DUEL) then
			SetState("", STATE_DUEL, true)
		end
		
		if math.mod(GetGametime(), 24) > MaxTimer then
			SetData("Blocked", 1)
		end
	end

	SetState("", STATE_DUEL, false)
	return
end

function InitAI(OpponentSum)
	local cash = GetMoney("")
	if cash > OpponentSum then
		cash = OpponentSum
	end
	
	local ChoiceSum = 0
	
	if Rand(2) == 0 then
		ChoiceSum = cash * 0.25
	else
		ChoiceSum = cash * 0.5
	end
	
	local raise = cash * 0.15
	SetData("Jackpod", ChoiceSum)
	SetData("RaiseCost", raise)
end

function AIConfirm()
	return "A"
end

function GetOSHData(MeasureID)
	--can be used again in:
	OSHSetMeasureRepeat("@L_ONSCREENHELP_7_MEASURES_TIMEINFOS_+2", Gametime2Total(mdata_GetTimeOut(MeasureID)))
end