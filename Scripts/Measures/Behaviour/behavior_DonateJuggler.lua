function Run()

	if GetImpactValue("","HaveBeenPickpocketed") > 0 then
		return
	end
	
	ai_GetWorkBuilding("Actor", 102, "Juggler")
	local begbonus = math.floor(GetImpactValue("Juggler", "RogueBonus"))
	local spender = chr_GetRank("")
	local charm = GetSkillValue("Actor", CHARISMA)

	spend = (spender * spender + charm)*2 + Rand(((charm + spender * spender)*2))

	local getbeg = math.floor(spend + ((spend / 100) * begbonus))
	CreditMoney("Actor", getbeg, "Offering")
	ShowOverheadSymbol("Actor", false, true, 0, "%1t", getbeg)
	
	if IsDynastySim("Owner") then
		chr_SpendMoney("Owner", getbeg, "Offering")
	end

	AddImpact("Owner", "HaveBeenPickpocketed", 1, 4)
end

