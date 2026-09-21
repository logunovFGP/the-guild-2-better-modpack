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
	if BuildingGetOwner("Destination", "TWP_OldOwner") then
		Old = GetID("TWP_OldOwner")
	end
	RemoveAlias("TWP_OldOwner")

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
