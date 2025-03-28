function Run()
	SetProperty("","InWedding",1)
	CreateCutscene("Debug/WeddingPanel", "Cutscene")
	CopyAliasToCutscene("", "Cutscene", "Spouse1")
	CutsceneCallScheduled("Cutscene", "Start")
end