function Run()

	if SimGetAge("") > 13 then
		return
	end
	
	if GetImpactValue("", "HaveBeenPickpocketed") > 0 then
		return
	end

	MeasureRun("", "", "FollowRatBoy", true)
end

