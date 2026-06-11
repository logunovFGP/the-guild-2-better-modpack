-------------------------------------------------------------------------------
----
----	OVERVIEW "behavior_pretrial.lua"
----
----	Behavior of all Sims which are attended to a current Trial
----	AI Interactions
----	
-------------------------------------------------------------------------------

function Run()
	LogMessage("@TRIAL #W Executing pre-trial behaviour with " .. GetName("Owner"))
	
	if DynastyIsPlayer("Owner") then
		return
	end
	
	if not GetInsideBuilding("Owner", "Townhall") then
		LogMessage("@TRIAL #E The Sim is not inside of the Town Hall (returning)")
		return
	end

	if BuildingGetType("Townhall") ~= GL_BUILDING_TYPE_TOWNHALL then
		LogMessage("@TRIAL #E The Sim is inside some other building, not the Town Hall (returning)")
		Sleep(2)
		return
	end

	BuildingGetRoom("Townhall", "Judge", "judgeroom")
	local CutsceneID = GetProperty("judgeroom", "NextCutsceneID")

	if (CutsceneID == nil) then
		Sleep(2)
		return
	end

	LogMessage("@TRIAL CutsceneID found: " .. CutsceneID)

	if GetAliasByID(CutsceneID, "Trial") == nil then
		LogMessage("@TRIAL #E No valid CutsceneAlias found for this trial...")
		return
	else
		LogMessage("@TRIAL Found valid CutsceneID (" .. GetID("Trial") .. ")")
	end

	local list = {"judge","accuser","accused","assessor1","assessor2"}
	local Checker

	for i = 1, 5 do
		LogMessage("@TRIAL GetDataFromCutscene with " .. list[i])
		Checker = behavior_pretrial_GetDataFromCutscene("Trial", list[i])
		if (Checker ~= false) then
			list[i] = Checker
		else
			return
		end
	end
	
	if HasProperty("", "HaveCutscene") then
		RemoveProperty("", "HaveCutscene")
	end
	
	while true do
		LogMessage("@TRIAL #W Waiting with " .. GetName("Owner"))

		for i = 1, 5 do
			if (GetID("") == list[i]) then
				behavior_pretrial_ActionsForActor(i)
			end
		end
		
		Sleep(10)
	end

end

function GetDataFromCutscene(CutsceneAlias, Data)
	if CutsceneGetData(CutsceneAlias, Data) then
		return GetData(Data)
	else
		return false
	end
end

