local function MissionsEnding(ShowStats,MissionEnds,Won)

	if ShowStats then
		ShowStatistics()
		local panels = {"StatisticsSheetGold", "StatisticsSheetAsset", "StatisticsSheetSkill", "StatisticsSheetAlign", "StatisticsSheetPoints", "StatisticsBalanceLast", "StatisticsBalanceTotal"}
		local i = 1

		while i <= 7 do
		  if HudPanelIsVisible(panels[i]) then
		    Sleep(1.0)
		    i = 1
		  else
		    i = i + 1
		  end
		end
	end

	if MissionEnds then
		CampaignExit(Won)
	end

end

function CleanUp()
end

local CreateMissionManager = function()

	local self = 
	{
		victory = 0,
		message = 
		{
			{"@L_FAMILY_6_DEATH_MSG_DEAD_END_OWNER_HEAD","@L_FAMILY_6_DEATH_MSG_DEAD_END_OWNER_BODY", GetProperty("Actor", "LastMemberID")},
			{"@L_TOOMUCHDEBT_2_HEAD", "@L_TOOMUCHDEBT_2_BODY", GetID("Actor")}
		},
		showstats = false,
		missionEnds = false,
		hasWon = true
	}

	self.setEnding = function(NUM)
		self.victory = NUM
			if NUM < 3 then
				self.hasWon = false
				f_StartHighPriorMusic(MUSIC_GAME_LOST)
			end
	end

	self.setMessage = function(index)
		self.message[3] = index
	end

	self.initEnding = function()
		MissionsEnding(self.showstats,self.missionEnds,self.hasWon)
	end

	self.getMsg = function(index)
		return self.message[self.victory][index]
	end

	self.toggleEnding = function(bool)
		self.missionEnds = bool
	end

	self.toggleStats = function(bool)
		self.showstats = bool
	end

	return self

end

MissionManager = CreateMissionManager()