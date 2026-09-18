-- Declares the feud the house is already in: one diplomatic band a day, down to hostility.
--
-- Why it had to exist. attf_ChangeStatus is the only other node in the tree that can lower
-- a diplomatic state, and it hangs under Feud/AttackFeud, whose Weight() wants the victim
-- outdoors and within 10000 of the actor. In the 2026-09-19 session dyn 593561 entered Feud
-- 166 times and AttackFeud never produced one weight line, so the status change was never
-- so much as evaluated. Meanwhile a duel had reset that pair from DIP_FOE back to DIP_NAP
-- and favour 18 back to 50 (Duel.lua EndDuel resets any state below neutral), and the house
-- spent the rest of the day posting taunting letters to a dynasty it was formally at peace
-- with - bf_Taunt is the one leaf that requires *not* being at war, so peace was also the
-- state in which its favourite move stayed legal. Nothing in the subtree could leave.
--
-- Stepped, not jumped. The engine's own diplomacy UI shows four bands and every other house
-- walks them one at a time; a blood enemy that goes from alliance to war between two ticks
-- reads as a bug rather than a grudge. From DIP_NAP that is two steps, so two days.
function Weight()
	if not aitwp_Allowed("dynasty", "PlayerDyn", "declare_foe") then
		return 0
	end
	if not aitwp_FindPlayerTarget("PlayerDyn", "best", "Victim") then
		return 0
	end
	-- the same key attf_ChangeStatus keeps, so the two nodes share one window instead of
	-- stepping the same pair of houses twice in a day
	if not ReadyToRepeat("dynasty", "DIP_" .. GetDynastyID("Victim")) then
		return 0
	end
	if aitwp_NextFoeStep("dynasty", "PlayerDyn") == nil then
		return 0
	end
	-- siblings share the alias "Victim" and the engine runs every Weight() before the
	-- winner's Execute(); file it under this node so no sibling can take it
	aiboard_Stash("bf_DeclareFoe", "Victim")
	-- scored: an aggressive house stops pretending sooner
	return utility_Score("dynasty", 50, {
		utility_Priority("dynasty", "Agressive"),
	}, "bf_DeclareFoe")
end

function Execute()
	utility_Picked("dynasty", "bf_DeclareFoe")
	if not aiboard_Claim("bf_DeclareFoe", "BF_FoeVictim") then
		return
	end
	-- re-read: every sibling's Weight() ran between the stash and this line
	local Step = aitwp_NextFoeStep("dynasty", "PlayerDyn")
	if Step == nil then
		aiboard_Drop("BF_FoeVictim")
		return
	end
	SetRepeatTimer("dynasty", "DIP_" .. GetDynastyID("BF_FoeVictim"), TWP_BF_FOE_HOURS)
	aitwp_Log("declares one band down on " .. GetName("BF_FoeVictim") .. ", to band " .. Step, "dynasty")
	MeasureCreate("Measure")
	MeasureAddData("Measure", "Choice", 1, false)
	MeasureAddData("Measure", "InitResult", Step, false)
	MeasureStart("Measure", "SIM", "BF_FoeVictim", "AdministrateDiplomacy")
	aiboard_Drop("BF_FoeVictim")
end
