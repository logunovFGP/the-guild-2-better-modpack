-------------------------------------------------------------------------------
----
----	OVERVIEW "ms_debug_ShowAni.lua"
----
----	you can play animations you select
----	for demo or RP reasons
----	
----
-------------------------------------------------------------------------------

function Run()
	local Choice = ""
	local result = MsgBox("dynasty", "Destination", "@P"..
								"@B[1, Bow]"..
								"@B[2, Giggle]"..
								"@B[3, Proposal_Male]"..
								"@B[4, Proposal_Female]"..
								"@B[5, Dance_Social_Female]"..
								"@B[6, Dance_Social_Male]"..
								"@B[7, Dance_Female_1]"..
								"@B[8, Dance_Female_2]"..
								"@B[9, Dance_Male_1]"..
								"@B[10, Dance_Male_2]"..
								"@B[A, Seite 2]",
								"Animation-Test",
								"Wähle die Animation aus!")
	
	
	
	if result == 1 then
		Choice = "bow"
	elseif result == 2 then
		Choice = "giggle"
	elseif result == 3 then
		Choice = "proposal_male"
	elseif result == 4 then
		Choice = "proposal_female"
	elseif result == 5 then
		Choice = "dance_social_female"
	elseif result == 6 then
		Choice = "dance_social_male"
	elseif result == 7 then
		Choice = "dance_female_1"
	elseif result == 8 then
		Choice = "dance_female_2"
	elseif result == 9 then
		Choice = "dance_male_1"
	elseif result == 10 then
		Choice = "dance_male_2"
	elseif result == "A" then
		-- Seite 2
		result = MsgBox("dynasty", "Destination", "@P"..
								"@B[1, give_a_slap]"..
								"@B[2, got_a_slap]"..
								"@B[3, curtsy]"..
								"@B[4, stair_up]"..
								"@B[5, stair_down]"..
								"@B[6, sew_in]"..
								"@B[7, sew_loop]"..
								"@B[8, sew_out]"..
								"@B[9, devotion]"..
								"@B[10, lie_idle]"..
								"@B[A, Seite 3]",
								"Animation-Test",
								"Wähle die Animation aus!")
		if result == 1 then
			Choice = "give_a_slap"
		elseif result == 2 then
			Choice = "got_a_slap"
		elseif result == 3 then
			Choice = "curtsy"
		elseif result == 4 then
			Choice = "stair_up"
		elseif result == 5 then
			Choice = "stair_down"
		elseif result == 6 then
			Choice = "sew_in"
		elseif result == 7 then
			Choice = "sew_loop"
		elseif result == 8 then
			Choice = "sew_out"
		elseif result == 9 then
			Choice = "devotion"
		elseif result == 10 then
			Choice = "lie_idle"
		elseif result == "A" then
			result = MsgBox("dynasty", "Destination", "@P"..
								"@B[1, sneak_male]"..
								"@B[2, crouch_down]"..
								"@B[3, crouch_idle]"..
								"@B[4, crouch_up]"..
								"@B[5, hobble]"..
								"@B[6, crouch_walk]"..
								"@B[7, sit_down_ground]"..
								"@B[8, stand_up_ground]"..
								"@B[9, walk_twohand]"..
								"@B[10, take_twohand]"..
								"@B[A, Seite 3]",
								"Animation-Test",
								"Wähle die Animation aus!")
			if result == 1 then
				Choice = "sneak_male"
			elseif result == 2 then
				Choice = "crouch_down"
			elseif result == 3 then
				Choice = "crouch_idle"
			elseif result == 4 then
				Choice = "crouch_up"
			elseif result == 5 then
				Choice = "hobble"
			elseif result == 6 then
				Choice = "crouch_walk"
			elseif result == 7 then
				Choice = "sit_down_ground"
			elseif result == 8 then
				Choice = "stand_up_ground"
			elseif result == 9 then
				Choice = "walk_twohand"
			elseif result == 10 then
				Choice = "take_twohand"
			end
		end
	end
	
	LoopAnimation("", Choice, 30)
end

function CleanUp()
	StopAnimation("")
end