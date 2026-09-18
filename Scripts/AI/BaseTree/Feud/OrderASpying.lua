function Weight()
	-- the ladder: against a human player only with the attitude, title and round for it
	if not aitwp_Allowed("dynasty", "Victim", "collect_evidence") then
		return 0
	end
	if not ReadyToRepeat("dynasty", "AI_OrderASpying") then
		return 0
	end
	if not dyn_GetIdleMyrmidon("dynasty", "MYRM") then
		return 0
	end

	
	-- SpiedByDyn causes crashes, do not use it!
	-- SetProperty("Destination", "TomAIBeingSpiedOn", 1)
--	if(HasProperty("Victim", "TomAIBeingSpiedOn")) then
--		-- someone is already spying on this one
--		return 0
--	end

	-- Re-enabled 2026-09-18. It was switched off on 2025-04-23 - "revert spying fix and
	-- disable AI spying to hopefully prevent CTD", a guess rather than a diagnosis - and the
	-- comment rode into naonauno's BaseTree import on 2025-08-16, ten months before this
	-- branch. The measure itself has been fixed since: ms_145_OrderASpying looped `while
	-- true` with an exit only the AI ever set, so an order ran forever and never freed the
	-- myrmidon (GHOSTau, 2026-06-12, 89582daa).
	--
	-- The crash history before the disable reads as spies accumulating - "reduce spies to a
	-- maximum of one per dynasty and victim", "prevent multiple spies on same sim", "Fixed
	-- crash on criminal actions (Spies)" - and this node never had the cooldown every other
	-- child of Feud has. It has one now; that is the part the history actually argues for.
	--
	-- SpiedByDyn above stays commented out. That is a separate hazard, a native that crashes,
	-- and nothing here touches it.
	return utility_Trace("dynasty", "OrderASpying", 20)
end

function Execute()
	utility_Picked("dynasty", "OrderASpying")
	SetRepeatTimer("dynasty", "AI_OrderASpying", TWP_SPY_HOURS)
	MeasureCreate("Measure")
	MeasureAddData("Measure", "TimeOut", 8, false)
	local Ok = MeasureStart("Measure", "MYRM", "Victim", "OrderASpying")
	aitwp_LogSpy("order", "MYRM", "Victim", Ok, nil)
end

