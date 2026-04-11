function Run()
	if DynastyIsPlayer("") then
		SetRichPresence("state", "Duel")
	end
	SimSetProduceItemID("", -1, -1)

	if not f_SimIsValid("") or GetState("", STATE_FIGHTING) then
		return
	end
	
	if GetOutdoorMovePosition("", "destination", "MovePos") then
		f_MoveTo("", "MovePos", GL_MOVESPEED_RUN)
	end
	
	Sleep(2000)
end

function CleanUp()
	if DynastyIsPlayer("") then
		SetRichPresence("state", "")
	end
end