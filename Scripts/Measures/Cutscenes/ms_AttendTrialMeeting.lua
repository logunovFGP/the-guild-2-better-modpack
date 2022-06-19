function Run()
	SimSetProduceItemID("", -1, -1)
	BuildingGetRoom("destination", "Judge", "Room")
	
	if not f_SimIsValid("") then
		return
	end	

	if GetInsideBuilding("", "InsideBuilding") then -- already inside
		if GetID("InsideBuilding") ~= GetID("destination") then -- wrong inside building
			f_ExitCurrentBuilding("")
			f_AttendMoveTo("", "Room", GL_MOVESPEED_RUN, 5)
		elseif GetInsideRoom("", "InsideRoom") then
			if GetID("InsideRoom") ~= GetID("Room") then -- wrong room
				f_AttendMoveTo("", "Room", GL_MOVESPEED_RUN, 5)
			end
		end
	else -- outside
		f_AttendMoveTo("", "Room", GL_MOVESPEED_RUN, 5)
	end
	
	if DynastyIsPlayer("") then
		return
	end
	
	SimSetBehavior("", "CheckPretrial")
end


