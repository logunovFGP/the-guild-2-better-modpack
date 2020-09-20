-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_Divorce"
----
----	with this measure the player can get rid of the court lover
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()
	
	SimGetCourtLover("", "CourtLover")
	SetState("CourtLover", STATE_INLOVE, false)
	RemoveProperty("CourtLover", "CourtDiff")
	RemoveProperty("CourtLover", "courted")
	
	SimReleaseCourtLover("")
	StopMeasure()
	return
	
end

