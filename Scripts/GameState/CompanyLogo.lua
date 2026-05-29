function Init()

	this:DisableModule("RenderCtrl")

	-- Temporary workaround to avoid game crash with movies.
	if (true or this:GetSettingInt("GAME", "SplashScreen", 0) == 0) then

		this:ChangeGameState("GameStartUp")

	else

		this:AttachModule("MovieCtrl", "cl_MovePlayController")

		Ctrl = FindNode("\\Application\\Game\\MovieCtrl")
		Ctrl:SetValueString("FileName", "movie/CompanyLogo.wmv")
		-- Ctrl:SetValueString("NextGameState", "CoPublisherLogo")
		Ctrl:SetValueString("NextGameState", "DeveloperLogo")

		this:EnableModule("MovieCtrl", 4)
	end

end

function CleanUp()

	this:DetachModule("MovieCtrl")

	this:EnableModule("RenderCtrl", 0)

end





