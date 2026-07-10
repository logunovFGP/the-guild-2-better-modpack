function Run()
 
	local GuardsCalled = false

	while not ActionIsStopped("Action") do
	
		if not AliasExists("Actor") then
			break
		end
		
		local Distance = GetDistance("Owner", "Actor")
		-- calculate the distance between the combat and the gaper 
		if Distance < 350 or Distance > 550 then
				GetFleePosition("Owner", "Actor", Rand(100)+400, "Away")
				f_MoveTo("Owner", "Away", GL_MOVESPEED_RUN)
				AlignTo("Owner", "Actor")
				Sleep(1)
		end
		
		if not GuardsCalled then
			if SimGetAge("Owner") < 16 then
				ShowOverheadSymbol("Owner", true, true,"OverheadSymbolID", "@L_GENERAL_MEASURES_146_ALERTTHEGUARD")
			else
				MsgSay("Owner", "@L_GENERAL_MEASURES_146_ALERTTHEGUARD")
			end
			CommitAction("call_guards", "Owner", "Owner")
			GuardsCalled = true
			Sleep(5)
			StopAction("call_guards", "Owner")
		end
		
		if Rand(100) < 25 then
			if SimGetGender("Owner") == GL_GENDER_MALE then
				PlaySound3DVariation("Owner", "CharacterFX/male_anger_loop", 1)
			else
				PlaySound3DVariation("Owner", "CharacterFX/female_anger_loop", 1)
			end
			PlayAnimation("Owner", "cheer_02")
		end
		
		Sleep(1)
		-- scream again from time to time
		if Rand (10) == 0 then
			GuardsCalled = false
		end
	end
end

function CleanUp()
	StopAction("call_guards","Owner")
	RemoveOverheadSymbols("Owner")
end


	
