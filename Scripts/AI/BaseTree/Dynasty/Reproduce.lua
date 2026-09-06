function Weight()
	if not ReadyToRepeat("dynasty", "AI_Reproduce") then
		return 0
	end

	-- choose married party member
	local PartyCount = DynastyGetMemberCount("dynasty")
	for i=0, PartyCount-1 do
		DynastyGetMember("dynasty", i, "Member")
		
		if SimGetAge("Member") >= 18 
				and SimGetSpouse("Member", "Spouse") 
				and SimGetChildCount("Member") <= GL_MAX_CHILD_COUNT
				and ai_GetUsefulChildCount("Member") < 4
				and dyn_IsIdleMember("Member")
				and dyn_IsIdleMember("Spouse") 
				and (ReadyToRepeat("Member", "AI_FailedReproduction_Cohabit") or ReadyToRepeat("Member", "AI_FailedReproduction_Adopt"))
				and (ReadyToRepeat("Spouse", "AI_FailedReproduction_Cohabit") or ReadyToRepeat("Spouse", "AI_FailedReproduction_Adopt"))
				then
			CopyAlias("Member", "SIM")
			return utility_Trace("dynasty", "Reproduce", 10)
		end
	end
	return 0
end

function Execute()
	utility_Picked("dynasty", "Reproduce")
	
end

