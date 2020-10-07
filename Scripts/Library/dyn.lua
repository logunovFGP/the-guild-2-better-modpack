-------------------------------------------------------------------------------
----
----	OVERVIEW "dyn"
----
----	Script functions library for dynasty issues
----
-------------------------------------------------------------------------------

-- -----------------------
-- Init
-- -----------------------
function Init()
 --needed for caching
end

-- -----------------------
-- IsLocalPlayer
-- -----------------------
function IsLocalPlayer(Object)
	GetLocalPlayerDynasty("LocPlayDyn")
	if GetID("LocPlayDyn") == GetDynastyID(Object) then
		return true
	else
		return false
	end
end

-- -----------------------
-- BlockEvilMeasures
-- -----------------------
function BlockEvilMeasures(BlockerDynAlias, BlockerDynID, Duration)

		if HasProperty(BlockerDynAlias, "NoEvilFrom"..BlockerDynID) then
			local ref = GetProperty(BlockerDynAlias, "NoEvilFrom"..BlockerDynID)
			SetProperty(BlockerDynAlias, "NoEvilFrom"..BlockerDynID, ref+1)
		else
			SetProperty(BlockerDynAlias, "NoEvilFrom"..BlockerDynID, 1)
		end
		
		-- This scriptcall will reset the effect
		
		CreateScriptcall("RemoveBlockEvilMeasures", Duration, "Library/dyn.lua", "RemoveBlockEvilMeasures", BlockerDynAlias, nil, BlockerDynID)
			
end

-- -----------------------
-- RemoveBlockEvilMeasures
-- -----------------------
function RemoveBlockEvilMeasures(BlockerDynID)

		if HasProperty("", "NoEvilFrom"..BlockerDynID) then
		
			local ref = GetProperty("", "NoEvilFrom"..BlockerDynID)
			
			if (ref == 1) then
				RemoveProperty("", "NoEvilFrom"..BlockerDynID)
			else
				SetProperty("", "NoEvilFrom"..BlockerDynID, ref-1)
				return true
			end
		end
		
		return false
end

-- -----------------------
-- EvilMeasuresBlocked
-- -----------------------
function EvilMeasuresBlocked(Blocked, Blocker)

		GetDynasty(Blocker, "DestDyn")
		if HasProperty("DestDyn", "NoEvilFrom"..GetDynastyID(Blocked)) then			
			GetDynasty(Blocked, "DestDyn")
			MsgBoxNoWait(Blocked, Blocker, "_GENERAL_ERROR_HEAD_+0", "@L_GENERAL_MEASURES_FAILURES_+17", GetID("DestDyn"))
			return true
		else
			return false
		end
						
end

function GetValidMember(Dynasty)
	local Count = DynastyGetMemberCount(Dynasty)
	for i=0, Count-1 do
		if DynastyGetMember(Dynasty, i, "Member") then
			if not GetState("Member", STATE_DYING) then
				if not GetState("Member", STATE_DEAD) then
					CopyAlias("Member", "DynastyBoss")
					break
				end
			end
		end
	end
	
	if not AliasExists("DynastyBoss") and AliasExists("Member") then
		CopyAlias("Member", "DynastyBoss")
	end
	
	local BossID = GetID("DynastyBoss")
	
	return BossID
end