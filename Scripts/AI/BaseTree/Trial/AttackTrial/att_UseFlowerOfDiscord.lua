function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "discord") then
		return 0
	end
	
	local	Item = "FlowerOfDiscord"

	if DynastyIsShadow("Victim") then
		return 0
	end

	if Rand(4) > 0 then
		return 0
	end
	
	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Use"..Item)) > 0 then
		return 0
	end

	if GetFavorToDynasty("Victim", "dynasty") > 40 then
		return 0
	end
	
	if not DynastyGetRandomVictim("Victim", 50, "VictimDynasty2") then
		return 0
	end
	
	local Count = DynastyGetMemberCount("VictimDynasty2")
	local Victim = Rand(Count)
	if not (DynastyGetMember("VictimDynasty2", Victim, "Victim2")) then
		return 0
	end	

	if not AliasExists("Victim2") then
		return 0
	end
	
	local Price = ai_CanBuyItem("SIM", Item)
	if Price<0 then
		return 0
	end
	
	if GetMoney("dynasty") < 5000 then
		return 0
	end

	return 100
end

function Execute()
	MeasureCreate("Measure")
	MeasureAddAlias("Measure","Believer","Victim2",false)
	MeasureStart("Measure","SIM","Victim","UseFlowerOfDiscord")
end
