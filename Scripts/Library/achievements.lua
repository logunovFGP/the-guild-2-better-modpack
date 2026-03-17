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

function IncrementStat(SIM, STAT)
	if not achievements_isValidSim(SIM, STAT) then
		return
	end
	if true then
		LogMessage("@STEAM #W Stat " .. STAT .. " called with " .. GetName(SIM) ..".")
	end
	UpdateStat(STAT, GetStat(STAT) + 1)
end

function GetWorldName()
	GetScenario("World")
	local WorldName = GetProperty("World", "WorldName")
	return WorldName
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

	if (REASON == "PRIVILEGE_TORTURE") then
		for i = 0, Count-1 do
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
