function Run()
	
	ai_GetWorkBuilding("Actor", GL_BUILDING_TYPE_JUGGLER, "Juggler")
	GetFleePosition("Owner", "Actor", Rand(50)+100, "Away")
	f_MoveTo("Owner", "Away", GL_MOVESPEED_WALK)
	AlignTo("Owner", "Actor")
	Sleep(1)

	if GetProperty("Actor", "Signal") == "JugglerTarot" then
	
		local ActionName = GetData("Action_Name")

		if Rand(2) == 0 then
			MsgSayNoWait("Owner", "_REN_BEHAVIOUR_GETTAROT_SPRUCH_+0")
		else
			MsgSayNoWait("Owner", "_REN_BEHAVIOUR_GETTAROT_SPRUCH_+4")
		end
		
		Sleep(1)

		local begbonus = math.floor(GetImpactValue("Juggler", "RogueBonus"))
		local spender = chr_GetRank("")
		local spend
		local charm = GetSkillValue("Actor", CHARISMA)
		
		if spender == 0 or spender == 1 then
			spend = 5
		elseif spender == 2 then
			spend = 10
		elseif spender == 3 then
			spend = 20
		elseif spender == 4 then
			spend = 40
		elseif spender == 5 then
			spend = 80
		end

		local getbeg = math.floor(spend + ((spend / 100) * begbonus)) + Rand(10)*charm
		chr_CreditMoney("Actor", getbeg, "Offering")
		economy_UpdateBalance("Juggler", "Service", getbeg)
		IncrementXPQuiet("Actor", 5)

		if dyn_IsLocalPlayer("Actor") then
			ShowOverheadSymbol("Actor", false, true, 0, "%1t", getbeg)
		end
		
		SetRepeatTimer("Owner", "SimGetKurios", 2)

		PlayAnimation("Owner", "manipulate_middle_low_r")
		Sleep(1)
		local getit = Rand(3)
		
		if getit == 0 then
			if SimGetGender("Owner") == GL_GENDER_MALE then
				PlaySound3DVariation("Owner", "CharacterFX/male_neutral", 1)
			else
				PlaySound3DVariation("Owner", "CharacterFX/female_neutral", 1)
			end
			
			MsgSayNoWait("Owner","_REN_BEHAVIOUR_GETTAROT_SPRUCH_+1")
			PlayAnimation("Owner", "talk_short")
		elseif getit == 1 then
			MsgSayNoWait("Owner","_REN_BEHAVIOUR_GETTAROT_SPRUCH_+2")
			PlayAnimation("Owner", "talk_negative")
		else
			MsgSayNoWait("Owner","_REN_BEHAVIOUR_GETTAROT_SPRUCH_+3")
			PlayAnimation("Owner", "talk_positive")
		end
	else
	
		local ActionName = GetData("Action_Name")
   		local TimeOut = GetGametime()+1

		local intro = Rand(3)
		if intro == 0 then
			MsgSayNoWait("Owner","_REN_BEHAVIOUR_GETFORTUNE_SPRUCH_+0")
		elseif intro == 1 then
			MsgSayNoWait("Owner","_REN_BEHAVIOUR_GETFORTUNE_SPRUCH_+1")
		else
			MsgSayNoWait("Owner","_REN_BEHAVIOUR_GETFORTUNE_SPRUCH_+2")
		end
		Sleep(1)

		local begbonus = math.floor(GetImpactValue("Juggler", "RogueBonus"))
		local spender = chr_GetRank("")
		local spend
		local charm = GetSkillValue("Actor", CHARISMA)
   
		if spender == 0 or spender == 1 then
			spend = 10
		elseif spender == 2 then
			spend = 20
		elseif spender == 3 then
			spend = 40
		elseif spender == 4 then
			spend = 80
		elseif spender == 5 then
			spend = 160
		end

		local getbeg = math.floor(spend + ((spend / 100) * begbonus)+Rand(10)*charm)
		local warte = PlayAnimation("Owner", "manipulate_middle_low_r")
		Sleep(1)
   	chr_CreditMoney("Actor", getbeg, "Offering")
   	economy_UpdateBalance("Juggler", "Service", getbeg)
		IncrementXPQuiet("Actor", 5)
		IncrementXPQuiet("Owner", 20)
		
		if dyn_IsLocalPlayer("Actor") then
			ShowOverheadSymbol("Actor",false,true,0,"%1t",getbeg)
		end

		SetRepeatTimer("Owner", "SimGetKurios", 6)
		Sleep(warte-1)
		
		local getit = Rand(6)
		if getit == 0 then
			MsgSayNoWait("Owner", "_REN_BEHAVIOUR_GETFORTUNE_SPRUCH_+8")
			PlayAnimation("Owner", "talk_short")
		elseif getit == 1 then
			if SimGetGender("") == GL_GENDER_MALE then
				PlaySound3DVariation("Owner", "CharacterFX/male_anger",1)
			else
				PlaySound3DVariation("Owner", "CharacterFX/female_anger",1)
			end
			MsgSayNoWait("Owner","_REN_BEHAVIOUR_GETFORTUNE_SPRUCH_+3")
			PlayAnimation("Owner", "talk_negative")
		elseif getit == 2 then
			if SimGetGender("Owner") == GL_GENDER_MALE then
				PlaySound3DVariation("Owner","CharacterFX/male_rejoice",1)
			else
				PlaySound3DVariation("Owner","CharacterFX/female_rejoice",1)
			end
			MsgSayNoWait("Owner","_REN_BEHAVIOUR_GETFORTUNE_SPRUCH_+4")
			PlayAnimation("Owner", "giggle")
		elseif getit == 3 then
			MsgSayNoWait("Owner","_REN_BEHAVIOUR_GETFORTUNE_SPRUCH_+5")
			PlayAnimation("Owner", "shake_head")
		elseif getit == 4 then
			MsgSayNoWait("Owner","_REN_BEHAVIOUR_GETFORTUNE_SPRUCH_+6")
			PlayAnimation("Owner", "talk_short")
		else
			if SimGetGender("")==GL_GENDER_MALE then
				PlaySound3DVariation("","CharacterFX/male_friendly",1)
			else
				PlaySound3DVariation("","CharacterFX/female_friendly",1)
			end
			MsgSayNoWait("Owner","_REN_BEHAVIOUR_GETFORTUNE_SPRUCH_+7")
			PlayAnimation("Owner", "talk_positive")
		end	
	end

end
