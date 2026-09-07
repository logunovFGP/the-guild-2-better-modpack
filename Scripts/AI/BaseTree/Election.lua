
function Weight()
	-- select SIM with upcoming office session
	local Count = DynastyGetMemberCount("dynasty")
	for i=0, Count-1 do
		if DynastyGetMember("dynasty", i, "Member") and dyn_IsIdleMember("Member") then
			if SimIsAppliedForOffice("Member") then
				CopyAlias("Member", "ElectionSIM")
				-- scored: the daily political priority and the house's ambition decide how
				-- hard it campaigns. No goal factor: the application is a commitment already
				-- made, and a house on another goal must still fight the election it entered
				return utility_Score("dynasty", 50, {
					utility_Priority("dynasty", "Political"),
					utility_Trait("dynasty", "ambition"),
				}, "Election")
			end
		end
	end
	
	-- no trial upcoming
	return 0
end

function Execute()
	utility_Picked("dynasty", "Election")
	CopyAlias("ElectionSIM", "SIM")
	RemoveAlias("ElectionSIM")
end