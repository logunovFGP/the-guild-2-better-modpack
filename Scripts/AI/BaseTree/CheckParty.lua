function Weight()

	if not ReadyToRepeat("dynasty", "AI_CheckPartyMember") then
		return 0
	end	

	local DynastyCount = DynastyGetMemberCount("dynasty") -- active group members
	if DynastyCount > 2 then
		SetRepeatTimer("dynasty", "AI_CheckPartyMember", 6)
		return 0
	end
	
	local FamilyCount = DynastyGetFamilyMemberCount("dynasty") -- all members of the family
	local BestWeight = -1

	if FamilyCount == DynastyCount then -- nothing to add
		SetRepeatTimer("dynasty", "AI_CheckPartyMember", 16)
		return 0
	end
	
	for idx=0, FamilyCount-1 do
		if DynastyGetFamilyMember("dynasty", idx, "member") then
			if GetID("dynasty") == GetDynastyID("member") then -- make sure we don't steal members
				local Weight =  checkparty_CheckMember("member")
				if Weight > BestWeight then
					BestWeight = Weight
					CopyAlias("member", "SIM")
				end
			end
		end
	end
	
	if not AliasExists("SIM") then
		SetRepeatTimer("dynasty", "AI_CheckPartyMember", 12)
		return 0
	end
	
	return 100
end

function CheckMember(SimAlias)
	if GetState(SimAlias, STATE_DEAD) or GetState(SimAlias, STATE_DYING) or HasProperty(SimAlias, "Wedding") then
		return -1
	end
	
	-- don't add members used by other players
	if GetHomeBuilding(SimAlias, "Home") then
		if GetDynastyID("Home") ~= GetID("dynasty") then
			return -1
		end
	end	

	local Age = SimGetAge(SimAlias)
	
	if Age >= 72 or < 16 then
		return -1
	end
	
	if IsPartyMember(SimAlias) then
		return -1
	end
	
	local Weight
	Weight = 2*(72 - (Age - 16)) + SimGetLevel(SimAlias) * 10
	
	return Weight
end

function Execute()
	LogMessage("Dynasty added "..GetName("SIM").." to group of Dynasty "..GetID("dynasty"))
	DynastyAddMember("dynasty", "SIM")
end

