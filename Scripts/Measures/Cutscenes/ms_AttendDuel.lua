function Run()
	SimSetProduceItemID("", -1, -1)
	
	if GetState("", STATE_FIGHTING) then
		return
	end
	
	if not f_SimIsValid("") then
		return
	end
	
	if GetOutdoorMovePosition("", "destination", "MovePos") then
		f_MoveTo("", "MovePos", GL_MOVESPEED_RUN)
	end
	
	Sleep(1000)
end
