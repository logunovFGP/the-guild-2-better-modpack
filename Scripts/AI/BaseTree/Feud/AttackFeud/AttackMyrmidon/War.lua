function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "thug_attack") then
		return 0
	end
	
	if ScenarioGetDifficulty() < 2 then
		return 0
	end
	
	if DynastyGetDiplomacyState("dynasty", "VictimDynasty") > DIP_NEUTRAL then
		return 0
	end

	-- the weakest fighter of the victim's house caught outdoors, rogues last - a squad
	-- cannot reach anyone indoors, and a random member often was
	if not aitwp_FindPlayerTarget("VictimDynasty", "duel", "WAR_SIM")
			and not aitwp_FindPlayerTarget("VictimDynasty", "rogue", "WAR_SIM") then
		return 0
	end
	
	if not CanBeControlled("WAR_SIM", "VictimDynasty") then
		return 0
	end
	
	return 5
end

function Execute()
	SquadCreate("MYRM", "SquadWar", "WAR_SIM", "SquadWarMember", "SquadWarMember")
end

