-------------------------------------------------------------------------------
----
----	OVERVIEW "behavior_childness.lua"
----
----	Behavior of a child from 0 to 4 years of age.
----	The child cannot be controlled by the player and will stay
----	inside the residence playing.
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()
	local Age = SimGetAge("")
	-- assign correct behavior
	if Age > 16 then
		SetState("", STATE_CHILD, false)
		SimSetAge("", Age) -- change model to grown up automaticly
		SimSetBehavior("", "idle")
		return
	else
		SimSetBehavior("", "Childness")
	end
end

