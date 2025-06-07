function OnButtonPressed_ReturnToStartMenu(x, y, device, key)
	local HUD = FindNode("\\application\\game\\hud")
	local GAME = FindNode("\\application\\game\\hud")
	HUD:ShowPanel("Changelogs", false)
	GAME:ShowStartMenu()
end

