-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_BreakUp"
----
----	with this measure the player can get rid of the court lover
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()
	
	if SimGetCourtLover("", "CourtLover")
		SetState("CourtLover", STATE_INLOVE, false)
		RemoveProperty("CourtLover", "CourtDiff")
		RemoveProperty("CourtLover", "courted")
		SimReleaseCourtLover("")
		return
	elseif SimGetLiaison("", "Liaison")
		-- todo
		return
	end
end

