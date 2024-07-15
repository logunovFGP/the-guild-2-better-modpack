function Run()

	local result = InitData("@P"..
	"@B[1,Player wedding,Start a wedding with your Sim,hud/buttons/btn_will.tga]"..
	"@B[2,AI wedding,Start a wedding involving only NPCs,hud/buttons/btn_will.tga]",
	nil,
	"Which wedding setup do you want to run?",
	"")

	if result == 1 then
		ms_debug_weddings_PlayerWedding()
	else
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