-- Reassigning a building to another dynasty member. This file was deleted from the mod in
-- 8bc1a356 ("only ship what we are modifying") and vanilla's copy ran instead; it is back
-- because vanilla's does not work once the building already has an owner, which is exactly
-- the case the player hits when the only Rogue dies and the engine hands the thieves' guild
-- to a sibling of the wrong class.
--
-- meta/engine.signatures.tsv, recovered from the binary, gives BuildingSetOwner THREE
-- parameters - building, sim, bool - where meta/engine.d.lua documents two and every caller
-- in either tree passes two. The only call that demonstrably works, Measures/Debug/
-- Construct.lua, assigns a building it has just spawned and which therefore has no previous
-- owner. Nobody has ever exercised the transfer case.
--
-- So: the two-argument form FIRST, unchanged, because every case that works today must keep
-- working. Only when that has already failed do we reach for the third argument, whose
-- meaning is a guess - "force" is merely the likeliest reading of a trailing bool. how= in
-- the log says which one succeeded, so the next session can settle it instead of guessing.
TWP_ASSIGN_FORCE = true

function Run()
	GetInsideBuilding("", "Destination")
	if not AliasExists("Destination") then
		return
	end

	f_MoveTo("", "Destination", GL_MOVESPEED_RUN)

	local Old = -1
	local Mine = true
	if BuildingGetOwner("Destination", "TWP_OldOwner") then
		Old = GetID("TWP_OldOwner")
		Mine = GetDynastyID("TWP_OldOwner") == GetDynastyID("")
	end
	RemoveAlias("TWP_OldOwner")

	-- Only an unowned building or one this dynasty already holds. Vanilla never needed this
	-- test because its filter admitted rivals' buildings too and the engine simply refused
	-- the transfer - the refusal WAS the guard. The force fallback below exists to defeat a
	-- refusal, so without this it would defeat that one too: walk a class-matching member
	-- into a rival shop, press the button, take it. Filter 122 was already this permissive in
	-- vanilla; dropping NOT(IsBuildingOwnedByMe) added OUR OWN buildings to the set, not
	-- other houses'. The hole is the forcing, so the guard belongs next to it.
	if not Mine then
		aitwp_LogAssign("", "Destination", Old, false, "notmine")
		MsgQuick("", "@L_GENERAL_MEASURES_035_ASSIGNCHARACTERTOBUILDING_FAILURES_+0", GetID(""), GetID("Destination"))
		return
	end

	local Ok = BuildingSetOwner("Destination", "")
	local How = "plain"
	if not Ok and TWP_ASSIGN_FORCE then
		Ok = BuildingSetOwner("Destination", "", true)
		How = "force"
	end

	aitwp_LogAssign("", "Destination", Old, Ok, How)

	if not Ok then
		MsgQuick("", "@L_GENERAL_MEASURES_035_ASSIGNCHARACTERTOBUILDING_FAILURES_+0", GetID(""), GetID("Destination"))
	end
end
