function Run()
	SetProperty("", "IsMainActorInWeddingCeremony", "1")
	local _MainChoice
	local _SubChoice
	local _Options = {}

	local START_SELECTING_OPTIONS = 1

	_MainChoice = MsgBox("", "", 
		"@B[0,@L_MEASURE_WEDDING_OPTION_+0]"..
		"@B[1,@L_MEASURE_WEDDING_OPTION_+1]"..
		"@B[2,@L_MEASURE_WEDDING_OPTION_+2]",
		"@L_FAMILY_1_MARRIAGE_MESSAGE_HEAD_LEAVE_+0",
		"@L_MEASURE_WEDDING_QUESTION_+0",
		GetID(""), GetID(""), 0)

	local GetHiredMusicians = function()
		for _, v in helpfuncs_myipairs(_Options) do
			if v == "@B[0,Hire Musicians]" then
				return true
			end
		end
		return false
	end

	local GetDistributeMoney = function()
		for _, v in helpfuncs_myipairs(_Options) do
			if v == "@B[1,Distribute Money]" then
				return true
			end
		end
		return false
	end

	local GetDecorateFlowers = function()
		for _, v in helpfuncs_myipairs(_Options) do
			if v == "@B[2,Decorate with Flowers]" then
				return true
			end
		end
		return false
	end

	local GetBox = function()
		local Labels = ''
		if not GetHiredMusicians() then
			Labels = Labels .. "@B[0,Hire Musicians]"
		end
		if not GetDistributeMoney() then
			Labels = Labels .. "@B[1,Distribute Money]"
		end
		if not GetDecorateFlowers() then
			Labels = Labels .. "@B[2,Decorate with Flowers]"
		end
		return Labels
	end

	local CreateBox = function()
		return MsgBox("", "", 
			GetBox()..
			"@B[3,Let's start the ceremony.]",
			"@B[4,@L_MEASURE_WEDDING_OPTION_+2]",
			"@L_FAMILY_1_MARRIAGE_MESSAGE_HEAD_LEAVE_+0",
			"@L_MEASURE_WEDDING_QUESTION_+0",
			GetID(""), GetID(""), 0)
	end

	local ProcessSelection = function()
		local Selection = CreateBox()
		local Length

		if Selection == 0 then
			Length = helpfuncs_mytablelength(_Options)
			_Options[Length+1] = "@B[0,Hire Musicians]"
		end
		if Selection == 1 then
			Length = helpfuncs_mytablelength(_Options)
			_Options[Length+1] = "@B[1,Distribute Money]"
		end
		if Selection == 2 then
			Length = helpfuncs_mytablelength(_Options)
			_Options[Length+1] = "@B[2,Decorate with Flowers]"
		end
		return Selection
	end

	local Selection

	if _MainChoice == START_SELECTING_OPTIONS then
		repeat
			Selection = ProcessSelection()
		until Selection > 2
	end

	if Selection == 3 then
		ms_debug_weddings_PlayerWedding()
	elseif Selection == 4 then
		ms_debug_weddings_NPCWedding()
	end

end

function PlayerWedding()

	GetSettlement("", "Settlement")
	GetPosition("", "Position")
	SimCreate(918, "Settlement", "Position", "NPC")

	local isGirl = false

	while not isGirl do
		if SimGetGender("NPC") == GL_GENDER_MALE then
			isGirl = false
			SimCreate(918, "Settlement", "Position", "NPC")
		else
			isGirl = true
		end
	end

	SimSetFirstname("NPC", "Courted")
	SimSetLastname("NPC", "Person")

	Sleep(1)
	SimSetCourtLover("", "NPC")
	SimSetProgress("", 100)

	SetProperty("","InWedding",1)
	
    CreateCutscene("WeddingCeremony", "Cutscene(Wedding)")
    CopyAliasToCutscene("", "Cutscene(Wedding)", "#MAIN")
    CopyAliasToCutscene("NPC", "Cutscene(Wedding)", "#COURTED")
    CutsceneCallScheduled("Cutscene(Wedding)", "Init")
end

function NPCWedding()
	GetSettlement("", "Settlement")
	GetPosition("", "Position")

	SimCreate(918, "Settlement", "Position", "NPC_FEMALE")

	local isGirl = false

	while not isGirl do
		if SimGetGender("NPC_FEMALE") == GL_GENDER_MALE then
			isGirl = false
			SimCreate(918, "Settlement", "Position", "NPC_FEMALE")
		else
			isGirl = true
		end
	end

	SimCreate(918, "Settlement", "Position", "NPC_MALE")

	local isGuy = false 

	while not isGuy do
		if SimGetGender("NPC_MALE") == GL_GENDER_FEMALE then
			isGuy = false
			SimCreate(918, "Settlement", "Position", "NPC_MALE")
		else
			isGuy = true
		end
	end

	Sleep(1)
	SimSetCourtLover("NPC_FEMALE", "NPC_MALE")
	SimSetProgress("NPC_FEMALE", 100)
	
    CreateCutscene("WeddingCeremony", "Cutscene(Wedding)")
    CopyAliasToCutscene("NPC_FEMALE", "Cutscene(Wedding)", "#MAIN")
    CopyAliasToCutscene("NPC_MALE", "Cutscene(Wedding)", "#COURTED")
    CutsceneCallScheduled("Cutscene(Wedding)", "Init")
end

function CleanUp()
	LogMessage("CleanUp, in debug measure: Weddings.")
end 