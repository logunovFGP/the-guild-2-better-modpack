function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "ambush") then
		return 0
	end
	if not dyn_GetIdleMyrmidon("dynasty", "MYRM") then
		return 0
	end
	return aitwp_GetAgressiveness("dynasty")
end

function Execute()
end
