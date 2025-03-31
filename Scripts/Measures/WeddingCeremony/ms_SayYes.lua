function Run()
	SimGetCutscene("","Cutscene")
	CutsceneCallThread("Cutscene", "SayYes", "#MAIN")
end

function CleanUp()
end