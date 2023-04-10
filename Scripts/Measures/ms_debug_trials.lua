function loadTexture(ID)
	return trialData.texture[ID]
end

function modifyToggle(ID)
	local checker = trialData.presence[ID]
	if checker then
		trialData.tog(ID,'ManageEmployee',"won't")
	else
		trialData.tog(ID,'Ok',"will")
	end
end

varManager =
	function()
		local self = {
			list = {"judge","accuser","accused","assessor1","assessor2"},
			presence = {true,true,true,true,true},
			texture = {'Ok','Ok','Ok','Ok','Ok'}
		}
		self.tog =
			function(ID,TEXTURE,STRING)
				self.texture[ID] = TEXTURE
				self.presence[ID] = not self.presence[ID]
				LogMessage("CodeRework, Trial. The actor "..self.list[ID].." "..STRING.." be attending the trial.")
			end

		self.debug =
			function()
				self.Attending = {}
				for i = 1, 5 do
					if self.presence[i] then
						LogMessage("CodeRework, Trial. Fortunately, our "..(self.list[i]).." will be attending the trial.")
						self.Attending[i] = self.list[i]
					else
						LogMessage("CodeRework, Trial. Unfortunately, our "..(self.list[i]).." will be missing the trial.")
						self.Attending[i] = nil
					end
				end
			end

		self.title =
			function(ID)
				if self.presence[ID] then 
					return '0'
				else
					return '1'
				end
			end

		return self
	end

trialData = varManager()

function Run()

	local result = InitData("@P"..
	"@B[1,@L_GENERAL_TITLE_JUDGE_+"..trialData.title(1)..",Should the Judge participate in the trial?,hud/buttons/btn_"..trialData.texture[1]..".tga]"..
	"@B[2,@L_GENERAL_TITLE_ACCUSER_+"..trialData.title(2)..",Should the Plaintiff participate in the trial?,hud/buttons/btn_"..trialData.texture[2]..".tga]"..
	"@B[3,@L_GENERAL_TITLE_ACCUSED_+"..trialData.title(3)..",Should the Defendant participate in the trial?,hud/buttons/btn_"..trialData.texture[3]..".tga]"..
	"@B[4,@L_GENERAL_TITLE_ASSESSOR2_+"..trialData.title(4)..",Should the first Assessor participate in the trial?,hud/buttons/btn_"..trialData.texture[4]..".tga]"..
	"@B[5,@L_GENERAL_TITLE_ASSESSOR1_+"..trialData.title(5)..",Should the second Assessor participate in the trial?,hud/buttons/btn_"..trialData.texture[5]..".tga]"..
	"@B[6,Start!,Click this button to start the action and checks whether or not some participants should miss the trial.,hud/buttons/btn_BuildingUpgrade.tga]",
	nil,
	"Which actor should be missing the trial? Check = attending!",
	"")

	if result ~= "C" and result ~= 6 then
		ms_debug_trials_modifyToggle(result)
		ms_debug_trials_Run() 
	end
	if result == 6 then 
		ms_debug_trials_Start()
	end

end

function Start()
	if debugTrial == false then ms_debug_trials_triggerDebug() end
	LogMessage("Starting a debug trial")

	local Names = {"Fajeth","ThreeOfMe","Nao","Ictiv","Erilambus","VSX","Jollina","F-man","Craftgeeking","Dr.Kulid357","drouz"}

	SimCreate(918, "", "", "NPC")
	SimSetFirstname("NPC", "Almighty")
	SimSetLastname("NPC", Names[Rand(11)+1])
	AddEvidence("", "NPC", "", Rand(15)+1, "NPC") -- Note: charges go up to 15
	GetSettlement("", "Settlement")
	CityGetRandomBuilding("Settlement",GL_BUILDING_CLASS_PUBLICBUILDING,GL_BUILDING_TYPE_TOWNHALL,-1,-1,FILTER_IGNORE,"CouncilBuilding")
	GetLocatorByName("councilbuilding", "ApproachUsherPos", "destpos")
	SimBeamMeUp("", "destpos", false)
	SimChargeCharacter("","NPC")
end

function CleanUp()
end

debugTrial = false
function triggerDebug()
	debugTrial = not debugTrial
end