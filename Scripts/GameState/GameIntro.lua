function Init()

	this:DisableModule("RenderCtrl")

	-- Temporary workaround to avoid game crash with movies.
	this:ChangeGameState("GameStartUp")

	if (false) then
		this:AttachModule("MovieCtrl", "cl_MovePlayController")

		Ctrl = FindNode("\\Application\\Game\\MovieCtrl")
		Ctrl:SetValueString("FileName", "movie/GameIntro.wmv")
		Ctrl:SetValueString("NextGameState", "GameStartUp")

		this:EnableModule("MovieCtrl", 4)
	end

end

function CleanUp()

	this:DetachModule("MovieCtrl")
	this:EnableModule("RenderCtrl", 0)

end





