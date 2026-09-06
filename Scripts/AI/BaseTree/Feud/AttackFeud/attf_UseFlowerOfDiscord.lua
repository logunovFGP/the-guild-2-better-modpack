function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "discord") then
		return 0
	end
	
	local	Item = "FlowerOfDiscord"

	if DynastyIsShadow("Victim") then
		return 0
	end

	if GetRepeatTimerLeft("SIM", GetMeasureRepeatName2("Use"..Item)) > 0 then
		return 0
	end

	-- sow discord between the victim and the friend they value most, never one of our own friends
	if not aitwp_FindBeliever("SIM", "Victim", "SIM", 50, "friend", "VictimDynasty2", "Victim2") then
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

	return 5 -- was 20 behind a 1-in-4 dice gate; same expected share, no dice
end

function Execute()
	MeasureCreate("Measure")
	MeasureAddAlias("Measure","Believer","Victim2",false)
	MeasureStart("Measure","SIM","Victim","UseFlowerOfDiscord")
end
