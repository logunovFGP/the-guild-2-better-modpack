function CheckStart()
  return true
end

function Start()
	local Options = FindNode("\\Settings\\Options")
	local Difficulty = Options:GetValueInt("MissionDifficulty")
	
	SetData("MissionDifficulty",Difficulty)
	if (Difficulty==0) then
		SetData("MoneyLimit",25000)
		SetData("DiffReplace","EASY")
	elseif (Difficulty==1) then
		SetData("MoneyLimit",100000)
		SetData("DiffReplace","MEDIUM")
	else
		SetData("MoneyLimit",500000)
		SetData("DiffReplace","HARD")
	end

	GetLocalPlayerDynasty("LocalPlayerDynasty")
	if (GetID("LocalPlayerDynasty") == GetID("Actor")) then
		SetMainQuestTitle("MAIN_MISSION","@L_INTERFACE_MISSIONS_QUESTBOOK_HEADER","@L_MISSIONS_MISSIONS_MAKEMONEY_+0")
		SetMainQuestDescription("MAIN_MISSION","@L_MISSIONS_MISSIONS_MAKEMONEY_+1",GetData("MoneyLimit"))
		SetMainQuest("MAIN_MISSION")
	end
	
	GetScenario("World")
	if HasProperty("World", "Finito") then
		RemoveProperty("World", "Finito")
	end
	
	feedback_MessageMission("Actor","@L_MISSIONS_MISSIONS_MAKEMONEY_+0","@L_MISSIONS_MISSIONS_MAKEMONEY_+1",GetData("MoneyLimit"))
end

function CheckEnd()

	if HasProperty("World", "Finito") then
		return true
	end

	if (DynastyGetRanking("Actor") >= GetData("MoneyLimit")) then
		return true
	else
		if CheckPlayerExtinct("Actor") then
			SetData("extinct", 1)
			return true
		elseif CheckPlayerBankrupt("Actor") then
			SetData("bankrupt", 1)
			return true
		end
		
		GetLocalPlayerDynasty("LocalPlayerDynasty")
		if (GetID("LocalPlayerDynasty") == GetID("Actor")) then
			SetMainQuestDescription("MAIN_MISSION","@L_INTERFACE_MISSIONS_MAKEMONEY_+0",GetData("MoneyLimit"),DynastyGetRanking("Actor"))
		end
		return false
  end
end

function End()

	if IsMultiplayerGame() then

		if HasProperty("World", "Finito") then
			if MsgBox("Actor", nil, "@P@B[1,Let's go for a few more rounds...]@B[2,This game's over. Let's stop now.]", "@L_MISSIONS_MISSIONS_LOOSE_HEAD", "@L_MISSIONS_MISSIONS_LOOSE_MULTIPLAYER_BODY", GetProperty("World", "Finito")) == 2 then
				DynastyAvoidControl("Actor")
			end
			return
		end

		if HasData("extinct") then 
			MsgBoxNoWait("Actor", nil, "@L_FAMILY_6_DEATH_MSG_DEAD_END_OWNER_HEAD", "@L_FAMILY_6_DEATH_MSG_DEAD_END_OWNER_BODY", GetProperty("Actor", "LastMemberID"))
			f_StartHighPriorMusic(MUSIC_GAME_LOST)
		elseif HasData("bankrupt") then 
			MsgBoxNoWait("Actor", nil, "@L_TOOMUCHDEBT_2_HEAD", "@L_TOOMUCHDEBT_2_BODY", GetID("Actor"))
			f_StartHighPriorMusic(MUSIC_GAME_LOST)
		else
			SetProperty("World", "Finito", GetID("Actor"))
			if (GetID("LocalPlayerDynasty") == GetID("Actor")) then
				f_StartHighPriorMusic(MUSIC_GAME_WON)
					if MsgBox("Actor", nil, "@P@B[1,Let's go for a few more rounds...]@B[2,This game's over. Let's stop now.]", "@L_MISSIONS_MISSIONS_MAKEMONEY_+0", "@L_MISSIONS_MISSIONS_MAKEMONEY_+2", GetData("MoneyLimit")) == 2 then
						DynastyAvoidControl("Actor")
					end	
			else
				f_StartHighPriorMusic(MUSIC_GAME_LOST)
			end
		end
			
	else

		Include ( "campaign/_missions/Mission_Manager.lua" )

		if HasData("extinct") then
			MissionManager.setEnding(1)
		elseif HasData("bankrupt") then
			MissionManager.setEnding(2)
		else
			MissionManager.setEnding(3)
			MissionManager.setMessage({"@L_MISSIONS_MISSIONS_MAKEMONEY_+0", "@L_MISSIONS_MISSIONS_MAKEMONEY_+2", GetData("MoneyLimit")})
			f_StartHighPriorMusic(MUSIC_GAME_WON)
		end

		local query = MsgBox("Actor", nil, "@P@B[1,@L_INTERFACE_BUTTONS_ENDGAME]@B[2,@L_INTERFACE_BUTTONS_STATISTICS]@B[3,Let's go for a few more rounds...]", MissionManager.getMsg(1), MissionManager.getMsg(2), MissionManager.getMsg(3))
			if query < 3 and query ~= "C" then
				MissionManager.toggleEnding(true)
				if query == 2 then
					MissionManager.toggleStats(true)
				end
			end

		MissionManager.initEnding()

	end
	
end

function CleanUp()
end
