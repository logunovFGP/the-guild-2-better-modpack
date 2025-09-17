-- SimMarry has a nasty engine bug that could corrupt the dynasty if there are circular marriages and lead to unpreventable crashes later in the game
-- We need to check if we can safely marry the sim

function Init()
 --needed for caching
end



function CanSafelyUseSimMarry(SourceSim, DestinationSim)
	-- temporarily restrict marriage targets to serfs to prevent player saves from getting corrupted until we find a better solution
	return enginebugchecks_SuperStrictCheck(SourceSim, DestinationSim)
	--if not enginebugchecks_CircularMarriageCheck(SourceSim, DestinationSim) then
	--	LogMessage("@SMFIX Detected circular marriage. Preventing marriage between source: '" .. GetName(SourceSim) .. "' and destination: '" .. GetName(DestinationSim))
	--	return false
	--end
	return true
end


function CircularMarriageCheck(SourceSim, DestinationSim)
	-- DestinationSim is not a dynasty sim, the safest option
	if not IsDynastySim(DestinationSim) then
		return true
	end
	
	local SourceDynasty = "SMFIX_SourceDynasty"
	local DestinationDynasty = "SMFIX_DestinationDynasty"
	if not (GetDynasty(SourceSim, SourceDynasty) and GetDynasty(DestinationSim, DestinationDynasty)) then
		return false
	end
	
	local SourceFamilyCount = DynastyGetFamilyMemberCount(SourceDynasty)
	local DestinationFamilyCount = DynastyGetFamilyMemberCount(DestinationDynasty)
	local memberAlias = "SMFIX_Member"
	
	-- First we need to check if there are no members of DestinationDynasty in SourceDynasty family
	for idx=0, SourceFamilyCount-1 do
		if DynastyGetFamilyMember(SourceDynasty, idx, memberAlias) then
			if GetDynastyID(memberAlias) == GetDynastyID(DestinationDynasty) then
				return false
			end
			-- to be sure
			if HasProperty(memberAlias, "FamilyID") and (GetProperty(memberAlias, "FamilyID") == GetDynastyID(DestinationDynasty)) then
				return false
			end
		end
	end
	
	-- Now we need to check if there are no members of SourceDynasty in DestinationDynasty family
	for idx=0, DestinationFamilyCount-1 do
		if DynastyGetFamilyMember(DestinationDynasty, idx, memberAlias) then
			if GetDynastyID(memberAlias) == GetDynastyID(SourceDynasty) then
				return false
			end
			-- to be sure
			if HasProperty(memberAlias, "FamilyID") and (GetProperty(memberAlias, "FamilyID") == GetDynastyID(SourceDynasty)) then
				return false
			end
		end
	end
	
	return true
end

-- SuperStrictCheck forbids marriage between dynasties altogether, and only allows marrying commoners - then we can be sure even circular marriages of higher degree don't happen.
-- That's the nuclear option, so it's unused for now
function SuperStrictCheck(SourceSim, DestinationSim)
	if IsDynastySim(DestinationSim) then
		return false
	end
	return true
end
