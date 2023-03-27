function Run()
	
	-- Workaround for bugged characters (no class)
	local MyClass = SimGetClass("")
	
	if GetNobilityTitle("") >= 2 and MyClass < 1 then
		LogMessage(GetName("").." class is "..MyClass.." fixing now!")
		if GetState("", STATE_NPCFIGHTER) then
			SetState("", STATE_NPCFIGHTER, false)
		end

		local RandomClass = Rand(4)+1
		SimSetClass("", RandomClass)
	end

	local DoNothing = GetProperty("", "_DO_NOTHING_TIME") or 5

	RemoveProperty("", "_DO_NOTHING_TIME")
	if DoNothing < 5 then
		DoNothing = 5
	end
	
	if DynastyIsPlayer("") and IsDynastySim("") then
		DoNothing = 30
	end
	
	Sleep(DoNothing)
end

