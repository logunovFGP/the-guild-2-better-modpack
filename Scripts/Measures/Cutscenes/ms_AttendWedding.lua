function Run()
	LogMessage("@NAO AttendWedding:Run -> " .. GetName("") .. " ("..GetID("")..")")

	SimSetProduceItemID("", -1, -1)
	SetProperty("", "destination_ID", GetID("destination"))

	if not f_SimIsValid("") then 
		return
	end

	if GetInsideBuilding("", "InsideBuilding") then
		if GetID("InsideBuilding") ~= GetID("destination") then
			f_ExitCurrentBuilding("")
			f_AttendMoveTo("", "destination", GL_MOVESPEED_RUN, 5)
		end
	else
		f_AttendMoveTo("", "destination", GL_MOVESPEED_RUN, 5)
	end

	if DynastyIsPlayer("") then
		return
	end

	LogMessage("@NAO AttendWedding:SimSetBehavior to CheckPrewedding.")
	--SimSetBehavior("", "WeddingGuest")
end