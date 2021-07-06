function Run()

	if SimGetAge("") > 12 then
		return
	end
	
	if GetImpactValue("", "HaveBeenPickpocketed") > 0 then
		return
	end

	MeasureRun("", "", "FollowRatBoy", true)
end

