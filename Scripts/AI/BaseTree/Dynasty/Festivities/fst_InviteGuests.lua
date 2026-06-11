function Weight()
	if not AliasExists("FST_Home") then
		return 0
	end

	local Left = GetProperty("FST_Home", "InvitationsLeft") or 0
	if Left < 1 then
		return 0
	end

	if (GetProperty("FST_Home", "CanInvite") or 0) ~= 1 then
		return 0
	end

	if not BuildingGetOwner("FST_Home", "FST_Host") then
		return 0
	end

	if not ReadyToRepeat("FST_Home", "AI_FeastInvite") then
		return 0
	end

	return 70
end

function Execute()
	SetRepeatTimer("FST_Home", "AI_FeastInvite", 1)

	local DynCount = ScenarioGetObjects("cl_Dynasty", 50, "FST_Dyn")
	if DynCount < 1 then
		return
	end

	local MyID = GetID("dynasty")
	for i = 1, DynCount do
		local DynAlias = "FST_Dyn"..Rand(DynCount)
		if AliasExists(DynAlias) and GetID(DynAlias) ~= MyID then
			if DynastyGetMemberRandom(DynAlias, "FST_Guest") then
				if not GetState("FST_Guest", STATE_DEAD) and not HasProperty("FST_Guest", "InvitedBy") and GetFavorToDynasty("FST_Guest", "FST_Host") >= 30 then
					MeasureRun("FST_Host", "FST_Guest", "InviteToFeast", false)
					return
				end
			end
		end
	end
end