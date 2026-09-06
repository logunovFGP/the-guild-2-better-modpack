function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "false_gauntlet") then
		return 0
	end
	
	if ScenarioGetDifficulty() < 2 then
		return 0
	end
	
	if DynastyIsShadow("Victim") then
		return 0
	end
	
	if GetImpactValue("SIM", "DeliverTheFalseGauntlet")==0 then
		return 0
	end
	
	-- the believer is the highest office holder the victim still respects; that favour hit costs votes
	if not aitwp_FindBeliever("SIM", "Victim", "Victim", 60, "office", "VictimDynasty2", "Victim2") then
		return 0
	end

	return 100
end


function Execute()
	MeasureCreate("Measure")
	MeasureAddAlias("Measure","Believer","Victim2",false)
	MeasureStart("Measure","SIM","Victim","DeliverTheFalseGauntlet")
end
