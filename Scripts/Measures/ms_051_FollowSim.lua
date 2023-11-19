-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_051_FollowSim"
----
----	With this measure a sim will start following another sim
----
-------------------------------------------------------------------------------

-- -----------------------
-- Run
-- -----------------------
function Run()
	if DynastyGetDiplomacyState("", "Destination") ~= DIP_FOE then
		SetProperty("", "Follows", GetID("Destination"))
		if GetImpactValue("", "MoveSpeed") < 1.2 then
			AddImpact("", "MoveSpeed", 1.2, 4)
		end

		while true do
			local CurrentDistance = GetDistance("", "Destination")
			if CurrentDistance > 200 and CurrentDistance < 750 then
				f_Follow("", "Destination", GL_MOVESPEED_WALK, 150, true)
			elseif CurrentDistance >= 750 then
				f_Follow("", "Destination", GL_MOVESPEED_RUN, 150, true)
			end
			Sleep(2)
		end		
	end
end

-- -----------------------
-- CleanUp
-- -----------------------
function CleanUp()
	StopFollow("")
end

