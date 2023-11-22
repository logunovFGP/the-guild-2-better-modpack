function Run()
	
	ai_GetWorkBuilding("Actor", GL_BUILDING_TYPE_JUGGLER, "Juggler")
	GetFleePosition("Owner", "Actor", Rand(50)+100, "Away")
	f_MoveTo("Owner", "Away", GL_MOVESPEED_WALK)
	AlignTo("Owner", "Actor")
	local RandomWait = Rand(4) + 2
	Sleep(RandomWait)
	if SimGetGender("Owner") == GL_GENDER_MALE then
		PlaySound3DVariation("Owner", "CharacterFX/male_neutral", 1)
	else
		PlaySound3DVariation("Owner", "CharacterFX/female_neutral", 1)
	end
	PlayAnimation("Owner", "talk_short")
	
	local begbonus = math.floor(GetImpactValue("Juggler", "RogueBonus"))
	local spender = chr_GetRank("")
	local spend
	local charm = GetSkillValue("Actor", CHARISMA)
		
	if spender == 0 or spender == 1 then
		spend = 2
	elseif spender == 2 then
		spend = 4
	elseif spender == 3 then
		spend = 8
	elseif spender == 4 then
		spend = 16
	elseif spender == 5 then
		spend = 32
	end

	local getbeg = math.floor(spend + ((spend / 100) * begbonus)) + Rand(8)*charm
	chr_CreditMoney("Actor", getbeg, "Offering")
	ShowOverheadSymbol("Actor", false, true, 0, "%1t", getbeg)
	
	if IsDynastySim("Owner") then
		chr_SpendMoney("Owner", getbeg, "Offering")
	end

	SetRepeatTimer("Owner", "DonateJuggler", 1)
	
	if chr_SkillCheck("Actor", CHARISMA, 1, "Owner", EMPATHY) then
		Sleep(2)
		if SimGetGender("Owner") == GL_GENDER_MALE then
			PlaySound3DVariation("Owner", "CharacterFX/male_rejoice", 1)
		else
			PlaySound3DVariation("Owner", "CharacterFX/female_rejoice", 1)
		end
		if Rand(3) == 0 then
			PlayAnimation("Owner", "cheer_01")
		else
			PlayAnimation("Owner", "nod")
		end
		
		-- again
		spend = (spender * spender + charm)*3 + Rand(((charm + spender * spender)*3))
		chr_CreditMoney("Actor", getbeg, "Offering")
		ShowOverheadSymbol("Actor", false, true, 0, "%1t", getbeg)
		
		if IsDynastySim("Owner") then
			chr_SpendMoney("Owner", getbeg, "Offering")
		end
	end
end

