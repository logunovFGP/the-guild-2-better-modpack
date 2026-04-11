function Run()

	local MaxDistance = 1000
	local ActionDistance = 50
	
	--run to destination and start action at MaxDistance
	if not ai_StartInteraction("", "Destination", MaxDistance, ActionDistance, nil, true) then
		StopMeasure()
	end
	
	feedback_OverheadActionName("Destination")
	PlayAnimation("", "watch_for_guard")
	PlayAnimation("", "manipulate_bottom_r")
	
	local Booty = Plunder("", "Destination", 1)
	
	if Booty > 0 then -- you can steal multiple times if the character has items in the inventory
		-- start crime action
		if GetImpactValue("Destination", "REVOLT") == 0 then
			CommitAction("rob", "", "Destination", "Destination")
			Sleep(0.75)
		end
		--for the mission
		mission_ScoreCrime("", Booty)
		feedback_MessageCharacter("", "@L_BATTLE_FIGHTROB_MSG_SUCCESS_OWNER_HEAD_+0",
							"@L_BATTLE_FIGHTROB_MSG_SUCCESS_OWNER_BODY_+0", GetID("Destination"))
		MsgNewsNoWait("Destination", "", "", "intrigue", -1,
					"@L_BATTLE_FIGHTROB_MSG_SUCCESS_VICTIM_HEAD_+0",
					"@L_BATTLE_FIGHTROB_MSG_SUCCESS_VICTIM_BODY_+0", GetID("Destination"), GetID(""))
		xp_CommitCrime("", "Destination")
		if achievements_isValidSim("", "CRIME_ROB") then
			UpdateStat("STAT_ROB_MONEY", (GetStat("STAT_ROB_MONEY") or 0) + math.floor(Booty))
		end
	else
		local MoneyToSteal = chr_GetBudget("Destination", 2)
		
		-- base value is 50% of the maximum. you can steal more if you are a skilled thief
		local SkillBonus = chr_GetSkillValue("", SHADOW_ARTS) * 0.03
		local AbilityBoost = GetImpactValue("", "ThiefBoost")
		local Multiplier = 0.50 + SkillBonus
		MoneyToSteal = (MoneyToSteal * Multiplier) * (1 + AbilityBoost)
		
		-- get the actual money available (0 for non-dynasty characters)
		local Money = 0
		if IsDynastySim("Destination") then
			Money = GetMoney("Destination")
		end
		
		-- reserve 25% of the actual money for fairplay reasons
		if Money > 0 then
			if MoneyToSteal > (Money * 0.75) then
				MoneyToSteal = Money * 0.75
			end
		end
		
		local RecentlyRobbed = GetImpactValue("Destination", "recentlyrobbed")
		if RecentlyRobbed > 0 then
			MoneyToSteal = 0
		end
		
		--LogMessage("MoneyToSteal final is "..MoneyToSteal)
		
		if MoneyToSteal >= 50 then
			
			-- start crime action
			if GetImpactValue("Destination", "REVOLT") == 0 then
				CommitAction("rob", "", "Destination", "Destination")
				Sleep(0.75)
			end
			
			chr_UseBudget("Destination", 2, MoneyToSteal, "CostRobbers") -- budget; dynasty chars lose it for real
			AddImpact("Destination", "recentlyrobbed", 1, 12) -- timeout for robbing this character is 12 hours
			
			if Money > 0 then
				MsgNewsNoWait("Destination", "", "", "intrigue", -1,
					"@L_BATTLE_FIGHTROB_MSG_SUCCESS_VICTIM_HEAD_+0",
					"@L_BATTLE_FIGHTROB_MSG_SUCCESS_VICTIM_BODY_+1", GetID("Destination"), GetID(""), MoneyToSteal)
			end
			
			Sleep(0.25)
			chr_RecieveMoney("", MoneyToSteal, "IncomeRobber")
			Sleep(0.4)
			mission_ScoreCrime("", MoneyToSteal)
			if achievements_isValidSim("", "CRIME_ROB") then
				UpdateStat("STAT_ROB_MONEY", (GetStat("STAT_ROB_MONEY") or 0) + math.floor(MoneyToSteal))
			end
			xp_CommitCrime("", "Destination")
		else
			MsgQuick("", "@L_BATTLE_FIGHTROB_FAILED_+0", GetID("Destination"))
		end
	end

	Sleep(1)
	StopAction("rob", "Owner")
end

