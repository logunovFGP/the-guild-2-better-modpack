function Run()

	local VictimArray = {}
	local Found = 0
	for i=0, 3 do

		if HasProperty("Actor", "Pamphlet_"..i) then
			VictimArray[i] = GetProperty("Actor", "Pamphlet_"..i)
			GetAliasByID(VictimArray[i], "Victim_"..i)
			Found = Found + 1
			local MinFav = 20 -- don't influence enemies with lower favor
			local MaxFav = 80 -- don't influence friends with higher favor
			local CheckFav = GetFavorToSim("", "Victim_"..i)
			
			-- influence favor
			if IsDynastySim("") then
				if GetDynastyID("") ~= GetDynastyID("Victim_"..i) then -- is that my family?
					if CheckFav < MaxFav and CheckFav > MinFav then -- does this effect me?
						chr_ModifyFavor("", "Victim_"..i, -GL_FAVOR_MOD_VERYSMALL)
						Sleep(0.15)
						chr_GainXP("", GL_EXP_GAIN_SIMPLE)
						Sleep(0.1)
					end
				end
			else
				if CheckFav < MaxFav and CheckFav > MinFav then -- does this effect me?
					chr_ModifyFavor("", "Victim_"..i, -GL_FAVOR_MOD_VERYSMALL)
					Sleep(0.15)
					chr_GainXP("", GL_EXP_GAIN_SIMPLE)
					Sleep(0.1)
				end
			end
		end
	end
	
	if Found >= 1 then -- found at least one pamphlet? Look at them more closely
		
		GetOutdoorMovePosition("", "Actor", "MovePos")
		f_MoveTo("", "MovePos", GL_MOVESPEED_WALK, 100)
		AlignTo("Owner", "Actor")
		Sleep(2)
		
		for i=0, Found-1 do
		
			if AliasExists("Victim_"..i) then
			
				local MinFav = 20 -- don't influence enemies with lower favor
				local MaxFav = 80 -- don't influence friends with higher favor
				local CheckFav = GetFavorToSim("", "Victim_"..i)
				local Cheer = false
				
				if IsDynastySim("") then
					if GetDynastyID("") ~= GetDynastyID("Victim_"..i) then -- is that my family?
						if CheckFav < MaxFav and CheckFav > MinFav then -- does this effect me?
							Cheer = true
						end
					else -- react to us being the victim!
						Cheer = false
						MsgSay("", "_HPFZ_BEHAVIOUR_CHEERBB_NEGATIVE_SPRUCH")
						Sleep(1)
						-- remove the pamphlet
						local Idx = -1
						for r=0, 3 do
							if HasProperty("Actor", "Pamphlet_"..r) then
								local PamphletID = GetProperty("Actor", "Pamphlet_"..r)
								Idx = r
							end
						end
						
						if Idx >= 0 and HasProperty("Actor", "Pamphlet_"..Idx) then
							-- animation stuff
							GetLocatorByName("Actor", "entry1", "MovePos")
							f_MoveTo("", "MovePos", GL_MOVESPEED_RUN)
							AlignTo("", "Actor")
							Sleep(1)
							PlayAnimationNoWait("", "manipulate_middle_up_r")
							Sleep(1)
							
							-- check again
							if HasProperty("Actor", "Pamphlet_"..Idx) then
								if BlackBoardRemovePamphlet("Actor", Idx) then
									if HasProperty("Actor", "Pamphlet_"..Idx) then
										RemoveProperty("Actor", "Pamphlet_"..Idx)
									end

									if HasProperty("Actor", "Pamphlet_"..Idx.."Dur") then
										RemoveProperty("Actor", "Pamphlet_"..Idx.."Dur")
									end
									
									chr_GainXP("", 50)
									Sleep(0.2)
									MsgNewsNoWait("", "", "", "intrigue" , -1,
												"@L_PATROLTOWN_PAMPHLET_REMOVE_SUCCESS_HEAD_+0",
												"@L_HPFZ_BEHAVIOUR_CHEERBB_NEGATIVE_MESSAGE_BODY_+0",
												GetID(""))
								end
							end
						end
					end
				else
					if CheckFav < MaxFav and CheckFav > MinFav then -- does this effect me?
						Cheer = true
					end
				end
				
				if Cheer then
					local funny = Rand(4)
					MsgSay("", "_HPFZ_BEHAVIOUR_CHEERBB_SPRUCH_+"..funny, GetID("Victim_"..i))
					
					if Rand(14) > 5 then
						if SimGetGender("") == GL_GENDER_MALE then
							PlaySound3DVariation("", "CharacterFX/male_cheer", 0.7)
						else
							PlaySound3DVariation("", "CharacterFX/female_cheer", 0.7)
						end

						PlayAnimation("", "cheer_01")
					else
						if SimGetGender("") == GL_GENDER_MALE then
							PlaySound3DVariation("", "CharacterFX/male_joy_loop", 0.7)
						else
							PlaySound3DVariation("", "CharacterFX/female_joy_loop", 0.7)
						end
						
						PlayAnimation("", "talk_2")
					end
				end
			end
		end
	end
end

function CleanUp()
end
