function Weight()

	if not ReadyToRepeat("dynasty", "AI_CheckDynastyHeir") then
		return 0
	end	
	
	local Heir = GetProperty("dynasty", "Heir") or 0
	if Heir > 0 then
		-- still alive?
		if GetAliasByID(Heir, "HeirAlias") then
			if GetState("HeirAlias", STATE_DEAD) or GetState("HeirAlias", STATE_DYING) then
				if HasProperty("HeirAlias", "DynastyHeir") then
					RemoveProperty("HeirAlias", "DynastyHeir")
					RemoveProperty("dynasty", "Heir")
				end
			end
		end
	else
		-- choose a new if you have an available family member
		local FamilyCount = DynastyGetFamilyMemberCount("dynasty")
		if FamilyCount >= 4 then
			-- select a new
			local BestWeight = 0
			for idx=0, FamilyCount-1 do
				if DynastyGetFamilyMember("dynasty", idx, "member") then
					if GetID("dynasty") == GetDynastyID("member") then -- make sure we don't steal members
						local Weight =  checkheir_CheckMember("member")
						if Weight > BestWeight then
							BestWeight = Weight
							CopyAlias("member", "SIM")
						end
					end
				end
			end
		end
	end
	
	if AliasExists("SIM") then
		return 100
	end
	
	SetRepeatTimer("dynasty", "AI_CheckDynastyHeir", 4)
	return 0
end

function CheckMember(Alias)
	local Age = SimGetAge(Alias)
	if Age < 16 then
		return 0
	end
	
	if IsPartyMember(Alias) then
		return 0
	end
	
	local Weight = 100 - Age + (SimGetLevel(Alias) * 3)
	local BossClass = 1
	
	if DynastyGetMember("dynasty", 0, "Boss") then
		BossClass = SimGetClass("Boss")
	end
	
	if SimGetClass(Alias) == BossClass then
		Weight = Weight + 20
	end
	
	return Weight
end

function Execute()
	SetRepeatTimer("dynasty", "AI_CheckDynastyHeir", 12)
	LogMessage("Dynasty selected "..GetName("SIM").." as the heir of Dynasty "..GetName("dynasty"))
	-- set heir
	SetProperty("dynasty", "Heir", GetID("SIM"))
	SetProperty("SIM", "DynastyHeir", 1)
end

