load = 
{
	[1]='hud/buttons/btn_Ok.tga',
	[2]='hud/buttons/btn_Ok.tga',
	[3]='hud/buttons/btn_Ok.tga',
	[4]='hud/buttons/btn_Ok.tga',
	[5]='hud/buttons/btn_Ok.tga'
}

function loadTexture(ID)
	return load[ID]
end

-- this:function(param) is just a syntax shortcut for this.function(this, param) NAUNO:RUN()

function toggle(ID)
	if ID ~= '6' then
		local list = {"1","2","3","4","5"}
		for i = 1,5 do
			if ID == list[i] then
				ID = i
			end
		end
		if load[ID] == 'hud/buttons/btn_Ok.tga' then
			load[ID] = 'hud/buttons/btn_ManageEmployee.tga'
		else
			load[ID] = 'hud/buttons/btn_Ok.tga'
		end
	end
end

function Run()

	local result = InitData("@P"..
	"@B[1,Judge,Should the Judge participate in the trial?,"..ms_debug_trials_loadTexture(1).."]"..
	"@B[2,Plaint.,Should the Plaintiff participate in the trial?,"..ms_debug_trials_loadTexture(2).."]"..
	"@B[3,Defend.,Should the Defendant participate in the trial?,"..ms_debug_trials_loadTexture(3).."]"..
	"@B[4,1st Ass.,Should the first Assessor participate in the trial?,"..ms_debug_trials_loadTexture(4).."]"..
	"@B[5,2st Ass.,Should the second Assessor participate in the trial?,"..ms_debug_trials_loadTexture(5).."]"..
	"@B[6,Start!,Click this button to start the action and checks whether or not some participants should miss the trial.,hud/buttons/btn_BuildingUpgrade.tga]",
	nil,
	"Which actor should be missing the trial? Check = attending!",
	"")

	LogMessage("result is: "..result)

	if result ~= "C" and result ~= 6 then
		ms_debug_trials_toggle(string.sub(result,1)) -- d
		ms_debug_trials_Run() 
	end
	if result == 6 then 
		ms_debug_trials_Start()
	elseif result == "C" then
		Cold.infectSim('',true)
	end

end

function Start()
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
