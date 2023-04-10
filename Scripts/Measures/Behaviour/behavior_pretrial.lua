-------------------------------------------------------------------------------
----
----	OVERVIEW "behavior_pretrial.lua"
----
----	Behavior of all Sims which are attended to a current Trial
----	AI Interactions
----	
-------------------------------------------------------------------------------

function Run()
	LogMessage("behavior_pretrial: Running Run()")
	
	if DynastyIsPlayer("") then
		return
	end
	
	if not GetInsideBuilding("", "Townhall") then
		LogMessage("PreTrial, no InsideRoom for"..GetName(""))
		return
	end

	BuildingGetRoom("Townhall", "Judge", "judgeroom")
	local CutsceneID = GetProperty("judgeroom","NextCutsceneID")

	if GetAliasByID(CutsceneID,"CutsceneAlias") == nil then
		LogMessage("No Cutscene Alias from judgeroom")
	end

	local list = {"judge","accuser","accused","assessor1","assessor2"}

	for i = 1, 5 do
		list[i] = behavior_pretrial_GetDataFromCutscene("CutsceneAlias", list[i])
	end
	
	if HasProperty("", "HaveCutscene") then
		LogMessage("PreTrial: remove HaveCutscene")
		RemoveProperty("", "HaveCutscene")
	end
	
	while true do

		LogMessage("behavior_pretrial: Running while true do")

		for i = 1, 5 do
			if (GetID("") == list[i]) then
				LogMessage("43 | TRIAL: Actor ["..list[i].."] is making an Action")
				LogMessage("Actor is making an Action")
				behavior_pretrial_ActionsForActor(i)
			end
		end
		
		Sleep(10)
	end

end

function GetDataFromCutscene(CutsceneAlias, Data)
	CutsceneGetData(CutsceneAlias, Data)
	return GetData(Data)
end

function ActionsForActor(ID)
	LogMessage("behavior_pretrial: Running ActionForActor("..ID..")")
	local action = Rand(2)

	if ID == 3 or ID == 2 then 
		local judge = behavior_pretrial_GetDataFromCutscene("CutsceneAlias","judge")
		local SimExists = GetAliasByID(judge,"JudgeAlias")
		if (SimExists == true) then
			--AIExecutePlan("", "Trial", "SIM", "","Trial_Destination","JudgeAlias")  e
			Sleep(1)
		end
	end

	if ID > 3 then 
		if GetInsideRoom("","InsideRoom") then
			if (GetID("judgeroom") ~= GetID("InsideRoom")) then
				return
			end
		end
	end

	if action == 0 then

		RoomGetInsideSimList("judgeroom","visitor_list")

		local accuser, accused, judge
		if ID == 2 then 
			accused = behavior_pretrial_GetDataFromCutscene("CutsceneAlias","accused")
		elseif ID ~= 2 and ID < 4 then
			accuser = behavior_pretrial_GetDataFromCutscene("CutsceneAlias","accuser")
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

		if ID == 1 or ID == 2 then 
			local accused = behavior_pretrial_GetDataFromCutscene("CutsceneAlias","accused")
			local SimExists = GetAliasByID(accused,"accusedAlias")
			if SimExists then CopyAlias("accusedAlias","TalkToAlias") end
		elseif ID == 3 then 
			local accuser = behavior_pretrial_GetDataFromCutscene("CutsceneAlias","accuser")
			local SimExists = GetAliasByID(accuser,"accuserAlias")
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