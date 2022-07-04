function Run()

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

