function Run()

	local MaxDistance = 1000
	local ActionDistance = 50
	
	--run to destination and start action at MaxDistance
	if not ai_StartInteraction("", "Destination", MaxDistance, ActionDistance, nil, true) then
		StopMeasure()
	end
	
	feedback_OverheadActionName("Destination")
	PlayAnimation("", "watch_for_guard")
	PlayAnimation("","manipulate_bottom_r")
	
	local Booty = Plunder("", "Destination", 1)
	local Rank = chr_GetRank("Destination") or 1
	
	local XP = GetData("BaseXP") * Rank
	if Rank < 3 then
		XP = XP / 2
	end
	
	if Booty > 0 then -- you can steal multiple times if the character has items in the inventory
		-- start crime action
		if GetImpactValue("Destination", "REVOLT") == 0 then
			CommitAction("rob", "", "", "Destination")
			Sleep(0.75)
		end
		--for the mission
		mission_ScoreCrime("", Booty)
		feedback_MessageCharacter("", "@L_BATTLE_FIGHTROB_MSG_SUCCESS_OWNER_HEAD_+0",
							"@L_BATTLE_FIGHTROB_MSG_SUCCESS_OWNER_BODY_+0", GetID("Destination"))
		MsgNewsNoWait("Destination", "", "", "intrigue", -1,
					"@L_BATTLE_FIGHTROB_MSG_SUCCESS_VICTIM_HEAD_+0",
					"@L_BATTLE_FIGHTROB_MSG_SUCCESS_VICTIM_BODY_+0", GetID("Destination"), GetID(""))
		chr_GainXP("", XP)
	else
		local MoneyToSteal = chr_GetBudget("Destination", 2) * 58 -- 2: luxury budget . Multiply with 58 for actual coins
		
		-- base value is half of the maximum. you can steal more if you are a skilled thief
		local SkillBonus = chr_GetSkillValue("", SHADOW_ARTS) * 0.03
		local AbilityBoost = GetImpactValue("", "ThiefBoost")
		MoneyToSteal = ((MoneyToSteal / 2) * (1 + SkillBonus)) * (1 + AbilityBoost)
		
		-- get the actual money available (0 for non-dynasty characters)
		local Money = GetMoney("Destination") or 0
		if not IsDynastySim("Destination") then
			Money = 0
		end
		
		-- reserve 10% of the actual money for fairplay reasons
		if Money > 0 then
			if MoneyToSteal > (Money * 0.9) then
				MoneyToSteal = Money * 0.9
			end
		end
		
		local RecentlyRobbed = GetImpactValue("Destination", "recentlyrobbed")
		MoneyToSteal = MoneyToSteal - RecentlyRobbed*MoneyToSteal
		--LogMessage("MoneyToSteal final is "..MoneyToSteal)
		
		if MoneyToSteal >= 50 then
			
			-- start crime action
			if GetImpactValue("Destination", "REVOLT") == 0 then
				CommitAction("rob", "", "", "Destination")
				Sleep(0.75)
			end
			
			chr_UseBudget("Destination", 2, MoneyToSteal) -- budget
			AddImpact("Destination", "recentlyrobbed", 1, 12) -- timeout for robbing this character is 12 hours
			
			if Money > 0 then
				chr_SpendMoney("Destination", MoneyToSteal, "CostRobbers", false) -- dynasty chars lose that money for real
				MsgNewsNoWait("Destination", "", "", "intrigue", -1,
					"@L_BATTLE_FIGHTROB_MSG_SUCCESS_VICTIM_HEAD_+0",
					"@L_BATTLE_FIGHTROB_MSG_SUCCESS_VICTIM_BODY_+1", GetID("Destination"), GetID(""), MoneyToSteal)
			end
			
			Sleep(0.25)
			chr_RecieveMoney("", MoneyToSteal, "IncomeRobber")
			Sleep(0.4)
			mission_ScoreCrime("", MoneyToSteal)
			chr_GainXP("", XP)
		else
			MsgQuick("", "@L_BATTLE_FIGHTROB_FAILED_+0", GetID("Destination"))
		end
	end

	Sleep(1)
	StopAction("rob", "Owner")
end

