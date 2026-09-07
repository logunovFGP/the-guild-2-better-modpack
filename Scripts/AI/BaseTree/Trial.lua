function Weight()
	-- select SIM with upcoming trial
	local Count = DynastyGetMemberCount("dynasty")
	for i=0, Count-1 do
		if DynastyGetMember("dynasty", i, "Member") and dyn_IsIdleMember("Member") then
			if GetImpactValue("Member", "TrialTimer") >= 1 and ImpactGetMaxTimeleft("Member", "TrialTimer") <= 14 then
				CopyAlias("Member", "TrialSIM")
				-- scored: the nearer the hearing the harder the house works on it (x1 at
				-- 14 hours out, x2 at the door), and the daily political priority
				local Left = ImpactGetMaxTimeleft("Member", "TrialTimer")
				return utility_Score("dynasty", 50, {
					{ value = utility_Norm(14 - Left, 0, 14), curve = "quad", lo = 1, hi = 2 },
					utility_Priority("dynasty", "Political"),
				}, "Trial")
			end
		end
	end
	
	-- no trial upcoming
	return 0
end

function Execute()
	utility_Picked("dynasty", "Trial")
	CopyAlias("TrialSIM", "SIM")
	RemoveAlias("TrialSIM")
end