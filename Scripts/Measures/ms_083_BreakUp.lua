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
	
	if SimGetCourtLover("", "CourtLover") then
		SetState("CourtLover", STATE_INLOVE, false)
		RemoveProperty("", "CourtingDiff")
		RemoveProperty("CourtLover", "courted")
		SimReleaseCourtLover("")
		return
	end
end