function ActionsForActor(ID)
	local action = Rand(2)
	LogMessage("@TRIAL Running action " .. action .. ". Sim: " .. GetName("Owner") .. " ("..ID..")")

	if (ID == 3) or (ID == 2) then
		local judge = behavior_pretrial_GetDataFromCutscene("Trial","judge")

		local SimExists = false
		if judge and judge ~= 0 then
			SimExists = GetAliasByID(judge,"JudgeAlias")
		end
		if (SimExists == true) then
			LogMessage("@TRIAL #W Judge found.")
			if AIExecutePlan("", "Trial", "SIM", "", "Trial_Destination", "JudgeAlias") then
				LogMessage("@TRIAL #W AI Plan executed.")
			end
			Sleep(1)
		else
			LogMessage("@TRIAL #W Judge does not exist.")
		end
	end

	if ID > 3 then 
		if GetInsideRoom("", "InsideRoom") then
			if (GetID("judgeroom") ~= GetID("InsideRoom")) then
				Sleep(1)
				return
			end
		end
	end

	if action == 0 then
		RoomGetInsideSimList("judgeroom", "visitor_list")

		local accuser, accused, judge
		if (ID == 2) then 
			accused = behavior_pretrial_GetDataFromCutscene("Trial", "accused")
		elseif (ID ~= 2) and (ID < 4) then
			accuser = behavior_pretrial_GetDataFromCutscene("Trial", "accuser")
		end

		local num = ListSize("visitor_list")
		ListGetElement("visitor_list",Rand(num),"TalkToAlias")

		local list = {"JUDGE","ACCUSER","ACCUSED","ASSESSOR1","ASSESSOR2"}

		if ID == 2 and accused == GetID("TalkToAlias") then
			return
		end

		if not HasProperty("TalkToAlias","BUILDING_NPC") then
			if not ((accuser == GetID("TalkToAlias")) or not (judge == GetID("TalkToAlias"))) then

			if (GetID("") ~= GetID("TalkToAlias") and not DynastyIsPlayer("TalkToAlias")) then
				if CanBeInterruptetBy("","TalkToAlias","BribeCharacter") == true then
					if not HasProperty("TalkToAlias","TrialUse") then
						SetProperty("TalkToAlias","TrialUse",0)
					end
					if (GetProperty("TalkToAlias","TrialUse") > 0) then
					else
						SetProperty("TalkToAlias","TrialUse",GetID(""))
						SetProperty("","TrialUse",GetID(""))
						f_WeakMoveTo("","TalkToAlias",GL_MOVESPEED_WALK,128)
						if (GetProperty("TalkToAlias","TrialUse") == GetID("")) then
							AlignTo("","TalkToAlias")
							AlignTo("TalkToAlias","")
							Sleep(0.5)
	
							LoopAnimation("", "talk", -1)

							if ID == 2 then
								MsgSay("", "@L_ATTENDTRIAL_ACCUSER_TEXT1_QUESTION",accused)
							elseif ID > 3 then
								MsgSay("", "@L_ATTENDTRIAL_ASSESSOR_TEXT1_QUESTION",GetID("AppAlias"))							
							else
								MsgSay("", "@L_ATTENDTRIAL_"..list[ID].."_TEXT1_QUESTION",GetID("AppAlias"))
							end

							StopAnimation("")

							if ID == 1 then
								local Favor = GetFavorToSim("","TalkToAlias")
								if (Favor < 50) then
									PlayAnimationNoWait ("TalkToAlias", "shake_head")
									MsgSay("TalkToAlias", "@L_ATTENDTRIAL_ACCUSED_TEXT1_ANSWER_NEG")
								else
									PlayAnimationNoWait ("TalkToAlias", "nod")
									MsgSay("TalkToAlias", "@L_ATTENDTRIAL_ACCUSED_TEXT1_ANSWER_POS")
								end
							elseif ID == 2 then
								LoopAnimation("TalkToAlias", "talk", -1)
								MsgSay("TalkToAlias", "@L_ATTENDTRIAL_ACCUSER_TEXT1_ANSWER")
							elseif ID > 3 then
								LoopAnimation("", "talk", -1)
								MsgSay("TalkToAlias", "@L_ATTENDTRIAL_ASSESSOR_TEXT1_ANSWER")
							else	
								PlayAnimationNoWait ("TalkToAlias", "nod")
								MsgSay("TalkToAlias", "@L_ATTENDTRIAL_JUDGE_TEXT1_ANSWER")
							end

							StopAnimation("TalkToAlias")	
							AlignTo("TalkToAlias")
							SetProperty("TalkToAlias","TrialUse",0)
							GetFleePosition("","TalkToAlias",Rand(100)+300,"MyPoss")
							
							if GetState("", STATE_CUTSCENE) == false then
								f_WeakMoveTo("","MyPoss")
							end
							
							SetProperty("","TrialUse",0)
						else
							SetProperty("","TrialUse",0)
						end
					end
				end
				end
			end
		end
	end

	if action == 1 then

		local SimExists = false

		if ID == 1 or ID == 2 then
			local accused = behavior_pretrial_GetDataFromCutscene("Trial","accused")
			if accused and accused ~= 0 then
				SimExists = GetAliasByID(accused,"accusedAlias")
			end
			if SimExists then CopyAlias("accusedAlias","TalkToAlias") end
		elseif ID == 3 then
			local accuser = behavior_pretrial_GetDataFromCutscene("Trial","accuser")
			if accuser and accuser ~= 0 then
				SimExists = GetAliasByID(accuser,"accuserAlias")
			end
			if SimExists then CopyAlias("accuserAlias","TalkToAlias") end
		end
		
		if SimExists then
	
			if GetInsideRoom("TalkToAlias","InsideRoom") then
				if CanBeInterruptetBy("","TalkToAlias","BribeCharacter") == true then
					if (GetID("judgeroom") == GetID("InsideRoom")) then
						if (GetID("") ~= GetID("TalkToAlias") and not DynastyIsPlayer("TalkToAlias")) then
							if not HasProperty("TalkToAlias","TrialUse") then
								SetProperty("TalkToAlias","TrialUse",0)
							end
							if (GetProperty("TalkToAlias","TrialUse") > 0) then
							else
								SetProperty("TalkToAlias","TrialUse",GetID(""))
								SetProperty("","TrialUse",GetID(""))
								f_WeakMoveTo("","TalkToAlias",GL_MOVESPEED_WALK,128)
								if (GetProperty("TalkToAlias","TrialUse") == GetID("")) then
									AlignTo("","TalkToAlias")
									AlignTo("TalkToAlias","")
									Sleep(0.5)

									if ID == 1 then 			
										LoopAnimation("", "talk", -1)
										MsgSay("", "@L_ATTENDTRIAL_JUDGE_TEXT2_QUESTION",GetID("AppAlias"))
									elseif ID == 2 then 
										LoopAnimation("", "talk", -1)
										MsgSay("", "@L_ATTENDTRIAL_ACCUSER_TEXT2_QUESTION",GetID("AppAlias"))
									elseif ID == 3 then 
										PlayAnimationNoWait ("", "threat")
										MsgSay("", "@L_ATTENDTRIAL_ACCUSED_TEXT2_QUESTION",GetID("AppAlias"))
									end
									
									StopAnimation("")

									if ID == 1 then 
										local time = PlayAnimationNoWait("TalkToAlias", "devotion")
										MsgSay("TalkToAlias", "@L_ATTENDTRIAL_JUDGE_TEXT2_ANSWER")
									elseif ID == 2 then 
										PlayAnimationNoWait ("TalkToAlias", "threat")
										MsgSay("TalkToAlias", "@L_ATTENDTRIAL_ACCUSER_TEXT2_ANSWER")
									elseif ID == 3 then
										local time = PlayAnimationNoWait("TalkToAlias", "talk")
										MsgSay("TalkToAlias", "@L_ATTENDTRIAL_ACCUSED_TEXT2_ANSWER")
									end								
									
									StopAnimation("TalkToAlias")
			
									AlignTo("TalkToAlias")
									SetProperty("TalkToAlias","TrialUse",0)
									GetFleePosition("","TalkToAlias",Rand(100)+300,"MyPoss")
									
									if GetState("", STATE_CUTSCENE) == false then										
										f_WeakMoveTo("","MyPoss")
									end
									
									SetProperty("","TrialUse",0)
								else
									SetProperty("","TrialUse",0)
								end
							end
						end
					end
				end
			end
		end
	end
end

function ActionsForJudge()
-- ID: 1
end

function ActionsForAccused()
-- ID: 3
end

function ActionsForAccuser()
-- ID: 2
end

function ActionsForAssessor()
-- ID: >3
end