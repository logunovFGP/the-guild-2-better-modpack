function Run()

end

function Unlock(SIM, ID)
	if not achievements_isValidSim(SIM, ID) then
		return
	end
	if true then
		LogMessage("@STEAM #W Achievement " .. ID .. " called with " .. GetName(SIM) ..".")
	end
	UnlockAchievement(ID)
end

function UnlockVictory(BossAlias, Sub, Diff)
	if not AliasExists(BossAlias) then
		return
	end
	achievements_Unlock(BossAlias, "VICTORY_EASY_"..Sub)
	if Diff >= 1 then
		achievements_Unlock(BossAlias, "VICTORY_MEDIUM_"..Sub)
	end
	if Diff >= 2 then
		achievements_Unlock(BossAlias, "VICTORY_HARD_"..Sub)
	end
end

function IncrementStat(SIM, STAT)
	if not achievements_isValidSim(SIM, STAT) then
		return
	end
	if true then
		LogMessage("@STEAM #W Stat " .. STAT .. " called with " .. GetName(SIM) ..".")
	end
	local current = GetStat(STAT) or 0
	UpdateStat(STAT, current + 1)
end

function GetWorldName()
	GetScenario("World")
	local WorldName = GetProperty("World", "WorldName")
	return WorldName
end

function IncrementStatForDynasty(SIM, STAT)
	if not AliasExists(SIM) then
		return
	end
	GetLocalPlayerDynasty("PlayerDynasty")
	if GetID("PlayerDynasty") ~= GetDynastyID(SIM) then
		return
	end
	local current = GetStat(STAT) or 0
	UpdateStat(STAT, current + 1)
end

function UnlockForDynasty(SIM, ID)
	if not AliasExists(SIM) then
		return
	end
	GetLocalPlayerDynasty("PlayerDynasty")
	if GetID("PlayerDynasty") ~= GetDynastyID(SIM) then
		return
	end
	UnlockAchievement(ID)
end

function isValidSim(SIM, REASON)
	if true then
		LogMessage("@STEAM #W (" .. GetName(SIM) .. ")Reason -> " .. REASON)
	end

	if not AliasExists(SIM) then
		return
	end

	local playerDynasty = GetLocalPlayerDynasty("PlayerDynasty")
	local CheckDynasty = GetID("PlayerDynasty") == GetDynastyID(SIM) and IsPartyMember(SIM)

	if false then
		-- 'Count' was undefined here, count the family members instead
		for i = 0, DynastyGetFamilyMemberCount("PlayerDynasty")-1 do
			if DynastyGetFamilyMember("PlayerDynasty", i, "SIM") then
				if AliasExists("SIM") then
					if (GetImpactValue("SIM", "CommandPrisonGuard") > 0) then
						return true
					else
						return false
					end
				end
			end
		end
	end

	if not CheckDynasty then
		if not CanBeControlled(SIM, "PlayerDynasty") then
			return false
		else
			return true
		end
	else
		return CheckDynasty
	end
end

function CleanUp()

end
