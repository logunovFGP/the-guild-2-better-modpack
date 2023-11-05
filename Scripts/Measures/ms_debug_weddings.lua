function Run()

	if not SimGetCourtLover("", "#Courted") then
		MsgQuick("", "No courted Sim found for "..GetName("").."!")
		return
	end

	CreateCutscene("WeddingCeremony", "Wedding")

	CopyAliasToCutscene("", "Wedding", "#MAIN")
	CopyAliasToCutscene("#Courted", "Wedding", "#COURTED")

	CutsceneCallScheduled("Wedding", "Start")
end

function CleanUp()
end