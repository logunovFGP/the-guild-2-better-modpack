function Run()
	
	if GetImpactValue("", "SeenPox") == 0 then
		chr_ModifyFavor("", "Actor", -5)
		AddImpact("", "SeenPox", 1, 2)
	end

	return ""
end

