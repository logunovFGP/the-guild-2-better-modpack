function Run()
	SimGetCutscene("","Cutscene")
	CutsceneCallThread("Cutscene", "SayNo", "#MAIN")
end

function CleanUp()
end