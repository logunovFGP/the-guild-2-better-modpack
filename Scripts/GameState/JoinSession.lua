function Init()

	this:SetValueInt("GameMode",1)
	this:SetValueString("SessionType", "CLIENT")
	this:SetValueString("WorldName", "Hulahup")

	this:AttachModule("SimulationController", "cl_SimulationController")

	this:AttachModule("SessionCtrl", "cl_ClientController")
	this:EnableModule("SessionCtrl", 2)

end

function Idle()

	local WorldReady = 0

	while( WorldReady == 0) do

		Sleep(1)

		local Controller = FindNode("\\Application\\Game\\Controller")
		if( not(Controller == nil)) then

			WorldReady = Controller:GetValueInt("WorldReady")

		end

	end

	local World = FindNode("\\World")
	World:SetValueInt("Renderable", 1)

	Game:ChangeGameState("Game")

end

function CleanUp()


	this:DetachModule("SessionSelector")

end


