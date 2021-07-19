function Run()
	if not AliasExists("Destination") then
		return
	end
	
	local	Distance = Rand(400)+100
	if not f_MoveTo("", "Destination", GL_MOVESPEED_RUN, Distance) then
		return
	end

	local BootyFilter	= "__F((Object.GetObjectsByRadius(Sim)== 1500) AND(Object.BelongsToMe())AND(Object.GetProfession()==15))"
	local NumRobbers = Find("Destination", BootyFilter, "Robbers", -1)
	
	for i=0, NumRobbers-1 do
		if SquadGet("Robbers"..i, "Squad") then
			SquadAddMember("Squad", -1, "")
			return
		end
	end
	
	SquadCreate("", "SquadWaylayForBooty", "Destination", "SquadWaylayMember", "SquadWaylayMember")
end
