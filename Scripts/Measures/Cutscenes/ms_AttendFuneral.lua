function Run()
	SimSetProduceItemID("", -1, -1)

	if not f_SimIsValid("") then
		return
	end

	SetProperty("", "AccessAllAreas", 1)
	f_MoveTo("", "destination", GL_MOVESPEED_RUN)
	f_Stroll("", 300, 3)
	
	Sleep(1000)
end

